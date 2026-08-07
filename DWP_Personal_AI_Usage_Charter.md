# Personal AI Usage Charter — DWP Desktop/Endpoint Engineer
**Version:** 1.0 | **Date:** 2026-08-07 | **Owner:** [Your Name / Staff ID]

---

## 1. Appropriate Uses of Public AI Assistants

I may use public LLMs (e.g. GitHub Copilot, ChatGPT) for the following **with no DWP data included in the prompt**:

- Drafting or explaining PowerShell, Python, or batch scripts using **fictional/sanitised examples**
- Understanding Windows 11, Intune, SCCM, or Active Directory concepts and syntax
- Generating regex patterns, GPO logic, or registry key explanations
- Converting technical notes into plain-English user communications (using dummy names/IDs)
- Researching error codes, event log IDs, or Microsoft documentation equivalents
- Structuring triage notes, runbooks, or internal how-to guides in template form
- Preparing training material or process documentation drafts

---

## 2. Tasks I Will NOT Use Public AI For

- Any prompt containing **real usernames, staff IDs, email addresses, or device hostnames**
- Any prompt containing **actual case reference numbers, incident IDs, or ticket content**
- Uploading or pasting **Active Directory exports, device inventories, or group membership lists**
- Anything involving **credentials, certificates, API keys, or authentication tokens**
- Troubleshooting live production issues where prompt text would include **real system state or logs with PII**
- Policy interpretation where the output could be mistaken for **official DWP guidance**
- Any task explicitly marked as **OFFICIAL-SENSITIVE or above** under DWP data classification

---

## 3. Data Handling Rule — PII and Credentials

> **Before submitting any prompt: STOP and ask — "Does this contain real names, IDs, device details, or secrets?"**

- **Anonymise first:** Replace real values with placeholders — e.g. `USER001`, `DEVICE-TEST01`, `<password_redacted>`
- **Never paste** password reset outputs, MFA seeds, BitLocker keys, or certificate thumbprints into any public tool
- **Treat AI chat history as insecure:** Assume all input to a public LLM is potentially stored and retrievable
- If in doubt, use only **DWP-approved internal tooling** (confirm current approved list with line manager)

---

## 4. Personal 'Generate Then Verify' Rule — Scripts and System Changes

When AI generates a script or recommends a system change, I will follow this sequence **every time, without exception:**

| Step | Action |
|------|--------|
| **1. Read** | Read the full output before running anything — understand what each line does |
| **2. Check scope** | Confirm the script targets only the intended device(s), user(s), or registry path(s) |
| **3. Test environment first** | Run in a test VM or non-production device before any live endpoint |
| **4. Verify the source logic** | Cross-check key commands against Microsoft Docs, not just the AI output |
| **5. Log the change** | Record what was run, where, and when — even for informal fixes |
| **6. Review output** | Check actual results match expected results; roll back if behaviour is unexpected |

AI-generated scripts are a **starting point, not a finished product.** I am accountable for everything I execute on DWP systems.

---

## Acknowledgement

By using this charter I commit to reviewing and updating it if DWP AI policy changes, if I change role, or at least every **6 months**.

**Signed:** _______________________  **Date:** _______________
