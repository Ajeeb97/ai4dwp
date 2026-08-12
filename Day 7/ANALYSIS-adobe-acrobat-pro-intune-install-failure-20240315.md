# Intune App Install Failure Analysis - Adobe Acrobat Pro v23.6

## Version Header

| Field | Value |
|-------|-------|
| Title | Intune App Install Failure Analysis - Adobe Acrobat Pro v23.6 |
| Version | 1.0 |
| Date | 12/08/2026 |
| Author | GitHub Copilot |
| Reviewed | self |
| Status | draft |
| Change | initial Day 7 analysis from provided Intune install log |

## 1. Incident Summary

| Field | Detail |
|-------|--------|
| Incident type | Intune Win32 app deployment failure |
| Application | Adobe Acrobat Pro v23.6 |
| Package | `AdobeAcrobatPro.intunewin` |
| Install context | `SYSTEM` |
| First failure window | `2024-03-15 10:01:00` to `10:01:47` |
| Retry window | `2024-03-15 11:01:47` to `11:02:32` |
| Installer return code | `1603` on initial attempt and retry |
| Detection result | `Not detected` |
| Outcome | Intune deployment failed and scheduled retry |
| Severity | Medium - app unavailable to targeted endpoint; repeat failure pattern confirmed |

## 2. Source Log Extract - Key Evidence

Observed sequence from the supplied deployment log:

1. `10:01:00` - Agent starts app install for `Adobe Acrobat Pro v23.6`.
2. `10:01:01` - Install context confirmed as `SYSTEM`.
3. `10:01:02` - Package `AdobeAcrobatPro.intunewin` selected.
4. `10:01:03` - Install command runs: `msiexec /i AcrobatPro.msi /quiet`.
5. `10:01:44` - Installer returns `1603`.
6. `10:01:45` - Detection rule checks registry path `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`.
7. `10:01:45` - Detection value is not found.
8. `10:01:46` - Detection reports `Not detected`.
9. `10:01:47` - Agent marks result `Failed` and schedules retry after `60 minutes`.
10. `11:01:47` - Retry attempt 1 starts.
11. `11:01:48` - Same install command runs again.
12. `11:02:31` - Installer again returns `1603`.
13. `11:02:32` - Retry 1 fails.

## 3. Technical Interpretation

1. The application did not install successfully on either attempt.
- Evidence: `msiexec` returned `1603` twice.
- Meaning: Windows Installer reported a fatal installation error. This is a generic failure code and does not identify the exact installer-side cause by itself.

2. Intune detection did not find the expected registry value after the failed install.
- Evidence: detection rule checked `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0` and returned `Value: not found`.
- Meaning: after the install attempt, Intune could not confirm the application as present.

3. The retry mechanism behaved as expected but reproduced the same failure state.
- Evidence: retry occurred after `60 minutes` and failed with the same return code.
- Meaning: this is not a transient check-in issue. The endpoint or package state remained unchanged between attempts.

## 4. Findings

### Finding 1 - Repeated installer failure under SYSTEM context

The installer command `msiexec /i AcrobatPro.msi /quiet` failed twice with return code `1603`.

What can be concluded safely:
- The failure happened inside Windows Installer execution, not at Intune assignment level.
- The failure is reproducible across at least two attempts.
- The error is not narrowed further by the provided log alone.

What cannot be concluded from this log alone:
- Whether the failure was caused by an existing conflicting Adobe product, missing prerequisite, bad transform, packaging defect, permission issue, or source file issue.

### Finding 2 - Detection rule appears misaligned with the deployed product name

The app being deployed is `Adobe Acrobat Pro v23.6`, but the detection rule checks `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`.

This is significant because:
- `Acrobat Reader` and `Acrobat Pro` are different product lines.
- A Reader registry path is not an appropriate default detection target for a Pro package unless the product team explicitly documents that this installer writes the same key.
- Even if the install had succeeded, this detection rule could still report `Not detected` if the Pro installer writes to a different registry location or version value.

### Finding 3 - Two faults may be present at the same time

The evidence supports two separate deployment defects:
- a real installer execution failure (`1603`)
- a probable detection-rule configuration defect (Reader path used for Pro app detection)

These faults can coexist. The detection defect does not explain the `1603`, and the `1603` does not make the detection rule valid.

## 5. Most Likely Failure Model

Based on the supplied log alone, the most defensible interpretation is:

1. Intune successfully invoked the package in `SYSTEM` context.
2. The MSI installation failed with a generic fatal error before the app could register a detectable installed state.
3. Intune then checked a registry path that appears to belong to `Acrobat Reader`, not `Acrobat Pro`.
4. Detection therefore returned `Not detected`, which reinforced the failed deployment state.
5. The automatic retry repeated the same behavior because neither the package configuration nor the device condition changed.

## 6. Operational Impact

| Area | Impact |
|------|--------|
| App availability | Adobe Acrobat Pro v23.6 not installed on targeted endpoint |
| Deployment health | Failure repeats across retries, likely generating growing failed-device counts in Intune |
| Support load | Medium risk of repeated tickets if assigned broadly before correction |
| Reporting accuracy | Potentially degraded by misaligned detection rule |

## 7. Recommended Next Checks

1. Enable verbose MSI logging for the install command to isolate the true source of the `1603`.
Example: `msiexec /i AcrobatPro.msi /quiet /L*v C:\Windows\Temp\AcrobatPro-v23.6-install.log`

2. Validate whether `Adobe Acrobat Pro v23.6` is expected to install successfully in `SYSTEM` context without additional transforms, licensing parameters, or prerequisite packages.

3. Confirm the correct detection path for Acrobat Pro by checking a known-good installed endpoint.

4. Review whether the current detection path `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0` was copied from a Reader deployment instead of a Pro deployment.

5. Do not widen assignment scope until both the installer failure and the detection rule are corrected.

## 8. Conclusion

The supplied evidence shows a reproducible Intune deployment failure for `Adobe Acrobat Pro v23.6`. The direct technical symptom is repeated MSI return code `1603` under `SYSTEM` context. A second likely packaging defect is present in the detection rule, which points to an `Acrobat Reader` registry path rather than an obvious `Acrobat Pro` path. Further MSI logging is required to prove the exact installer-side cause, but the app should be treated as misconfigured for deployment until both issues are reviewed.