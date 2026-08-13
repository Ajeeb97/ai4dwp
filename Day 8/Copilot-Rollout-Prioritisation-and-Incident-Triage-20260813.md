# Copilot Rollout Prioritisation and Incident Triage (Finance)

## Version Header
- Date: 2026-08-13
- Author: DWP Engineering
- Scope: Finance Copilot readiness and ticket triage
- Related document: Prompt-Copilot-Readiness-Checklist-Finance.md

---

## 1) Rollout Checklist Prioritisation (Finance)

### MUST complete before rollout (blocking)
1. Permissions and oversharing audit across SharePoint, Teams, OneDrive, and shared drives.
2. Access boundary validation for Finance confidential content (least privilege, group membership hygiene, legacy access cleanup).
3. Sensitivity label and DLP policy validation for Finance data classes (board packs, payroll, forecasts, M&A, regulated records).
4. Pilot user access-path validation (test accounts can retrieve only what they should, and cannot retrieve what they should not).
5. Incident response guardrails for data exposure events (ownership, escalation path, rollback/containment action).

### SHOULD complete before rollout (high risk if skipped)
1. Data indexing readiness checks for key Finance repositories and recently migrated content.
2. Shared mailbox and delegated access scenario checks for executives, assistants, and finance operations users.
3. External/guest sharing behavior tests for common cross-org workflows (client and auditor document access patterns).
4. User communication and L1 triage playbook aligned to known non-bug causes.

### CAN complete during/after rollout (lower risk)
1. License assignment quality sweep and exception cleanup after initial pilot cohort is stable.
2. Client version harmonization and channel optimization where baseline support already exists.
3. Prompt coaching packs and advanced usage enablement by persona.
4. Telemetry tuning and trend dashboards for adoption and ticket categorization.

### Why permissions/oversharing is MUST in Finance (even if license/client checks are simpler)
Permissions and oversharing audit belongs in MUST because impact severity, not verification simplicity, determines rollout blockers in Finance. License/client checks are generally fast, deterministic, and reversible: if a user lacks a license or has an unsupported build, access can be corrected with low blast radius. By contrast, permission mis-scoping can immediately expose confidential financial data to the wrong audience, and Copilot can surface that data at speed once access exists.

For Finance, this creates a materially higher business and regulatory risk profile:
- A single ACL mistake can expose salary, forecasting, board, tax, or transaction data.
- Oversharing issues are often silent until discovery, so prevention must happen before scale.
- Remediation after exposure is costlier than prevention and may trigger legal/compliance actions.
- Correct licensing does not mitigate data boundary failures; it only enables service usage.

Therefore, permissions/oversharing controls are a precondition for safe rollout, while licensing/client verification is important but operationally lower risk.

---

## 2) Prompt for Copilot Incident Triage

Use this rubric for DWP Copilot support tickets. Rank likely causes from this list only:
- permissions/access boundary
- data indexing lag
- sensitivity label restriction
- license/client prerequisite issue
- guest/external sharing limitation
- genuine Copilot fault (last resort)

Default to non-Copilot causes unless evidence rules them out.

### Ticket Triage Output

#### Ticket 1
- id: 1
- ticket: Finance lead: Copilot won't summarise the Q3 board pack in SharePoint. "It's right there, I can see it myself."
- Likely cause (ranked):
  1. permissions/access boundary
  2. sensitivity label restriction
  3. data indexing lag
  4. license/client prerequisite issue
  5. guest/external sharing limitation
  6. genuine Copilot fault
- Fastest check: Confirm whether the board pack library/file has unique permissions, restricted group membership, or label-based access policy that differs from the user's interactive view path.
- Is this actually a Copilot bug?: No. Most evidence points to access-boundary or policy controls rather than a product defect.

#### Ticket 2
- id: 2
- ticket: New hire (started yesterday): Copilot in Outlook seems to know nothing about my recent emails.
- Likely cause (ranked):
  1. data indexing lag
  2. license/client prerequisite issue
  3. permissions/access boundary
  4. sensitivity label restriction
  5. guest/external sharing limitation
  6. genuine Copilot fault
- Fastest check: Check mailbox indexing/crawl freshness and provisioning age for the new account.
- Is this actually a Copilot bug?: No. New-user indexing and provisioning delay is the most likely explanation.

#### Ticket 3
- id: 3
- ticket: HR manager: Asked Copilot in Word to pull data from a sensitive salary review spreadsheet, got "I don't have access to that content."
- Likely cause (ranked):
  1. sensitivity label restriction
  2. permissions/access boundary
  3. data indexing lag
  4. license/client prerequisite issue
  5. guest/external sharing limitation
  6. genuine Copilot fault
- Fastest check: Inspect sensitivity label and effective rights on the salary file for that HR manager identity.
- Is this actually a Copilot bug?: No. The response is consistent with intentional policy or access enforcement.

#### Ticket 4
- id: 4
- ticket: Sales rep: Copilot in Teams can't find a client contract that was shared with her via a guest link from another org.
- Likely cause (ranked):
  1. guest/external sharing limitation
  2. permissions/access boundary
  3. data indexing lag
  4. license/client prerequisite issue
  5. sensitivity label restriction
  6. genuine Copilot fault
- Fastest check: Verify whether the content is in an external tenant and only accessible by guest link rather than org-native indexed access.
- Is this actually a Copilot bug?: No. Cross-tenant guest-link scope is the most probable limitation.

#### Ticket 5
- id: 5
- ticket: IT admin: Copilot suddenly stopped working for the whole Finance team this morning, was fine yesterday.
- Likely cause (ranked):
  1. license/client prerequisite issue
  2. permissions/access boundary
  3. genuine Copilot fault
  4. data indexing lag
  5. sensitivity label restriction
  6. guest/external sharing limitation
- Fastest check: Check tenant-wide license assignment and service health/admin advisories for Finance scope changes since yesterday.
- Is this actually a Copilot bug?: Unclear. Could be platform-side, but first rule out tenant configuration/licensing changes and known service incidents.

#### Ticket 6
- id: 6
- ticket: Manager: Copilot found and summarised a file I don't remember ever opening, from a folder I forgot I had access to.
- Likely cause (ranked):
  1. permissions/access boundary
  2. data indexing lag
  3. sensitivity label restriction
  4. license/client prerequisite issue
  5. guest/external sharing limitation
  6. genuine Copilot fault
- Fastest check: Validate current effective permissions and historical group membership on that folder/file.
- Is this actually a Copilot bug?: No. This indicates legitimate but potentially over-broad access, not necessarily product malfunction.

#### Ticket 7
- id: 7
- ticket: Analyst: Copilot gives generic answers, doesn't seem to use any of our internal SharePoint content at all.
- Likely cause (ranked):
  1. license/client prerequisite issue
  2. permissions/access boundary
  3. data indexing lag
  4. sensitivity label restriction
  5. guest/external sharing limitation
  6. genuine Copilot fault
- Fastest check: Validate the analyst's Copilot license status and supported client build/channel first.
- Is this actually a Copilot bug?: No. Generic responses often map to prerequisite or access scope gaps.

#### Ticket 8
- id: 8
- ticket: Executive assistant: Copilot in Outlook can't see a shared mailbox's calendar that I manage on behalf of my director.
- Likely cause (ranked):
  1. permissions/access boundary
  2. guest/external sharing limitation
  3. license/client prerequisite issue
  4. data indexing lag
  5. sensitivity label restriction
  6. genuine Copilot fault
- Fastest check: Confirm delegated/shared mailbox calendar permissions are supported for Copilot retrieval in this scenario and correctly granted.
- Is this actually a Copilot bug?: Unclear. Shared/delegated mailbox behavior can be limitation-driven; verify supported scenario boundaries before treating as defect.
