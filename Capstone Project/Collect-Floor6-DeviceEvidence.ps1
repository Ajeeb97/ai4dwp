[CmdletBinding()]
param(
    [switch]$DryRun,
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = 'C:\ProgramData\FinBridge\Floor6-Evidence.json'
)

$ErrorActionPreference = 'Stop'
$startTime = (Get-Date).AddHours(-4)
$applicationPattern = '*Document Manager*'

if ($DryRun) {
    [pscustomobject]@{
        Mode = 'DRY-RUN'
        ComputerName = $env:COMPUTERNAME
        WouldCollect = @('installed application/version', 'recent profile/policy events', 'performance samples', 'enrollment key inventory')
        WouldWrite = $OutputPath
    } | ConvertTo-Json -Depth 4
    return
}

function Get-InstalledDocumentManager {
    $paths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($path in $paths) {
        Get-ItemProperty -Path $path -ErrorAction Stop |
            Where-Object { $_.DisplayName -like $applicationPattern } |
            Select-Object DisplayName, DisplayVersion, InstallDate, InstallLocation, UninstallString
    }
}

function Get-SignInEvents {
    $logs = @('System', 'Application')
    $providers = @('Microsoft-Windows-User Profiles Service', 'Microsoft-Windows-GroupPolicy', 'Winlogon')

    foreach ($log in $logs) {
        Get-WinEvent -FilterHashtable @{ LogName = $log; StartTime = $startTime } -MaxEvents 5000 -ErrorAction Stop |
            Where-Object { $providers -contains $_.ProviderName } |
            Select-Object LogName, ProviderName, Id, LevelDisplayName, TimeCreated, Message
    }
}

function Get-PerformanceSnapshot {
    Get-Counter -Counter @(
        '\LogicalDisk(*)\Disk Transfers/sec',
        '\Processor(_Total)\% Processor Time',
        '\Memory\Available MBytes'
    ) -SampleInterval 1 -MaxSamples 3 |
        Select-Object -ExpandProperty CounterSamples |
        Select-Object Path, InstanceName, CookedValue, Timestamp
}

function Invoke-EvidenceCollection {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [scriptblock]$Collector
    )

    try {
        [pscustomobject]@{
            Name = $Name
            Success = $true
            Error = $null
            Data = @(& $Collector)
        }
    }
    catch {
        [pscustomobject]@{
            Name = $Name
            Success = $false
            Error = $_.Exception.Message
            Data = @()
        }
    }
}

$evidence = [ordered]@{
    ComputerName = $env:COMPUTERNAME
    CollectedAt = (Get-Date).ToString('o')
    CollectionWindowStart = $startTime.ToString('o')
    DryRun = [bool]$DryRun
    Collections = @(
        Invoke-EvidenceCollection -Name 'Application' -Collector { Get-InstalledDocumentManager }
        Invoke-EvidenceCollection -Name 'SignInEvents' -Collector { Get-SignInEvents }
        Invoke-EvidenceCollection -Name 'Performance' -Collector { Get-PerformanceSnapshot }
        Invoke-EvidenceCollection -Name 'IntuneRegistry' -Collector {
            Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction Stop |
                ForEach-Object {
                    Get-ItemProperty -Path $_.PSPath -ErrorAction Stop |
                        Select-Object PSPath, ProviderID, EnrollmentType, UPN, LastSyncTime, DiscoveryServiceFullURL
                }
        }
    )
}

$parent = Split-Path -Parent $OutputPath
New-Item -Path $parent -ItemType Directory -Force | Out-Null
$evidence | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Output "Evidence written to $OutputPath"
