# DEX Signal Analysis – Finance-Win11 Startup Performance Drop
**Date:** 2026-08-12
**Analyst:** DWP Analyst
**Device group:** Finance-Win11 (215 devices)
**Metric:** Median startup time (login to usable desktop) / DEX score (0–100)

---

## Scope Facts (established before analysis)

| Fact | Detail |
|---|---|
| Affected group | Finance-Win11 — 215 devices |
| Config change | Security baseline profile deployed 2026-08-04 at 02:00 |
| Change contents | Compliance logging startup script + additional Defender scan policy |
| Startup time before | ~18 sec (score 83) |
| Startup time after | ~42 sec (score 61) — sustained across 3 days |
| Score drop | 22 points (83 → 61) |
| Comparison group | IT-Win11 (40 devices) — excluded from change, score held at 84–85 |

The timing of the drop is exact (overnight 03→04 Aug), the comparison group is clean, and the drop has not self-recovered. These three facts together provide strong causal direction.

---

## Ranked Causes

---

### Cause 1 — Compliance Logging Startup Script Adding Synchronous Login Latency

**Probability: Highest**

**Why it fits the evidence:**
The startup script was added as part of the 02:00 deployment and runs at login before the desktop becomes usable — matching the exact timing of the degradation. The comparison group (IT-Win11) had no script deployed and showed no change in startup time across the same dates. A ~24-second increase is consistent with a script that runs sequentially and waits for a response (e.g. writing to a log server, waiting for network availability, or executing a slow query). The sustained nature of the drop (3 days, no recovery) indicates the script is running every login, not a one-time event.

**Fastest check to confirm or eliminate:**
Review Windows event logs on an affected Finance device (`Event ID 4688` or PowerShell operational log) to find the script execution time at login. Alternatively, run `Measure-Command` around the script manually on one device and compare elapsed time to the observed ~24-second increase.

---

### Cause 2 — Defender Scan Policy Triggering a Blocking Scan at Login

**Probability: Medium**

**Why it fits the evidence:**
The additional Defender scan policy was deployed in the same change window as the startup script. If the policy triggers a quick scan synchronously at login (before the desktop is released), it could account for the delay. Again, IT-Win11 had no policy change and showed no degradation — consistent with this being the cause. Defender scans can take 20–40 seconds on cold-start depending on the device state and file count.

**Fastest check to confirm or eliminate:**
Check Windows Security event logs for `Microsoft-Windows-Windows Defender/Operational` on an affected device. Look for scan-start and scan-complete events timestamped within the login window (within 60 seconds of boot). If scan events appear at login, this cause is confirmed. If scans are scheduled but not at login, eliminate it.

---

### Cause 3 — Combined Sequential Execution of Both Changes

**Probability: Lower (dependent on Causes 1 and 2 both being partial contributors)**

**Why it fits the evidence:**
If neither the script nor the Defender policy alone accounts for the full 24-second increase, the two running sequentially at login could together produce the observed total. The deployment applied both changes simultaneously, so they could be compounding. This cause is only likely if individual investigation of Causes 1 and 2 each shows partial but not full impact.

**Fastest check to confirm or eliminate:**
On a test Finance device, temporarily disable each policy element one at a time (script off, then Defender policy off) and measure startup time after each change. If disabling one fully restores startup time, the other is not a factor. If neither alone restores it, sequential combination is confirmed.

---

## Recommended Next Step

Begin with **Cause 1** — review script execution time in event logs on a single affected device. This is a read-only check with no risk and can be completed in under 15 minutes. If the script execution time accounts for ~24 seconds, escalate to the security baseline owner to review whether the script can be made asynchronous or deferred until after the desktop is usable.
