# Analysis - Legal Document Manager Crash Wave

## Version Header
- Incident date: 2024-03-25
- Affected group: `Legal-Win11`, Floor 6
- Fleet size: 45 devices
- Analysis status: High-confidence hypothesis; confirm at device level before closure

---

## Scope Facts

- Legal reports a wave of application crashes on the morning of 2024-03-25.
- Scope is `Legal-Win11`, containing 45 devices.
- At 08:00, the DEX score was 91, crash rate was 0.1%, and disk I/O was normal.
- At 09:00, the DEX score was 90, crash rate was 0.2%, and disk I/O was normal.
- At 10:00, the DEX score fell to 58, app crash rate rose to 6.2%, and disk I/O was high.
- At 11:00, the DEX score was 55, app crash rate was 6.8%, and disk I/O remained high.
- `DocManager.exe` accounted for 74% of crashes between 10:00 and 11:00.
- SCCM began deploying `Legal Document Manager v2.1` to all 45 Legal-Win11 devices at 09:38:20.
- SCCM recorded the installation as successful on 45 of 45 devices at 09:44:07.
- The previous stable version, v2.0, had been deployed six weeks earlier.
- Vendor release notes for v2.1 describe a new auto-save feature and a known limitation: devices with under 8 GB RAM can see high disk I/O and intermittent crashes during the first few hours while an initial index builds.
- Fleet hardware: 60% of devices have 8 GB RAM and 40% have 4 GB RAM. This equates to 18 devices with 4 GB RAM.

## Cross-Tool Correlation

The two sources produce one joined sequence rather than separate observations:

1. DEX was healthy at 09:00: score 90, crash rate 0.2%, normal disk I/O.
2. SCCM started v2.1 deployment at 09:38:20 and completed successfully for all 45 devices at 09:44:07.
3. By 10:00, after the deployment completed, DEX detected the first major change: score fell to 58, crashes reached 6.2%, and disk I/O became high.
4. The main crashing process was the newly deployed application's process, `DocManager.exe`.
5. The vendor's stated under-8-GB limitation predicts exactly the combined symptom pattern of high disk I/O and intermittent crashes during the first hours after installation.
6. The fleet's 40% 4-GB proportion is a precise candidate population of 18 devices for targeted confirmation.

## Most Likely Cause

`Legal Document Manager v2.1` likely triggered its initial auto-save indexing workload on Legal devices with 4 GB RAM. The workload caused high disk I/O and intermittent `DocManager.exe` crashes during the first hours after installation.

Confidence is high because the timing, affected process, DEX symptom pattern, vendor limitation, and low-memory fleet segment all align. The source data does not directly identify which individual devices crashed, so device-level correlation between crash events and RAM capacity remains the fastest confirmation step.

## Alternative Hypotheses

### 1. v2.1 auto-save indexing impact on 4-GB devices

**Why it fits**

- It aligns with the deployment-to-symptom time sequence.
- `DocManager.exe` is the dominant crash process.
- High disk I/O and intermittent crashes match the vendor's named limitation.
- 18 fleet devices have 4 GB RAM, the capacity range named by the vendor.

**Fastest check**

- Join crash/DEX data with SCCM inventory to confirm whether affected devices are disproportionately the 4-GB cohort and whether their v2.1 installation times precede the crashes.

### 2. A v2.1 defect affecting all Legal devices, independent of RAM

**Why it fits**

- All 45 devices received the new version before the crash-rate increase.
- The application process is responsible for most crashes.

**Why it is lower ranked**

- The vendor release note provides a more specific under-8-GB pathway that also explains the high disk I/O.

**Fastest check**

- Compare crash and disk-I/O rates for 4-GB versus 8-GB devices after the deployment.

### 3. An unrelated Floor 6 storage or endpoint performance issue

**Why it fits**

- High disk I/O could arise from a local storage, security-agent, or endpoint problem.

**Why it is lower ranked**

- DEX was healthy before the deployment and `DocManager.exe` dominates the post-deployment crashes.

**Fastest check**

- Examine disk-I/O owners and Windows/application events on both a 4-GB affected device and an 8-GB unaffected comparison device.

## Containment and Resolution Approach

1. Pause further deployment of v2.1 to any additional collections.
2. Identify the 4-GB Legal devices and correlate them with post-09:44 crash and high-I/O data.
3. Contact the vendor for an approved fix, configuration change, or guidance to suppress/defer the initial auto-save indexing workload.
4. If no immediate supported mitigation exists, roll back v2.1 to the known stable v2.0 on confirmed affected devices, starting with the 4-GB cohort.
5. Keep v2.1 deployment paused until the remediation is tested on a small 4-GB pilot group.

## Verification Criteria

- `DocManager.exe` crash rate returns close to the 08:00-09:00 baseline for remediated devices.
- DEX score and disk-I/O behaviour return toward the pre-deployment baseline.
- Affected users complete normal Document Manager workflows without a recurring crash.
- SCCM inventory confirms the intended application version on every remediated device.