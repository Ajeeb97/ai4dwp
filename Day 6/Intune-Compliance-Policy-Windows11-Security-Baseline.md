# Intune Compliance Policy – Windows 11 Security Baseline
**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Policy Scope:** Windows 11 managed devices (Microsoft Intune)  
**Grace Period:** 7 days applied to all settings  

---

## Overview

This document translates the DWP Windows 11 security baseline into Intune compliance policy settings. Each requirement maps to the exact Intune setting name, the value to configure, its enforcement effect, known false-positive risks, and recommendations to reduce noise without weakening security.

---

## Requirement 1 – BitLocker must be enabled on the OS drive

| Field | Detail |
|---|---|
| **Setting Name** | Require BitLocker |
| **UI Path** | Intune > Endpoint security > Disk encryption *or* Devices > Compliance policies > [Policy] > System Security > Require BitLocker |
| **Value** | Require |
| **Effect** | Enforces that BitLocker Drive Encryption is active on the operating system (C:) drive. Devices without BitLocker enabled will be marked non-compliant. |
| **False-Positive Risk** | BitLocker may be enabled but the Intune compliance check reads the protection status from WMI. A device that has BitLocker on but is in a suspended state (e.g. after a firmware update, BIOS change, or pending reboot) will report as non-compliant until protection is resumed. Also, devices awaiting the initial encryption pass after enrolment will fail until encryption completes. |
| **Recommendation** | Pair this setting with a BitLocker configuration profile (Endpoint Security > Disk Encryption) that silently enables BitLocker at enrolment. This reduces the window where devices are flagged during initial setup. Use the 7-day grace period to cover the encryption completion window. |

> ⚠️ **UI Path Note:** The Disk Encryption blade path has been reorganised in recent Intune releases. Verify under **Endpoint security > Disk encryption** as well as **Devices > Compliance policies** — both surfaces now exist. Confirm current path in the Intune admin centre at time of deployment.

---

## Requirement 2 – Secure Boot must be enabled

| Field | Detail |
|---|---|
| **Setting Name** | Require Secure Boot to be enabled on the device |
| **UI Path** | Devices > Compliance policies > [Policy] > Device Health > Require Secure Boot to be enabled on the device |
| **Value** | Require |
| **Effect** | Verifies that UEFI Secure Boot is active. This prevents unauthorised bootloaders and OS-level rootkits from loading before Windows starts. Devices with Secure Boot disabled or in legacy BIOS mode will be marked non-compliant. |
| **False-Positive Risk** | Devices with older BIOS/UEFI firmware that do not support Secure Boot will always fail. Some enterprise hardware refresh models ship with Secure Boot disabled in BIOS by default. Dual-boot configurations (Linux/Windows) may require Secure Boot to be disabled. |
| **Recommendation** | Before enforcing, run a Intune device report filtered on this setting to identify legacy hardware. Exclude known dual-boot or legacy BIOS asset groups via a dynamic AAD group and apply a separate policy without this requirement where a documented exception exists. |

> ⚠️ **UI Path Note:** This setting relies on the **Device Health Attestation** service. The attestation report can occasionally be delayed by up to 24 hours after a device state change. Factor this into incident triage before assuming non-compliance is genuine.

---

## Requirement 3 – Minimum OS build: 22621.2861 (N-1)

| Field | Detail |
|---|---|
| **Setting Name** | Minimum OS version |
| **UI Path** | Devices > Compliance policies > [Policy] > Device Properties > Minimum OS version |
| **Value** | `10.0.22621.2861` |
| **Effect** | Marks any device running a Windows build older than 22621.2861 (Windows 11 22H2, N-1 from the current stable 22621.3155) as non-compliant. This ensures devices are at a minimum one cumulative update behind the latest, reducing the risk of known CVEs. |
| **False-Positive Risk** | Devices that have a Windows Update scan pending or are mid-update cycle will temporarily fail. Devices blocked from Windows Update by a network or WSUS policy may genuinely fall behind. Virtual machines or gold images that have not been re-sysprepped since the baseline was raised will also fail. |
| **Recommendation** | Set the minimum build to `10.0.22621.2861` now and schedule a policy review each Patch Tuesday to raise the floor. Pair with a Windows Update for Business ring policy (Intune > Devices > Update rings) to actively push the latest CU to managed devices, preventing genuine non-compliance from build age. |

> ℹ️ **Build Reference:**  
> - Latest known good (N): `22621.3155`  
> - N-1 minimum floor: `22621.2861`  
> - Intune format requires the full `Major.Minor.Build.Revision` format: `10.0.22621.2861`

---

## Requirement 4 – Windows Defender real-time protection must be on

| Field | Detail |
|---|---|
| **Setting Name** | Require real-time protection |
| **UI Path** | Devices > Compliance policies > [Policy] > System Security > Microsoft Defender Antimalware > Require real-time protection |
| **Value** | Require |
| **Effect** | Verifies that Microsoft Defender Antivirus real-time protection is active. Devices where RTP has been disabled (manually, via script, or by a conflicting third-party AV product) will be marked non-compliant. |
| **False-Positive Risk** | If a third-party AV product (e.g. CrowdStrike, Sophos) is installed, Windows Security Centre may register it as the active AV and place Defender in passive mode. Intune's compliance check evaluates Defender specifically — passive mode may be read as RTP "off" depending on the Intune build and reporting cadence. |
| **Recommendation** | If a third-party EDR/AV is in use across the estate, validate whether the Intune compliance check respects passive mode before enforcing. If the third-party AV provides its own health attestation via a compliance partner connector (Intune > Tenant Administration > Connectors), use that instead to avoid false positives. |

> ⚠️ **UI Path Note:** This setting has moved between Intune releases. It may appear under **System Security > Microsoft Defender Antimalware** or under **Endpoint security > Antivirus**. Confirm current location in the Intune admin centre. The setting name in the compliance policy payload remains `defenderEnabled`.

---

## Requirement 5 – Firewall must be enabled for all profiles

| Field | Detail |
|---|---|
| **Setting Name** | Require Windows Firewall |
| **UI Path** | Devices > Compliance policies > [Policy] > System Security > Windows Firewall |
| **Value** | Require |
| **Effect** | Confirms that Windows Firewall is active on all three network profiles: Domain, Private, and Public. A device with Firewall disabled on any profile will be marked non-compliant. |
| **False-Positive Risk** | Some enterprise environments disable Windows Firewall via Group Policy in favour of a host-based firewall delivered by a security agent (e.g. Zscaler, Palo Alto Cortex). If GPO disables the Windows Firewall service, the Intune compliance check will flag those devices even though an equivalent control is in place. Certain VPN clients also temporarily toggle firewall profiles. |
| **Recommendation** | If a third-party host firewall is deployed, check whether it registers itself with the Windows Security Centre Firewall provider. If it does, Intune will read it as compliant. If it does not, raise an exception group and document the compensating control. Do not disable this check without a documented alternative. |

---

## Requirement 6 – A PIN or password must be configured

| Field | Detail |
|---|---|
| **Setting Name** | Require a password to unlock mobile devices *(Windows desktop: Password settings block)* |
| **UI Path** | Devices > Compliance policies > [Policy] > System Security > Password > Require a password to unlock mobile devices |
| **Value** | Require |
| **Supporting Settings** | Password type: `Alphanumeric` or `Numeric (PIN)` — set per DWP password policy; Minimum password length: per DWP standard (recommend ≥ 8); Maximum minutes of inactivity before password is required: `15` (or per DWP policy) |
| **Effect** | Ensures a screen lock credential (PIN, password, or Windows Hello) is configured on the device. Devices with no lock screen credential will be marked non-compliant. |
| **False-Positive Risk** | Shared kiosk devices or unattended workstations configured without a user password (auto-logon scenarios) will always fail this check. Domain-joined devices where the password policy is enforced by on-premises GPO may report as non-compliant if Intune cannot read the local security policy state via MDM. |
| **Recommendation** | For kiosk or shared devices, create a dedicated compliance policy with this requirement excluded and assign it to a separate dynamic group (e.g. `Kiosk-Devices`). For domain-joined co-managed devices, verify that the MDM authority workload for device compliance is set to Intune (not Configuration Manager) to ensure the check is evaluated. |

> ⚠️ **UI Path Note:** Password compliance settings on Windows desktop devices are less granular than on mobile. The setting label may read "mobile devices" in the UI but applies to all Windows 11 devices. This is a known labelling inconsistency in the Intune console — validate behaviour in a test tenant before broad rollout.

---

## Requirement 7 – Device must not be jailbroken or rooted

| Field | Detail |
|---|---|
| **Setting Name** | Block jailbroken devices |
| **UI Path** | Devices > Compliance policies > [Policy] > Device Health > Block jailbroken devices |
| **Value** | Block |
| **Effect** | On Windows, this setting ties into the **Device Health Attestation (DHA)** service, which checks the TPM-backed boot log for indicators of tampering, disabled Secure Boot, test-signing enabled, or code integrity violations. A device that fails attestation will be marked non-compliant. |
| **False-Positive Risk** | The term "jailbroken/rooted" primarily applies to iOS/Android. On Windows 11, the equivalent check uses DHA. Delays in attestation reporting (up to 24 hours), TPM firmware issues, or devices without a TPM 2.0 chip may cause sporadic failures. Developer mode or Hyper-V test environments with test-signing enabled will also trigger this. |
| **Recommendation** | Ensure all Windows 11 devices have TPM 2.0 enabled in BIOS (required for Windows 11 anyway). Monitor the DHA report in Intune to identify devices with genuine attestation failures vs. reporting delays. Combine with Requirement 2 (Secure Boot) for defence-in-depth — both are evaluated via the same DHA channel. |

> ⚠️ **UI Path Note:** On Windows, "Block jailbroken devices" is enforced via Device Health Attestation. The UI label may not clearly indicate this on Windows platforms. As of recent Intune builds this may also appear under **Device Health > Windows Health Attestation Service evaluation rules**. Confirm current UI labelling at time of deployment.

---

## Grace Period

| Setting | Value |
|---|---|
| **Mark device non-compliant** | After **7 days** |
| **UI Path** | Devices > Compliance policies > [Policy] > Actions for noncompliance > Mark device noncompliant > Schedule (days after noncompliance) = `7` |

The 7-day grace period applies to **all seven requirements above**. During this window, users will receive noncompliance notifications but will not be blocked from accessing resources (subject to Conditional Access policy configuration).

**Recommendation:** Configure the following noncompliance action sequence:
- Day 0: Send email to user
- Day 3: Send push notification reminder
- Day 7: Mark device non-compliant (triggers Conditional Access block if configured)

---

## Summary Table

| # | Requirement | Intune Setting | Value |
|---|---|---|---|
| 1 | BitLocker on OS drive | Require BitLocker | Require |
| 2 | Secure Boot enabled | Require Secure Boot to be enabled | Require |
| 3 | Min OS build 22621.2861 | Minimum OS version | 10.0.22621.2861 |
| 4 | Defender RTP on | Require real-time protection | Require |
| 5 | Firewall all profiles | Require Windows Firewall | Require |
| 6 | PIN or password configured | Require a password to unlock | Require |
| 7 | Not jailbroken/rooted | Block jailbroken devices | Block |
| – | Grace period | Mark device noncompliant | 7 days |

---

## UI Path Verification Checklist

The following settings have a **high likelihood of UI path changes** since training data. Verify each in the Intune admin centre before deployment:

- [ ] **Require BitLocker** — may appear in both Endpoint Security > Disk Encryption and Compliance Policies
- [ ] **Require real-time protection** — setting label and location varies by Intune build; check `defenderEnabled` in Graph API as ground truth
- [ ] **Block jailbroken devices (Windows)** — may be relabelled under Device Health Attestation rules
- [ ] **Require a password** — UI label says "mobile devices" but applies to Windows desktop; verify scope
- [ ] **Device Health Attestation** — attestation evaluation rules may have been split into discrete settings in newer Intune releases

**Recommended verification resource:** [Microsoft Intune compliance settings for Windows – Microsoft Learn](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-policy-create-windows)

---

## High-Risk Setting Analysis – Mass False-Non-Compliant Risk at Scale

### Highest-Risk Setting: Require BitLocker

**Why this is the highest risk at 10,000-device scale**

BitLocker is the single setting most likely to trigger a mass false-non-compliant event during a Windows 11 migration. Unlike Secure Boot or Defender RTP — which are either on or off and stable — BitLocker protection status is dynamic. It can move into a **suspended state** without user action, during routine, automated events that are common during a migration wave. At 10,000 devices all being re-imaged, domain-joined, or receiving BIOS/firmware updates in a short window, the probability of a significant percentage entering suspended BitLocker state simultaneously is high.

**The specific scenario in which it fires incorrectly**

During a Windows 11 in-place upgrade or bare-metal migration:

1. The upgrade/imaging process suspends BitLocker protection to allow the bootloader to be replaced.
2. Windows resumes protection automatically after the first successful reboot post-upgrade.
3. However, if the device has not yet completed that first reboot, or if a second update (firmware, BIOS, driver) is queued and triggers another suspension before Intune polls the device, the compliance check fires against a device in `ProtectionStatus = Suspended`.
4. Intune reads `Suspended` as non-compliant.
5. With a 7-day grace period, users are notified but not blocked — however, if Conditional Access is already enforcing compliance, those devices lose resource access immediately, generating a flood of helpdesk calls.

At 10,000 devices, even a 5% suspension window = **500 devices falsely flagged in the first 48 hours**.

**Exact value to set to prevent false positives while maintaining security intent**

Do not change the compliance setting value — keep it as `Require`. Changing the value weakens the control. Instead, mitigate through **timing and configuration**:

| Control | Exact Setting / Action |
|---|---|
| Grace period | Set to **7 days** (already planned) — this prevents Conditional Access blocks during the encryption completion window |
| BitLocker silent enablement profile | Endpoint Security > Disk Encryption > Create policy > Windows > BitLocker > **Require device encryption**: `Enabled`; **Allow standard users to enable encryption during Autopilot**: `Yes` |
| Delay Conditional Access enforcement | In the CA policy, set the compliance requirement grant control to enforce only after the grace period elapses — do not enable CA enforcement on day 0 of migration rollout |
| Phased assignment | Assign the compliance policy to a pilot group of ~500 devices first, observe BitLocker compliance rates for 48 hours, then expand to full fleet |

**What to monitor in the first 24 hours after policy assignment**

| What to monitor | Where to look | Threshold to act |
|---|---|---|
| Non-compliant device count for BitLocker specifically | Intune > Reports > Device compliance > Setting compliance > filter on "Require BitLocker" | >2% of assigned devices non-compliant after 24h should trigger investigation |
| Devices in grace period vs. genuinely non-compliant | Intune > Devices > Compliance status > filter "In grace period" | Large spike in grace period (>5%) on day 1 = likely suspension wave |
| BitLocker protection status on sample devices | Run `manage-bde -status C:` on 5–10 flagged devices via Intune Remediations or direct RDP | If status = "Protection Suspended" rather than "Off", it is a false positive — protection will auto-resume |
| Helpdesk ticket volume for access denied | ServiceNow / ticketing system — filter on Conditional Access / MFA / compliance keywords | Any spike in access-denied tickets in first 2 hours post-assignment = CA policy enforcing too early |

---

## Validation Steps – Post-Assignment Compliance Check

### 1. Where to find the device's compliance status for this specific policy

After the test device syncs, navigate in the Intune admin centre:

**Devices > [Device name] > Device compliance**

This shows a list of all compliance policies assigned to the device. Select the **Windows 11 Security Baseline** policy to drill into per-setting results. Each requirement will show as `Compliant`, `Not compliant`, or `Not applicable`.

Alternative path for a policy-first view:  
**Devices > Compliance policies > [Policy name] > Device status**  
This lists every device assigned to the policy and its current status — useful for fleet-wide checking rather than per-device.

For the most granular setting-level breakdown:  
**Devices > [Device name] > Device compliance > [Policy name] > Per setting status**

---

### 2. What compliance states mean for Conditional Access

| Status | Meaning | Conditional Access impact |
|---|---|---|
| **Compliant** | All settings in the policy are met | Device is granted access to resources protected by CA policies that require compliant devices. No action needed. |
| **Not compliant** | One or more settings are not met AND the grace period has expired | CA policies enforcing `Require device to be marked as compliant` will **block access** to protected resources (e.g. Exchange Online, SharePoint, Teams) until the device returns to compliance. The user will see an access-denied page with a message prompting them to resolve compliance. |
| **In grace period** | One or more settings are not met BUT the grace period (7 days) has not yet elapsed | CA does **not** block access during the grace period. The user receives notification emails and portal warnings but can still access resources. After day 7, if still non-compliant, the status moves to "Not compliant" and CA blocking applies. |

> **Important:** "In grace period" is only protective if your CA policy is configured to respect the grace period. If the CA grant control is set to `Require device to be marked as compliant`, it will block on `Not compliant` but not on `In grace period`. Verify your CA policy grant configuration matches this expectation.

---

### 3. Device shows non-compliant on BitLocker despite BitLocker being enabled – three most common causes

**Cause 1: BitLocker is in a suspended (not off) state**

- **Why it happens:** A Windows Update, firmware update, or BIOS change caused BitLocker to auto-suspend protection. Intune reads `ProtectionStatus = Suspended` as non-compliant.
- **Fastest check:** On the device, open an elevated PowerShell prompt and run:
  ```powershell
  manage-bde -status C:
  ```
  Look at `Protection Status`. If it says **Protection Suspended**, BitLocker is on but paused. It will resume automatically on the next reboot. Reboot the device and re-sync Intune (`Settings > Accounts > Access work or school > [Account] > Info > Sync`).

---

**Cause 2: Intune compliance report is stale – device has not synced since BitLocker was enabled**

- **Why it happens:** The compliance check timestamp in Intune reflects the last successful MDM check-in, not real-time device state. If BitLocker was enabled after the last sync, Intune still shows the pre-BitLocker state.
- **Fastest check:** In Intune > Devices > [Device name], check the **Last check-in** timestamp. If it pre-dates when BitLocker was enabled, force a sync. On the device:
  ```
  Settings > Accounts > Access work or school > [Account] > Info > Sync
  ```
  Or from Intune admin centre: **Devices > [Device name] > Sync**. Allow up to 15 minutes for the compliance status to refresh.

---

**Cause 3: BitLocker is enabled but only on a non-OS drive, or C: drive encryption is incomplete**

- **Why it happens:** BitLocker may have been enabled on a data drive (D:) but not C:, or the initial encryption pass on C: is still in progress (large drives can take hours). Intune's `Require BitLocker` check evaluates the OS drive specifically.
- **Fastest check:** Run the following in elevated PowerShell to see per-volume status:
  ```powershell
  manage-bde -status
  ```
  Check the entry for `C:`. The **Percentage Encrypted** field must show `100%` and **Protection Status** must show `Protection On`. If encryption is in progress, wait for it to complete — no remediation needed, just patience. If C: shows `Protection Off` while another drive shows `Protection On`, BitLocker needs to be enabled on the OS drive explicitly:
  ```powershell
  Enable-BitLocker -MountPoint "C:" -RecoveryPasswordProtector
  ```

---

## UI Path Verification Checklist

The following settings have a **high likelihood of UI path changes** since training data. Verify each in the Intune admin centre before deployment:

- [ ] **Require BitLocker** — may appear in both Endpoint Security > Disk Encryption and Compliance Policies
- [ ] **Require real-time protection** — setting label and location varies by Intune build; check `defenderEnabled` in Graph API as ground truth
- [ ] **Block jailbroken devices (Windows)** — may be relabelled under Device Health Attestation rules
- [ ] **Require a password** — UI label says "mobile devices" but applies to Windows desktop; verify scope
- [ ] **Device Health Attestation** — attestation evaluation rules may have been split into discrete settings in newer Intune releases

**Recommended verification resource:** [Microsoft Intune compliance settings for Windows – Microsoft Learn](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-policy-create-windows)

---

*Document prepared by DWP Engineer. Review against current Intune admin centre UI before policy deployment. Raise any exceptions through the DWP change management process.*
