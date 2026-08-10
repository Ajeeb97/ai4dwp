# Endpoint Health Report (Read-Only)
# PowerShell 5.1 script for DWP endpoint diagnostics.
# This script only reads system information and does not modify system state.

# ==============================
# Section 1: System uptime
# What this does:
# Reads the last boot time from Win32_OperatingSystem and calculates current uptime.
# VERIFY BEFORE RUNNING:
# - to confirm: CIM/WMI access is permitted on this device.
# ==============================
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $lastBoot = $os.LastBootUpTime
    $uptime = (Get-Date) - $lastBoot

    Write-Host "=== 1. System Uptime ===" -ForegroundColor Cyan
    Write-Host ("Last Boot Time : {0}" -f $lastBoot)
    Write-Host ("Uptime         : {0} days {1} hours {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
    Write-Host ""
}
catch {
    Write-Host "=== 1. System Uptime ===" -ForegroundColor Cyan
    Write-Host ("Unable to read uptime: {0}" -f $_.Exception.Message)
    Write-Host ""
}

# ==============================
# Section 2: Free disk space
# What this does:
# Lists local fixed disks and reports total size and free space in GB.
# VERIFY BEFORE RUNNING:
# - to confirm: local disk enumeration via CIM is allowed.
# ==============================
try {
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop

    Write-Host "=== 2. Free Disk Space ===" -ForegroundColor Cyan
    if ($disks) {
        $disks |
            Select-Object DeviceID,
                          @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB, 2)}},
                          @{Name='FreeGB';Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
                          @{Name='FreePercent';Expression={
                              if ($_.Size -gt 0) {
                                  [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
                              }
                              else {
                                  $null
                              }
                          }} |
            Format-Table -AutoSize
    }
    else {
        Write-Host "No local fixed disks found."
    }
    Write-Host ""
}
catch {
    Write-Host "=== 2. Free Disk Space ===" -ForegroundColor Cyan
    Write-Host ("Unable to read disk information: {0}" -f $_.Exception.Message)
    Write-Host ""
}

# ==============================
# Section 3: Pending reboot (registry checks)
# What this does:
# Checks common Windows registry indicators that suggest a reboot is pending.
# VERIFY BEFORE RUNNING:
# - to confirm: these registry paths match your enterprise baseline and OS build.
# ==============================
$pendingRebootIndicators = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
)

Write-Host "=== 3. Pending Reboot Status ===" -ForegroundColor Cyan

$rebootPending = $false
$matchedIndicators = New-Object System.Collections.Generic.List[string]

# Indicator 1: CBS RebootPending key exists
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
    $rebootPending = $true
    $matchedIndicators.Add('Component Based Servicing: RebootPending key exists') | Out-Null
}

# Indicator 2: Windows Update RebootRequired key exists
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
    $rebootPending = $true
    $matchedIndicators.Add('Windows Update: RebootRequired key exists') | Out-Null
}

# Indicator 3: PendingFileRenameOperations has entries
try {
    $sessionManager = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue
    if ($null -ne $sessionManager.PendingFileRenameOperations) {
        $rebootPending = $true
        $matchedIndicators.Add('Session Manager: PendingFileRenameOperations is present') | Out-Null
    }
}
catch {
    # Ignore missing value or access issues for this single indicator.
}

Write-Host ("Pending reboot: {0}" -f $rebootPending)
if ($matchedIndicators.Count -gt 0) {
    Write-Host "Matched indicators:"
    $matchedIndicators | ForEach-Object { Write-Host ("- {0}" -f $_) }
}
else {
    Write-Host "No common pending reboot indicators found."
}
Write-Host ""

# ==============================
# Section 4: Top 5 processes by memory (Working Set)
# What this does:
# Lists the five running processes using the most physical memory (working set).
# VERIFY BEFORE RUNNING:
# - to confirm: endpoint policy allows process inspection for all users.
# ==============================
try {
    Write-Host "=== 4. Top 5 Processes by Memory (Working Set) ===" -ForegroundColor Cyan
    Get-Process -ErrorAction Stop |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First 5 ProcessName, Id,
                      @{Name='WorkingSetMB';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}},
                      @{Name='CPUSeconds';Expression={$_.CPU}},
                      Path |
        Format-Table -AutoSize
    Write-Host ""
}
catch {
    Write-Host "=== 4. Top 5 Processes by Memory (Working Set) ===" -ForegroundColor Cyan
    Write-Host ("Unable to read process memory usage: {0}" -f $_.Exception.Message)
    Write-Host ""
}

# ==============================
# Section 5: Top 5 processes by CPU
# What this does:
# Lists the five processes with the highest cumulative CPU time since process start.
# VERIFY BEFORE RUNNING:
# - to confirm: CPU metric here is cumulative CPU seconds, not real-time CPU percentage.
# ==============================
try {
    Write-Host "=== 5. Top 5 Processes by CPU (Cumulative Seconds) ===" -ForegroundColor Cyan
    Get-Process -ErrorAction Stop |
        Where-Object { $null -ne $_.CPU } |
        Sort-Object -Property CPU -Descending |
        Select-Object -First 5 ProcessName, Id,
                      @{Name='CPUSeconds';Expression={[math]::Round($_.CPU, 2)}},
                      @{Name='WorkingSetMB';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}},
                      Path |
        Format-Table -AutoSize
    Write-Host ""
}
catch {
    Write-Host "=== 5. Top 5 Processes by CPU (Cumulative Seconds) ===" -ForegroundColor Cyan
    Write-Host ("Unable to read process CPU usage: {0}" -f $_.Exception.Message)
    Write-Host ""
}

# ==============================
# Section 6: Last 5 system log errors
# What this does:
# Reads the System event log and returns the 5 most recent Error-level events.
# VERIFY BEFORE RUNNING:
# - to confirm: reading System log is permitted and log retention is sufficient.
# ==============================
try {
    Write-Host "=== 6. Last 5 System Log Errors ===" -ForegroundColor Cyan
    # Level 2 = Error
    Get-WinEvent -FilterHashtable @{LogName='System'; Level=2} -MaxEvents 5 -ErrorAction Stop |
        Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message |
        Format-List
    Write-Host ""
}
catch {
    Write-Host "=== 6. Last 5 System Log Errors ===" -ForegroundColor Cyan
    Write-Host ("Unable to read System event log errors: {0}" -f $_.Exception.Message)
    Write-Host ""
}

Write-Host "Endpoint health report completed (read-only checks)." -ForegroundColor Green
