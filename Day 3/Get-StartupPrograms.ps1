#Requires -Version 5.1
<#
.SYNOPSIS
    Audit and manage Windows startup programs for DWP endpoints.
.DESCRIPTION
    Lists all startup programs registered via the common Run registry keys and
    startup folders. When -Disable is used, the named entry is disabled via the
    StartupApproved registry mechanism (the same method Task Manager uses) so
    the original command value is preserved and can be re-enabled at any time.
.PARAMETER Disable
    Name of the startup entry to disable. Must match the Name column shown in
    the default listing. Case-insensitive.
.PARAMETER ShowAll
    Include entries that are already disabled in the listing (hidden by default).
.EXAMPLE
    .\Get-StartupPrograms.ps1
    .\Get-StartupPrograms.ps1 -ShowAll
    .\Get-StartupPrograms.ps1 -Disable "OneDrive"
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Disable,

    [switch]$ShowAll
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# =============================================================================
# SECTION: Registry source definitions
# Maps each Run key to its StartupApproved counterpart where Windows stores the
# enabled/disabled state without deleting the original command value.
# =============================================================================
$registrySources = @(
    @{
        RunKey      = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
        ApprovedKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
        Scope       = 'HKLM (All Users)'
        NeedsAdmin  = $true
    },
    @{
        RunKey      = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
        ApprovedKey = $null
        Scope       = 'HKLM RunOnce (All Users)'
        NeedsAdmin  = $true
    },
    @{
        RunKey      = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
        ApprovedKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
        Scope       = 'HKCU (Current User)'
        NeedsAdmin  = $false
    },
    @{
        RunKey      = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
        ApprovedKey = $null
        Scope       = 'HKCU RunOnce (Current User)'
        NeedsAdmin  = $false
    },
    @{
        # 32-bit apps on 64-bit Windows register under Wow6432Node
        RunKey      = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run'
        ApprovedKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
        Scope       = 'HKLM 32-bit (All Users)'
        NeedsAdmin  = $true
    }
)

$startupFolders = @(
    @{ Path = [Environment]::GetFolderPath('Startup');       Scope = 'Startup Folder (Current User)' },
    @{ Path = [Environment]::GetFolderPath('CommonStartup'); Scope = 'Startup Folder (All Users)'    }
)

# =============================================================================
# SECTION: Disabled-state check
# Reads the StartupApproved binary value; byte[0] = 0x03 means disabled.
# =============================================================================
function Test-StartupEntryDisabled {
    param([string]$ApprovedKey, [string]$EntryName)
    if (-not $ApprovedKey -or -not (Test-Path $ApprovedKey)) { return $false }
    try {
        $raw = (Get-ItemProperty -Path $ApprovedKey -Name $EntryName -ErrorAction SilentlyContinue).$EntryName
        if ($raw -is [byte[]] -and $raw.Length -ge 4) { return $raw[0] -eq 0x03 }
    }
    catch { }
    return $false
}

# =============================================================================
# SECTION: Collect entries from registry Run keys
# =============================================================================
function Get-RegistryStartupEntries {
    $entries = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($source in $registrySources) {
        if (-not (Test-Path $source.RunKey)) { continue }
        try {
            $props = Get-ItemProperty -Path $source.RunKey -ErrorAction Stop
        }
        catch {
            Write-Warning "Cannot read '$($source.RunKey)': $_"
            continue
        }

        $valueNames = $props.PSObject.Properties |
            Where-Object { $_.Name -notmatch '^PS(Path|ParentPath|ChildName|Drive|Provider)$' } |
            Select-Object -ExpandProperty Name

        foreach ($name in $valueNames) {
            $disabled = Test-StartupEntryDisabled -ApprovedKey $source.ApprovedKey -EntryName $name
            $entries.Add([PSCustomObject]@{
                Name        = $name
                Command     = $props.$name
                Location    = $source.RunKey
                Scope       = $source.Scope
                Status      = if ($disabled) { 'Disabled' } else { 'Enabled' }
                ApprovedKey = $source.ApprovedKey
                NeedsAdmin  = $source.NeedsAdmin
            })
        }
    }
    return $entries
}

# =============================================================================
# SECTION: Collect entries from startup folders (.lnk shortcuts)
# =============================================================================
function Get-FolderStartupEntries {
    $entries = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($folder in $startupFolders) {
        if (-not (Test-Path $folder.Path)) { continue }
        try {
            $shortcuts = Get-ChildItem -Path $folder.Path -Filter '*.lnk' -ErrorAction Stop
        }
        catch {
            Write-Warning "Cannot read startup folder '$($folder.Path)': $_"
            continue
        }
        foreach ($lnk in $shortcuts) {
            $target = ''
            try {
                $shell  = New-Object -ComObject WScript.Shell
                $target = $shell.CreateShortcut($lnk.FullName).TargetPath
            }
            catch { $target = $lnk.FullName }

            $entries.Add([PSCustomObject]@{
                Name        = [System.IO.Path]::GetFileNameWithoutExtension($lnk.Name)
                Command     = $target
                Location    = $lnk.FullName
                Scope       = $folder.Scope
                Status      = 'Enabled'
                ApprovedKey = $null
                NeedsAdmin  = $false
            })
        }
    }
    return $entries
}

# =============================================================================
# SECTION: Disable a startup entry
# Writes the disabled flag (byte[0] = 0x03) to the StartupApproved key.
# This preserves the original command value in the Run key, making it reversible.
# =============================================================================
function Disable-StartupEntry {
    param([PSCustomObject]$Entry)

    if ($Entry.Status -eq 'Disabled') {
        Write-Host "  '$($Entry.Name)' is already disabled. No change made." -ForegroundColor Yellow
        return
    }

    if (-not $Entry.ApprovedKey) {
        Write-Warning "'$($Entry.Name)' is a startup-folder shortcut. Delete or move the .lnk file manually to disable it."
        return
    }

    if ($Entry.NeedsAdmin) {
        $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error "'$($Entry.Name)' is a machine-wide (HKLM) entry. Re-run as Administrator to disable it."
            return
        }
    }

    # 12-byte disabled flag: first byte 0x03, rest 0x00 (matches Task Manager behaviour)
    $disabledFlag = [byte[]](0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)

    try {
        if (-not (Test-Path $Entry.ApprovedKey)) {
            New-Item -Path $Entry.ApprovedKey -Force | Out-Null
        }
        Set-ItemProperty -Path $Entry.ApprovedKey -Name $Entry.Name -Value $disabledFlag -Type Binary -ErrorAction Stop
        Write-Host "  '$($Entry.Name)' disabled successfully." -ForegroundColor Green
        Write-Host "  Approval key : $($Entry.ApprovedKey)"
        Write-Host "  To re-enable : remove the '$($Entry.Name)' value from the approval key, or set byte[0] to 0x02."
    }
    catch {
        Write-Error "Failed to disable '$($Entry.Name)': $_"
    }
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
Write-Host ''
Write-Host ('=' * 70) -ForegroundColor Cyan
Write-Host '  DWP Startup Program Auditor' -ForegroundColor Cyan
Write-Host "  Host: $env:COMPUTERNAME  |  User: $env:USERNAME  |  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ('=' * 70) -ForegroundColor Cyan
Write-Host ''

$allEntries = [System.Collections.Generic.List[PSCustomObject]]::new()
try { Get-RegistryStartupEntries | ForEach-Object { $allEntries.Add($_) } } catch { Write-Warning "Registry scan error: $_" }
try { Get-FolderStartupEntries   | ForEach-Object { $allEntries.Add($_) } } catch { Write-Warning "Folder scan error: $_"   }

# =============================================================================
# SECTION: Disable mode
# =============================================================================
if ($Disable) {
    Write-Host "Disable mode: searching for '$Disable' ..." -ForegroundColor Yellow
    Write-Host ''

    $target = $allEntries | Where-Object { $_.Name -ieq $Disable } | Select-Object -First 1
    if (-not $target) {
        Write-Error "No startup entry named '$Disable' found. Run without -Disable to list all entries."
        exit 1
    }

    Write-Host "  Name     : $($target.Name)"
    Write-Host "  Location : $($target.Location)"
    Write-Host "  Command  : $($target.Command)"
    Write-Host "  Status   : $($target.Status)"
    Write-Host ''

    Disable-StartupEntry -Entry $target
    Write-Host ''
    exit 0
}

# =============================================================================
# SECTION: List mode — group by scope for structured output
# =============================================================================
$displayEntries = if ($ShowAll) { $allEntries } else { $allEntries | Where-Object { $_.Status -eq 'Enabled' } }

if (-not $displayEntries) {
    Write-Host 'No startup entries found.' -ForegroundColor Yellow
    exit 0
}

foreach ($group in ($displayEntries | Group-Object -Property Scope)) {
    Write-Host "  [$($group.Name)]" -ForegroundColor Cyan
    foreach ($item in $group.Group) {
        $color = if ($item.Status -eq 'Disabled') { 'DarkGray' } else { 'White' }
        $tag   = if ($item.Status -eq 'Disabled') { '[DISABLED] ' } else { '' }
        Write-Host ("    {0,-35} {1}{2}" -f $item.Name, $tag, $item.Command) -ForegroundColor $color
    }
    Write-Host ''
}

$enabledCount  = ($allEntries | Where-Object { $_.Status -eq 'Enabled'  }).Count
$disabledCount = ($allEntries | Where-Object { $_.Status -eq 'Disabled' }).Count

Write-Host ('─' * 70)
Write-Host "  Total: $($allEntries.Count)  |  Enabled: $enabledCount  |  Disabled: $disabledCount"
if (-not $ShowAll -and $disabledCount -gt 0) {
    Write-Host "  ($disabledCount disabled entries hidden — use -ShowAll to include them)" -ForegroundColor DarkGray
}
Write-Host ''
Write-Host '  To disable an entry:  .\Get-StartupPrograms.ps1 -Disable "<Name>"' -ForegroundColor DarkGray
Write-Host ('=' * 70) -ForegroundColor Cyan
Write-Host ''
