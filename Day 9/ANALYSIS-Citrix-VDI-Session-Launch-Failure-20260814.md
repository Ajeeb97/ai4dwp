# Citrix VDI Session Launch Failure Analysis

## Version Header
- Date: 2026-08-14
- Author: DWP Engineering
- Service: Citrix Virtual Desktop Infrastructure
- Status: Root-cause hypothesis identified; remediation and verification required

---

## Scope Facts

- Affected pool: `FinBridge-VDI-Pool-02`.
- User impact: 22 of 30 users affected.
- Unaffected comparison pool: `FinBridge-VDI-Pool-01`, in the same site.
- Broker outcome: session launch failed with error `1030`, with the literal message `No machines available in the desktop group`.
- Broker timing: timeout waiting for a machine-registration response after 30,000 ms.
- Pool-02 catalog: 25 provisioned, 3 registered, 22 unregistered, and 0 in maintenance mode.
- Pool-01 catalog: 20 provisioned, 19 registered, and 1 unregistered.
- Sample Pool-02 machines reported `Unable to contact Delivery Controller`; connections to `dc-vdi-02.finbridge.local:80` were refused.
- `dc-vdi-02`: Citrix Broker Service stopped; it was last known running yesterday at 23:40. A Windows Update was installed today at 00:15, with a reboot-required flag set and no reboot performed.
- `dc-vdi-01`, which serves Pool-01: Citrix Broker Service running with 14 days uptime.

## Error-Code Note

The evidence supplies error `1030` and the broker's literal text, `No machines available in the desktop group`. This analysis does not assign any additional Citrix product-specific meaning to error `1030`, because no authoritative error-code reference was supplied.

---

## Ranked Hypotheses

### 1. Citrix Broker Service is stopped on `dc-vdi-02`, preventing Pool-02 machine registration

**Why it fits the evidence**

- The Pool-02 hosts report refused connections to `dc-vdi-02.finbridge.local:80` during registration attempts.
- `dc-vdi-02` has its Citrix Broker Service stopped.
- Pool-02 has 22 unregistered machines, closely matching the 22 affected users.
- The broker waited for machine registration and then failed the launch.
- Pool-01 remains largely registered and its serving controller, `dc-vdi-01`, has a running Broker Service.

**Fastest check**

- On `dc-vdi-02`, confirm the `Citrix Broker Service` state is `Running` after starting it, then trigger or await a registration refresh and confirm Pool-02's registered-machine count increases from 3.

**Remediation if confirmed**

- Restore the Citrix Broker Service on `dc-vdi-02`, complete the outstanding restart under the approved change/incident process, and confirm the service starts automatically after restart.
- Return only successfully registered Pool-02 machines to normal session availability.

### 2. `dc-vdi-02` has not been restarted after the installed Windows Update, leaving the Citrix broker stack in a stopped state

**Why it fits the evidence**

- The controller records a Windows Update installation at 00:15 and an outstanding reboot-required flag.
- Its Broker Service was last known running before that change, at 23:40 the previous day.
- The stopped service and uncompleted restart condition align with the affected controller's loss of registration availability.

**Fastest check**

- Review the approved Windows Update and service-control events on `dc-vdi-02` around 00:15 to determine whether the Broker Service stopped during or after the update activity.

**Remediation if confirmed**

- Perform the approved controller restart, confirm Citrix services start automatically, and validate machine registration and session launches before closing the incident.

### 3. Pool-02 machines lack effective Delivery Controller failover or registration connectivity when `dc-vdi-02` is unavailable

**Why it fits the evidence**

- The affected machines' registration attempts target `dc-vdi-02` and fail when that endpoint refuses connections.
- A second controller is healthy, but the evidence does not show Pool-02 machines successfully using it for registration.
- This would explain why a controller-specific service outage produces a near-pool-wide registration loss.

**Fastest check**

- Review the configured Delivery Controller list and registration event logs on representative Pool-02 machines. Confirm whether `dc-vdi-01` is configured as a valid fallback and whether registration succeeds when `dc-vdi-02` is unavailable.

**Remediation if confirmed**

- Correct the Pool-02 machine catalog or VDA Delivery Controller configuration so both approved controllers are configured, then validate failover in a controlled test.

---

## Final Hypothesis

The most probable cause is that the stopped Citrix Broker Service on `dc-vdi-02` prevented Pool-02 machines from registering. The evidence directly connects the stopped service, refused registration connections to that controller, 22 unregistered Pool-02 machines, and the broker timeout during session launch.

The pending-reboot state following the Windows Update is a likely contributing change, but the supplied evidence does not prove it caused the service to stop.

---

## Remediation Procedure

### 1. Contain and prepare

1. Record the current incident evidence: Pool-02 registration state, Broker Service state, and current user impact.
2. Confirm `dc-vdi-01` remains healthy and continue to protect the unaffected Pool-01 service.
3. Obtain approval for the `dc-vdi-02` service restart and, if required, controller reboot through the incident/change process.

### 2. Restore controller service

1. On `dc-vdi-02`, verify that the Citrix Broker Service is stopped and that no active maintenance activity would make a restart unsafe.
2. Start the Citrix Broker Service.
3. Confirm the service reaches and remains in the `Running` state.
4. If the service does not start, stops again, or the pending-reboot condition prevents stable operation, restart `dc-vdi-02` in the approved maintenance window.
5. After restart, confirm the Citrix Broker Service is configured to start automatically and is `Running`.

### 3. Restore Pool-02 registration and capacity

1. Monitor the Pool-02 catalog for machine registration recovery.
2. Check representative former-unregistered machines, including `VDI-P02-014` and `VDI-P02-017`, for successful registration rather than refused controller connections.
3. Keep any machine unregistered after controller recovery out of normal session use and investigate it separately.
4. When sufficient registered capacity is restored, conduct controlled session-launch tests before broad user retry communication.

## Correct Order of Operations

1. Preserve the current service and catalog evidence.
2. Confirm `dc-vdi-01` and Pool-01 remain healthy.
3. Restore the Broker Service on `dc-vdi-02`.
4. Reboot `dc-vdi-02` if the service cannot remain healthy or to complete the approved pending-reboot action.
5. Verify controller service health.
6. Verify Pool-02 machine registrations recover.
7. Test session launch using a controlled account.
8. Return the service to normal operation and monitor for recurrence.

## Resolution Verification

Resolution is verified only when all of the following are true:

- `dc-vdi-02` Citrix Broker Service is `Running` and remains stable after the observation period.
- Pool-02's registered-machine count has increased materially from 3, with registration failures to `dc-vdi-02:80` no longer occurring.
- A controlled Pool-02 session launch completes successfully without the 30,000 ms registration timeout or the quoted broker message.
- User reports confirm restored access, and no new Pool-02 session-launch failures are recorded during the agreed monitoring window.

## Preventive Action

- Monitor Citrix Broker Service state and Pool-02 registration percentage, with alerting for a stopped service or a material registration decline.
- Add a post-Windows-Update controller health gate: confirm required Citrix services are running after planned updates and reboots before returning the controller to production duty.
- Validate and periodically test Delivery Controller failover configuration for Pool-02 VDAs.