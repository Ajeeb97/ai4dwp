# Root Cause Analysis - Adobe Acrobat Pro v23.6 Intune Install Failure

## Version Header

| Field | Value |
|-------|-------|
| Title | Root Cause Analysis - Adobe Acrobat Pro v23.6 Intune Install Failure |
| Version | 1.0 |
| Date | 12/08/2026 |
| Author | GitHub Copilot |
| Reviewed | self |
| Status | draft |
| Change | initial Day 7 RCA from provided Intune install log |

## 1. Executive Summary

Adobe Acrobat Pro v23.6 failed to install from Intune because the deployed package configuration contains at least one confirmed control defect and one unresolved installer failure. The confirmed defect is the detection rule: the deployment for `Adobe Acrobat Pro` checks a registry path for `Adobe Acrobat Reader`, which is not a reliable validation target for the product being deployed. In parallel, the installer itself returned MSI error `1603` twice under `SYSTEM` context, proving that the install package or endpoint prerequisites were not deployment-ready.

The most defensible root-cause statement is therefore:

`A deployment configuration defect allowed an unverified Adobe Acrobat Pro package to be assigned with a misaligned detection rule and without enough installer validation to prevent repeated MSI 1603 failures.`

## 2. Problem Statement

An Intune Win32 deployment for `Adobe Acrobat Pro v23.6` failed on the target endpoint during initial install and first retry. Intune reported the app as failed and not detected.

## 3. Evidence Summary

1. The app started from Intune successfully in `SYSTEM` context.
2. The install command `msiexec /i AcrobatPro.msi /quiet` returned `1603` at `10:01:44`.
3. The detection rule checked `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0`.
4. The detection rule found no value and returned `Not detected`.
5. Intune scheduled a retry for `60 minutes` later.
6. The retry used the same install command and returned `1603` again.

## 4. Root Cause Assessment

### Primary Root Cause - Deployment configuration quality failure

The deployment was promoted without sufficient validation of two critical controls:

1. Installer execution behavior under Intune `SYSTEM` context.
2. Detection rule alignment with the actual product being deployed.

This is the primary root cause because both controls should have been validated before broad assignment:
- a test install should have exposed the repeated `1603`
- a packaging review should have identified that `Adobe Acrobat Pro` was using an `Acrobat Reader` registry path for detection

### Contributing Cause 1 - Installer returned MSI error 1603

MSI return code `1603` is a fatal install error. From the supplied log alone, the exact internal cause is not proven, but the package clearly was not ready for reliable deployment.

Likely categories to investigate:
- conflicting existing Adobe product state
- missing transform or product-specific installation parameter
- source packaging defect
- prerequisite or licensing dependency
- endpoint condition blocking silent install

### Contributing Cause 2 - Detection rule likely copied from the wrong Adobe product

The detection target `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0` appears to belong to Acrobat Reader rather than Acrobat Pro.

This creates two risks:
- false negatives after a successful install
- repeated reinstall or failed compliance reporting because Intune cannot confirm the app state correctly

## 5. Five Why Analysis

### Why 1 - Why did the deployment fail?

Because the installer returned `1603`, and Intune could not detect the application afterward.

### Why 2 - Why could Intune not detect the application?

Because the install did not complete successfully, and the configured detection rule points to a registry path that appears to match `Acrobat Reader`, not `Acrobat Pro`.

### Why 3 - Why was a misaligned detection rule in place?

Most likely because the deployment configuration was reused from another Adobe package or created from an incorrect template without validation against a known-good Pro installation.

### Why 4 - Why was the install command still promoted despite returning `1603`?

Because pre-deployment validation was incomplete or not enforced. A pilot validation step should have captured installer failure and blocked release.

### Why 5 - Why was incomplete validation able to reach deployment?

Because the packaging and release process did not enforce a hard gate for these controls before assignment:
- successful silent install test in `SYSTEM` context
- successful uninstall test
- verified detection rule on a known-good device
- documented return-code review

## 6. Impact Assessment

| Area | Impact |
|------|--------|
| Target endpoint | Adobe Acrobat Pro remained unavailable |
| Intune reporting | Device shows failed / not detected state |
| Deployment confidence | Low until package validation is corrected |
| Enterprise risk | High if assigned at scale, because repeated retries and false detection can multiply impact |

## 7. Corrective Actions

1. Withdraw the current `Adobe Acrobat Pro v23.6` assignment from any pilot or production groups until validation is complete.

2. Rebuild or revalidate the install command with MSI verbose logging.
Recommended validation command:
`msiexec /i AcrobatPro.msi /quiet /L*v C:\Windows\Temp\AcrobatPro-v23.6-install.log`

3. Test the package in the same execution model used by Intune: silent install under `SYSTEM` context.

4. Replace the current detection rule with a verified Acrobat Pro-specific detection method taken from a known-good installed device.

5. Retest the full lifecycle before reassignment:
- install
- detection
- app launch
- uninstall
- reinstall

6. Re-run pilot deployment only after all five checks pass.

## 8. Preventive Actions

1. Introduce a mandatory packaging checklist for all Intune Win32 apps:
- install command tested under `SYSTEM`
- uninstall command tested
- detection rule verified on installed endpoint
- return codes reviewed and documented
- retry behavior understood

2. Require peer review for detection rules whenever package families are similar, such as `Reader` versus `Pro` variants.

3. Keep a standard lab validation record for each application version before assignment to production groups.

4. Block rollout approval when MSI `1603` appears in any test run until root cause is isolated and corrected.

## 9. Final Root Cause Statement

The deployment failed because an insufficiently validated Intune Win32 package for `Adobe Acrobat Pro v23.6` was released with two deployment-control weaknesses: a repeated MSI `1603` install failure under `SYSTEM` context and a detection rule that appears to target `Adobe Acrobat Reader` instead of `Adobe Acrobat Pro`. The immediate symptom was application install failure; the underlying process failure was inadequate package validation before assignment.