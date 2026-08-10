# AVD Incident Communications Pack

Date: 2026-08-10
Source of truth: incident analysis and RCA for POOL-FIN-01 black-screen incident (resolved at 10:00 on 2024-03-15).

## Audience 1 - Non-technical Executive
Your access and data are safe. This morning, some Finance virtual desktops in POOL-FIN-01 showed a black screen after sign-in following an overnight update; POOL-FIN-02 was unaffected. We paused the rollout, removed affected machines from use, applied the approved fix, restarted them, and verified normal sign-in with no repeat issues. Service was fully restored at 10:00. No action is needed; if it returns, contact the Service Desk.

## Audience 2 - Affected End-User Team (10 users)
Hi team - your access and data are safe. This morning, about 40% of users in Finance desktop pool POOL-FIN-01 saw a black screen after sign-in because an overnight update in that pool caused repeated desktop display crashes; POOL-FIN-02 was unaffected. We paused the rollout, removed affected machines from use, applied the approved fix, restarted them, and verified normal sign-in with no repeat issues. Service was restored at 10:00. If you see this again, note the time, reconnect once, and contact the Service Desk (ext 4421).

## Audience 3 - Engineer-to-Engineer Internal Note
Incident: AVD black-screen post-logon in POOL-FIN-01 (Finance), starting ~07:00 on 2024-03-15, resolved 10:00.

Root cause:
- Overnight image update to POOL-FIN-01 introduced post-logon display stack instability.
- Confirmed crash signature on affected host(s): Application Error Event 1000 (dwm.exe faulting in igdumd64.dll, exception 0xc0000005), DWM Event 9009 exits, and LSM Event 21 success followed by Event 40 disconnect loop.
- Control comparison: POOL-FIN-02 (not updated) unaffected; comparison host showed DWM Event 9011 start-success and no matching Event 1000 in window.

Exact actions taken:
- Paused rollout of the same image to other pools.
- Identified impacted POOL-FIN-01 session hosts and put them in drain mode to stop new user placement.
- Applied approved remediation path for the affected display stack/image baseline on impacted hosts (environment package/version reference to-verify in change records).
- Rebooted remediated hosts.
- Kept hosts drained until validation completed; then returned validated hosts to rotation.

Configuration/detail context:
- Affected pool: POOL-FIN-01.
- Unaffected pool: POOL-FIN-02.
- Update timing: ~02:00 wave for POOL-FIN-01 only.
- Scope observed: ~40% of POOL-FIN-01 users affected.

Verification performed:
- Functional: successful test and user logons to remediated POOL-FIN-01 hosts.
- Telemetry: no recurring Application Error Event 1000 (dwm.exe/igdumd64.dll) and no recurring DWM Event 9009 in validation window.
- Service status: confirmed restored at 10:00; no further user reports at closure.

Preventive action required:
- Enforce canary/ringed rollout (5-10%) before full pool deployment.
- Add automated post-update health gate to block promotion on DWM crash/disconnect-loop signatures (Event 1000 + Event 9009 + repeated Event 21->40 pattern).
- Require cross-pool telemetry comparison against non-updated control pool before broad rollout.
