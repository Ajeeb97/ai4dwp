# Floor 6 Monday Incident Response

## Version Header

| Field | Value |
|---|---|
| Title | Floor 6 Win11 / Intune / Document Management Incident Response |
| Date | Monday morning; exact calendar date not supplied |
| Location | FinBridge Floor 6 |
| Business area | Legal |
| Population | 45 people |
| Status | Initial assessment and response plan; evidence collection pending |
| Audience | IT Operations, Service Desk, Security/Privacy, Legal partners |

## 1. Executive Assessment

At 09:14, IT Ops reported at least 12 Floor 6 users with sign-in failure or severe sign-in delay. Additional reports were:

- Copilot surfaced a client matter that one paralegal says she never had access to.
- A user's desktop shortcuts disappeared.
- A new document management application was rolled out to the floor on Friday afternoon.
- The floor recently migrated to Windows 11 and enrolled in Intune.

No logs, exports, or user/device list were supplied. Therefore no root cause is confirmed yet.

### Working incident statement

A likely change-related endpoint incident is affecting Floor 6, with a separate high-priority potential data-access incident embedded in the symptom set. The Friday document-management deployment is the leading common-cause hypothesis for the sign-in and desktop symptoms, but the Copilot report must be investigated independently as a possible over-broad permission, group-membership, sensitivity-label, indexing, or data-governance failure. Copilot itself must not be blamed or cleared until the user's effective access to the exact client matter is verified.

### Initial priority

- **P1 security/privacy workstream:** preserve evidence and restrict the reported matter if unauthorized access is confirmed or cannot be quickly explained.
- **P2 major incident workstream:** stabilize Floor 6 sign-in and desktop access for the affected users.
- **Change control:** pause further deployment of the document-management application until its scope, health, and rollback path are verified.

Do not make a broad tenant permission change, delete evidence, or uninstall the application from all 45 devices before the affected cohort and rollback impact are known.

## 2. What Is Known, Unknown, and Assumed

### Confirmed from the initial report

- The affected business area is Legal on Floor 6.
- The floor contains 45 people.
- At least 12 people are unable to sign in or experience very slow sign-in.
- One user reported unexpected Copilot access to a client matter.
- One user reported missing desktop shortcuts.
- The document-management application was deployed to that floor on Friday afternoon.
- The floor recently moved to Windows 11 and enrolled in Intune.

### Not yet known

- Which users, devices, applications, and locations are affected.
- Whether sign-in fails before authentication, during profile load, or after the desktop appears.
- Whether the affected devices received the application and which version.
- Whether the application changed shell, profile, folder-redirection, OneDrive, or shortcut policy.
- Whether the Copilot result came from a file the user could already access.
- The exact client matter, file path, prompt, timestamp, and response shown by Copilot.
- Whether access was interactive, inherited, group-based, guest-based, or label-controlled.
- Whether the issue is confined to Floor 6 or is a wider Win11/Intune/change ring problem.
- Whether any client data was copied, downloaded, shared, or acted upon.

### Assumptions that must be tested

- The Friday deployment is a common change in the affected cohort.
- The sign-in reports represent one incident rather than unrelated account, network, and profile problems.
- The missing shortcuts may be a profile or policy symptom rather than deleted files.
- The Copilot report may represent legitimate but unexpected access; it is not proof of a Copilot security defect.

## 3. Immediate Actions: First 30 Minutes

### 3.1 Establish control and protect evidence

1. Open one major incident record and a linked security/privacy incident record for the Copilot report. Record 09:14 as the first known report time and keep all timestamps in local time plus UTC where possible.
2. Appoint separate owners:
   - Major incident lead for sign-in and endpoint recovery.
   - Security/privacy lead for the client-matter report.
   - Communications owner for the 45-person floor and partners.
   - Change owner for deployment pause and rollback assessment.
3. Ask the IT Ops lead for the first affected user, the currently affected count, device names, exact symptoms, and whether the count is rising.
4. Preserve the reported user's Copilot prompt, response, conversation link, matter/file URL, timestamp, screenshot, and browser/client details. Do not ask the user to keep testing the sensitive matter.
5. Tell the reporting user not to forward, download, copy, or discuss the surfaced client content beyond the named incident team. Do not include client content in general chat or the incident title.
6. Restrict the reported file or matter only through the data owner/security process if the access review shows the user should not have access. Preserve the current ACL and audit state before changing it.
7. Pause the document-management deployment to any devices or rings not already completed. Do not remove the application from all 45 devices yet.
8. Create a device/user impact table with columns: user, device, sign-in symptom, first seen, app version/install time, Win11 build, Intune last check-in, profile status, shortcuts status, and recovery result.

### 3.2 Give users a safe holding message

> IT is investigating a Floor 6 sign-in and desktop issue following recent system changes. If you cannot sign in, stop repeated attempts and contact the Service Desk with your name, device name, time, and exact message. Do not open, copy, or share any unexpected client material surfaced by Copilot; report it privately to IT immediately. Please do not uninstall the new document-management application or delete local/profile files while we investigate.

### 3.3 First containment targets

Within 30 minutes, aim to achieve:

- No further deployment beyond the current Floor 6 scope.
- A named list of all currently affected users and devices.
- One representative affected device and one apparently healthy comparison device.
- Evidence preserved for the Copilot report.
- A decision on whether the matter access is valid, unknown, or unauthorized.
- A tested recovery path for one user before any broad remediation.

## 4. Evidence Collection and Checks

Collect read-only evidence first. Each result must include source, collector, timestamp, user/device scope, and interpretation.

| Question | Evidence to collect | Check and decision |
|---|---|---|
| Is the issue tied to Friday's change? | Intune app deployment report, application version, install/uninstall times, assignment group, deployment status | Join affected devices to the Friday deployment. A strong correlation is affected devices receiving the same version before symptoms while comparison devices do not. |
| Is sign-in failing at identity or profile load? | Screenshot/error text; Entra sign-in logs; Windows `User Profile Service`, `Winlogon`, `GroupPolicy`, and `Shell-Core` events; sign-in duration | Separate authentication failure, policy delay, profile load, and shell/desktop failure. Do not call all of these "login failure." |
| Is there a device or network cohort? | Device model, Win11 build, RAM/disk health, Wi-Fi/VPN, Intune check-in, compliance, Conditional Access result | Compare affected and healthy Floor 6 devices. A shared build, model, policy, or network segment points away from individual accounts. |
| Did Intune apply a profile or remediation on Friday? | Device timeline, configuration-policy status, remediation scripts, ESP/provisioning status, policy assignment changes | Correlate policy application time with first symptom. Capture failed policy names and error codes. |
| Did the app alter the shell/profile/shortcuts? | Vendor install log, MSI/installer return code, application version, release notes, known issues, shortcut locations, GPO/Intune policy history | Check whether shortcuts are absent from the profile, moved to OneDrive/known folders, removed by policy, or merely hidden. Test a new profile before restoring files. |
| Are shortcuts missing for one user or many? | Desktop folder contents, `C:\Users\<user>\Desktop`, public desktop, OneDrive Desktop status, Start menu, Explorer hidden-item setting | If only one profile is affected, investigate profile/OneDrive sync. If many devices share the pattern, investigate package or policy behavior. |
| Is the Copilot matter access authorized? | Exact matter/file URL, user's Entra ID, SharePoint/Teams location, effective permissions, group memberships, sensitivity label, sharing links, audit logs | Verify direct and inherited access to the exact object. Compare current permissions with the user's expected matter assignment. |
| Did Copilot bypass access controls? | Purview/SharePoint audit events, Copilot interaction/audit records where available, file access events, download/share events | Do not infer bypass from an unexpected result. Bypass is supported only if the user lacked effective access at retrieval time and service/audit evidence shows the content was returned. |
| Is the issue wider than Floor 6? | Service health, Entra/Intune incident advisories, sign-in failure rates, other Win11 deployment rings | A matching wider outage changes containment from floor-specific to tenant/service-level response. |

### Minimum data request to each affected user

Request only operational metadata at first: name, username, device name, exact sign-in message, first occurrence time, whether another device works, whether the desktop eventually appears, and whether shortcuts are missing from Desktop, Start, or both. Do not request client document contents through an open channel.

### Representative device comparison

Use at least:

1. One affected device that received the Friday application deployment.
2. One affected device with the same Win11/Intune baseline but a different symptom, if available.
3. One apparently healthy Floor 6 device that received the same deployment.
4. One healthy comparison device outside Floor 6, if the deployment was broader.

Capture before remediation. A single successful reboot is not proof that the cause is fixed.

## 5. Hypotheses and Discriminating Checks

### H1: Friday document-management deployment caused endpoint/profile degradation

**Why it fits:** It is the only named common change immediately before the incident and could affect shell integration, profile folders, authentication plug-ins, startup tasks, or disk activity.

**Cheapest disconfirming check:** Compare affected devices with install success/version/time and application logs. If affected devices did not receive the package, H1 cannot explain the common symptom.

**Evidence needed to confirm:** Affected devices received the same version before symptoms, the installer or app logs show a matching failure, and a controlled rollback or vendor mitigation restores sign-in/desktop behavior.

### H2: Win11/Intune policy or profile migration issue caused slow sign-in and missing shortcuts

**Why it fits:** The floor recently migrated and enrolled; policy processing, OneDrive Known Folder Move, profile conversion, or shell policy can affect both sign-in duration and visible shortcuts.

**Cheapest disconfirming check:** Review `User Profile Service`, `GroupPolicy`, and Intune policy status on affected and healthy devices, then test a known-good profile on one affected device.

**Evidence needed to confirm:** A common policy/profile error or delayed policy processing precedes the symptoms and reproduces independently of the document-management application.

### H3: Identity, Conditional Access, or account lockout problem

**Why it fits:** Some users cannot sign in, and recent migration/enrolment can expose stale credentials, device registration, or Conditional Access conditions.

**Cheapest disconfirming check:** Compare Entra sign-in results for affected users and test one account on a known-good device. If authentication succeeds but the desktop takes a long time to load, H3 is not the primary cause.

**Evidence needed to confirm:** Repeated identity errors, lockouts, token/device registration failures, or Conditional Access blocks aligned to the affected users/devices.

### H4: Legitimate but over-broad access caused the Copilot report

**Why it fits:** Users may retain inherited SharePoint permissions, old security-group membership, a sharing link, or access through the document-management app's matter workspace without realizing it.

**Cheapest disconfirming check:** Resolve the exact file's effective permissions for the paralegal and compare them with the matter access register.

**Evidence needed to confirm:** The user had effective access at retrieval time but should not have had it under the matter's approved access list. This is an access-governance incident even if Copilot operated as designed.

### H5: Genuine Copilot retrieval/access-control defect

**Why it fits:** It remains possible, especially if the user had no effective access and audit evidence shows the exact restricted content was returned.

**Cheapest disconfirming check:** Reproduce only with an approved synthetic test file and test account after evidence preservation; do not repeatedly query the live client matter.

**Evidence needed to confirm:** Effective permissions deny access, labels/policies do not grant an exception, the content was returned, and Microsoft/service telemetry supports a product defect.

### H6: Unrelated coincidence or multiple concurrent faults

**Why it fits:** Sign-in, missing shortcuts, and Copilot retrieval can have different owners and failure modes.

**Cheapest disconfirming check:** Build the user/device timeline. If affected users split across deployment status, device baseline, and symptom onset, stop forcing a single-cause explanation.

## 6. Decision Tree for the Copilot Report

1. **Can the user identify the exact matter, file, workspace, or URL?**
   - No: preserve the prompt/response and escalate for privacy review; do not classify yet.
   - Yes: continue.
2. **Did the user have effective access at the time?**
   - Yes, but access was unexpected or unnecessary: classify as access-governance exposure; review and remove excess access through the matter owner.
   - No: continue.
3. **Was the object protected by a sensitivity label, DLP rule, restricted location, or external/guest boundary?**
   - Yes: preserve policy/audit evidence and escalate as a possible enforcement failure or configuration exception.
   - No: continue.
4. **Do audit records show the object was returned to the user?**
   - Yes: open a Microsoft/security product investigation with exact timestamps and object IDs.
   - No or records are unavailable: classify as unverified report, keep evidence, and do not assert a breach.

Until this decision tree completes, partners should be told only that an unexpected-content report is under restricted investigation.

## 7. Stabilisation and Remediation Plan

### 7.1 Sign-in and desktop symptoms

1. Keep the deployment paused and export its assignment/status before changing targets.
2. Triage users into four buckets: cannot authenticate; authenticates but profile load is slow; desktop loads without shortcuts; desktop loads normally after delay.
3. For one affected device, collect logs and create a recovery checkpoint according to approved endpoint tooling.
4. If the document-management package is confirmed as the common cause, use the vendor-approved repair or rollback on a pilot device first. Record version, package hash/source, and result.
5. If profile or policy processing is causal, correct the specific assignment or profile state; do not delete profiles or reset devices as a first response.
6. If an account/Conditional Access issue is causal, remediate the identity object or policy exception for the smallest affected scope and verify on a test device.
7. Restore shortcuts only after determining whether they were deleted, redirected, hidden, or unsynced. Restore from the approved source; do not copy client-sensitive shortcuts or content through personal storage.
8. Expand the fix in rings: one device, three devices, remaining confirmed affected cohort. Keep a rollback path at each ring.

### 7.2 Security/privacy workstream

- Preserve the exact object ID, ACL, labels, group membership, audit records, prompt, response, and timestamps.
- Notify the Legal matter owner and the designated privacy/security lead, not the whole floor.
- If unauthorized access is confirmed, remove only the unnecessary access, preserve a before/after record, review recent access/download/share activity, and follow FinBridge's breach-assessment process.
- If access was authorized but surprising, document the permission path and perform a least-privilege review.
- Do not delete the matter, purge audit records, or ask users to self-investigate by opening more client documents.

## 8. Verification and Closure Criteria

The major incident is not closed when one user can sign in. Close only when all applicable conditions pass:

- The affected-user/device list is complete enough to explain all reported cases.
- No new Floor 6 sign-in or profile-load reports occur during an agreed observation window.
- Representative affected devices complete two sign-ins each, with measured sign-in duration recorded.
- The document-management application version and deployment state match the approved remediation plan.
- Desktop shortcuts are present from the correct managed source, or the intended profile/policy behavior is documented.
- Intune check-in, compliance, and relevant policy status are healthy for remediated devices.
- The Copilot report has a documented classification: authorized access, over-broad access, suspected enforcement failure, or unverified.
- Any access change has a before/after permission record and matter-owner approval.
- Security/privacy confirms whether further notification or breach assessment is required.
- The deployment remains paused until the change owner approves resumption based on pilot evidence.

### Suggested operational thresholds

Use the floor's normal baseline where available. If no baseline exists, measure each representative device from credential submission to usable desktop and compare affected versus healthy devices. Do not invent a universal pass/fail time without recording the local baseline and user experience.

## 9. Rollback Triggers

Immediately stop expansion and keep the change paused if any of the following occurs:

- A remediated device shows the same sign-in or profile failure.
- The document-management application causes new installer, shell, profile, or authentication errors.
- Shortcuts or known folders disappear again after remediation.
- The Copilot investigation confirms content was returned despite denied effective access.
- New affected users appear outside the original Floor 6 cohort.
- The pilot cannot be reversed cleanly or its state cannot be verified.

For an unstable endpoint, isolate it from receiving further deployment, preserve logs, and use the approved endpoint rollback or recovery path. Do not repeatedly reboot or wipe it before evidence capture unless there is an immediate safety or data-protection reason.

## 10. Partner Update by Lunch

### What partners need to know

> IT is investigating a Floor 6 technology incident affecting sign-in speed and desktop availability for a number of Legal colleagues after recent Windows 11, Intune, and document-management changes. The document-management rollout has been paused while we compare affected and unaffected devices and test a controlled recovery. We are also handling one report of unexpected client-matter content in Copilot as a restricted security/privacy review. We have not concluded that client data was exposed or that Copilot malfunctioned; we are verifying the user's actual permissions and the relevant audit records. Users should not open, copy, or share unexpected content and should report it privately to IT. We will provide the next update after the first controlled remediation and access review results.

### Plain-English answers to likely questions

**Is client data exposed?**

We have one report that requires verification. We are checking whether the user already had permission to the matter and reviewing audit records. We are not declaring a breach before that check is complete.

**Can Legal keep working?**

Users who can sign in should use normal approved workflows. Users with sign-in problems should contact the Service Desk rather than repeatedly retrying or changing their device. Do not uninstall the new application or delete profile files.

**What is IT doing right now?**

We paused further rollout, identified affected devices, collected technical evidence, tested a controlled recovery, and escalated the unexpected-content report to the appropriate security/privacy owners.

**When will there be another update?**

Provide a specific time agreed by the incident lead, even if the update is that investigation is still in progress. Do not promise full resolution by lunch unless verification supports it.

## 11. Ticket and Evidence Record Template

Record the following in the major incident ticket:

- Incident start: `09:14` reported time; actual first symptom time when known.
- Scope: Floor 6 Legal, 45 people; current affected count and trend.
- Change: document-management application name/version, deployment start/completion, assignment, and rollback status.
- Cohort: user, device, Win11 build, Intune check-in, application version, symptom bucket.
- Evidence: source, exact timestamp, event/policy/error ID, interpretation, and collector.
- Actions: owner, time, scope, expected result, actual result, rollback point.
- Communications: user holding message, partner update time, next update time.
- Closure: verification results, residual risk, security/privacy disposition, and change resumption decision.

Record the following only in the restricted security/privacy record:

- Matter/file/object identifier and location.
- User identity and effective permission result.
- Sensitivity label, group path, sharing link, and relevant policy state.
- Copilot prompt/response evidence and audit correlation.
- Access/download/share activity and approved containment actions.

## 12. Root Cause Position at This Stage

**Confirmed:** Floor 6 has a multi-symptom incident beginning after a Friday document-management deployment, against a background of recent Win11 migration and Intune enrolment. At least 12 users are affected or reported affected. **Reasoning:** These are the facts in the original 09:14 report; they establish timing and scope, but do not by themselves prove the application caused the symptoms.

**Leading hypothesis:** The new document-management change or an associated policy/profile action caused sign-in/profile/desktop degradation in a specific device cohort. **Reasoning:** It is the most specific shared change immediately before the symptoms, so it outranks the older Win11/Intune migration; the device comparison and controlled rollback are required to test that ranking.

**Not confirmed:** The application is the root cause; the missing shortcuts have been deleted; Copilot bypassed permissions; client data was exposed; or all reported symptoms share one cause. **Reasoning:** No device inventory, event logs, effective-permission result, or audit records were supplied, so each claim would exceed the evidence.

The final RCA must be based on joined device, deployment, identity, policy, application, permission, and audit evidence. Until that evidence exists, communicate the leading hypothesis as an investigation direction, not as a fact.

## 13. Preventive Actions After Recovery

1. Require a representative pilot before floor-wide application deployment, including recently migrated Win11/Intune devices and different hardware/profile conditions.
2. Capture pre- and post-change sign-in duration, profile-load errors, shortcut state, and Intune policy health.
3. Add deployment health gates that pause rollout when sign-in failures, profile errors, or shell/shortcut regressions exceed the local baseline.
4. Require release-note review for shell integration, profile folders, authentication plug-ins, and known limitations.
5. Add a Copilot data-boundary test set using synthetic Legal content and test accounts representing direct, inherited, guest, and restricted access.
6. Schedule recurring access reviews for Legal matter workspaces, inherited groups, sharing links, and document-management permissions.
7. Define a restricted unexpected-content reporting path so users can report possible exposure without reproducing or broadly forwarding client material.
8. Keep major incident, security/privacy, and change records linked but separately permissioned.

## 14. Required Triage Order: First 30 Minutes

| Order | Problem separated from the Slack report | First check | Why this order |
|---:|---|---|---|
| 1 | Possible client-data access through Copilot | Preserve the exact prompt, response, matter/file URL, user, and timestamp; then check effective permission on that exact object | Potential confidentiality impact outranks availability. Reproduction can create more exposure, so evidence comes first. |
| 2 | Users cannot authenticate | Compare one affected user's Entra sign-in log with the same user's attempt from a known-good device; capture the exact error | This distinguishes account/Conditional Access failure from a slow Windows profile and prevents needless endpoint changes. |
| 3 | Users authenticate but sign-in is very slow | Measure credential-to-desktop time and collect User Profile Service, Group Policy, Winlogon, and Intune policy errors on one affected device | A common profile/policy or application startup delay can affect many users and is directly testable. |
| 4 | Desktop shortcuts vanished | Check the user's Desktop, Public Desktop, OneDrive Known Folder Move state, and shortcut policy on an affected and healthy device | Shortcuts may be redirected, hidden, unsynced, or removed by policy; restoring files before identifying the path can destroy evidence. |
| 5 | Friday document-management deployment | Pause further assignment and correlate installed version/install time against affected devices | It is the strongest shared change, but containment must preserve the ability to prove or disprove causation. |
| 6 | Scope and trend | Build the 45-person/user/device impact list and query service health for wider Win11/Intune incidents | This determines whether the response stays floor-specific or becomes a tenant/service incident. |

### Copilot escalation

This is a security signal: it may indicate that a person can see client information they should not see, even if Copilot itself is working exactly as designed. It is not a normal Copilot support ticket and must not be closed as "AI weirdness"; preserve the exact object and access records, do not ask the user to reproduce it, and route it to Security/Privacy and the matter owner because only an access check can distinguish authorised access from possible exposure.

**Two-sentence escalation:**

> At 09:14, a Floor 6 paralegal reported that Copilot returned content from client matter `<matter/file identifier>` that she says she was not authorised to access; the prompt, response, object URL, user identity, and timestamp are preserved in the restricted incident record. Please perform an immediate effective-permission and audit review with Security/Privacy and the matter owner; do not reproduce against the live matter, and classify the event as authorised access, over-broad access, suspected enforcement failure, or unverified.

## 15. Ranked Differential and Deployment Test

### 1. Friday document-management application or its shell/profile integration

Fastest check: on one affected and one healthy Floor 6 device, join installed application version, install completion time, application logs, startup entries, and sign-in duration. The deployment is supported if affected devices received the same version before symptoms, healthy comparison devices did not share the condition, and an approved rollback or vendor fix restores the symptoms. It is ruled out as the primary cause if affected devices did not receive it, symptoms predate installation, or the same failure remains after a controlled rollback while the application is absent.

### 2. Intune policy, OneDrive folder redirection, or migrated Windows profile

Fastest check: compare Intune policy status and `User Profile Service`, `GroupPolicy`, and `Shell-Core` events on affected and healthy devices, then test a known-good profile. Confirming evidence is a common policy/profile error aligned to symptom onset and reproduction without the application. A clean policy state and a failure that follows the app install more closely lowers this rank.

### 3. Identity, device registration, or Conditional Access failure

Fastest check: compare Entra sign-in results for an affected account on the affected device and a known-good device. Repeated identity errors, lockouts, device-registration failures, or Conditional Access blocks confirm this path; successful authentication followed by a slow desktop rules it out as the primary explanation.

### 4. Network, storage, or security-agent performance regression

Fastest check: capture Wi-Fi/VPN state, disk latency, free space, and top CPU/disk processes during a slow sign-in. A shared network/storage/security-agent signature across devices supports it; a clean baseline and app-specific errors do not.

### 5. Multiple coincidental faults

Fastest check: build the user/device timeline. If affected users split across app assignment, policy baseline, symptom type, and onset, do not force a single root-cause explanation.

## 15a. Reflection: First Instinct Corrected

My first instinct was to blame the recent Windows 11 migration and Intune enrolment because the symptoms looked like a broad policy or profile problem: slow sign-in, missing shortcuts, and many users affected at once. The evidence did not support treating that as the leading cause. The Friday document-management deployment was the more specific shared change, and the discriminating check is whether affected devices received the same application version before their symptoms while a comparable healthy device did not.

That changed my working position from "the Win11/Intune baseline is probably broken" to "the Friday application deployment is the leading endpoint hypothesis, with Win11/Intune still a competing explanation to test." The same correction appears in Section 3a: the first AI-generated collector was too loose about its dry-run behavior and evidence scope, so I hand-corrected it to return before collection in dry-run mode, inspect both uninstall registry paths, limit events to relevant providers and time windows, and produce structured evidence. The lesson is the same in both cases: a plausible broad cause is not enough; the next check must be specific enough to change the decision.

## 16. Evidence Script: AI Draft and Hand-Corrected Version

The script is read-only unless a future maintainer adds a mutation outside the collection functions. Supplying `-DryRun` prints the intended collection scope and returns before reading or writing endpoint evidence.

### AI-generated first draft

```powershell
param(
   [switch]$DryRun = $true,
   [string]$OutputPath = "C:\Temp\Floor6-Evidence.json"
)

$app = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
   Where-Object { $_.DisplayName -like "*Document Manager*" } |
   Select-Object DisplayName, DisplayVersion, InstallDate

$events = Get-WinEvent -FilterHashtable @{ LogName = "System"; Id = 6005,6006 } -MaxEvents 20
$disk = Get-Counter "\\LogicalDisk(*)\\% Disk Time" -SampleInterval 1 -MaxSamples 3

$result = [pscustomobject]@{
   ComputerName = $env:COMPUTERNAME
   CollectedAt = Get-Date
   Application = $app
   Events = $events
   Disk = $disk
}

if ($DryRun) {
   Write-Output "Dry run: would write evidence to $OutputPath"
} else {
   $result | ConvertTo-Json -Depth 5 | Out-File $OutputPath
}
```

### Hand-corrected version

```powershell
[CmdletBinding()]
param(
   [switch]$DryRun,
   [ValidateNotNullOrEmpty()]
   [string]$OutputPath = 'C:\ProgramData\FinBridge\Floor6-Evidence.json'
)

$ErrorActionPreference = 'Stop'
$startTime = (Get-Date).AddHours(-4)
$applicationPattern = '*Document Manager*'

if ($DryRun) {
   [pscustomobject]@{
      Mode = 'DRY-RUN'
      ComputerName = $env:COMPUTERNAME
      WouldCollect = @('installed application/version', 'recent profile/policy events', 'performance samples', 'enrollment key inventory')
      WouldWrite = $OutputPath
   } | ConvertTo-Json -Depth 4
   return
}

function Get-InstalledDocumentManager {
   $paths = @(
      'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
      'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
   )

   foreach ($path in $paths) {
      Get-ItemProperty -Path $path -ErrorAction Stop |
         Where-Object { $_.DisplayName -like $applicationPattern } |
         Select-Object DisplayName, DisplayVersion, InstallDate, InstallLocation, UninstallString
   }
}

function Get-SignInEvents {
   $logs = @('System', 'Application')
   $providers = @('Microsoft-Windows-User Profiles Service', 'Microsoft-Windows-GroupPolicy', 'Winlogon')

   foreach ($log in $logs) {
      Get-WinEvent -FilterHashtable @{ LogName = $log; StartTime = $startTime } -MaxEvents 5000 -ErrorAction Stop |
         Where-Object { $providers -contains $_.ProviderName } |
         Select-Object LogName, ProviderName, Id, LevelDisplayName, TimeCreated, Message
   }
}

function Get-PerformanceSnapshot {
   Get-Counter -Counter @(
      '\LogicalDisk(*)\Disk Transfers/sec',
      '\Processor(_Total)\% Processor Time',
      '\Memory\Available MBytes'
   ) -SampleInterval 1 -MaxSamples 3 |
      Select-Object -ExpandProperty CounterSamples |
      Select-Object Path, InstanceName, CookedValue, Timestamp
}

function Invoke-EvidenceCollection {
   param(
      [Parameter(Mandatory)]
      [string]$Name,
      [Parameter(Mandatory)]
      [scriptblock]$Collector
   )

   try {
      [pscustomobject]@{
         Name = $Name
         Success = $true
         Error = $null
         Data = @(& $Collector)
      }
   }
   catch {
      [pscustomobject]@{
         Name = $Name
         Success = $false
         Error = $_.Exception.Message
         Data = @()
      }
   }
}

$evidence = [ordered]@{
   ComputerName = $env:COMPUTERNAME
   CollectedAt = (Get-Date).ToString('o')
   CollectionWindowStart = $startTime.ToString('o')
   DryRun = [bool]$DryRun
   Collections = @(
      Invoke-EvidenceCollection -Name 'Application' -Collector { Get-InstalledDocumentManager }
      Invoke-EvidenceCollection -Name 'SignInEvents' -Collector { Get-SignInEvents }
      Invoke-EvidenceCollection -Name 'Performance' -Collector { Get-PerformanceSnapshot }
      Invoke-EvidenceCollection -Name 'IntuneRegistry' -Collector {
         Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction Stop |
            ForEach-Object {
               Get-ItemProperty -Path $_.PSPath -ErrorAction Stop |
                  Select-Object PSPath, ProviderID, EnrollmentType, UPN, LastSyncTime, DiscoveryServiceFullURL
            }
      }
   )
}

$parent = Split-Path -Parent $OutputPath
New-Item -Path $parent -ItemType Directory -Force | Out-Null
$evidence | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Output "Evidence written to $OutputPath"
```

**Hand correction:** I made dry-run return before collection, added the 32-bit uninstall path, limited events to the relevant providers and a 5,000-event safety bound, captured actionable event fields, recorded useful enrollment values, and recorded per-collector errors instead of silently treating missing evidence as a clean result.

## 17. Immediate Fix and Concrete Commands

The most-likely cause is the Friday document-management deployment, pending the comparison check. To pause new delivery without uninstalling the application from existing devices, change the suspect assignment to a pre-approved empty hold group. This is an assignment change, not a universal Intune pause, so export the original assignment first and obtain change-owner approval:

```powershell
# Run from an approved admin workstation after Connect-MgGraph with the required scopes.
$mobileAppId = '<document-manager-app-object-id>'
$appAssignmentId = '<document-manager-assignment-id>'
$holdGroupId = '<pre-approved-empty-hold-group-object-id>'
$originalAssignment = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $mobileAppId -MobileAppAssignmentId $appAssignmentId
$originalAssignment | ConvertTo-Json -Depth 10 | Set-Content 'C:\ProgramData\FinBridge\Floor6-original-assignment.json'
$body = @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $holdGroupId } } | ConvertTo-Json -Depth 5
Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$mobileAppId/assignments/$appAssignmentId" -Body $body -ContentType 'application/json'
```

Expected result: the assignment targets only the approved empty hold group, the original assignment is preserved for rollback, and no new device receives the suspect deployment. If the assignment uses required intent or dependencies that make reassignment unsafe, stop and use the approved Intune change procedure instead.

For a confirmed affected device with a known MSI product code, the approved endpoint rollback command is:

```powershell
msiexec.exe /x '{<DOCUMENT-MANAGER-MSI-PRODUCT-CODE>}' /qn /norestart /L*v 'C:\ProgramData\FinBridge\DocManager-rollback.log'
```

The command must be run elevated, with the product code and supported rollback package substituted from the change record. If the application is not MSI-based, use the vendor's signed rollback package and record its hash; do not invent an uninstall string from an untrusted source. Validate one affected device, then three, before expanding.

## 18. Deliverable Map

- Operational runbook: `Capstone Project/Floor-6-Document-Manager-Rollback-Runbook.md`
- Evidence comparison template: `Capstone Project/Evidence-Comparison-Template.md`
- L1 article: `Capstone Project/KB-L1-Floor-6-Sign-In-and-Shortcuts.md`
- L2 article: `Capstone Project/KB-L2-Floor-6-Document-Manager-Regression.md`
- Partner handout: `Capstone Project/Floor-6-Partner-Update-by-Lunch.md`
