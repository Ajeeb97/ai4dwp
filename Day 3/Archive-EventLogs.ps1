#Requires -Version 5.1
<#
.SYNOPSIS
    Archive and clean up Windows Event Logs for DWP endpoints.
.DESCRIPTION
    Exports selected Windows Event Log channels to dated .evtx archive files,
    then clears the live logs. Only logs that contain records older than the
    configured age threshold are targeted. Supports dry-run preview, rollback
    from a previous archive run, timestamped audit logging, and idempotent
    execution — if a log was already archived today it is automatically skipped.
.PARAMETER DryRun
    Preview mode. Reports how many old records exist in each log without
    modifying any logs or creating any files.
.PARAMETER OlderThanDays
    Only process event logs that contain at least one record older than this
    many days. Default: 3.
.PARAMETER LogNames
    Array of Windows Event Log channel names to target.
    Default: Application, System, Security, Setup.
.PARAMETER ArchiveRoot
    Root folder used for archive output, rollback manifests, and script logs.
    Default: C:\EventLogArchive.
.PARAMETER Rollback
    Restore previously archived .evtx files to a dated Restored subfolder and
    print instructions for loading them in Windows Event Viewer.
.PARAMETER RollbackArchivePath
    Full path to a specific archive run folder to restore from.
    If omitted, the most recent folder under ArchiveRoot is used automatically.
.EXAMPLE
    # Preview what would be archived — no changes made
    .\Archive-EventLogs.ps1 -DryRun

    # Archive logs containing records older than the default 3 days
    .\Archive-EventLogs.ps1

    # Archive logs with records older than 7 days
    .\Archive-EventLogs.ps1 -OlderThanDays 7

    # Target only specific channels
    .\Archive-EventLogs.ps1 -LogNames Application,System -OlderThanDays 3

    # Roll back the most recent archive run
    .\Archive-EventLogs.ps1 -Rollback

    # Roll back a specific archive run (dry-run preview)
    .\Archive-EventLogs.ps1 -Rollback -RollbackArchivePath "C:\EventLogArchive\20260810_040205" -DryRun
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Archive')]
param(
    # Preview mode — shared between Archive and Rollback parameter sets
    [Parameter(ParameterSetName = 'Archive')]
    [Parameter(ParameterSetName = 'Rollback')]
    [switch]$DryRun,

    # Age threshold in days; logs with no records older than this are skipped
    [Parameter(ParameterSetName = 'Archive')]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$OlderThanDays = 3,

    # Windows Event Log channel names to evaluate
    [Parameter(ParameterSetName = 'Archive')]
    [string[]]$LogNames = @('Application', 'System', 'Security', 'Setup'),

    # Root folder for archive files, manifests, and script log files
    [Parameter(ParameterSetName = 'Archive')]
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$ArchiveRoot = 'C:\EventLogArchive',

    # Activates rollback mode instead of archive mode
    [Parameter(ParameterSetName = 'Rollback', Mandatory)]
    [switch]$Rollback,

    # Optional: explicit archive run folder to restore from; auto-detected if omitted
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$RollbackArchivePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =============================================================================
# SECTION: Runtime constants
# Computed once at startup; all paths and timestamps derive from these values.
# =============================================================================
$runTimestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$todayStamp   = Get-Date -Format 'yyyyMMdd'
$cutoffDate   = (Get-Date).AddDays(-$OlderThanDays)

# Script log files are kept in a Logs subfolder so they do not mix with archives
$scriptLogDir  = Join-Path $ArchiveRoot 'Logs'
$scriptLogFile = Join-Path $scriptLogDir "EventLogArchive_$runTimestamp.log"

# Each archive run gets its own timestamped subfolder under ArchiveRoot
$archiveRunDir = Join-Path $ArchiveRoot $runTimestamp
$manifestPath  = Join-Path $archiveRunDir 'manifest.csv'

# =============================================================================
# SECTION: Summary counters
# Accumulated throughout execution and printed in the final report.
# =============================================================================
$summary = [ordered]@{
    LogsEvaluated    = 0
    LogsArchived     = 0
    LogsSkipped      = 0
    LogsFailed       = 0
    TotalOldRecords  = 0
}

# =============================================================================
# SECTION: Write-Log helper
# Writes a timestamped, level-tagged line to both the console and the log file.
# =============================================================================
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DRY')]
        [string]$Level = 'INFO'
    )

    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message

    switch ($Level) {
        'ERROR' { Write-Host $line -ForegroundColor Red    }
        'WARN'  { Write-Host $line -ForegroundColor Yellow }
        'DRY'   { Write-Host $line -ForegroundColor Cyan   }
        default { Write-Host $line }
    }

    # Append to log file; warn on failure but do not abort the run
    try {
        Add-Content -Path $scriptLogFile -Value $line -Encoding UTF8
    }
    catch {
        Write-Warning "Unable to write to log file '$scriptLogFile': $_"
    }
}

# =============================================================================
# SECTION: Administrator privilege check
# Event log operations require elevation; fail fast with a clear message.
# =============================================================================
function Assert-AdminPrivilege {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'This script must be run as Administrator. Right-click PowerShell and choose "Run as administrator".'
    }
}

# =============================================================================
# SECTION: Directory initialisation
# Creates the script log directory before the first Write-Log call.
# =============================================================================
function Initialize-LogDirectory {
    if (-not (Test-Path $scriptLogDir)) {
        try {
            New-Item -ItemType Directory -Path $scriptLogDir -Force | Out-Null
        }
        catch {
            # Fall back to a temp path so logging still works
            $script:scriptLogFile = Join-Path $env:TEMP "EventLogArchive_$runTimestamp.log"
            Write-Warning "Could not create log directory '$scriptLogDir'. Logging to '$script:scriptLogFile'."
        }
    }
}

# =============================================================================
# SECTION: Old-record counter
# Queries Get-WinEvent with an EndTime filter to count records older than the
# cutoff. Returns the count, or -1 when the query itself throws an error.
# =============================================================================
function Get-OldRecordCount {
    param(
        [string]   $LogName,
        [datetime] $CutoffDate
    )

    try {
        # EndTime = upper bound, so this returns all records created before the cutoff
        $filter = @{
            LogName = $LogName
            EndTime = $CutoffDate
        }
        $events = Get-WinEvent -FilterHashtable $filter -ErrorAction SilentlyContinue
        return $(if ($events) { $events.Count } else { 0 })
    }
    catch {
        Write-Log "Could not query records in '$LogName': $_" -Level ERROR
        return -1
    }
}

# =============================================================================
# SECTION: Idempotency check
# Scans all archive run folders created today and returns $true if the given
# log name already appears in one of their manifests.
# =============================================================================
function Test-AlreadyArchivedToday {
    param([string]$LogName)

    try {
        $todayFolders = Get-ChildItem -Path $ArchiveRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "$todayStamp*" }

        foreach ($folder in $todayFolders) {
            $mPath = Join-Path $folder.FullName 'manifest.csv'
            if (Test-Path $mPath) {
                $rows = Import-Csv -Path $mPath -Encoding UTF8 -ErrorAction SilentlyContinue
                if ($rows | Where-Object { $_.LogName -eq $LogName }) {
                    return $true
                }
            }
        }
    }
    catch {
        Write-Log "Idempotency check error for '$LogName': $_" -Level WARN
    }

    return $false
}

# =============================================================================
# SECTION: Archive-SingleLog
# Exports a log channel to an .evtx file using wevtutil, clears the live log,
# and appends a manifest row so the run can be rolled back.
# Returns $true on full success, $false if any step fails.
# =============================================================================
function Archive-SingleLog {
    param(
        [string]$LogName,
        [string]$ArchiveRunDir,
        [string]$ManifestPath
    )

    # Replace path-separator characters so the log name is safe as a filename
    $safeName    = $LogName -replace '[/\\<>:"|?*]', '-'
    $archivePath = Join-Path $ArchiveRunDir "$safeName.evtx"

    # Create the per-run archive directory on first use
    if (-not (Test-Path $ArchiveRunDir)) {
        try {
            New-Item -ItemType Directory -Path $ArchiveRunDir -Force | Out-Null
            Write-Log "Created archive run directory: $ArchiveRunDir"
        }
        catch {
            Write-Log "Failed to create archive directory '$ArchiveRunDir': $_" -Level ERROR
            return $false
        }
    }

    # --- Step A: Export the full log to an .evtx file ---
    Write-Log "Exporting '$LogName' to '$archivePath' ..."
    try {
        # /ow:true overwrites the destination file if it already exists
        $output = wevtutil.exe epl $LogName $archivePath /ow:true 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "wevtutil epl returned exit code $LASTEXITCODE. Output: $output"
        }
        Write-Log "Export of '$LogName' completed successfully."
    }
    catch {
        Write-Log "Export failed for '$LogName': $_" -Level ERROR
        return $false
    }

    # --- Step B: Clear the live log now that the archive is safely written ---
    Write-Log "Clearing live log '$LogName' ..."
    try {
        $output = wevtutil.exe cl $LogName 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "wevtutil cl returned exit code $LASTEXITCODE. Output: $output"
        }
        Write-Log "Cleared '$LogName' successfully. Archive preserved at: $archivePath"
    }
    catch {
        Write-Log "Clear failed for '$LogName' (archive is preserved at '$archivePath'): $_" -Level ERROR
        return $false
    }

    # --- Step C: Append a manifest row for rollback use ---
    try {
        $row = [PSCustomObject]@{
            LogName     = $LogName
            ArchivePath = $archivePath
            ArchivedAt  = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        }
        $csvParams = @{
            Path              = $ManifestPath
            NoTypeInformation = $true
            Encoding          = 'UTF8'
        }
        if (Test-Path $ManifestPath) {
            $row | Export-Csv @csvParams -Append
        }
        else {
            $row | Export-Csv @csvParams
        }
        Write-Log "Manifest updated: $ManifestPath"
    }
    catch {
        Write-Log "Could not write manifest entry for '$LogName': $_" -Level WARN
    }

    return $true
}

# =============================================================================
# SECTION: Rollback helper — locate the most recent timestamped archive folder
# =============================================================================
function Get-LatestArchiveFolder {
    try {
        $folders = Get-ChildItem -Path $ArchiveRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^\d{8}_\d{6}$' } |
            Sort-Object Name -Descending
        if ($folders) { return $folders[0].FullName }
    }
    catch {
        Write-Log "Error scanning '$ArchiveRoot' for archive folders: $_" -Level ERROR
    }
    return $null
}

# =============================================================================
# SECTION: Invoke-Rollback
# Reads the manifest from a previous archive run and copies each archived .evtx
# file to a new Restored_ subfolder. The restored files can be opened in Windows
# Event Viewer (File > Open Saved Log) to inspect or retrieve the original events.
# Automated re-import into the live channel is intentionally avoided because it
# requires stopping the Windows Event Log service, which is disruptive.
# =============================================================================
function Invoke-Rollback {
    param([string]$ArchiveFolderPath)

    $mPath = Join-Path $ArchiveFolderPath 'manifest.csv'

    if (-not (Test-Path $mPath)) {
        Write-Log "Manifest not found at '$mPath'. Cannot proceed with rollback." -Level ERROR
        return
    }

    try {
        $entries = Import-Csv -Path $mPath -Encoding UTF8
    }
    catch {
        Write-Log "Failed to read manifest '$mPath': $_" -Level ERROR
        return
    }

    if (-not $entries) {
        Write-Log "Manifest '$mPath' is empty — nothing to restore." -Level WARN
        return
    }

    # Each rollback run gets its own dated restore folder to avoid collisions
    $restoreDir = Join-Path $ArchiveRoot "Restored_$runTimestamp"

    foreach ($entry in $entries) {
        $logName     = $entry.LogName
        $archivePath = $entry.ArchivePath

        Write-Log "Rollback: processing '$logName' (archived at '$($entry.ArchivedAt)')"

        if (-not (Test-Path $archivePath)) {
            Write-Log "Archive file missing for '$logName': '$archivePath'" -Level WARN
            continue
        }

        if ($DryRun) {
            Write-Log "[DRY RUN] Would copy '$archivePath' to '$restoreDir'" -Level DRY
            continue
        }

        # Create the restore destination directory on first use
        try {
            if (-not (Test-Path $restoreDir)) {
                New-Item -ItemType Directory -Path $restoreDir -Force | Out-Null
                Write-Log "Created restore directory: $restoreDir"
            }
        }
        catch {
            Write-Log "Failed to create restore directory '$restoreDir': $_" -Level ERROR
            continue
        }

        # Copy the .evtx archive to the restore folder
        try {
            $destPath = Join-Path $restoreDir (Split-Path $archivePath -Leaf)
            Copy-Item -Path $archivePath -Destination $destPath -Force
            Write-Log "Restored '$logName' archive to: $destPath"
            Write-Log "  --> To view events: open Windows Event Viewer, File > Open Saved Log > $destPath"
        }
        catch {
            Write-Log "Copy failed for '$logName': $_" -Level ERROR
        }
    }

    if (-not $DryRun -and (Test-Path $restoreDir)) {
        Write-Log "All restored archives are in: $restoreDir"
        Write-Log "Open each .evtx file in Windows Event Viewer (File > Open Saved Log) to inspect the original events."
    }
}

# =============================================================================
# MAIN EXECUTION STARTS HERE
# =============================================================================

# --- Privilege check (fail immediately if not elevated) ---
try {
    Assert-AdminPrivilege
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}

# --- Ensure the script log directory exists before the first Write-Log call ---
Initialize-LogDirectory

# --- Opening banner ---
Write-Log ('=' * 60)
Write-Log "  DWP Event Log Archive Utility  |  Run ID: $runTimestamp"
Write-Log "  Host: $env:COMPUTERNAME  |  User: $env:USERNAME"
if ($DryRun)   { Write-Log '  MODE: DRY RUN — no changes will be made to any log' -Level DRY }
if ($Rollback) { Write-Log '  MODE: ROLLBACK' }
Write-Log ('=' * 60)

# =============================================================================
# SECTION: Rollback execution path
# When -Rollback is specified the script locates or accepts an archive folder,
# then restores the archived .evtx files to a dated Restored_ directory.
# =============================================================================
if ($Rollback) {
    # Auto-detect the most recent archive folder if none was supplied
    if (-not $RollbackArchivePath) {
        Write-Log 'No -RollbackArchivePath specified; locating most recent archive folder ...'
        try {
            $RollbackArchivePath = Get-LatestArchiveFolder
        }
        catch {
            Write-Log "Error during auto-detection of archive folder: $_" -Level ERROR
        }
    }

    if (-not $RollbackArchivePath -or -not (Test-Path $RollbackArchivePath)) {
        Write-Log "No valid archive folder found. Provide -RollbackArchivePath or run an archive first." -Level ERROR
        exit 1
    }

    Write-Log "Source archive folder: $RollbackArchivePath"
    Invoke-Rollback -ArchiveFolderPath $RollbackArchivePath

    Write-Log ('=' * 60)
    Write-Log '  Rollback complete.'
    Write-Log "  Script log: $scriptLogFile"
    Write-Log ('=' * 60)
    exit 0
}

# =============================================================================
# SECTION: Archive execution path
# Iterates over each target log channel, counts old records, skips ineligible
# or already-archived logs, then archives and clears qualifying logs.
# =============================================================================
Write-Log "Age threshold : records older than $OlderThanDays day(s) (before $($cutoffDate.ToString('yyyy-MM-dd HH:mm:ss')))"
Write-Log "Target logs   : $($LogNames -join ', ')"
Write-Log "Archive root  : $ArchiveRoot"
Write-Log ('-' * 60)

foreach ($logName in $LogNames) {
    $summary.LogsEvaluated++
    Write-Log "Evaluating: $logName"

    # --- Query the count of records older than the cutoff ---
    $oldCount = -1
    try {
        $oldCount = Get-OldRecordCount -LogName $logName -CutoffDate $cutoffDate
    }
    catch {
        Write-Log "Unexpected error querying '$logName': $_" -Level ERROR
        $summary.LogsFailed++
        continue
    }

    if ($oldCount -lt 0) {
        # Get-OldRecordCount already logged the error details
        $summary.LogsFailed++
        Write-Log ('-' * 60)
        continue
    }

    if ($oldCount -eq 0) {
        Write-Log "  No records older than $OlderThanDays day(s) found — skipping '$logName'."
        $summary.LogsSkipped++
        Write-Log ('-' * 60)
        continue
    }

    Write-Log "  Found $oldCount record(s) older than $OlderThanDays day(s) in '$logName'."
    $summary.TotalOldRecords += $oldCount

    # --- Dry run: report and move to next log without making changes ---
    if ($DryRun) {
        Write-Log "  [DRY RUN] Would archive and clear '$logName' ($oldCount old record(s) would be removed)." -Level DRY
        Write-Log ('-' * 60)
        continue
    }

    # --- Idempotency check: skip logs already archived today ---
    try {
        if (Test-AlreadyArchivedToday -LogName $logName) {
            Write-Log "  '$logName' was already archived today ($todayStamp). Skipping (idempotent)." -Level WARN
            $summary.LogsSkipped++
            Write-Log ('-' * 60)
            continue
        }
    }
    catch {
        Write-Log "  Idempotency check error for '$logName': $_" -Level WARN
        # Continue with the archive attempt rather than skipping on check failure
    }

    # --- Archive and clear the log ---
    try {
        $ok = Archive-SingleLog -LogName $logName -ArchiveRunDir $archiveRunDir -ManifestPath $manifestPath
        if ($ok) {
            $summary.LogsArchived++
            Write-Log "  '$logName' archived successfully."
        }
        else {
            $summary.LogsFailed++
        }
    }
    catch {
        Write-Log "  Unhandled error archiving '$logName': $_" -Level ERROR
        $summary.LogsFailed++
    }

    Write-Log ('-' * 60)
}

# =============================================================================
# SECTION: Final summary report
# Prints a structured summary of the run to both console and log file.
# =============================================================================
Write-Log ('=' * 60)
Write-Log '  SUMMARY'
Write-Log ('=' * 60)
Write-Log "  Logs evaluated     : $($summary.LogsEvaluated)"
Write-Log "  Logs archived      : $($summary.LogsArchived)"
Write-Log "  Logs skipped       : $($summary.LogsSkipped)"
Write-Log "  Logs failed        : $($summary.LogsFailed)"
Write-Log "  Old records found  : $($summary.TotalOldRecords)"

if ($DryRun) {
    Write-Log '  [DRY RUN] No changes were made.' -Level DRY
}
elseif ($summary.LogsArchived -gt 0) {
    Write-Log "  Archive folder     : $archiveRunDir"
    Write-Log "  Manifest           : $manifestPath"
    Write-Log "  To roll back this run, use:"
    Write-Log "    .\Archive-EventLogs.ps1 -Rollback -RollbackArchivePath `"$archiveRunDir`""
}

Write-Log "  Script log         : $scriptLogFile"
Write-Log ('=' * 60)

# Exit with code 1 when any log failed so calling systems (e.g. Task Scheduler) can detect the error
if ($summary.LogsFailed -gt 0) { exit 1 }
exit 0
