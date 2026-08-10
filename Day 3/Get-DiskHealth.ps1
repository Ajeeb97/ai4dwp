#Requires -Version 5.1
<#
.SYNOPSIS
    Report disk health and optimisation status for DWP endpoints. READ-ONLY.
.DESCRIPTION
    Gathers and displays health, capacity, and optimisation state for all disks
    and volumes on the local machine using WMI/CIM and PowerShell Storage cmdlets.
    This script is STRICTLY READ-ONLY. It never invokes defragmentation,
    optimisation, disk repair, formatting, or any write operation of any kind.
.PARAMETER IncludeReliability
    Include SMART-style storage reliability counters (temperature, wear level,
    error counts) where the hardware exposes them.
.PARAMETER ExportCsv
    Optional path to export a combined report as a CSV file.
.EXAMPLE
    .\Get-DiskHealth.ps1
    .\Get-DiskHealth.ps1 -IncludeReliability
    .\Get-DiskHealth.ps1 -IncludeReliability -ExportCsv C:\Reports\disk-health.csv
#>

[CmdletBinding()]
param(
    [switch]$IncludeReliability,
    [string]$ExportCsv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# =============================================================================
# SECTION: Output helpers
# =============================================================================
function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host "  [$Title]" -ForegroundColor Cyan
    Write-Host ('  ' + ('─' * 66)) -ForegroundColor DarkGray
}

function Write-Field {
    param([string]$Label, [string]$Value, [System.ConsoleColor]$ValueColor = 'White')
    Write-Host ("    {0,-30} {1}" -f ($Label + ':'), $Value) -ForegroundColor $ValueColor
}

# Maps common status strings to a console colour for quick visual scanning
function Get-StatusColor {
    param([string]$Status)
    switch -Regex ($Status) {
        'Healthy|OK|Online|Pass|Good|True' { return 'Green'  }
        'Warning|Degraded|Unknown'          { return 'Yellow' }
        'Unhealthy|Failed|Offline|Error'    { return 'Red'    }
        default                             { return 'Gray'   }
    }
}

function Format-Value {
    param($Value)
    if ($null -eq $Value -or "$Value" -eq '') { return 'N/A' }
    return "$Value"
}

# =============================================================================
# SECTION: Physical disk report
# Get-PhysicalDisk reads hardware identity and health state — no writes occur.
# =============================================================================
function Show-PhysicalDisks {
    Write-Section 'PHYSICAL DISKS'
    try {
        $disks = Get-PhysicalDisk -ErrorAction Stop | Sort-Object DeviceId
    }
    catch {
        Write-Host "    Unable to query physical disks: $_" -ForegroundColor Yellow
        return @()
    }

    $report = foreach ($disk in $disks) {
        $sizeGB = if ($disk.Size -gt 0) { [math]::Round($disk.Size / 1GB, 1) } else { 0 }
        Write-Host ''
        Write-Host "    Disk $($disk.DeviceId): $($disk.FriendlyName)" -ForegroundColor White
        Write-Field 'Media Type'           $disk.MediaType
        Write-Field 'Bus Type'             $disk.BusType
        Write-Field 'Size'                 "$sizeGB GB"
        Write-Field 'Health Status'        (Format-Value $disk.HealthStatus)       -ValueColor (Get-StatusColor $disk.HealthStatus)
        Write-Field 'Operational Status'   (Format-Value $disk.OperationalStatus)  -ValueColor (Get-StatusColor $disk.OperationalStatus)
        Write-Field 'Firmware Version'     (Format-Value $disk.FirmwareVersion)
        Write-Field 'Serial Number'        (Format-Value $disk.SerialNumber)
        Write-Field 'Spindle Speed (RPM)'  (if ($disk.SpindleSpeed -gt 0) { "$($disk.SpindleSpeed)" } else { 'N/A (SSD/NVMe)' })

        [PSCustomObject]@{
            Section           = 'PhysicalDisk'
            Id                = $disk.DeviceId
            Name              = $disk.FriendlyName
            MediaType         = $disk.MediaType
            BusType           = $disk.BusType
            SizeGB            = $sizeGB
            HealthStatus      = $disk.HealthStatus
            OperationalStatus = $disk.OperationalStatus
            FirmwareVersion   = $disk.FirmwareVersion
            SerialNumber      = $disk.SerialNumber
        }
    }
    return $report
}

# =============================================================================
# SECTION: Volume report
# Get-Volume reads file system metadata and space usage — no writes occur.
# =============================================================================
function Show-Volumes {
    Write-Section 'VOLUMES'
    try {
        $volumes = Get-Volume -ErrorAction Stop |
            Where-Object { $_.DriveLetter -or $_.FileSystemLabel } |
            Sort-Object DriveLetter
    }
    catch {
        Write-Host "    Unable to query volumes: $_" -ForegroundColor Yellow
        return @()
    }

    $report = foreach ($vol in $volumes) {
        $totalGB = if ($vol.Size          -gt 0) { [math]::Round($vol.Size          / 1GB, 2) } else { 0 }
        $freeGB  = if ($vol.SizeRemaining -gt 0) { [math]::Round($vol.SizeRemaining / 1GB, 2) } else { 0 }
        $usedGB  = [math]::Round($totalGB - $freeGB, 2)
        $freePct = if ($totalGB -gt 0) { [math]::Round($freeGB / $totalGB * 100, 1) } else { 0 }

        # 20-character visual bar for used vs free space
        $usedBars   = if ($totalGB -gt 0) { [int]([math]::Round($usedGB / $totalGB * 20)) } else { 0 }
        $bar        = '[' + ('#' * $usedBars) + ('.' * (20 - $usedBars)) + ']'
        $spaceColor = if ($freePct -lt 10) { 'Red' } elseif ($freePct -lt 20) { 'Yellow' } else { 'Green' }

        $label = if ($vol.DriveLetter) { "$($vol.DriveLetter):\" } else { '(no drive letter)' }
        Write-Host ''
        Write-Host "    $label  $($vol.FileSystemLabel)  [$($vol.FileSystem)]" -ForegroundColor White
        Write-Field 'Health Status'      (Format-Value $vol.HealthStatus)      -ValueColor (Get-StatusColor $vol.HealthStatus)
        Write-Field 'Operational Status' (Format-Value $vol.OperationalStatus) -ValueColor (Get-StatusColor $vol.OperationalStatus)
        Write-Field 'Total Size'         "$totalGB GB"
        Write-Field 'Used'               "$usedGB GB"
        Write-Host  ("    {0,-30} {1} {2}% free" -f 'Free Space:', $bar, $freePct) -ForegroundColor $spaceColor

        [PSCustomObject]@{
            Section           = 'Volume'
            DriveLetter       = $vol.DriveLetter
            Label             = $vol.FileSystemLabel
            FileSystem        = $vol.FileSystem
            TotalGB           = $totalGB
            UsedGB            = $usedGB
            FreeGB            = $freeGB
            FreePercent       = $freePct
            HealthStatus      = $vol.HealthStatus
            OperationalStatus = $vol.OperationalStatus
        }
    }
    return $report
}

# =============================================================================
# SECTION: Disk flags and partition style
# Get-Disk reads partition table metadata — no writes occur.
# =============================================================================
function Show-DiskFlags {
    Write-Section 'DISK FLAGS & PARTITION STYLE'
    try {
        $disks = Get-Disk -ErrorAction Stop | Sort-Object Number
    }
    catch {
        Write-Host "    Unable to query disk metadata: $_" -ForegroundColor Yellow
        return
    }
    foreach ($disk in $disks) {
        Write-Host ''
        Write-Host "    Disk $($disk.Number): $($disk.FriendlyName)" -ForegroundColor White
        Write-Field 'Partition Style'      $disk.PartitionStyle
        Write-Field 'Operational Status'   (Format-Value $disk.OperationalStatus)  -ValueColor (Get-StatusColor $disk.OperationalStatus)
        Write-Field 'Is Boot Disk'         (Format-Value $disk.IsBoot)
        Write-Field 'Is System Disk'       (Format-Value $disk.IsSystem)
        Write-Field 'Is Read-Only'         (if ($disk.IsReadOnly) { 'Yes (write protected)' } else { 'No' }) `
                                           -ValueColor (if ($disk.IsReadOnly) { 'Yellow' } else { 'Green' })
        Write-Field 'Is Offline'           (if ($disk.IsOffline)  { 'Yes' } else { 'No' }) `
                                           -ValueColor (if ($disk.IsOffline)  { 'Red'   } else { 'Green' })
        Write-Field 'Number of Partitions' (Format-Value $disk.NumberOfPartitions)
    }
}

# =============================================================================
# SECTION: Storage reliability counters (SMART)
# Get-StorageReliabilityCounter is a passive read — no test or scan is started.
# Not all disks or drivers expose these values; missing data appears as N/A.
# =============================================================================
function Show-ReliabilityCounters {
    Write-Section 'STORAGE RELIABILITY COUNTERS (SMART)'
    try {
        $disks = Get-PhysicalDisk -ErrorAction Stop
    }
    catch {
        Write-Host "    Unable to query physical disks: $_" -ForegroundColor Yellow
        return
    }
    foreach ($disk in $disks) {
        Write-Host ''
        Write-Host "    Disk $($disk.DeviceId): $($disk.FriendlyName)" -ForegroundColor White
        try {
            $rel       = $disk | Get-StorageReliabilityCounter -ErrorAction Stop
            $tempColor = if ($rel.Temperature -ge 55) { 'Red' } elseif ($rel.Temperature -ge 45) { 'Yellow' } else { 'Green' }
            $wearColor = if ($rel.Wear -ge 90)        { 'Red' } elseif ($rel.Wear -ge 70)        { 'Yellow' } else { 'Green' }
            Write-Field 'Temperature (°C)'   (if ($rel.Temperature) { "$($rel.Temperature)" } else { 'N/A' }) -ValueColor $tempColor
            Write-Field 'Wear Level (%)'     (if ($rel.Wear -gt 0)  { "$($rel.Wear)"        } else { 'N/A' }) -ValueColor $wearColor
            Write-Field 'Read Errors Total'  (Format-Value $rel.ReadErrorsTotal)
            Write-Field 'Write Errors Total' (Format-Value $rel.WriteErrorsTotal)
            Write-Field 'Power On Hours'     (Format-Value $rel.PowerOnHours)
            Write-Field 'Start/Stop Cycles'  (Format-Value $rel.StartStopCycleCount)
        }
        catch {
            Write-Host "    Reliability counters not available for this disk." -ForegroundColor DarkGray
        }
    }
}

# =============================================================================
# SECTION: Optimisation schedule status
# Reads the ScheduledDefrag task and Defrag registry key for last/next run times.
# This is a status read only — no defragmentation or optimisation is triggered.
# =============================================================================
function Show-OptimisationStatus {
    Write-Section 'DISK OPTIMISATION SCHEDULE (STATUS READ-ONLY)'

    try {
        $task      = Get-ScheduledTask -TaskName 'ScheduledDefrag' -TaskPath '\Microsoft\Windows\Defrag\' -ErrorAction Stop
        $info      = $task | Get-ScheduledTaskInfo -ErrorAction Stop
        $taskColor = if ($task.State -eq 'Ready') { 'Green' } elseif ($task.State -eq 'Disabled') { 'Yellow' } else { 'Gray' }

        Write-Host ''
        Write-Field 'Scheduled Task State' $task.State -ValueColor $taskColor
        Write-Field 'Last Run Time'  (if ($info.LastRunTime -and $info.LastRunTime.Year -gt 1900) { $info.LastRunTime.ToString('yyyy-MM-dd HH:mm:ss') } else { 'Never / Unknown' })
        Write-Field 'Next Run Time'  (if ($info.NextRunTime -and $info.NextRunTime.Year -gt 1900) { $info.NextRunTime.ToString('yyyy-MM-dd HH:mm:ss') } else { 'Not scheduled'   })
        Write-Field 'Last Result'    "0x$('{0:X8}' -f $info.LastTaskResult)"
    }
    catch {
        Write-Host "    ScheduledDefrag task not found or inaccessible." -ForegroundColor DarkGray
    }

    # Per-volume last-optimised timestamps stored by Windows after each completed run
    Write-Host ''
    Write-Host '    Per-volume last optimised (registry):' -ForegroundColor White
    $defragKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Defrag'
    try {
        if (Test-Path $defragKey) {
            $volKeys = Get-ChildItem -Path $defragKey -ErrorAction SilentlyContinue
            if ($volKeys) {
                foreach ($vk in $volKeys) {
                    try {
                        $props      = Get-ItemProperty -Path $vk.PSPath -ErrorAction SilentlyContinue
                        $raw        = $props.'LastRunTime'
                        $lastRunStr = if ($raw) { [datetime]::FromFileTime([System.BitConverter]::ToInt64($raw, 0)).ToString('yyyy-MM-dd HH:mm:ss') } else { 'Unknown' }
                        Write-Host ("      {0,-40} Last run: {1}" -f (Split-Path $vk.PSPath -Leaf), $lastRunStr) -ForegroundColor Gray
                    }
                    catch { }
                }
            }
            else { Write-Host '      No per-volume history found.' -ForegroundColor DarkGray }
        }
        else { Write-Host '      Defrag registry key not present.' -ForegroundColor DarkGray }
    }
    catch { Write-Host "      Could not read defrag registry key: $_" -ForegroundColor DarkGray }

    Write-Host ''
    Write-Host '    NOTE: This script never runs defragmentation or optimisation.' -ForegroundColor DarkGray
    Write-Host '    To analyse manually (read-only): Optimize-Volume -DriveLetter C -Analyze -Verbose' -ForegroundColor DarkGray
}

# =============================================================================
# SECTION: BitLocker encryption status
# Queries Win32_EncryptableVolume via WMI — read-only, no encryption changes.
# =============================================================================
function Show-BitLockerStatus {
    Write-Section 'DRIVE ENCRYPTION STATUS (BitLocker)'
    try {
        $vols = Get-CimInstance -Namespace 'Root\CIMV2\Security\MicrosoftVolumeEncryption' `
                                -ClassName  'Win32_EncryptableVolume' -ErrorAction Stop
        Write-Host ''
        foreach ($v in $vols | Sort-Object DriveLetter) {
            $status = switch ($v.ProtectionStatus) {
                0 { 'Protection OFF (unencrypted)' }
                1 { 'Protection ON  (encrypted)'   }
                2 { 'Protection UNKNOWN'            }
                default { "Status code $($v.ProtectionStatus)" }
            }
            $color = switch ($v.ProtectionStatus) { 1 { 'Green' } 2 { 'Yellow' } default { 'White' } }
            Write-Host ("    {0,-6} {1}" -f "$($v.DriveLetter):", $status) -ForegroundColor $color
        }
    }
    catch {
        Write-Host "    BitLocker WMI class unavailable on this OS edition." -ForegroundColor DarkGray
    }
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
Write-Host ''
Write-Host ('=' * 70) -ForegroundColor Cyan
Write-Host '  DWP Disk Health Reporter  [READ-ONLY — NO CHANGES WILL BE MADE]' -ForegroundColor Cyan
Write-Host "  Host: $env:COMPUTERNAME  |  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ('=' * 70) -ForegroundColor Cyan

$csvRows = [System.Collections.Generic.List[PSCustomObject]]::new()

try { Show-PhysicalDisks | ForEach-Object { $csvRows.Add($_) } } catch { Write-Warning "Physical disk section error: $_" }
try { Show-Volumes       | ForEach-Object { $csvRows.Add($_) } } catch { Write-Warning "Volume section error: $_"        }
try { Show-DiskFlags }                                            catch { Write-Warning "Disk flags section error: $_"    }

if ($IncludeReliability) {
    try { Show-ReliabilityCounters } catch { Write-Warning "Reliability section error: $_" }
}

try { Show-OptimisationStatus } catch { Write-Warning "Optimisation section error: $_" }
try { Show-BitLockerStatus    } catch { Write-Warning "BitLocker section error: $_"    }

# =============================================================================
# SECTION: CSV export
# =============================================================================
if ($ExportCsv) {
    try {
        $csvRows | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
        Write-Host ''
        Write-Host "  Report exported to: $ExportCsv" -ForegroundColor Green
    }
    catch { Write-Warning "CSV export failed: $_" }
}

Write-Host ''
Write-Host ('─' * 70)
Write-Host '  Report complete. No disk data was modified.' -ForegroundColor Green
if (-not $IncludeReliability) {
    Write-Host '  Tip: Use -IncludeReliability to add SMART / wear data.' -ForegroundColor DarkGray
}
Write-Host ('=' * 70) -ForegroundColor Cyan
Write-Host ''
