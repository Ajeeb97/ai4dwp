#Requires -Version 5.1
<#
.SYNOPSIS
    Safe temp-file cleanup utility for DWP Windows endpoints.
.DESCRIPTION
    Removes temporary files from standard Windows temp locations.
    Supports dry-run preview, age filtering, per-file error handling,
    rollback from backup archive, timestamped logging, and idempotent execution.
.PARAMETER DryRun
    Lists files that would be deleted without removing anything.
.PARAMETER OlderThanDays
    Only target files whose LastWriteTime is older than this many days. Default: 0 (all files).
.PARAMETER Rollback
    Restores files from the most recent rollback archive created by this script.
.PARAMETER RollbackArchivePath
    Full path to a specific rollback archive folder to restore from (overrides auto-detect).
.PARAMETER DryRun
    When combined with -Rollback, lists files that would be restored without copying anything.
.EXAMPLE
    .\Cleanup-TempFiles.ps1 -DryRun
    .\Cleanup-TempFiles.ps1 -OlderThanDays 30
    .\Cleanup-TempFiles.ps1 -OlderThanDays 7 -DryRun
    .\Cleanup-TempFiles.ps1 -Rollback
    .\Cleanup-TempFiles.ps1 -Rollback -DryRun
    .\Cleanup-TempFiles.ps1 -Rollback -RollbackArchivePath "C:\CleanupRollback\20260810_143000"
    .\Cleanup-TempFiles.ps1 -Rollback -RollbackArchivePath "C:\CleanupRollback\20260810_143000" -DryRun
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Cleanup')]
param(
    # Preview mode - no files are deleted or restored when this switch is set.
    [Parameter(ParameterSetName = 'Cleanup')]
    [Parameter(ParameterSetName = 'Rollback')]
    [switch]$DryRun,

    # Age threshold in days; files newer than this are skipped.
    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$OlderThanDays = 0,

    # Trigger rollback mode instead of cleanup.
    [Parameter(ParameterSetName = 'Rollback', Mandatory)]
    [switch]$Rollback,

    # Optional explicit rollback archive path; auto-detected if omitted.
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$RollbackArchivePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================
# SECTION: Constants and path setup
# Root directory for rollback archives and log files lives
# alongside the script to keep everything self-contained.
# ============================================================
$ScriptRoot    = Split-Path -Parent $MyInvocation.MyCommand.Path
$RunTimestamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
$LogDir        = Join-Path $ScriptRoot 'CleanupLogs'
$RollbackRoot  = Join-Path $ScriptRoot 'CleanupRollback'
$LogFile       = Join-Path $LogDir "cleanup_$RunTimestamp.log"

# Temp locations targeted by this script.
# VERIFY: Confirm these paths are approved for cleanup under your DWP endpoint policy.
$TargetPaths = @(
    $env:TEMP,
    $env:TMP,
    (Join-Path $env:SystemRoot 'Temp')
) | Select-Object -Unique | Where-Object { Test-Path $_ }

# ============================================================
# SECTION: Logging helper
# Writes a timestamped entry to both the console and the log
# file. Colour-codes output by severity for quick scanning.
# ============================================================
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )

    $entry = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message

    $colour = switch ($Level) {
        'WARN'    { 'Yellow'  }
        'ERROR'   { 'Red'     }
        'SUCCESS' { 'Green'   }
        default   { 'Cyan'    }
    }

    Write-Host $entry -ForegroundColor $colour
    Add-Content -Path $LogFile -Value $entry -Encoding UTF8
}

# ============================================================
# SECTION: Initialisation
# Creates required directories and writes the run header to
# the log so each log file is self-describing.
# ============================================================
foreach ($dir in @($LogDir, $RollbackRoot)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Log "=========================================="
Write-Log "DWP Temp Cleanup Script - Run: $RunTimestamp"
Write-Log "ParameterSet : $($PSCmdlet.ParameterSetName)"
Write-Log "DryRun       : $DryRun"
Write-Log "OlderThanDays: $OlderThanDays"
Write-Log "=========================================="

# ============================================================
# SECTION: Rollback mode
# Reads the manifest CSV written during a previous cleanup run
# and copies each backed-up file back to its original location.
# Idempotent: if the original file already exists it is skipped.
# ============================================================
if ($Rollback) {
    Write-Log "Rollback mode activated." 'INFO'

    # Auto-detect the most recent archive if no explicit path given.
    if (-not $RollbackArchivePath) {
        $latest = Get-ChildItem -Path $RollbackRoot -Directory |
                      Sort-Object Name -Descending |
                      Select-Object -First 1

        if (-not $latest) {
            Write-Log "No rollback archives found in: $RollbackRoot" 'ERROR'
            exit 1
        }
        $RollbackArchivePath = $latest.FullName
    }

    $manifest = Join-Path $RollbackArchivePath 'manifest.csv'
    if (-not (Test-Path $manifest)) {
        Write-Log "Manifest not found at: $manifest" 'ERROR'
        exit 1
    }

    Write-Log "Restoring from archive: $RollbackArchivePath"
    if ($DryRun) { Write-Log '--- DRY RUN - no files will be restored ---' 'WARN' }
    $entries        = Import-Csv -Path $manifest
    $restoredCount  = 0
    $skippedCount   = 0
    $rollbackErrors = 0

    foreach ($entry in $entries) {
        $originalPath = $entry.OriginalPath
        $backupPath   = $entry.BackupPath

        # Idempotency: file already back in place - nothing to do.
        if (Test-Path $originalPath) {
            Write-Log "SKIP (already exists): $originalPath" 'WARN'
            $skippedCount++
            continue
        }

        if (-not (Test-Path $backupPath)) {
            Write-Log "SKIP (backup missing): $backupPath" 'WARN'
            $skippedCount++
            continue
        }

        if ($DryRun) {
            Write-Log "WOULD RESTORE: $originalPath  [from: $backupPath]"
            $restoredCount++
            continue
        }

        try {
            $destDir = Split-Path -Parent $originalPath
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item -Path $backupPath -Destination $originalPath -Force
            Write-Log "RESTORED: $originalPath" 'SUCCESS'
            $restoredCount++
        }
        catch {
            Write-Log "ROLLBACK ERROR [$originalPath]: $($_.Exception.Message)" 'ERROR'
            $rollbackErrors++
        }
    }

    Write-Log "------------------------------------------"
    $rollbackMode = if ($DryRun) { 'DRY RUN' } else { 'COMPLETE' }
    Write-Log "Rollback $rollbackMode - Would restore: $restoredCount  Skipped: $skippedCount  Errors: $rollbackErrors"
    Write-Log "Log saved to: $LogFile"
    exit 0
}

# ============================================================
# SECTION: File discovery
# Recursively enumerates files under each target path and
# applies the age filter. Directories and system files are
# excluded; only plain files are considered for deletion.
# ============================================================
Write-Log "Discovering files in target paths..."
$cutoffDate = (Get-Date).AddDays(-$OlderThanDays)
$candidateFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

foreach ($targetPath in $TargetPaths) {
    Write-Log "Scanning: $targetPath"
    try {
        $files = Get-ChildItem -Path $targetPath -Recurse -File -Force -ErrorAction SilentlyContinue |
                     Where-Object { $_.LastWriteTime -lt $cutoffDate }
        foreach ($f in $files) { $candidateFiles.Add($f) }
    }
    catch {
        Write-Log "Could not enumerate path [$targetPath]: $($_.Exception.Message)" 'WARN'
    }
}

Write-Log "Files found matching criteria: $($candidateFiles.Count)"

if ($candidateFiles.Count -eq 0) {
    Write-Log "Nothing to process. Exiting." 'SUCCESS'
    exit 0
}

# ============================================================
# SECTION: Dry-run mode
# Prints what would be deleted without touching anything.
# Script exits cleanly after listing; no archive is created.
# ============================================================
if ($DryRun) {
    Write-Log "--- DRY RUN - no files will be deleted ---" 'WARN'
    foreach ($file in $candidateFiles) {
        Write-Log "WOULD DELETE: $($file.FullName)  [LastWrite: $($file.LastWriteTime)]  [Size: $($file.Length) bytes]"
    }
    $totalSize = ($candidateFiles | Measure-Object -Property Length -Sum).Sum
    Write-Log "--- DRY RUN COMPLETE - $($candidateFiles.Count) file(s), $([math]::Round($totalSize/1MB,2)) MB would be freed ---" 'SUCCESS'
    Write-Log "Log saved to: $LogFile"
    exit 0
}

# ============================================================
# SECTION: Rollback archive creation
# Before deleting anything, every candidate file is copied to
# a timestamped archive folder and recorded in manifest.csv.
# This makes the cleanup fully reversible via -Rollback.
# ============================================================
$archivePath = Join-Path $RollbackRoot $RunTimestamp
New-Item -ItemType Directory -Path $archivePath -Force | Out-Null
Write-Log "Rollback archive created: $archivePath"

$manifestPath    = Join-Path $archivePath 'manifest.csv'
$manifestEntries = [System.Collections.Generic.List[PSCustomObject]]::new()
$archiveErrors   = 0

foreach ($file in $candidateFiles) {
    # Preserve relative path inside archive so filenames never collide.
    $relativePath = $file.FullName -replace [regex]::Escape($env:SystemDrive), '' -replace '^\\', ''
    $backupDest   = Join-Path $archivePath $relativePath

    try {
        $backupDir = Split-Path -Parent $backupDest
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        Copy-Item -Path $file.FullName -Destination $backupDest -Force
        $manifestEntries.Add([PSCustomObject]@{
            OriginalPath = $file.FullName
            BackupPath   = $backupDest
            SizeBytes    = $file.Length
            LastWriteTime = $file.LastWriteTime
        })
    }
    catch {
        Write-Log "ARCHIVE ERROR [$($file.FullName)]: $($_.Exception.Message)" 'WARN'
        $archiveErrors++
    }
}

$manifestEntries | Export-Csv -Path $manifestPath -NoTypeInformation -Encoding UTF8
Write-Log "Manifest written: $manifestPath  ($($manifestEntries.Count) entries, $archiveErrors archive errors)"

# ============================================================
# SECTION: File deletion
# Attempts to delete each candidate file individually.
# Locked files are caught and logged; the script continues.
# Already-absent files are skipped (idempotency).
# ============================================================
Write-Log "Starting deletion..."

$deletedCount = 0
$skippedCount = 0
$lockedCount  = 0
$errorCount   = 0
$deletedBytes = [long]0

foreach ($file in $candidateFiles) {

    # Idempotency: another process may have already removed this file.
    if (-not (Test-Path -LiteralPath $file.FullName)) {
        Write-Log "SKIP (already gone): $($file.FullName)" 'WARN'
        $skippedCount++
        continue
    }

    try {
        # Attempt removal; an IOException here usually means the file is locked.
        Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
        Write-Log "DELETED: $($file.FullName)  [$($file.Length) bytes]" 'SUCCESS'
        $deletedBytes += $file.Length
        $deletedCount++
    }
    catch [System.IO.IOException] {
        # File is held open by another process - log and continue, do not abort.
        Write-Log "LOCKED (skipped): $($file.FullName) - $($_.Exception.Message)" 'WARN'
        $lockedCount++
    }
    catch {
        Write-Log "ERROR deleting [$($file.FullName)]: $($_.Exception.Message)" 'ERROR'
        $errorCount++
    }
}

# ============================================================
# SECTION: Empty directory pruning
# After file deletion, remove any directories that are now
# empty. Errors are non-fatal - a dir may still be in use.
# ============================================================
Write-Log "Pruning empty directories..."
foreach ($targetPath in $TargetPaths) {
    try {
        $emptyDirs = Get-ChildItem -Path $targetPath -Recurse -Directory -Force -ErrorAction SilentlyContinue |
                         Where-Object { ($_ | Get-ChildItem -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0 } |
                         Sort-Object FullName -Descending  # deepest first

        foreach ($dir in $emptyDirs) {
            try {
                Remove-Item -LiteralPath $dir.FullName -Force -ErrorAction Stop
                Write-Log "REMOVED EMPTY DIR: $($dir.FullName)" 'INFO'
            }
            catch {
                Write-Log "SKIP DIR (in use): $($dir.FullName)" 'WARN'
            }
        }
    }
    catch {
        Write-Log "Could not prune directories in [$targetPath]: $($_.Exception.Message)" 'WARN'
    }
}

# ============================================================
# SECTION: Summary report
# Printed to both console and log file for audit purposes.
# ============================================================
$freedMB = [math]::Round($deletedBytes / 1MB, 2)

Write-Log "=========================================="
Write-Log "CLEANUP SUMMARY"
Write-Log "  Deleted      : $deletedCount file(s)  ($freedMB MB freed)"
Write-Log "  Skipped      : $skippedCount (already absent)"
Write-Log "  Locked       : $lockedCount (in use by another process)"
Write-Log "  Errors       : $errorCount"
Write-Log "  Archive errors: $archiveErrors"
Write-Log "  Rollback from: $archivePath"
Write-Log "  Log file     : $LogFile"
Write-Log "=========================================="
