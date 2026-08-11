# Runbook - Finance Team Cannot Access Shared Drives

## Version Header

| Field | Value |
|-------|-------|
| Title | Runbook - Finance Team Cannot Access Shared Drives |
| Version | 1.0 |
| Date | 07/08/2026 |
| Author | Ajeeb |
| Reviewed | self |
| Status | draft |
| Change | initial version from RCA |

Source RCA: FIN-SHARE-ACCESS-20240315
Incident pattern: Finance users cannot open mapped/shared drives after policy refresh; access returns after mapping policy and group membership are corrected.

## 1. Prerequisites

1. Confirm active incident/ticket assignment and approved change window.
2. Confirm access to AD Users and Computers (group membership review). [ELEVATED PERMISSIONS REQUIRED]
3. Confirm access to Group Policy Management Console (GPMC). [ELEVATED PERMISSIONS REQUIRED]
4. Confirm access to File Server management console and share/NTFS ACL review. [ELEVATED PERMISSIONS REQUIRED]
5. Confirm access to Event Viewer on one affected endpoint and one unaffected endpoint.
6. Confirm known-good comparison group (for example, HR or IT users still accessing their shared drives).
7. Confirm communication channel with Service Desk for user confirmation before closure.

## 2. Procedure

1. Add a ticket work note with start time, impacted group (Finance), and primary path (for example, \\FS01\\Finance$).
Expected result: Incident timeline is anchored and scope is explicit.

2. On one affected endpoint, run Command Prompt and execute `whoami /groups`.
Expected result: Output confirms whether expected access group (for example, `FIN-SharedDrive-Access`) is present.

3. On the same endpoint, run PowerShell `Get-SmbMapping`.
Expected result: Missing or failed mapping is visible for Finance drive letter/path.

4. Open Event Viewer > Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational and filter Event ID 4098.
Expected result: Drive mapping failure appears with path and error details.

5. Open Event Viewer > Windows Logs > System and filter Event IDs 1058 and 1030.
Expected result: Policy processing errors are present in the incident window.

6. On an unaffected comparison endpoint, run `Get-SmbMapping` and capture output.
Expected result: Comparison endpoint shows expected share mapping and healthy access.

7. Open AD Users and Computers > target user > Member Of, and add missing Finance share access group if absent. [ELEVATED PERMISSIONS REQUIRED]
Expected result: User account now includes the required share access group.

8. Open Group Policy Management > domain > Group Policy Objects > Finance Drive Mapping GPO > User Configuration > Preferences > Windows Settings > Drive Maps.
Expected result: Mapping item for Finance share path exists and target filter is correct.

9. Correct drive-map target path and item-level targeting if misconfigured, then save GPO. [ELEVATED PERMISSIONS REQUIRED]
Expected result: GPO now points to correct UNC path and Finance security group.

10. On affected endpoint, run `gpupdate /force`.
Expected result: User policy updates successfully without error.

11. On affected endpoint, sign out and sign in once.
Expected result: New token includes updated group membership and policy mapping.

12. Run `Get-SmbMapping` again and open the mapped drive in File Explorer.
Expected result: Finance shared drive is present and opens without access denied.

13. Repeat Steps 7-12 for remaining affected users/scope as needed.
Expected result: Access is restored for all impacted Finance users.

## 3. Verification

1. Validate at least three affected users can open the Finance share path.
Expected result: All three users can read required folders with no access denied.

2. Check Event Viewer GroupPolicy Operational log after fix on one affected endpoint.
Expected result: No new Event 4098 entries for Finance drive mapping.

3. Check System log for new Event 1058/1030 after fix window.
Expected result: No new policy processing errors tied to mapping GPO.

4. Confirm Service Desk queue for 30 minutes after fix.
Expected result: No new Finance shared-drive incidents are raised.

## 4. Rollback

Trigger rollback if post-change access failures increase, or new broad access-denied reports appear.

1. Revert the Finance Drive Mapping GPO setting to the last known-good backup in GPMC. [ELEVATED PERMISSIONS REQUIRED]
Expected result: Previous mapping configuration is restored.

2. Force policy refresh on pilot user endpoint with `gpupdate /force`.
Expected result: Endpoint receives reverted policy successfully.

3. Remove recently added temporary targeting/group changes that were part of failed fix. [ELEVATED PERMISSIONS REQUIRED]
Expected result: User targeting returns to pre-change state.

4. Validate access on pilot user using `Get-SmbMapping` and File Explorer.
Expected result: Pilot user returns to baseline behavior.

5. If rollback restores access, apply rollback to full impacted scope; if not, keep incident open and escalate to AD/File Services team.
Expected result: Production impact is contained and ownership is clear.

## 5. Notes

- Edge case: User may need full sign-out/sign-in after group membership change for token refresh.
- Edge case: Offline files or stale credentials can mask successful backend fix.
- Warning: Do not test only with admin accounts; validate with real affected Finance users.
- Related documents:
  - RCA-FIN-SHARE-ACCESS-20240315
  - Known-Error-Finance-Shared-Drives-Access
  - KB-L2-L3-Finance-Shared-Drives-Access
