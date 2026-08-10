# KB: AVD Black Screen After Logon (POOL-FIN-01) - L2/L3 Engineer Guide

## Version Header
- Version: 1.0
- Date: 07/08/2026
- Status: Draft

## Background
Azure Virtual Desktop provides Finance users with published desktops from pool POOL-FIN-01. The service is business-critical because Finance users cannot process daily work if desktop rendering fails after sign-in. This incident pattern is important because authentication succeeds, but desktop presentation fails, creating repeated disconnect/reconnect loops and high ticket volume.

## Symptom
What users report:
- Black screen after sign-in.
- Some sessions recover after about 30 seconds.
- Some sessions disconnect and return to sign-in.

What engineers observe:
- Impact concentrated in POOL-FIN-01.
- Approximate partial impact (not all users, not all hosts).
- Logon success events followed by desktop subsystem crash events.
- Repeating sign-in followed by disconnect sequence.

## Root Cause
Specific technical cause:
- Overnight update applied to POOL-FIN-01 introduced display stack instability.
- Desktop Window Manager process dwm.exe crashes in module igdumd64.dll shortly after successful logon.

Evidence that confirms the cause:
- Event ID 1000 (Application Error): Faulting application name = dwm.exe; Faulting module name = igdumd64.dll; exception code 0xc0000005.
- Event ID 9009 (Desktop Window Manager Operational): DWM exit after logon.
- Event ID 21 then Event ID 40 (TerminalServices-LocalSessionManager Operational): successful logon followed by session disconnect.
- Comparison check: POOL-FIN-02 (not in the update wave) remains healthy with DWM Event ID 9011 and no matching Event ID 1000 crash signature.

## Detection
Target: confirm or reject this incident pattern in under 3 minutes per suspect host.

Set variables once in elevated PowerShell on your admin workstation:

```powershell
$SuspectHost = "SHFIN-01-A"      # POOL-FIN-01 host under investigation
$ControlHost = "SHFIN-02-A"      # POOL-FIN-02 unaffected comparison host
$Start = (Get-Date).AddHours(-4)  # adjust window if needed
```

1. In Azure portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts and pick the suspect host name for $SuspectHost.
Expected result: You have one specific POOL-FIN-01 host to test.

2. In Azure portal, open Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts and pick one control host name for $ControlHost.
Expected result: You have one unaffected comparison host.

3. Query the exact Application log on the suspect host for Event ID 1000.

```powershell
Invoke-Command -ComputerName $SuspectHost -ScriptBlock {
	Get-WinEvent -FilterHashtable @{
		LogName='Application'
		Id=1000
		StartTime=$using:Start
	} | Where-Object {
		$_.Message -match 'Faulting application name:\s*dwm\.exe' -and
		$_.Message -match 'Faulting module name:\s*igdumd64\.dll'
	} | Select-Object -First 5 TimeCreated, Id, ProviderName, Message
}
```

Expected result: One or more Event 1000 entries match both fields:
- Faulting application name = dwm.exe
- Faulting module name = igdumd64.dll

4. Query Desktop Window Manager Operational log on the suspect host for Event ID 9009.

```powershell
Invoke-Command -ComputerName $SuspectHost -ScriptBlock {
	Get-WinEvent -FilterHashtable @{
		LogName='Microsoft-Windows-Desktop Window Manager/Operational'
		Id=9009
		StartTime=$using:Start
	} | Select-Object -First 10 TimeCreated, Id, ProviderName, Message
}
```

Expected result: One or more Event 9009 entries appear in the same incident window.

5. Query TerminalServices-LocalSessionManager Operational log on the suspect host for Event IDs 21 and 40.

```powershell
Invoke-Command -ComputerName $SuspectHost -ScriptBlock {
	Get-WinEvent -FilterHashtable @{
		LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
		Id=@(21,40)
		StartTime=$using:Start
	} | Sort-Object TimeCreated | Select-Object -First 20 TimeCreated, Id, Message
}
```

Expected result: At least one 21 (logon success) is followed by 40 (disconnect) for same user/time slice.

6. Run unaffected baseline check on POOL-FIN-02 control host: Application Event 1000 and DWM Event 9011.

```powershell
Invoke-Command -ComputerName $ControlHost -ScriptBlock {
	$app1000 = Get-WinEvent -FilterHashtable @{
		LogName='Application'
		Id=1000
		StartTime=$using:Start
	} | Where-Object {
		$_.Message -match 'Faulting application name:\s*dwm\.exe' -and
		$_.Message -match 'Faulting module name:\s*igdumd64\.dll'
	}

	$dwm9011 = Get-WinEvent -FilterHashtable @{
		LogName='Microsoft-Windows-Desktop Window Manager/Operational'
		Id=9011
		StartTime=$using:Start
	}

	[pscustomobject]@{
		MatchingApp1000Count = $app1000.Count
		Dwm9011Count = $dwm9011.Count
	}
}
```

Expected result:
- MatchingApp1000Count = 0 on POOL-FIN-02 control host
- Dwm9011Count >= 1 on POOL-FIN-02 control host (healthy baseline signal)

7. If remote PowerShell is unavailable, use GUI path on suspect host:
- Event Viewer > Windows Logs > Application (Event ID 1000)
- Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational (Event ID 9009)
- Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational (Event IDs 21,40)
Expected result: Same event/signature outcome as Steps 3-5.

Diagnosis threshold to proceed:
- Proceed only when all are true:
- Suspect host has Application Event 1000 with dwm.exe + igdumd64.dll
- Suspect host has DWM Operational Event 9009 in same window
- Suspect host shows 21 -> 40 loop behavior
- POOL-FIN-02 control host shows Event 9011 baseline and no matching Application Event 1000 crash signature

## Resolution
Target: complete one host remediation in 5-10 minutes.

CLI setup (run once):

```bash
az extension add --name desktopvirtualization --upgrade
RG="<resource-group>"
HP="POOL-FIN-01"
SH="SHFIN-01-A.domain.local"
VM="SHFIN-01-A"
PKG_CMD='msiexec /i "C:\\Packages\\<approved-remediation>.msi" /qn /norestart'
```

1. Open exact portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select SHFIN-01-A.domain.local.
Expected result: Session host details pane opens for the target host.

2. Set option Allow new sessions = Off on the selected session host. [ELEVATED PERMISSIONS REQUIRED]
CLI equivalent:

```bash
az desktopvirtualization session-host update --resource-group "$RG" --host-pool-name "$HP" --name "$SH" --allow-new-session false
```

Expected result: Host is drained and no longer accepts new user sessions.

3. Open exact portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions.
Expected result: User session list is visible for the host pool.

4. Filter User sessions by Session host = SHFIN-01-A.domain.local, then choose each session and click Sign out. [ELEVATED PERMISSIONS REQUIRED]
CLI equivalent:

```bash
az desktopvirtualization user-session list --resource-group "$RG" --host-pool-name "$HP" --query "[?contains(sessionHostName, '$SH')].name" -o tsv
# Sign out each returned session name:
az desktopvirtualization user-session delete --resource-group "$RG" --host-pool-name "$HP" --name "<session-name>" --yes
```

Expected result: Active session count for SHFIN-01-A.domain.local is 0.

5. Open exact portal path: Azure portal > Virtual machines > SHFIN-01-A > Operations > Run command > RunPowerShellScript. [ELEVATED PERMISSIONS REQUIRED]
Expected result: Run command blade is open and ready for script input.

6. Execute approved remediation package install command in RunPowerShellScript.
CLI equivalent:

```bash
az vm run-command invoke --resource-group "$RG" --name "$VM" --command-id RunPowerShellScript --scripts "$PKG_CMD"
```

Expected result: Command returns exit success and package installation completes.

7. Open exact portal path: Azure portal > Virtual machines > SHFIN-01-A > Overview > Restart.
CLI equivalent:

```bash
az vm restart --resource-group "$RG" --name "$VM"
```

Expected result: VM restarts and returns to Running.

8. Open exact portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
CLI equivalent:

```bash
az desktopvirtualization session-host show --resource-group "$RG" --host-pool-name "$HP" --name "$SH" --query "{status:status,allowNewSession:allowNewSession}" -o table
```

Expected result: status = Available and allowNewSession = false.

9. Perform one controlled test sign-in to this host through Windows App/Remote Desktop.
Expected result: Desktop becomes usable in under 60 seconds with no persistent black screen.

10. Set Allow new sessions = On for the validated host. [ELEVATED PERMISSIONS REQUIRED]
CLI equivalent:

```bash
az desktopvirtualization session-host update --resource-group "$RG" --host-pool-name "$HP" --name "$SH" --allow-new-session true
```

Expected result: Host returns to normal user placement.

11. Repeat Steps 1-10 for each impacted session host in POOL-FIN-01.
Expected result: All impacted hosts are remediated using the same fast path.

## Verification
1. Open exact portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
CLI equivalent:

```bash
az desktopvirtualization session-host list --resource-group "$RG" --host-pool-name "$HP" --query "[].{Host:name,Status:status,AllowNew:allowNewSession}" -o table
```

Expected result: Every remediated host shows Status = Available and AllowNew = true.

2. Run two controlled sign-ins per remediated host.
Expected result: Both sign-ins on each host complete with usable desktop in under 60 seconds.

3. Validate no new crash telemetry on each remediated host for the post-fix window.
CLI equivalent:

```powershell
$Start = (Get-Date).AddMinutes(-30)
Invoke-Command -ComputerName "SHFIN-01-A" -ScriptBlock {
	$app = Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$using:Start} |
		Where-Object { $_.Message -match 'dwm\.exe' -and $_.Message -match 'igdumd64\.dll' }
	$dwm = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$using:Start}
	[pscustomobject]@{App1000Match=$app.Count; Dwm9009=$dwm.Count}
}
```

Expected result: App1000Match = 0 and Dwm9009 = 0 for each remediated host.

4. Open exact portal path: ITSM/Service Desk queue filtered by assignment group and keyword black screen for last 30 minutes.
Expected result: No new POOL-FIN-01 black-screen spike.

## Rollback
Use immediately if the fix increases failures or reintroduces crash pattern.

1. Open exact portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > select regressed host > set Allow new sessions = Off. [ELEVATED PERMISSIONS REQUIRED]
CLI equivalent:

```bash
az desktopvirtualization session-host update --resource-group "$RG" --host-pool-name "$HP" --name "$SH" --allow-new-session false
```

Expected result: Regressed host is immediately drained.

2. Open exact portal path: Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions > filter Session host = regressed host > Sign out all. [ELEVATED PERMISSIONS REQUIRED]
CLI equivalent:

```bash
az desktopvirtualization user-session list --resource-group "$RG" --host-pool-name "$HP" --query "[?contains(sessionHostName, '$SH')].name" -o tsv
az desktopvirtualization user-session delete --resource-group "$RG" --host-pool-name "$HP" --name "<session-name>" --yes
```

Expected result: Session count on regressed host is 0.

3. Open exact portal path: Azure portal > Virtual machines > SHFIN-01-A > Operations > Run command > RunPowerShellScript and run approved rollback package command (previous known-good version). [ELEVATED PERMISSIONS REQUIRED]
CLI equivalent:

```bash
az vm run-command invoke --resource-group "$RG" --name "$VM" --command-id RunPowerShellScript --scripts 'msiexec /i "C:\\Packages\\<known-good-package>.msi" /qn /norestart'
```

Expected result: Rollback package install completes successfully.

4. Open exact portal path: Azure portal > Virtual machines > SHFIN-01-A > Overview > Restart.
CLI equivalent:

```bash
az vm restart --resource-group "$RG" --name "$VM"
```

Expected result: VM returns to Running while host remains drained.

5. Verify rollback health before re-entry.
CLI equivalent:

```powershell
$Start = (Get-Date).AddMinutes(-15)
Invoke-Command -ComputerName "SHFIN-01-A" -ScriptBlock {
	$app = Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$using:Start} |
		Where-Object { $_.Message -match 'dwm\.exe' -and $_.Message -match 'igdumd64\.dll' }
	$dwm = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$using:Start}
	[pscustomobject]@{App1000Match=$app.Count; Dwm9009=$dwm.Count}
}
```

Expected result: App1000Match = 0 and Dwm9009 = 0.

6. If Step 5 passes, set Allow new sessions = On; if Step 5 fails, keep host drained and escalate to Problem Management with host name, Event IDs, and timestamps.
CLI equivalent:

```bash
az desktopvirtualization session-host update --resource-group "$RG" --host-pool-name "$HP" --name "$SH" --allow-new-session true
```

Expected result: Only stable hosts are returned to user traffic.

## Preventive
1. Ring deployment control (existing, strengthened): Owner = release engineer + change manager; Timing = during deployment.
Pass criteria: Canary ring (5-10% hosts) runs 60 minutes with Event 1000 (dwm.exe/igdumd64.dll) = 0 per host, Event 9009 <= 1 per host, and black-screen ticket rate < 2% of active users.
Fail action: Freeze promotion to next ring and hold change in "Implementation Paused" until RCA review is completed.
Mode: Manual approval using automated metrics [REQUIRES: ring-gate checklist in ITSM change template].

2. Automated health gate (existing, strengthened): Owner = image owner; Timing = during deployment.
Pass criteria: For each updated host, Event 1000 (dwm.exe/igdumd64.dll) < 3 per hour and no repeated 21->40 loops (>2 sequences in 15 minutes).
Fail action: Pipeline blocks further rollout, auto-creates incident, and notifies DWP engineer + change manager.
Mode: Automated [REQUIRES: telemetry pipeline rule for Event IDs 1000, 9009, 21, 40].

3. Cross-pool baseline comparison (existing, strengthened): Owner = DWP engineer; Timing = before full deployment.
Pass criteria: Updated pool does not exceed control pool by more than +1 Event 1000 per host/hour and maintains Event 9011 presence on control hosts.
Fail action: Do not promote release beyond current ring; open problem record with comparison report attached.
Mode: Manual review of automated report [REQUIRES: pooled telemetry comparison report].

4. Rollback trigger policy (existing, strengthened): Owner = change manager; Timing = during and immediately after deployment.
Pass criteria: User-impact rate remains < 5% in first 60 minutes and no host breaches Event 1000 >= 3/hour with matching Event 9009.
Fail action: Trigger rollback runbook within 5 minutes, set impacted hosts Allow new sessions = Off, and stop rollout.
Mode: Manual trigger from automated alert [REQUIRES: alert-to-change integration].

5. Return-to-service control (existing, strengthened): Owner = DWP engineer; Timing = after deployment.
Pass criteria: Each host has 1 successful controlled sign-in plus 30-minute clean window with Event 1000 match count = 0 and Event 9009 count = 0.
Fail action: Keep host drained, do not set Allow new sessions = On, escalate to Problem Management.
Mode: Manual decision backed by automated event query output.

6. Pre-deployment smoke-test gate (gap fill): Owner = image owner; Timing = before deployment.
Pass criteria: Test host completes sign-in smoke test (2 logins, both < 60 seconds, zero Event 1000 dwm.exe/igdumd64.dll, zero Event 9009 in 15 minutes).
Fail action: Cancel production rollout and return image to packaging queue for fix.
Mode: Manual execution with scripted checks [REQUIRES: non-production AVD smoke-test host/process].

7. In-flight rollout alerting (gap fill): Owner = service desk lead; Timing = during deployment window.
Pass criteria: Alert dashboard shows Event 1000 and Event 9009 below threshold and black-screen ticket count below 3 in any 15-minute window.
Fail action: Service desk lead initiates incident bridge and requests immediate deployment hold.
Mode: Automated alerting with manual incident activation [REQUIRES: AVD incident dashboard + alert rules].

8. Post-deployment change validation gate (gap fill): Owner = change manager; Timing = after deployment, before change closure.
Pass criteria: 60-minute post-window shows zero matching Event 1000 crash signatures on remediated hosts and no new POOL-FIN-01 black-screen incidents.
Fail action: Change remains open and moves to "Monitoring Extended" with assigned remediation owner.
Mode: Manual closure decision based on automated evidence export.

9. Automatic rollback safety gate (gap fill): Owner = release engineer; Timing = during deployment.
Pass criteria: Safety gate remains untriggered while thresholds stay below Event 1000 >= 3/hour/host or user-impact >= 5%/60 minutes.
Fail action: Automation executes rollback workflow and disables new-session placement for affected hosts.
Mode: Automated [REQUIRES: rollback automation playbook in release pipeline].

10. Knowledge update control (gap fill): Owner = DWP engineer; Timing = after incident closure.
Pass criteria: Runbook, L2 KB, and on-call checklist are updated within 2 business days and approved by change manager.
Fail action: Keep problem record open and block next similar image rollout until documentation task is complete.
Mode: Manual with tracked task in ITSM [REQUIRES: KB review workflow if not currently defined].

## Related
- RCA-AVD-POOL-FIN-01-black-screen-20240315
- Known-Error-AVD-POOL-FIN-01-black-screen-20240315
- AVD-black-screen-analysis-POOL-FIN-01
- Closure-Note-AVD-POOL-FIN-01-20240315
- Runbook-AVD-POOL-FIN-01-Black-Screen
