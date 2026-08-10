#Requires -Version 5.1
<#
.SYNOPSIS
    Find and report large files on Windows endpoints. READ-ONLY.
.DESCRIPTION
    Recursively scans one or more paths and reports all files whose size meets
    or exceeds the configured threshold. Makes no changes to any file or
    directory. Access-denied errors are collected separately so the scan
    continues past protected folders.
.PARAMETER Path
    One or more root paths to scan. Defaults to all local fixed drives.
.PARAMETER ThresholdMB
    Minimum file size in megabytes to include in results. Default: 100.
.PARAMETER Top
    Limit output to the N largest files. 0 = unlimited. Default: 0.
.PARAMETER ExcludePath
    Wildcard patterns applied to the full file path to skip matching files.
.PARAMETER ExportCsv
    Optional path to write results as a CSV file.
.EXAMPLE
    .\Find-LargeFiles.ps1
    .\Find-LargeFiles.ps1 -Path C:\ -ThresholdMB 500
    .\Find-LargeFiles.ps1 -Path D:\ -ThresholdMB 50 -Top 20
    .\Find-LargeFiles.ps1 -Path C:\Users -ExcludePath 'C:\Users\*\AppData\*' -ExportCsv C:\Reports\large-files.csv
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string[]]$Path,

    [ValidateRange(1, [int]::MaxValue)]
    [int]$ThresholdMB = 100,

    [ValidateRange(0, [int]::MaxValue)]
    [int]$Top = 0,

    [string[]]$ExcludePath,

    [string]$ExportCsv
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Continue'

    $allPaths       = [System.Collections.Generic.List[string]]::new()
    $accessErrors   = [System.Collections.Generic.List[string]]::new()
    $results        = [System.Collections.Generic.List[PSCustomObject]]::new()
    $thresholdBytes = [long]$ThresholdMB * 1MB
    $startTime      = Get-Date

    Write-Host ''
    Write-Host ('=' * 70) -ForegroundColor Cyan
    Write-Host '  DWP Large File Finder  [READ-ONLY]' -ForegroundColor Cyan
    Write-Host "  Host: $env:COMPUTERNAME  |  Threshold: $ThresholdMB MB  |  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host ('=' * 70) -ForegroundColor Cyan
    Write-Host ''
}

process {
    if ($Path) { $Path | ForEach-Object { $allPaths.Add($_) } }
}

end {
    # =============================================================================
    # SECTION: Resolve scan targets
    # Default to all local fixed drives when no path is provided.
    # =============================================================================
    if ($allPaths.Count -eq 0) {
        try {
            $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction Stop |
                Where-Object { $_.Root -and (Test-Path $_.Root) }
            $drives | ForEach-Object { $allPaths.Add($_.Root) }
            Write-Host "  No path specified — scanning all local drives: $($drives.Root -join ', ')"
        }
        catch {
            Write-Error "Failed to enumerate local drives: $_"
            exit 1
        }
    }
    else {
        Write-Host "  Scan target(s): $($allPaths -join ', ')"
    }
    Write-Host ''

    # =============================================================================
    # SECTION: Recursive file scan
    # -ErrorVariable captures access-denied errors without stopping the scan.
    # =============================================================================
    foreach ($scanRoot in $allPaths) {
        if (-not (Test-Path $scanRoot)) {
            Write-Warning "Path not found, skipping: $scanRoot"
            continue
        }

        Write-Host "  Scanning: $scanRoot ..." -ForegroundColor DarkGray

        $scanErrors = $null
        try {
            $files = Get-ChildItem -Path $scanRoot -File -Recurse `
                        -ErrorAction SilentlyContinue -ErrorVariable scanErrors
        }
        catch {
            Write-Warning "Unexpected error scanning '$scanRoot': $_"
            continue
        }

        if ($scanErrors) { $scanErrors | ForEach-Object { $accessErrors.Add($_.TargetObject) } }

        foreach ($file in $files) {
            if ($file.Length -lt $thresholdBytes) { continue }

            $excluded = $false
            if ($ExcludePath) {
                foreach ($pattern in $ExcludePath) {
                    if ($file.FullName -like $pattern) { $excluded = $true; break }
                }
            }
            if ($excluded) { continue }

            $results.Add([PSCustomObject]@{
                SizeMB       = [math]::Round($file.Length / 1MB, 2)
                SizeBytes    = $file.Length
                Name         = $file.Name
                FullPath     = $file.FullName
                LastModified = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                Extension    = $file.Extension.ToLower()
            })
        }
    }

    # =============================================================================
    # SECTION: Sort and limit results
    # =============================================================================
    $sorted = $results | Sort-Object -Property SizeBytes -Descending
    $output = if ($Top -gt 0) { $sorted | Select-Object -First $Top } else { $sorted }

    # =============================================================================
    # SECTION: Display results
    # Colour-coded: red >= 1 GB, yellow >= 500 MB, white otherwise.
    # =============================================================================
    if ($output.Count -eq 0) {
        Write-Host "  No files >= $ThresholdMB MB found." -ForegroundColor Yellow
    }
    else {
        Write-Host "  Results (largest first):"
        Write-Host ''
        Write-Host ("  {0,12}   {1,-22}  {2}" -f 'Size (MB)', 'Last Modified', 'Path') -ForegroundColor Cyan
        Write-Host ("  {0,12}   {1,-22}  {2}" -f ('─' * 12), ('─' * 22), ('─' * 40)) -ForegroundColor DarkGray

        foreach ($item in $output) {
            $colour = if ($item.SizeBytes -ge 1GB)       { 'Red'    }
                      elseif ($item.SizeBytes -ge 500MB) { 'Yellow' }
                      else                               { 'White'  }
            Write-Host ("  {0,12}   {1,-22}  {2}" -f $item.SizeMB.ToString('F2'), $item.LastModified, $item.FullPath) -ForegroundColor $colour
        }
    }

    # =============================================================================
    # SECTION: Access-denied summary
    # =============================================================================
    if ($accessErrors.Count -gt 0) {
        Write-Host ''
        Write-Host "  Directories skipped (access denied): $($accessErrors.Count)" -ForegroundColor Yellow
        $accessErrors | Select-Object -Unique | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }

    # =============================================================================
    # SECTION: CSV export
    # =============================================================================
    if ($ExportCsv -and $output.Count -gt 0) {
        try {
            $output | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
            Write-Host ''
            Write-Host "  CSV exported to: $ExportCsv" -ForegroundColor Green
        }
        catch { Write-Warning "Failed to export CSV to '$ExportCsv': $_" }
    }

    # =============================================================================
    # SECTION: Summary footer
    # =============================================================================
    $elapsed     = (Get-Date) - $startTime
    $totalSizeGB = [math]::Round(($output | Measure-Object -Property SizeBytes -Sum).Sum / 1GB, 3)
    $topNote     = if ($Top -gt 0 -and $results.Count -gt $Top) { " (showing top $Top of $($results.Count) total)" } else { '' }

    Write-Host ''
    Write-Host ('─' * 70)
    Write-Host "  Files found   : $($output.Count)$topNote"
    Write-Host "  Total size    : $totalSizeGB GB"
    Write-Host "  Threshold     : $ThresholdMB MB"
    Write-Host "  Scan duration : $([math]::Round($elapsed.TotalSeconds, 1)) seconds"
    Write-Host ('=' * 70) -ForegroundColor Cyan
    Write-Host ''
}
