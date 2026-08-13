# Exercise: Legal Copilot Tickets - Incident Triage and End-User Communication

## Version Header
- Date: 2026-08-13
- Author: DWP Engineering
- Audience: Legal support triage and end users
- Scope: 5 Copilot support tickets

---

## 1) Incident Triage

### Ticket 1
- Ticket: Paralegal asked Copilot to summarise a client NDA in SharePoint and got "I don't have access to that content." The file is in a folder she has never opened before.
- Likely cause (ranked):
  1. permissions/access boundary
  2. sensitivity label restriction
  3. data indexing lag
  4. license/client prerequisite issue
  5. guest/external sharing limitation
  6. genuine Copilot fault
- Fastest check: Verify the paralegal has effective permission to the exact NDA file and folder path in SharePoint.
- Is this actually a Copilot bug?: No. The error strongly indicates normal access enforcement.

### Ticket 2
- Ticket: New associate (started this week) says Copilot in Outlook cannot find any case emails needed for context.
- Likely cause (ranked):
  1. data indexing lag
  2. license/client prerequisite issue
  3. permissions/access boundary
  4. sensitivity label restriction
  5. guest/external sharing limitation
  6. genuine Copilot fault
- Fastest check: Check mailbox indexing/provisioning freshness for the new account.
- Is this actually a Copilot bug?: No. New starter indexing delay is the most likely cause.

### Ticket 3
- Ticket: Partner saw Copilot summarise a draft settlement from a matter they are not assigned to and did not realize they had folder access.
- Likely cause (ranked):
  1. permissions/access boundary
  2. sensitivity label restriction
  3. data indexing lag
  4. license/client prerequisite issue
  5. guest/external sharing limitation
  6. genuine Copilot fault
- Fastest check: Validate the partner's effective permissions and group membership on that matter workspace.
- Is this actually a Copilot bug?: No. This is most consistent with over-broad access permissions rather than product failure.

### Ticket 4
- Ticket: Legal ops manager reports all 40 Legal users lost Copilot access this morning; it worked last week.
- Likely cause (ranked):
  1. license/client prerequisite issue
  2. permissions/access boundary
  3. genuine Copilot fault
  4. data indexing lag
  5. sensitivity label restriction
  6. guest/external sharing limitation
- Fastest check: Check tenant-level license assignment and Microsoft 365 service health for legal-user scope changes/incidents.
- Is this actually a Copilot bug?: Unclear. Team-wide failure can be service-side, but prerequisite and tenant config checks must be ruled out first.

### Ticket 5
- Ticket: Contract specialist gets vague generic answers about clauses in contract templates library; Copilot appears not to read documents.
- Likely cause (ranked):
  1. permissions/access boundary
  2. data indexing lag
  3. license/client prerequisite issue
  4. sensitivity label restriction
  5. guest/external sharing limitation
  6. genuine Copilot fault
- Fastest check: Test one known template file the user can open and ask Copilot about that file by name.
- Is this actually a Copilot bug?: No. Generic output usually means source content is not accessible/indexed for that query context.

---

## 2) End-User Communication (Plain English)

### Message to users
Most Copilot issues are caused by access settings, indexing delays, or account setup, not by Copilot being "broken." We can usually fix these quickly once we check the right first step.

### Issue 1: "I can't summarise the NDA"
What it means:
- Copilot is likely enforcing normal access controls on that NDA location.

What to do next:
1. Open the exact NDA file and folder directly in SharePoint.
2. If access is denied or partial, request access through your matter owner/IT route.
3. Re-try Copilot once access is confirmed.

### Issue 2: "I'm new and Copilot can't find my Outlook case emails"
What it means:
- New accounts often need time for mailbox indexing.

What to do next:
1. Wait and try again later today or next working day.
2. Confirm you are signed in with your work account.
3. If still empty, log a ticket with your start date and example email subject.

### Issue 3: "Copilot showed me a settlement draft I wasn't expecting"
What it means:
- You likely have real access to that workspace, even if you did not realize it.

What to do next:
1. Report this immediately to your manager or data owner.
2. Ask for an access review and removal of unnecessary permissions.
3. Continue using only matter-relevant workspaces while cleanup is done.

### Issue 4: "Our whole Legal team lost Copilot today"
What it means:
- This is likely a tenant-level setup, license, or service issue.

What to do next:
1. Raise a priority incident with IT Service Desk now.
2. Include team size affected, first time noticed, and screenshots.
3. Use normal manual workflows until service is restored.

### Issue 5: "Copilot gives generic answers on contract templates"
What it means:
- Copilot may not be reaching the expected template content for that prompt.

What to do next:
1. Ask Copilot about one specific template you can open.
2. Add context in your prompt (template name, clause type, output format).
3. If still generic, send IT one sample prompt and one template link for triage.

---

## 3) What to include when raising support
- App and platform (Outlook/Word/Excel/Teams; desktop or web)
- Exact Copilot error message
- File, mailbox, or workspace link (where possible)
- Time issue started and how many users are affected
- Screenshot, if permitted by policy
