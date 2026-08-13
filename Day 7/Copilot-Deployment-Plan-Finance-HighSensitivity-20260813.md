# Copilot Deployment Plan - Finance (High Sensitivity)

## Version Header
- Date: 2026-08-13
- Audience: IT Operations, Security, Finance Leadership
- Department Scope: Finance (~200 users)
- Baseline: M365 E5 assigned, Copilot add-on not assigned

## Deployment Context
- Data sensitivity is high: payroll, board packs, M&A artifacts, and client financial data.
- SharePoint permissions are inherited from 2019 migration and have not been fully audited.
- Risk profile is elevated for over-permissioned content exposure through semantic search and Copilot grounding.

## Decision
Do not perform broad Copilot add-on assignment to all 200 Finance users yet.
Proceed with a controlled rollout after access governance controls are validated.

## Top Risks To Address First
1. Over-permissioned SharePoint/OneDrive content could be surfaced to users who technically have access but should not.
2. Legacy inheritance and stale group memberships may grant broader visibility than intended.
3. No current evidence of recent end-to-end permission audit in Finance repositories.

## Day 0-5 Readiness Workstream (Mandatory)

### 1) Identity and Access Hygiene
- Review Finance Entra ID groups and nested group structure.
- Remove stale memberships (movers/leavers, temporary projects, legacy shared accounts).
- Enforce least privilege for high-impact sites (Payroll, Board, M&A, Client Finance).

### 2) SharePoint and OneDrive Permission Audit
- Inventory top Finance SharePoint sites, document libraries, and critical folders.
- Identify broken inheritance, broad Members/Visitors assignments, and Everyone/All Company exposure.
- Validate owner accountability for each sensitive site.
- Remediate over-broad ACLs before Copilot enablement.

### 3) Purview and Data Protection Baseline
- Confirm sensitivity labels for Finance data classes (Confidential Finance, Restricted M&A, Payroll Restricted).
- Validate DLP policies in Exchange, SharePoint, OneDrive, Teams for financial identifiers and board materials.
- Ensure audit logging and insider risk monitoring are enabled for pilot scope.

### 4) Copilot Policy and Experience Controls
- Define approved prompts/use cases for Finance.
- Configure Copilot-related controls (web grounding/search and plugin policy according to security requirements).
- Decide whether to restrict third-party connectors during pilot.

## Phased Rollout Plan

### Phase 1: Pilot (Week 1-2)
- Scope: 20 users (10 finance managers, 5 analysts, 5 operations users).
- Eligibility: Completed security briefing and approved use-case list.
- Licensing: Assign Copilot add-on only to pilot group.
- Success criteria:
  - No critical data exposure incidents.
  - >= 70% pilot users report measurable productivity gain.
  - <= 5% Sev-2 support issues tied to Copilot access/governance.

### Phase 2: Expanded Ring (Week 3-4)
- Scope: Additional 60 users.
- Gate: Phase 1 controls validated and remediation actions closed.
- Continue weekly permission drift checks and incident review.

### Phase 3: Full Finance Rollout (Week 5+)
- Scope: Remaining ~120 users.
- Gate: Security sign-off, data-owner sign-off, support readiness sign-off.

## Operational Tasks
1. Create group: FIN-Copilot-Pilot-Users.
2. Assign Copilot add-on to pilot group only.
3. Publish approved Finance prompt catalog and unacceptable-use examples.
4. Stand up support triage path: access issue, data exposure concern, quality feedback.
5. Implement weekly control report:
- New external shares
- Permission changes on sensitive sites
- DLP incidents and policy hits

## Communication Plan

### Pre-Pilot Message (Finance Pilot Users)
- Explain purpose, boundaries, and data handling expectations.
- Share support channel and expected response times.

### Leadership Update (Weekly)
- Pilot adoption, productivity indicators, risk findings, and go/no-go recommendation for next ring.

## Go/No-Go Checklist
- SharePoint permission audit completed for top sensitive Finance repositories.
- Critical over-permission findings remediated and revalidated.
- Sensitivity labels and DLP policy coverage confirmed.
- Pilot support runbook approved.
- Security and Finance data-owner sign-off recorded.

## Immediate Recommendation For Today
1. Start permission audit on highest-risk Finance sites (Payroll, Board Packs, M&A, Client Data).
2. Create pilot security baseline and pilot user cohort.
3. Delay broad license assignment until audit remediation is complete.
