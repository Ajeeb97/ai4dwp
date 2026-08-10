# AVD Incident Analysis - POOL-FIN-01 Black Screen

Date saved: 2026-08-10
Analyst context: Differential analysis only; no single root cause committed.

## Scope Facts
- Symptom: Black screen post-login; clears after about 30 seconds for some users, persists for others.
- Who: About 40% of users on POOL-FIN-01 affected; POOL-FIN-02 completely unaffected.
- Since: About 07:00 this morning.
- Change: Overnight image update to POOL-FIN-01 at 02:00; POOL-FIN-02 was not updated.

## Weighting Logic Used
1. Primary discriminator: POOL-FIN-02 was not updated and is unaffected.
2. Secondary discriminator: Onset after overnight update window.
3. Tertiary discriminator: Partial impact (~40%) within updated pool.

## Ranked Hypotheses (Most Probable First)

### 1) POOL-FIN-01 image/update regression
Why this fits:
- Impact is isolated to the updated pool.
- Unaffected pool did not receive the update.
- Start time aligns with update window.

Fastest check:
- Compare image/build version and post-boot error signatures between affected POOL-FIN-01 hosts and POOL-FIN-02 hosts.

### 2) Subset of session hosts in POOL-FIN-01 degraded after update
Why this fits:
- About 40% affected suggests host-level clustering rather than universal failure.
- Still constrained to the updated pool.

Fastest check:
- Correlate affected users to specific session hosts and test whether failures cluster on a subset.

### 3) FSLogix/profile attach behavior changed by updated image
Why this fits:
- Post-login black screen can occur when profile attach is delayed or fails.
- Pool-specific image change can selectively impact this path.

Fastest check:
- Review FSLogix operational events at login time on affected POOL-FIN-01 hosts for attach latency/failure patterns.

### 4) Logon initialization slowdown (shell, GPO, logon scripts) introduced by image
Why this fits:
- Variable duration (30s for some; persistent for others) is consistent with logon pipeline timing differences.
- Timing and pool isolation remain consistent with update-induced regression.

Fastest check:
- Capture a single affected logon trace and identify dominant delay stage (profile load, policy processing, shell start).

### 5) Pool-level configuration drift during deployment
Why this fits:
- Could explain pool-only impact if deployment altered FIN-01 settings.
- Lower likelihood than direct image regression unless explicit config deltas are found.

Fastest check:
- Diff host-pool/session-host configuration between POOL-FIN-01 and POOL-FIN-02 for deployment-time changes.

## Explicit Answer to Timing Clue Question
Most consistent cause with "POOL-FIN-02 not updated and unaffected" is:
- Image/update regression specific to POOL-FIN-01.

Rationale:
- It best matches change isolation, timing, and pool boundary conditions without requiring extra assumptions.

---

## Addendum - Event Evidence Review and Surviving Hypothesis

Date appended: 2026-08-10

### Evidence Window Reviewed
- Affected host: SHFIN-01-A (POOL-FIN-01), event window 07:00-07:30 on 2024-03-15.
- Comparison host: SHFIN-02-A (POOL-FIN-02, unaffected), same window.

### Key Event Details Captured
- 07:02:10 - TerminalServices-LocalSessionManager Event 21: session logon succeeded (FINBRIDGE\\mlopez).
- 07:02:14 - Kernel-General Event 1: host boot time recorded as 02:03:11 (post overnight image update reboot).
- 07:02:16 - Application Error Event 1000: dwm.exe faulting module igdumd64.dll, exception 0xc0000005.
- 07:02:17 - TerminalServices-LocalSessionManager Event 40: session disconnected.
- 07:02:18 - Desktop Window Manager Event 9009: DWM exited with code 0x40010004.
- 07:02:44 - TerminalServices-LocalSessionManager Event 21: reconnect logon succeeded.
- 07:02:46 - Application Error Event 1000: repeated dwm.exe / igdumd64.dll crash.
- 07:02:47 - TerminalServices-LocalSessionManager Event 40: repeated disconnect.
- 07:03:01 - Desktop Window Manager Event 9009: repeated DWM exit.
- 07:03:10 - TerminalServices-LocalSessionManager Event 21: second reconnect logon succeeded.
- 07:08:24 - Application Error Event 1000: same crash pattern for FINBRIDGE\\akapoor.
- Comparison (unaffected pool): 07:01:46 - Desktop Window Manager Event 9011 information: DWM started successfully; no App Error Event 1000 in window.

### Evidence Scoring Against Existing Hypotheses

1) POOL-FIN-01 image/update regression
- Judgement: Supports.
- Determining events: Kernel-General Event 1 at 07:02:14 plus repeated App Error Event 1000 at 07:02:16 and 07:02:46, with unaffected comparison host showing Event 9011 at 07:01:46.

2) Subset of session hosts in POOL-FIN-01 degraded after update
- Judgement: Neutral.
- Determining events: repeated failures confirmed on SHFIN-01-A (Event 1000 at 07:02:16, 07:02:46, 07:08:24), but no multi-host FIN-01 distribution evidence in this extract.

3) FSLogix/profile attach behavior changed by updated image
- Judgement: Contradicts (relative to primary signal in this evidence).
- Determining events: successful logons (Event 21 at 07:02:10, 07:02:44, 07:03:10) followed by DWM/driver crash pattern (Event 1000, Event 9009).

4) Logon initialization slowdown (shell, GPO, logon scripts) introduced by image
- Judgement: Neutral to weakly contradicts.
- Determining events: repeated crash-disconnect loop (Event 1000 -> Event 40 -> Event 9009) is more specific than generic slow initialization.

5) Pool-level configuration drift during deployment
- Judgement: Neutral.
- Determining events: pool-specific behavior is visible, but no direct config-delta event proof in this log set.

### Surviving Hypothesis
- Surviving hypothesis after elimination: POOL-FIN-01 image/update regression causing DWM instability via igdumd64.dll after logon.

---

## Addendum - Resolution Steps (Execution Runbook)

Date appended: 2026-08-10

### 1) Immediate Containment (0-15 minutes)
- Pause any further rollout of the same image to other pools.
- In POOL-FIN-01, identify hosts with repeated Event 1000 (dwm.exe/igdumd64.dll) and set those hosts to drain mode.
- Keep known-good hosts available to reduce user impact while remediation proceeds.
- Notify Service Desk that Finance users may see intermittent black screens while mitigation is active.

Success gate:
- New user sessions are no longer being placed on crash-loop hosts.

### 2) Targeted Technical Remediation on Affected FIN-01 Hosts
- Confirm impacted hosts are on the updated image and verify crash signature consistency.
- Apply approved rollback path for display stack on affected image (to-verify exact package in environment):
	- Option A: roll back Intel display driver package tied to igdumd64.dll.
	- Option B: redeploy prior known-good image for affected hosts.
- Reboot remediated hosts during controlled window.
- Keep hosts drained until post-reboot checks pass.

Success gate:
- No new Event 1000 (dwm.exe/igdumd64.dll) or Event 9009 entries for test logons after reboot.

### 3) Host Re-entry and User Recovery
- Run two test logons per remediated host (one standard Finance test account, one affected user if available).
- If both logons are stable, remove drain mode and return host to rotation.
- Continue host-by-host until all impacted FIN-01 hosts are cleared.

Success gate:
- Stable desktop presentation with no immediate disconnect loop (Event 21 not followed by Event 40 for the same session).

### 4) Validation Checklist
- Incident window + 60 minutes: confirm zero recurrence of Event 1000 (dwm.exe/igdumd64.dll) on remediated hosts.
- Confirm DWM normal-start informational pattern where available (Event 9011) and absence of Event 9009 errors.
- Confirm Finance ticket volume trends down and no new black-screen reports from remediated hosts.

### 5) Rollback Decision Points
- If crashes continue after driver rollback, revert host to previous known-good image baseline.
- If image rollback is not immediately possible, keep host drained and replace capacity with unaffected or rebuilt hosts.

### 6) User Communication (Operational)
- "We identified a host image issue in the Finance AVD pool causing post-login black screens. Mitigation is in place and affected hosts are being remediated in sequence. No data loss is indicated. Please retry sign-in; if the issue repeats, report time and host name from your client details."

### 7) Preventive Controls for Next Update Wave
- Add canary deployment stage (5-10% hosts) before full pool rollout.
- Add automated post-update health check for Event 1000 (dwm.exe) and Event 9009 within first logon cycles.
- Require cross-pool comparison check before promoting image to wider rings.
