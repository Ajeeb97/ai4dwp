# Runbook - AVD Black Screen After Logon (POOL-FIN-01)

## Version Header

| Field | Value |
|-------|-------|
| Title | Runbook - AVD Black Screen After Logon (POOL-FIN-01) |
| Version | 1.0 |
| Date | 07/08/2026 |
| Author | Ajeeb |
| Reviewed | self |
| Status | draft |
| Change | initial version from RCA |

Source RCA: RCA-2024-0315-AVD001 (POOL-FIN-01)
Incident pattern: Users log on successfully, then see black screen and/or disconnect loop caused by repeated `dwm.exe` crash in `igdumd64.dll`.

## 1. Prerequisites

1. Confirm you are assigned the active incident/ticket and have change authority for the maintenance window.
2. Confirm access to Azure portal for AVD host pool administration. **[ELEVATED PERMISSIONS REQUIRED]**
3. Confirm access to impacted session hosts with local administrator rights (or equivalent via approved endpoint tooling). **[ELEVATED PERMISSIONS REQUIRED]**
4. Confirm permission to manage user sessions on the host pool (drain mode, session control). **[ELEVATED PERMISSIONS REQUIRED]**
5. Confirm access to Windows Event Viewer (or central log platform) for Application, Desktop Window Manager, and TerminalServices logs.
6. Confirm approved remediation package/version from deployment records for the affected display stack/image baseline. **[ELEVATED PERMISSIONS REQUIRED]**
7. Confirm target scope is the affected pool only: `POOL-FIN-01` (do not change `POOL-FIN-02`).
8. Confirm communication channel with Service Desk for user validation before closing.

## 2. Procedure

1. Add an incident work note in your ITSM ticket with Start Time (UTC), your name, and scope `POOL-FIN-01`.
Expected result: Ticket contains a timestamped entry that explicitly names `POOL-FIN-01`.

2. In Azure portal, open `Azure Virtual Desktop` > `Host pools` and confirm no new update assignment is targeting pools outside `POOL-FIN-01`. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: No pending or active assignment exists for other pools using the suspect image/update.

3. In Azure portal, open `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`.
Expected result: Session host list for `POOL-FIN-01` is visible.

4. On one impacted host row, set `Allow new sessions` to `No` (drain mode). **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Host row shows `Allow new sessions = No`.

5. Open `POOL-FIN-01` > `User sessions` and identify sessions running on the drained host.
Expected result: You have a list of active sessions mapped to that host.

6. For each active session on the drained host, run `Sign out` from the session action menu. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Active session count for that host becomes `0` in `User sessions`.

7. Sign in to the drained host and open `Event Viewer`.
Expected result: Event Viewer console opens on the target host.

8. In `Windows Logs` > `Application`, run `Filter Current Log...` with Event IDs `1000`.
Expected result: Filtered view returns one or more `Application Error` entries in the incident window.

9. Open the newest Event `1000` entry and confirm `Faulting application name: dwm.exe`.
Expected result: Event details pane shows `dwm.exe` as the faulting application.

10. In the same Event `1000` entry, confirm `Faulting module name: igdumd64.dll`.
Expected result: Event details pane shows `igdumd64.dll` as the faulting module.

11. In `Applications and Services Logs` > `Microsoft` > `Windows` > `Desktop Window Manager` > `Operational`, run `Filter Current Log...` with Event IDs `9009`.
Expected result: Filtered view shows DWM exit events in the same incident window.

12. In `Applications and Services Logs` > `Microsoft` > `Windows` > `TerminalServices-LocalSessionManager` > `Operational`, run `Filter Current Log...` with Event IDs `21,40`.
Expected result: Filtered view shows at least one `21` event followed by `40` event in close time proximity.

13. Add a ticket note with host name and three timestamps: first `1000`, first `9009`, and nearest `21 -> 40` pair.
Expected result: Ticket note contains host plus all three evidence timestamps.

14. Install the approved remediation package/version from the change record on the drained host. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Installer exits successfully and logs a completed install state.

15. Reboot the remediated host from Azure portal `Session hosts` action menu or from the host console. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Host status returns to `Available` and still shows `Allow new sessions = No`.

16. Launch Azure Virtual Desktop client (Windows App or Remote Desktop), connect to the remediated host with a test account, and complete one full logon.
Expected result: Desktop is interactive within 60 seconds and no persistent black screen appears.

17. In Event Viewer `Windows Logs` > `Application`, filter Event ID `1000` for the post-reboot time window.
Expected result: Zero new entries contain both `dwm.exe` and `igdumd64.dll` after reboot.

18. In Event Viewer `Desktop Window Manager` > `Operational`, filter Event ID `9009` for the post-reboot time window.
Expected result: Zero new Event `9009` entries exist after reboot.

19. In Azure portal `POOL-FIN-01` > `Session hosts`, set `Allow new sessions` back to `Yes` for the validated host. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Host row shows `Allow new sessions = Yes` and can receive sessions.

20. Repeat Steps 4-19 for each remaining impacted host in `POOL-FIN-01`.
Expected result: Every impacted host is remediated and validated before re-entry.

21. Add a closure-candidate ticket note with host count remediated, hostnames, and pass/fail outcome per host.
Expected result: Ticket has a complete remediation summary ready for verification sign-off.

## 3. Verification

1. In Azure portal `POOL-FIN-01` > `Session hosts`, confirm all remediated hosts show `Status = Available` and `Allow new sessions = Yes`.
Expected result: 100% of remediated hosts are Available and enabled for new sessions.

2. Perform two separate test logons per remediated host using test accounts from different user profiles.
Expected result: Both logons per host reach a usable desktop in under 60 seconds with no black screen persisting beyond 5 seconds.

3. Observe each remediated host for 30 minutes after it is returned to rotation.
Expected result: Zero new Event `1000` entries with `dwm.exe` and `igdumd64.dll`, and zero new Event `9009` entries during the window.

4. In Service Desk tooling, filter incidents by assignment group and keyword `black screen` for the last 30 minutes.
Expected result: No new `POOL-FIN-01` black-screen tickets are created during the observation period.

5. Collect confirmation from at least two previously affected Finance users after their first successful post-fix logon.
Expected result: Both users confirm normal desktop load and no disconnect loop.

6. Set incident to Resolved only after Steps 1-5 are all passed and documented in the ticket.
Expected result: Ticket contains objective evidence for technical and user-experience recovery.

## 4. Rollback

Trigger: Start this rollback immediately if a host shows persistent black screen after remediation, new Event `1000` (`dwm.exe` + `igdumd64.dll`), new Event `9009`, or a repeated `21 -> 40` loop.

Target execution time: isolate user impact in under 3 minutes.

1. In Azure portal, open `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`.
Expected result: Session host grid is visible for `POOL-FIN-01`.

2. On the regressed host row, set `Allow new sessions` to `No`. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Host row shows `Allow new sessions = No` within seconds.

3. In `POOL-FIN-01` > `User sessions`, filter by the regressed host name.
Expected result: Only sessions on the regressed host are listed.

4. Select all listed sessions and click `Sign out`. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Active session count for the regressed host becomes `0`.

5. In Azure portal, open `Virtual machines` > select the regressed VM > `Restart` and confirm. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: VM `Power state` changes from `Running` to `Restarting`.

6. In the same VM page, wait until `Power state = Running`.
Expected result: VM is back online and still drained (`Allow new sessions = No` in AVD session host grid).

7. Connect to the host console and run the approved rollback installer or package reversion from the change record path. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Installer returns success code and shows completion in its log/output.

8. Restart the host once after package reversion from `Start` > `Power` > `Restart` or `Restart-Computer` in elevated PowerShell. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Host boots successfully and remains in drain mode.

9. Open Event Viewer `Windows Logs` > `Application` and filter Event ID `1000` for time since the second restart.
Expected result: Zero new events contain both `dwm.exe` and `igdumd64.dll`.

10. Open Event Viewer `Applications and Services Logs` > `Microsoft` > `Windows` > `Desktop Window Manager` > `Operational` and filter Event ID `9009` for time since the second restart.
Expected result: Zero new Event `9009` entries are present.

11. Run one controlled test logon through Azure Virtual Desktop client to the reverted host.
Expected result: Desktop becomes usable in under 60 seconds with no black screen persisting beyond 5 seconds.

12. If Step 9, Step 10, and Step 11 all pass, set `Allow new sessions` to `Yes` on the host row. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Host returns to rotation and accepts new sessions.

13. If any of Step 9, Step 10, or Step 11 fails, keep `Allow new sessions = No` and create a Problem Management escalation with the host name and exact failure timestamps.
Expected result: Unstable host remains isolated and escalation has actionable evidence.

## 5. Notes

- Edge case: If only a subset of hosts in `POOL-FIN-01` reproduces the crash signature, remediate host-by-host; do not perform blind pool-wide changes without evidence.
- Warning: Do not apply this playbook to `POOL-FIN-02` unless the same signature (`dwm.exe` + `igdumd64.dll`, Event 1000/9009, 21->40 pattern) is confirmed there.
- Warning: Keep hosts in drain mode until post-fix validation is complete; early re-entry can reintroduce user impact.
- Related incidents/documents:
  - `RCA-AVD-POOL-FIN-01-black-screen-20240315`
  - `Known-Error-AVD-POOL-FIN-01-black-screen-20240315`
  - `AVD-black-screen-analysis-POOL-FIN-01`
  - `Closure-Note-AVD-POOL-FIN-01-20240315`
