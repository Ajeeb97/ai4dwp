# Root Cause Analysis - Legal Document Manager Crash Wave

## Version Header
- Incident date: 2024-03-25
- Service: Legal Document Manager
- Affected group: `Legal-Win11`, Floor 6
- Fleet size: 45 devices
- Status: Root cause assessed with high confidence; device-level confirmation and remediation verification pending

---

## Incident Summary

| Field | Detail |
|---|---|
| User-visible symptom | Wave of application crashes reported by Legal users. |
| Primary application | `DocManager.exe`, responsible for 74% of crashes from 10:00 to 11:00. |
| Performance symptom | DEX score fell from 90 at 09:00 to 58 at 10:00 and 55 at 11:00; disk I/O changed from normal to high. |
| Change before onset | SCCM deployed Legal Document Manager v2.1 to 45 of 45 devices, completing at 09:44:07. |
| Known relevant vendor limitation | v2.1 auto-save indexing can cause high disk I/O and intermittent crashes in the first hours after installation on devices with under 8 GB RAM. |
| At-risk cohort | 40% of the 45-device fleet has 4 GB RAM: 18 devices. |
| Root-cause assessment | v2.1 initial auto-save indexing likely caused high I/O and intermittent crashes on the 4-GB device cohort. |

## Supporting Evidence

### DEX evidence

| Time | DEX score | App crash rate | Disk I/O |
|---|---:|---:|---|
| 08:00 | 91 | 0.1% | Normal |
| 09:00 | 90 | 0.2% | Normal |
| 10:00 | 58 | 6.2% | High |
| 11:00 | 55 | 6.8% | High |

### SCCM and vendor evidence

- 09:38:20: SCCM started `Legal Document Manager v2.1` deployment to `Legal-Win11`.
- 09:44:07: SCCM reported successful installation on 45 of 45 devices, with zero installation failures.
- v2.0 was stable and had been deployed for six weeks.
- v2.1 added auto-save functionality.
- The vendor warns that the initial auto-save index can generate high disk I/O and intermittent crashes in the first hours after installation on devices with less than 8 GB RAM.

### Correlated conclusion

The DEX degradation starts in the first hourly data point after deployment completion. The high disk I/O and `DocManager.exe` crash dominance match the v2.1 vendor limitation. The 18-device 4-GB cohort is the highest-risk group and should be validated directly before final closure.

## Timeline

| Time | Event | Evidence |
|---|---|---|
| 08:00 | Baseline healthy: DEX 91, crash rate 0.1%, normal disk I/O | Nexthink export |
| 09:00 | Baseline remains healthy: DEX 90, crash rate 0.2%, normal disk I/O | Nexthink export |
| 09:38:20 | Deployment of Legal Document Manager v2.1 begins for 45 devices | SCCM log |
| 09:44:07 | Installation completes successfully for 45 of 45 devices | SCCM log |
| 10:00 | DEX score drops to 58; crash rate rises to 6.2%; disk I/O becomes high | Nexthink export |
| 10:00-11:00 | `DocManager.exe` represents 74% of observed crashes | Nexthink export |
| 11:00 | Degradation persists: DEX 55, crash rate 6.8%, high disk I/O | Nexthink export |

## Root Cause Statement

The most likely root cause is the new v2.1 auto-save indexing process operating after the successful deployment. On Legal devices with 4 GB RAM, this matched the vendor-documented condition for high disk I/O and intermittent application crashes during the first few post-installation hours.

This conclusion is high confidence, but not fully proven from the supplied data because individual crash records have not yet been correlated to device RAM and installed version. That correlation is required before incident closure.

## Five Why Analysis

1. **Why did Legal users experience a wave of application crashes?**
   - `DocManager.exe` accounted for 74% of crashes during the degradation window.

2. **Why did `DocManager.exe` crash during that window?**
   - Its v2.1 deployment completed shortly before the crash spike, and the v2.1 release has a documented intermittent-crash condition during initial auto-save indexing.

3. **Why did the crash spike coincide with high disk I/O?**
   - The vendor describes the initial auto-save index as generating high disk I/O during the first hours after installation.

4. **Why was the Legal fleet especially exposed to this limitation?**
   - Forty percent of the fleet, 18 devices, has 4 GB RAM, which is below the vendor's 8 GB threshold.

5. **Why was the impact not prevented before broad deployment?**
   - The deployment was sent to all 45 devices without a low-memory pilot or a release-note review control that specifically tested the stated under-8-GB limitation.

## Remediation Plan

1. Pause v2.1 deployment beyond the Legal collection.
2. Use SCCM inventory and Nexthink data to identify 4-GB devices with v2.1, high disk I/O, or `DocManager.exe` crashes.
3. Obtain vendor guidance for a supported v2.1 fix, configuration change, or indexing control.
4. Where an immediate fix is unavailable, roll back confirmed affected 4-GB devices to the known stable v2.0 package.
5. Validate the selected remediation on a small 4-GB pilot before applying it to all affected devices.
6. Maintain user communication and capture affected-device details for post-incident validation.

## Verification and Closure Criteria

- Device-level data confirms the affected group and validates the RAM/version correlation.
- `DocManager.exe` crash rate falls toward the pre-deployment 0.1%-0.2% baseline after remediation.
- Disk I/O returns from high to normal on remediated devices.
- DEX score recovers toward the pre-deployment 90-91 range.
- SCCM confirms the planned application version on every affected device.
- Legal users confirm normal application use during the agreed observation period.

## Preventive Actions

| Action | Owner outcome |
|---|---|
| Introduce a phased pilot ring for application upgrades | New releases are first deployed to representative hardware, including low-RAM devices. |
| Require vendor-release-note risk review | Known hardware thresholds and first-run workloads are assessed before broad deployment. |
| Build hardware-aware SCCM collections | 4-GB and under-8-GB devices can be targeted, deferred, or remediated separately. |
| Add Nexthink deployment health monitoring | Alerts correlate crash-rate, DEX-score, and disk-I/O regression after major deployments. |
| Define rollback triggers | A documented crash-rate or DEX-score threshold automatically pauses deployment and starts rollback assessment. |

## Residual Risk

Risk remains until the device-level RAM/version correlation and post-remediation recovery are verified. Do not resume broad v2.1 rollout to lower-memory devices until a vendor-supported mitigation is proven in the pilot ring.