# JAMF macOS Security Baseline - Design Team

## Version Header
- Date: 2026-08-14
- Author: DWP Engineering
- Scope: 25 managed macOS devices in the Design team fleet
- Management platform: Jamf Pro
- Deployment approach: Pilot first, then phased production rollout

---

## Overview

This document translates the Design team macOS security baseline into Jamf Pro configuration-profile and operational settings. Jamf Pro UI locations, payload names, and supported preference keys can vary by Jamf Pro and macOS version. Verify the exact label and availability in the target Jamf Pro instance and test on a representative pilot before deploying to all 25 devices.

The baseline has two control types:

- **Configuration controls:** FileVault, Gatekeeper, firewall, password-after-sleep, and automatic security updates.
- **Lifecycle control:** minimum macOS version. This needs inventory/compliance scoping and an update workflow; it is not a single, permanently accurate static profile value.

## Policy Scope and Assignment

| Item | Recommended value |
|---|---|
| Configuration profile name | `DWP - macOS Design Security Baseline` |
| Initial scope | 3 to 5 representative Design-team pilot devices |
| Production scope | Design team smart group or static group containing 25 managed devices |
| Exclusions | Approved documented exceptions only, with an owner and expiry date |
| Review cadence | Monthly, and before each macOS major-version deployment |
| Failure handling | Do not remove the baseline globally for individual failures; diagnose the device or apply a time-limited exception with a compensating control |

> **UI/Payload Verification Rule:** Every UI path and payload name below is a current best-fit mapping, not an instruction to trust a label blindly. Check the available payloads, OS support notes, and generated profile in the local Jamf Pro instance before production deployment.

---

## Requirement 1 - FileVault Disk Encryption Must Be Enabled

| Field | Detail |
|---|---|
| **Payload type** | **Security & Privacy** payload, FileVault section. In some Jamf Pro versions this may be surfaced as a FileVault-focused configuration profile or implemented alongside a FileVault enablement policy. Verify the available workflow in the local console. |
| **Recommended value** | Enable FileVault. Escrow the personal recovery key to Jamf Pro. Use the organisation's approved institutional/personal recovery-key design and rotate keys according to policy. |
| **Effect** | Encrypts the internal startup volume so data at rest cannot be read without an authorised unlock credential or approved recovery method. Recovery-key escrow supports support-led recovery without weakening encryption. |
| **False-positive risk** | A device may be legitimately encrypting but not yet complete; inventory can be stale; external/removable volumes are not evidence that the startup volume is protected; hardware or account conditions may prevent bootstrap-token or secure-token workflows from completing. |
| **Recommendation** | Run a FileVault status inventory extension attribute or built-in inventory check before enforcement. Pilot devices that use mobile accounts, are recently migrated, or have complex recovery-key history. Do not treat a device as ready until recovery-key escrow has been confirmed. |

### Deployment and Validation

1. Configure FileVault enablement and approved recovery-key escrow.
2. Assign to the pilot group and have each pilot device check in.
3. Confirm encryption starts or is already enabled, then wait for it to complete before judging compliance.
4. Confirm Jamf records a valid recovery key for each pilot device according to the local recovery process.
5. Expand in phases only after the pilot has no unexplained escrow or encryption failures.

> **UI/Payload note:** FileVault settings and key-escrow workflow have changed across Jamf Pro releases and macOS versions. Verify the exact Security & Privacy/FileVault payload name, escrow certificate requirements, and whether a separate policy is required.

---

## Requirement 2 - Gatekeeper Must Allow Identified Developers Only

| Field | Detail |
|---|---|
| **Payload type** | Typically **Security & Privacy** / **Gatekeeper** or an equivalent **Restrictions** setting in Jamf Pro. Verify the available payload and supported macOS settings. |
| **Recommended value** | Set Gatekeeper to permit apps from the Mac App Store and identified developers. Do not allow apps from anywhere. |
| **Effect** | macOS checks whether downloaded software is signed by an identified developer and meets Gatekeeper assessment requirements before it can run. This blocks unsigned or untrusted downloaded applications by default. |
| **False-positive risk** | Internally developed, unsigned, incorrectly notarised, or ad-hoc-signed Design tools can be blocked even when business-approved. Software installed before the control may appear to work until it is updated or re-downloaded. |
| **Recommendation** | Inventory Design-team applications before enforcement. Obtain valid signing/notarisation from approved internal software owners or deploy approved applications through Jamf rather than bypassing Gatekeeper. Document any temporary exception with expiry and compensating control. |

### Validation

- Confirm the managed profile is installed on a pilot device.
- Test an approved signed application and an approved Design workflow.
- Attempt to launch a controlled unsigned test application only in a safe test environment; it should be blocked by Gatekeeper.
- Confirm no broad user or administrator bypass has been deployed as a workaround.

> **UI/Payload note:** The exact Gatekeeper control and wording may not be exposed in the same payload across Jamf Pro releases. Verify against the local Jamf UI and the macOS version in scope. Do not substitute a custom profile without reviewing its preference domain and Apple documentation.

---

## Requirement 3 - Minimum macOS Version: Current Stable Minus One Point Release

| Field | Detail |
|---|---|
| **Payload type** | This is primarily an **inventory, Smart Group, compliance, and software-update workflow** rather than a single configuration-profile payload. Use an OS-version Smart Group criterion and an approved Jamf software-update/declarative-management workflow where supported. |
| **Recommended value** | At each baseline review, define the minimum as the immediately preceding point release from the organisation-approved current stable macOS release. Record the exact version in the Smart Group criterion, for example: `OS version is less than <approved N-1 point release>`. |
| **Effect** | Identifies devices below the approved security floor and targets them for update/remediation. It does not itself update a device unless paired with a software-update action and user/change-management process. |
| **False-positive risk** | Inventory data can be stale after an update; devices can be mid-install or awaiting restart; the term "current stable" may differ between Apple's current public release and the organisation-approved release; version-comparison logic can misclassify releases if not tested. |
| **Recommendation** | Define "current stable" in a monthly change record, including the exact macOS version and approval date. Run a pilot update ring first. Re-inventory after updates and give devices a reasonable restart window before escalating. |

### Required Operating Process

1. Review Apple's current release and the organisation's approved release decision.
2. Record the approved current stable version ($N$) and the N-1 minimum version in the baseline change record.
3. Update the Jamf Smart Group criterion to identify devices below the N-1 minimum.
4. Scope an approved update workflow to the non-compliant group, starting with pilots.
5. Re-run inventory after installation and restart.
6. Escalate only devices that remain below the floor after the agreed grace period.

> **UI/Payload note:** Jamf's software-update and declarative-device-management capabilities vary by Jamf Pro version, supervision/enrolment state, and macOS release. Verify the available update action, deferral options, and version criterion in the target tenant.

---

## Requirement 4 - Firewall Must Be Enabled

| Field | Detail |
|---|---|
| **Payload type** | **Security & Privacy** payload, Firewall section; the label may vary by Jamf Pro version. |
| **Recommended value** | Enable the macOS Application Firewall. Do not enable broad "block all incoming connections" unless separately assessed for the Design workflow. Enable stealth mode only if required by the DWP security standard and compatibility-tested. |
| **Effect** | Restricts unsolicited inbound network connections to the Mac while allowing approved services and applications under macOS firewall rules. |
| **False-positive risk** | Approved local collaboration, device-discovery, remote-support, screen-sharing, printing, or specialist Design applications may require inbound connections and can appear unhealthy after firewall enforcement. A separate network-security product may cause support staff to misattribute connectivity failures to the macOS firewall. |
| **Recommendation** | Test remote support, printing, approved collaboration tools, and any Design-team peer/service workflow in the pilot. Add only narrowly scoped, approved firewall exceptions; do not disable the firewall fleet-wide to resolve an application issue. |

> **UI/Payload note:** Confirm the local Jamf payload exposes the desired firewall fields and that their effect matches the target macOS release. Apple has changed related firewall terminology and implementation over time.

---

## Requirement 5 - Require a Login Password After Sleep or Screen Saver

| Field | Detail |
|---|---|
| **Payload type** | Usually **Security & Privacy** payload, General/Password section, or a supported macOS preference delivered by a configuration profile. Verify exact naming in the target Jamf instance. |
| **Recommended value** | Require password immediately after sleep or screen saver begins. If an approved delay is required by DWP policy, set the documented maximum delay rather than leaving the control unrestricted. |
| **Effect** | A user must authenticate to regain access after the Mac sleeps or the screen saver activates, reducing exposure from unattended devices. |
| **False-positive risk** | Kiosk, lab, shared-device, or accessibility workflows can appear non-compliant by design. Stale inventory may not reflect a recently installed profile. Users can mistake a screen lock or identity-provider prompt for a failed local password setting. |
| **Recommendation** | Exclude only documented shared-device use cases. Verify on pilot devices by locking the screen, waiting for sleep or screen saver, and confirming authentication is required to return to the desktop. |

> **UI/Payload note:** The preference keys and displayed Jamf setting have varied across macOS releases. Verify the exact setting, whether it applies to both sleep and screen saver, and whether a profile conflict exists before rollout.

---

## Requirement 6 - Automatic Security Updates Must Be Enabled

| Field | Detail |
|---|---|
| **Payload type** | **Software Update** payload, or an equivalent Jamf managed-software-update/declarative-management setting. Verify the exact mechanism available in the target Jamf Pro version. |
| **Recommended value** | Enable automatic checking, downloading, and installation of macOS security updates. Use the organisation's approved restart/deferral process for updates that require a restart. |
| **Effect** | Keeps enrolled Macs receiving security updates with reduced dependence on users manually opening Software Update. It does not guarantee installation until the device is online, eligible, and has completed any required restart. |
| **False-positive risk** | Devices may be offline, asleep, low on storage, deferred by an update policy, awaiting restart, or blocked by a network proxy. A device can have automatic updates enabled but remain on an older version until it checks in and completes installation. |
| **Recommendation** | Pair this control with the OS-version Smart Group from Requirement 3, update monitoring, storage checks, and user communication for restart-required updates. Treat enabled automatic updates and current patch level as separate checks. |

> **UI/Payload note:** Jamf and Apple have evolved management of software updates, especially for declarative device management. Verify the current payload/action names and their supported update types before relying on a static label.

---

## Deployment Plan for 25 Devices

1. Create the profile and Smart Groups in a non-production or pilot scope.
2. Select 3 to 5 representative devices, including a standard user device and a Design workstation with approved specialist applications.
3. Validate FileVault escrow, signed-app operation, firewall compatibility, password-after-sleep, update behaviour, and inventory reporting.
4. Resolve profile conflicts and approved application exceptions before expansion.
5. Deploy to the remaining devices in two controlled waves, monitoring each wave for one business day.
6. Review exceptions monthly and remove them when the underlying application or workflow is corrected.

## Compliance and Verification Checklist

| Requirement | Verification evidence |
|---|---|
| FileVault | Startup volume encrypted; recovery key escrow confirmed in Jamf. |
| Gatekeeper | Managed setting present; signed approved software runs; controlled unsigned test is blocked in a test environment. |
| Minimum macOS version | Inventory date is current and OS version meets the approved N-1 floor. |
| Firewall | Firewall reported enabled; approved support and Design workflows have passed pilot tests. |
| Password after sleep | Test lock/sleep/screen-saver cycle requires user authentication. |
| Automatic security updates | Managed update setting installed; update report/inventory demonstrates current patching or a tracked pending restart. |

## High-Risk False-Positive Area

The minimum-version control has the highest risk of noisy or incorrect non-compliance because update state and inventory state can diverge. Before treating a device as overdue, check its last inventory date, update-installation status, and restart requirement. Do not lower the OS floor to hide reporting lag; re-run inventory and provide the approved restart window first.

## UI/Payload Verification Checklist

- [ ] FileVault payload, recovery-key escrow mechanism, and supported token workflow match the deployed macOS/Jamf versions.
- [ ] Gatekeeper's exact setting and scope are present in the target Jamf UI and deliver the "identified developers" outcome.
- [ ] The OS-version Smart Group comparison correctly identifies a known below-floor test device.
- [ ] Firewall setting names and application-impact behaviour have been tested on the pilot macOS version.
- [ ] Password-after-sleep/screen-saver payload controls both required states without conflict.
- [ ] Automatic-update payload or declarative-management action supports the required security-update workflow.

*Review this document against the target Jamf Pro instance and current Apple management documentation before deployment. Raise exceptions and changes through the DWP change-management process.*