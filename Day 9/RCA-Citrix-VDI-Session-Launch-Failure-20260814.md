# Root Cause Analysis - Citrix VDI Session Launch Failure

## Version Header
- Incident date: 2026-08-14
- Service: Citrix Virtual Desktop Infrastructure
- Affected service area: `FinBridge-VDI-Pool-02`
- Status: Cause identified from supplied evidence; remediation execution and verification pending

---

## Incident Summary

| Field | Detail |
|---|---|
| Primary symptom | Session launches failed for Pool-02 users. |
| User impact | 22 of 30 users on `FinBridge-VDI-Pool-02`. |
| Unaffected comparison | `FinBridge-VDI-Pool-01`, in the same site. |
| Broker result | Error `1030`: `No machines available in the desktop group`. |
| Broker timing | Machine-registration response timed out after 30,000 ms. |
| Root cause | Citrix Broker Service was stopped on `dc-vdi-02`, preventing Pool-02 machines from registering with that controller. |
| Likely contributing condition | A Windows Update had installed on `dc-vdi-02` and a reboot was pending. The supplied evidence does not prove this caused the Broker Service to stop. |

## Scope and Supporting Evidence

### Pool scope

| Pool | Provisioned | Registered | Unregistered | User impact |
|---|---:|---:|---:|---|
| `FinBridge-VDI-Pool-02` | 25 | 3 | 22 | 22 of 30 users affected |
| `FinBridge-VDI-Pool-01` | 20 | 19 | 1 | Unaffected |

### Registration evidence

- `VDI-P02-014` failed registration at 06:15:22 with `Unable to contact Delivery Controller`; `dc-vdi-02.finbridge.local:80` refused the connection.
- `VDI-P02-017` failed registration at 06:16:01 with the same controller connection refusal.
- The Pool-02 broker later timed out waiting for a registration response and failed the session launch.

### Controller health evidence

| Controller | Service state | Additional evidence |
|---|---|---|
| `dc-vdi-02` | Citrix Broker Service `STOPPED` | Last known running yesterday at 23:40; Windows Update installed at 00:15; reboot required and not completed. |
| `dc-vdi-01` | Citrix Broker Service `RUNNING` | Uptime: 14 days; serves the unaffected Pool-01. |

### Error-code handling

The source data supplies error `1030` and the literal broker text. No assertion is made about an external, product-specific meaning for the numeric code without an authoritative reference.

---

## Timeline

| Time | Event | Evidence |
|---|---|---|
| Yesterday 23:40 | `dc-vdi-02` Broker Service last known running | Controller health data |
| Today 00:15 | Windows Update installed on `dc-vdi-02` | Controller health data |
| 06:15:22 | `VDI-P02-014` registration failed; `dc-vdi-02:80` refused connection | Machine registration detail |
| 06:16:01 | `VDI-P02-017` registration failed; `dc-vdi-02:80` refused connection | Machine registration detail |
| 08:58:03 | User `jsmith` requested a Pool-02 session launch | Broker log |
| 08:58:04 | Broker queried available Pool-02 machines | Broker log |
| 08:58:34 | Registration wait exceeded 30,000 ms; launch failed with error `1030` | Broker log |
| Time not supplied | Pool-02 catalog showed 3 registered and 22 unregistered machines | Catalog status |
| Time not supplied | Pool-01 catalog showed 19 registered and 1 unregistered machine | Catalog status |

## Root Cause Statement

The Citrix Broker Service on `dc-vdi-02` was stopped. Pool-02 machines could not contact that controller to register, leaving 22 of 25 Pool-02 machines unregistered. With only three registered machines, the broker timed out waiting for registration and failed Pool-02 session launches.

## Five Why Analysis

### Problem

22 of 30 users could not launch a session in `FinBridge-VDI-Pool-02`.

1. **Why did user session launches fail?**
   - The broker timed out while waiting for a machine-registration response and returned `No machines available in the desktop group`.

2. **Why were machines unavailable to the broker?**
   - Pool-02 had only 3 registered machines; 22 were unregistered.

3. **Why were 22 Pool-02 machines unregistered?**
   - Sample machines failed registration because they could not contact `dc-vdi-02`; connections to port 80 were refused.

4. **Why could the machines not contact `dc-vdi-02` for registration?**
   - The Citrix Broker Service on `dc-vdi-02` was stopped.

5. **Why was the Broker Service stopped and not restored before the incident?**
   - The evidence shows an installed Windows Update and a pending reboot, but does not establish the cause of the stopped service. The control gap identified is the absence or failure of post-change service-health validation and alerting to restore the Broker Service before user impact.

## Remediation Plan

1. Preserve current controller, catalog, and broker-log evidence.
2. Confirm Pool-01 and `dc-vdi-01` remain healthy.
3. Start the Citrix Broker Service on `dc-vdi-02` and verify it remains `Running`.
4. If the service cannot stay running, complete an approved restart of `dc-vdi-02` to address the pending reboot, then confirm automatic service startup.
5. Monitor Pool-02 registration recovery, including former-unregistered machines.
6. Perform a controlled Pool-02 session launch only after registration capacity is restored.
7. Keep any machine that remains unregistered out of normal session assignment until separately repaired.

## Verification and Closure Criteria

- `dc-vdi-02` Citrix Broker Service is running and stable after remediation.
- Pool-02 registration increases from the pre-remediation state of 3 registered machines.
- Representative Pool-02 machines no longer report connection refusals to `dc-vdi-02:80` during registration.
- A controlled user can launch a Pool-02 session without a 30,000 ms registration timeout or the reported broker message.
- No new Pool-02 launch failures are observed during the agreed monitoring period.

## Preventive Actions

| Action | Purpose | Evidence of completion |
|---|---|---|
| Alert on stopped Citrix Broker Services | Detect controller-service loss before registration capacity collapses | Alert test and operational runbook recorded |
| Alert on machine-registration percentage by pool | Detect a material increase in unregistered VDAs | Dashboard and threshold alert enabled |
| Enforce post-update controller health checks | Confirm services are running after update/reboot work | Change-record checklist completed |
| Test Delivery Controller failover for Pool-02 | Ensure VDA registration remains resilient to one controller becoming unavailable | Controlled failover test recorded |
| Add controller restart ownership and confirmation | Prevent deferred reboot-required states from persisting | Approved operational procedure updated |

## Residual Risk

The immediate incident cannot be marked resolved from the supplied data alone, because no post-remediation service, registration, or session-launch result was provided. Closure requires the verification criteria above.