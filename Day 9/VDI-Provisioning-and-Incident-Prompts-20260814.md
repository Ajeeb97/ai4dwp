# VDI Provisioning and Incident Prompts

## Version Header
- Date: 2026-08-14
- Author: DWP Engineering
- Audience: VDI support and engineering teams
- Goal: Document provisioning work and scope Citrix VDI launch incidents from logs

---

## RDP Web Client

Use the approved web client to access the remote desktop environment:

https://client.wvd.microsoft.com/arm/webclient

---

## Provisioning Documentation Prompt

Use this prompt after completing provisioning work. Attach or provide the steps, command output, configuration changes, and any scripts created during the work.

```text
Create an operational provisioning document based only on the steps followed and the scripts created during this activity.

Include these sections:
- Version Header
- Purpose
- Prerequisites
- Procedure
- Scripts and configuration changes
- Verification
- Rollback
- Notes and known limitations

For each procedure step, state the action taken, the expected result, and any command or script used. Do not invent details that are not present in the supplied evidence; mark missing information as "to confirm".

Place the completed document and any scripts created during this activity in the Day 9 folder. If a supplied script currently exists elsewhere in the workspace, move it into the Day 9 folder and update its documented path.

Return the provisioning document in Markdown.
```

---

## Citrix VDI Scope-Analysis Prompt

Paste the relevant broker, machine catalog, and Delivery Controller logs after this prompt.

```text
You are a DWP analyst investigating a VDI session launch failure. From the logs below, extract:
  - Which pool is affected, and how many users?
  - What is the exact broker error?
  - What does the machine catalog registration status show, for both the affected and unaffected pool?
  - What does the Delivery Controller health check show, for both controllers?

Return only scope facts. Do not conclude a root cause yet.
```