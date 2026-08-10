# Root Cause Analysis - AVD Black Screen Incident
## RCA-2024-0315-AVD001 | POOL-FIN-01 | FinBridge

---

## 1. Incident Summary

| Field | Detail |
|-------|--------|
| Incident ID | RCA-2024-0315-AVD001 |
| Logged | 2024-03-15 07:18 |
| Incident window | 2024-03-15 07:00 to 10:00 |
| Resolved | 2024-03-15 10:00 |
| Service | Azure Virtual Desktop (AVD) |
| Affected pool | POOL-FIN-01 (Finance desktop pool) |
| Unaffected pool | POOL-FIN-02 (IT desktop pool) |
| User impact | Approximately 40% of POOL-FIN-01 users |
| Primary symptom | Black screen after logon; cleared after ~30 seconds for some users, persisted for others |
| Severity | High (multi-user production impact in Finance business unit) |

Outcome at closure:
- Resolution actions were applied.
- Verified users were able to log in to hosts in POOL-FIN-01.
- No further black-screen issues were reported after 10:00.

---

## 2. Scope and Constraints Used During Analysis

1. Primary weighting signal:
- POOL-FIN-02 was not updated and remained unaffected.

2. Secondary weighting signal:
- Symptom started in the morning after an overnight update wave.

3. Tertiary weighting signal:
- Partial impact (~40%) within a single pool, indicating non-global behavior.

---

## 3. Supporting Evidence

### 3.1 Change and Platform Context

- Overnight image update was applied to POOL-FIN-01 at 02:00.
- POOL-FIN-02 was excluded from that update wave.
- Affected host SHFIN-01-A recorded post-update boot context:
  - 07:02:14, Kernel-General Event 1, boot time = 2024-03-15 02:03:11.

### 3.2 Affected Host Event Evidence (SHFIN-01-A)

- 07:02:10, TerminalServices-LocalSessionManager Event 21:
  - Session logon succeeded (FINBRIDGE\\mlopez).
- 07:02:16, Application Error Event 1000:
  - Faulting application: dwm.exe (10.0.22621.2861)
  - Faulting module: igdumd64.dll (31.0.101.4146)
  - Exception code: 0xc0000005
- 07:02:17, TerminalServices-LocalSessionManager Event 40:
  - Session disconnected.
- 07:02:18, Desktop Window Manager Event 9009:
  - DWM exited with code 0x40010004.
- 07:02:44, TerminalServices-LocalSessionManager Event 21:
  - Reconnect logon succeeded.
- 07:02:46, Application Error Event 1000:
  - Repeated dwm.exe / igdumd64.dll crash signature.
- 07:02:47, TerminalServices-LocalSessionManager Event 40:
  - Repeated session disconnect.
- 07:03:01, Desktop Window Manager Event 9009:
  - Repeated DWM exit.
- 07:03:10, TerminalServices-LocalSessionManager Event 21:
  - Second reconnect logon succeeded.
- 07:08:24, Application Error Event 1000:
  - Same crash signature for FINBRIDGE\\akapoor.

Interpretation:
- Authentication succeeded multiple times (Event 21), then display stack instability occurred (Event 1000 and Event 9009), causing disconnect loops (Event 40).

### 3.3 Unaffected Comparison Evidence (SHFIN-02-A, POOL-FIN-02)

- Image reported as pre-update baseline: 10.0.22621.2861-build-20240313.
- 07:01:44, TerminalServices-LocalSessionManager Event 21:
  - Session logon succeeded.
- 07:01:46, Desktop Window Manager Event 9011 (Information):
  - DWM started successfully.
- No Application Error Event 1000 entries in the same window.

Interpretation:
- Unaffected pool showed healthy DWM start behavior and no matching crash signatures.

---

## 4. Timeline (UTC/Local per log source)

| Time | Event | Evidence |
|------|-------|----------|
| 02:00 | Update wave applied to POOL-FIN-01 | Change record / incident notes |
| 02:03:11 | Affected host boot after update | Kernel-General Event 1 (logged 07:02:14) |
| ~07:00 | First user-facing symptom window begins | Incident notes |
| 07:02:10 | Logon success on SHFIN-01-A | LSM Event 21 |
| 07:02:16 | First DWM/driver crash observed | Application Error Event 1000 |
| 07:02:17 | Session disconnect | LSM Event 40 |
| 07:02:18 | DWM exit recorded | DWM Event 9009 |
| 07:02:44 to 07:03:10 | Reconnect and repeat crash/disconnect pattern | Event 21, 1000, 40, 9009 |
| 07:08:24 | Same crash signature for second user | Application Error Event 1000 |
| 07:18 | Incident formally logged by service desk | Incident report |
| 10:00 | Resolution confirmed complete | Operations update / verification |
| Post-10:00 | Users verified logging in to POOL-FIN-01, no further reports | Service desk verification |

---

## 5. Hypothesis Elimination Summary

Initial ranked hypotheses were tested against evidence.

1. POOL-FIN-01 image/update regression causing display path instability
- Status: Supported.
- Basis: timing alignment, pool isolation, repeated dwm.exe + igdumd64.dll crashes after successful logon.

2. Subset host degradation within POOL-FIN-01
- Status: Partially supported/adjacent.
- Basis: repeated failures on affected host(s), consistent with host-level concentration.

3. FSLogix/profile attach issue
- Status: Contradicted by primary evidence.
- Basis: successful session logon prior to crash; failure signature centered on DWM/graphics module.

4. Generic logon-init slowdown (GPO/scripts)
- Status: Lower fit.
- Basis: deterministic crash events provide stronger explanation than non-specific slowness.

5. Pool-level configuration drift unrelated to image contents
- Status: Possible but not primary.
- Basis: no direct config-delta evidence needed once crash signature matched update path.

---

## 6. Confirmed Root Cause

Root cause:
- An overnight image update applied only to POOL-FIN-01 introduced display stack instability on affected session hosts, evidenced by repeated Desktop Window Manager crashes (dwm.exe) faulting in igdumd64.dll shortly after successful user logon.

Why this is the best-fit explanation:
- Temporal correlation: issue began after update window.
- Scope correlation: only updated pool affected; non-updated pool unaffected.
- Technical correlation: repeated Event 1000 and Event 9009 crash pattern aligned with black-screen symptom and disconnect loop.

---

## 7. Resolution Implemented

### 7.1 Containment

- Paused further rollout of the same image to additional pools.
- Identified and drained impacted POOL-FIN-01 hosts from new session placement.
- Preserved service continuity by steering users to stable hosts where available.

### 7.2 Remediation

- Confirmed crash signature consistency on impacted hosts.
- Applied approved remediation path for the affected display stack/image baseline (environment-specific package/version to-verify in deployment records).
- Rebooted remediated hosts and kept them in drain mode pending validation.

### 7.3 Validation and Re-entry

- Executed test logons per remediated host.
- Confirmed absence of repeat Event 1000 (dwm.exe/igdumd64.dll) and Event 9009 during verification window.
- Returned validated hosts to rotation.
- Monitored ticket volume and user confirmations.

### 7.4 Resolution Confirmation

- At 10:00, issue marked resolved.
- Verified users were logging in to POOL-FIN-01 successfully.
- No ongoing issues reported post-resolution.

---

## 8. Five Why Analysis

Problem statement:
- Finance users in POOL-FIN-01 saw black screens after AVD logon, with intermittent disconnect/reconnect behavior.

Why 1:
- Why did users see black screens and disconnect loops?
- Because DWM repeatedly crashed after session logon, interrupting desktop presentation.

Evidence:
- Application Error Event 1000 (dwm.exe faulting module igdumd64.dll), DWM Event 9009, and LSM Event 40 following Event 21.

Why 2:
- Why was DWM crashing on affected hosts?
- Because the display/graphics execution path on updated hosts became unstable under logon workload.

Evidence:
- Repeated identical faulting module and exception signature across multiple user sessions on affected host.

Why 3:
- Why was this instability present only in Finance pool?
- Because POOL-FIN-01 received the overnight image update; POOL-FIN-02 did not.

Evidence:
- Change scope plus unaffected comparison host behavior in POOL-FIN-02.

Why 4:
- Why did the update impact only part of the pool (~40%) rather than all users?
- Because users were distributed across hosts with different runtime exposure and/or host-specific manifestation conditions after update.

Evidence:
- Partial user impact and host-level recurring fault patterns.

Why 5:
- Why was this regression not prevented before production impact?
- Because pre-production guardrails were insufficient to detect this post-logon DWM crash signature before broad pool exposure.

Evidence:
- Incident occurred in production after overnight wave; no prior automated block on this signature.

Underlying process root cause:
- Update governance lacked robust canary and post-update health-gate checks specific to AVD desktop rendering stability.

---

## 9. Preventive and Corrective Actions (CAPA)

### 9.1 Immediate Preventive Controls

1. Introduce ringed deployment with enforced canary stage:
- Deploy to 5-10% of hosts first.
- Promote only if no critical rendering/sign-in regressions are observed in defined soak window.

2. Add automated post-update health gate for AVD hosts:
- Block promotion if Event 1000 (dwm.exe), Event 9009, or repeated Event 21->40 loop exceeds threshold.

3. Require cross-pool baseline comparison prior to full rollout:
- Compare canary pool telemetry against known-good pool not in wave.

### 9.2 Structural Corrective Actions

4. Formal rollback trigger policy:
- Define objective rollback thresholds (for example: >=3 DWM crash events per host per hour or >=5% login failure symptom rate).

5. Image certification checklist update:
- Include AVD logon/rendering test cases for representative user personas before production release.

6. Host admission policy hardening:
- Do not return remediated hosts to rotation until validation checklist passes and telemetry remains clean for observation period.

### 9.3 Monitoring and Reporting

7. Add incident-specific dashboard:
- Track black-screen complaints, host assignment, Event 1000/9009 counts, and reconnect loop rates by pool.

8. Weekly problem-management review:
- Review update-wave incidents and near misses; adjust gates and test coverage accordingly.

---

## 10. Lessons Learned

- Pool-isolated scope plus change timing is a strong discriminator and should be weighted early in triage.
- Successful authentication does not rule out severe post-logon session failure.
- Comparison pools provide high-value controls in rapid elimination.
- Fast containment (drain + pause rollout) reduces business impact while preserving evidence quality.

---

## 11. Residual Risk and Follow-up

Residual risk:
- Medium until deployment guardrails and automated health gates are fully implemented.

Follow-up actions:
- Complete CAPA implementation and evidence closure in change management records.
- Capture exact remediation package/version details in configuration baseline documentation (to-verify).

---

## 12. Sign-off

| Role | Name | Date |
|------|------|------|
| Incident Analyst | [DWP Engineer] | 2026-08-10 |
| Service Desk Lead | [Name] | |
| EUC/AVD Platform Owner | [Name] | |
| Change Manager | [Name] | |

---

Document classification: OFFICIAL (training dataset context).