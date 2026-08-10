<#
.SYNOPSIS
    Quick system health snapshot for a Windows endpoint.
.DESCRIPTION
    Reports four key health indicators in a single run:
      - Computer name and total physical memory
      - Free disk space on the C drive
      - Top 5 processes by memory consumption
      - Recent error-level events from the System event log
      - Count of user profiles unused for more than 90 days
.AUTHOR
    DWP Engineering Team
.HOW TO RUN
    Open PowerShell (no elevation required for most checks) and run:
        .\inherited.ps1
    To run with elevated rights (needed for all WMI queries on locked-down endpoints):
        Right-click PowerShell > Run as Administrator, then run .\inherited.ps1
.NOTES
    PowerShell 5.1+. No parameters. Read-only — no system changes are made.
#>

# Query WMI for basic computer information (name, RAM, domain, manufacturer)
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Get the amount of free space remaining on the C drive, in bytes
$driveFreeBytes = Get-PSDrive C | Select-Object -ExpandProperty Free

# Retrieve all running processes, sort by working-set memory (largest first), keep top 5
$topProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Read the 10 most recent System event log entries, then filter to errors only (Level 2)
$systemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object {$_.Level -eq 2}

# Find local user profiles that are not system accounts and have not been used in 90+ days
$staleProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
    -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)}

# Print the computer's hostname and its total installed RAM in bytes
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Convert free space from bytes to GB (2 decimal places) and print it
Write-Host ([math]::Round($driveFreeBytes/1GB,2)) 'GB free'

# Print the name and working-set memory (bytes) for each of the top 5 processes
$topProcesses | ForEach-Object { Write-Host $_.Name $_.WS }

# Print the timestamp and message for each error event found in the System log
$systemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# If any stale profiles were found, print how many there are
if ($staleProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleProfiles.Count }
