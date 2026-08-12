# Runbook - FinBridge Connect v3.1 Intune Deployment

## Version Header

| Field | Value |
|-------|-------|
| Title | Runbook - FinBridge Connect v3.1 Intune Deployment |
| Version | 1.0 |
| Date | 12/08/2026 |
| Author | GitHub Copilot |
| Reviewed | self |
| Status | draft |
| Change | initial deployment runbook for Day 7 lab |

## 1. Prerequisites

1. Confirm Intune administrator access for Windows app deployment. **[ELEVATED PERMISSIONS REQUIRED]**
2. Confirm `FinBridge Connect v3.1` package is present in the Intune app catalog.
3. Confirm `FinBridge Connect v3.0` package remains available for rollback.
4. Confirm target Azure AD or Entra groups exist for Finance pilot, Finance broad, and rollback.
5. Confirm the registry detection rule path and value were validated on a test endpoint.
6. Confirm Service Desk has the deployment notice and escalation contacts.

## 2. Procedure

1. Open Intune admin center and navigate to `Apps` > `Windows` > `Windows apps`. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: Windows app list is visible.

2. Open `FinBridge Connect v3.1` and verify package metadata, install command, uninstall command, and return codes.
Expected result: App configuration matches approved deployment record.

3. Open the detection rule section and confirm the registry path, value name, and version string match the packaged `v3.1` build.
Expected result: Detection rule exactly matches the approved production value.

4. Assign the app to the Ring 0 validation group as `Required`.
Expected result: Assignment is saved to the validation group only.

5. Monitor deployment status until the Ring 0 devices report installation results.
Expected result: Devices begin reporting install state and detection state.

6. On at least one Ring 0 endpoint, confirm the application launches successfully after install.
Expected result: `FinBridge Connect v3.1` opens without immediate error.

7. On the same endpoint, verify the registry version string manually.
Expected result: Registry value reports the expected `v3.1` version string.

8. On one Ring 0 endpoint, perform uninstall of `v3.1` and install of `v3.0` using the approved rollback path.
Expected result: Device returns to `v3.0` and is detected correctly.

9. If Ring 0 passes, assign `v3.1` to the Finance pilot group (`100` users) as `Required`.
Expected result: Pilot assignment is active only for Finance pilot users.

10. Review deployment status, failed device count, and user tickets every 2 hours during the first Finance pilot day.
Expected result: A current view of install health and user impact is maintained.

11. If pilot exit criteria are met, expand assignment to the remaining Finance broad group.
Expected result: The remaining `400` Finance users receive the app.

12. Exclude known `4 GB RAM` exception devices from broad production assignment until performance is validated.
Expected result: Low-spec devices are not included in unsupported waves.

13. After Finance completes successfully, assign the app to the enterprise pilot group.
Expected result: Non-Finance pilot deployment begins with controlled scope.

14. Expand to the enterprise broad group only after enterprise pilot criteria are met.
Expected result: Broad rollout proceeds with controlled monitoring.

## 3. Verification

1. Confirm Intune reports successful install state for at least `98%` of pilot devices.
Expected result: Success rate meets deployment threshold.

2. Confirm registry detection is accurate on sample upgraded endpoints.
Expected result: No false installed state is observed.

3. Confirm Finance users can complete their core workflow in `FinBridge Connect v3.1`.
Expected result: No finance-critical blocker is reported.

4. Confirm rollback to `v3.0` was successfully tested before enterprise broad rollout.
Expected result: Rollback path is proven and documented.

## 4. Rollback

Trigger: Start rollback if Finance-critical functionality fails, install success rate falls below `95%`, or low-spec devices show unacceptable performance.

1. Open Intune admin center and pause new `v3.1` assignments to affected production groups. **[ELEVATED PERMISSIONS REQUIRED]**
Expected result: No new devices are targeted with the failing wave.

2. Add affected devices or users to the approved rollback group.
Expected result: Rollback scope is explicitly defined.

3. Assign `FinBridge Connect v3.0` to the rollback group as `Required`.
Expected result: `v3.0` deployment becomes active for affected devices.

4. If required by package behavior, make `v3.1` uninstall available or superseded per the approved change design.
Expected result: Device can revert cleanly to `v3.0`.

5. Monitor rollback device status until detection confirms `v3.0`.
Expected result: Affected devices return to known-good version.

6. Notify Service Desk and Finance stakeholders of rollback scope and expected recovery timeline.
Expected result: Support teams can set correct user expectations.

## 5. Notes

- Treat Finance as a protected wave with tighter monitoring and lower tolerance for error.
- Keep detection rule validation evidence with the change record.
- Maintain separate reporting for low-spec device exceptions.