# KB: Finance Team Cannot Access Shared Drives - L2/L3 Engineer Guide

## Version Header
- Version: 1.0
- Date: 07/08/2026
- Status: Draft

## Background
Finance users depend on shared file paths for daily operations, month-end work, and approvals. If access fails, business processing stops even when user sign-in is otherwise successful.

## Symptom
What users report:
- Finance shared drive is missing from File Explorer.
- Opening shared path returns access denied or path unavailable.
- Issue starts for multiple Finance users in the same window.

What engineers observe:
- Affected users in Finance OU/security scope.
- Drive-map policy errors on affected endpoints.
- Comparison users outside Finance remain unaffected.

## Root Cause
Specific technical cause:
- Finance drive mapping policy target and group-based access drifted after directory/policy change.
- Affected users lacked effective membership or received incorrect drive mapping preference.

Evidence that confirms it:
- GroupPolicy Operational Event ID 4098 on affected endpoints for drive-map processing failure.
- System Event IDs 1058 and/or 1030 during policy processing window.
- SMB mapping missing or stale for Finance UNC path on affected users.
- Comparison check: unaffected control endpoint shows valid mapping and successful access.

## Detection
1. On affected endpoint, open Event Viewer > Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational and filter Event ID 4098.
Expected result: Event 4098 shows drive mapping failure tied to Finance path.

2. On affected endpoint, open Event Viewer > Windows Logs > System and filter Event IDs 1058,1030.
Expected result: Policy processing errors are visible in same time window.

3. On affected endpoint, run PowerShell `Get-SmbMapping`.
Expected result: Finance mapping is missing, disconnected, or pointing to wrong UNC path.

4. On affected endpoint, run `whoami /groups` and verify Finance access group.
Expected result: Required group is absent or recently changed for impacted users.

5. On unaffected control endpoint, run `Get-SmbMapping` and open same path.
Expected result: Mapping exists and path opens successfully.

Diagnosis threshold:
- Proceed only if affected endpoint has Event 4098 plus missing/failed mapping, while control endpoint remains healthy.

## Resolution
1. Open Azure AD/AD user management and confirm affected users are members of required Finance access group. [ELEVATED PERMISSIONS REQUIRED]
Expected result: Required group membership is present.

2. Open Group Policy Management > Group Policy Objects > Finance Drive Mapping GPO > User Configuration > Preferences > Windows Settings > Drive Maps.
Expected result: Finance mapping item is present and enabled.

3. Correct Finance mapping path and item-level targeting to Finance group if mismatched. [ELEVATED PERMISSIONS REQUIRED]
Expected result: GPO now references correct UNC and target group.

4. On affected endpoint, run `gpupdate /force` and sign out/sign in.
Expected result: User policy applies and token refresh completes.

5. On affected endpoint, run `Get-SmbMapping` and open Finance share in File Explorer.
Expected result: Mapping appears and path opens with expected permissions.

## Verification
1. Validate access with at least three previously affected Finance users.
Expected result: All can open required shared folders without errors.

2. Re-check GroupPolicy Operational log for new Event 4098 after fix.
Expected result: No new 4098 mapping failures.

3. Re-check System log for new Event 1058/1030 after fix.
Expected result: No new policy-processing errors for the fix window.

4. Confirm no new related tickets for 30 minutes.
Expected result: Incident volume drops to normal baseline.

## Rollback
1. Restore Finance Drive Mapping GPO from last known-good backup in GPMC. [ELEVATED PERMISSIONS REQUIRED]
Expected result: Prior mapping configuration is restored.

2. Remove temporary group/targeting changes introduced by failed fix. [ELEVATED PERMISSIONS REQUIRED]
Expected result: Scope returns to baseline.

3. Force policy refresh with `gpupdate /force` on pilot endpoint and retest access.
Expected result: Pilot endpoint returns to pre-change behavior.

4. If stable, apply rollback to full scope; if unstable, escalate to AD and File Services owners with event evidence.
Expected result: User impact is contained and ownership transferred.

## Preventive
1. Add pre-release GPO lint check for drive-map target path and group filter.
2. Require canary rollout to 5 Finance pilot users before full OU scope.
3. Add alert for Event 4098 count spikes on Finance endpoints.
4. Add monthly access recertification for Finance share group membership.
5. Update runbook/checklist after each shared-drive incident closure.

## Related
- Runbook-Finance-Shared-Drives-Access
- KB-L1-Self-Service-Finance-Shared-Drive-Access
- Known-Error-Finance-Shared-Drives-Access
- RCA-FIN-SHARE-ACCESS-20240315
