# Root Cause Analysis - User Logon Incident
## RCA-2024-0315-LOGON001 | cthompson | FinBridge

---

## 1. Incident Summary

| Field | Detail |
|-------|--------|
| Incident ID | RCA-2024-0315-LOGON001 |
| Logged symptom window | 2024-03-15 from approximately 08:40 |
| Resolved | 2024-03-15 09:09 |
| Service | User authentication / workstation logon |
| Affected user | FINBRIDGE\cthompson |
| Affected host | DESKTOP-FB022 |
| Additional source observed | 10.10.8.112 |
| User impact | Single user |
| Primary symptom | User unable to log in |
| Severity | Medium (single-user access failure) |

Outcome at closure:
- Resolution actions were applied before 09:09.
- At 09:09:01, successful interactive logon for FINBRIDGE\cthompson was recorded on DESKTOP-FB022.
- User login to host was verified and no further issues were reported.

---

## 2. Scope and Analytical Constraints

1. Primary weighting signal:
- Only one user, FINBRIDGE\cthompson, was affected.

2. Secondary weighting signal:
- Issue began around 08:40 with no declared environmental change.

3. Tertiary weighting signal:
- Authentication logs provided explicit failure reasons, allowing evidence-led elimination of alternative hypotheses.

---

## 3. Supporting Evidence

### 3.1 Initial Failure Sequence on DESKTOP-FB022

- 08:44:01, Security Event 4776, Audit Failure:
  - Domain controller attempted to validate credentials for FINBRIDGE\cthompson.
  - Error code: 0xC000006A.
  - Meaning: wrong password.
  - Source workstation: DESKTOP-FB022.

- 08:44:03, Security Event 4625, Audit Failure:
  - Account: FINBRIDGE\cthompson.
  - Failure reason: unknown user name or bad password.
  - Logon type: 2 (Interactive).
  - Source: DESKTOP-FB022.

- 08:44:28, Security Event 4625, Audit Failure:
  - Account: FINBRIDGE\cthompson.
  - Failure reason: unknown user name or bad password.
  - Logon type: 2 (Interactive).
  - Source: DESKTOP-FB022.

- 08:44:55, Security Event 4625, Audit Failure:
  - Account: FINBRIDGE\cthompson.
  - Failure reason: unknown user name or bad password.
  - Logon type: 2 (Interactive).
  - Source: DESKTOP-FB022.

Interpretation:
- The account experienced repeated wrong-password submissions from the affected workstation during interactive logon attempts.

### 3.2 Lockout Confirmation

- 08:44:56, Security Event 4740, Audit Failure:
  - A user account was locked out.
  - Account: FINBRIDGE\cthompson.
  - Caller computer: DESKTOP-FB022.

- 08:45:10, Security Event 4625, Audit Failure:
  - Account: FINBRIDGE\cthompson.
  - Failure reason: account locked out.
  - Logon type: 7 (Unlock attempt).
  - Source: DESKTOP-FB022.

Interpretation:
- The immediate cause of the user-facing login failure became account lockout after multiple bad-password attempts.

### 3.3 Additional Wrong-Password Activity from Secondary Source

- 08:45:44, Security Event 4771, Audit Failure:
  - Kerberos pre-authentication failed for FINBRIDGE\cthompson.
  - Failure code: 0x18.
  - Meaning: wrong password.
  - Source IP: 10.10.8.112.

- 08:46:01, Security Event 4771, Audit Failure:
  - Kerberos pre-authentication failed for FINBRIDGE\cthompson.
  - Failure code: 0x18.
  - Source IP: 10.10.8.112.

- 08:46:33, Security Event 4771, Audit Failure:
  - Kerberos pre-authentication failed for FINBRIDGE\cthompson.
  - Failure code: 0x18.
  - Source IP: 10.10.8.112.

Interpretation:
- A second source continued submitting wrong credentials after the initial lockout event, indicating a likely stale cached credential, service, session, or secondary device using an old password.

### 3.4 Resolution and Recovery Evidence

- 09:08:14, Security Event 4722, Audit Success:
  - A user account was enabled.
  - Account: FINBRIDGE\cthompson.
  - Done by: FINBRIDGE\helpdesk-admin.

- 09:09:01, Security Event 4624, Audit Success:
  - An account was successfully logged on.
  - Account: FINBRIDGE\cthompson.
  - Logon type: 2 (Interactive).
  - Source: DESKTOP-FB022.

Operational confirmation:
- Resolution was confirmed at 09:09.
- User login to host was verified.
- No ongoing issues were reported after the successful logon.

Interpretation:
- Administrative recovery action restored account usability, and the user successfully completed an interactive sign-in on the affected workstation.

---

## 4. Timeline

| Time | Event | Evidence |
|------|-------|----------|
| ~08:40 | User first unable to log in | Scope fact / incident report |
| 08:44:01 | Wrong password validated against domain credentials | Security Event 4776 on DESKTOP-FB022 |
| 08:44:03 | First interactive bad-password failure | Security Event 4625 on DESKTOP-FB022 |
| 08:44:28 | Second interactive bad-password failure | Security Event 4625 on DESKTOP-FB022 |
| 08:44:55 | Third interactive bad-password failure | Security Event 4625 on DESKTOP-FB022 |
| 08:44:56 | Account locked out | Security Event 4740, caller computer DESKTOP-FB022 |
| 08:45:10 | Unlock attempt blocked by lockout state | Security Event 4625, lockout reason |
| 08:45:44 | Additional wrong-password Kerberos failure from second source | Security Event 4771 from 10.10.8.112 |
| 08:46:01 | Repeated wrong-password Kerberos failure from second source | Security Event 4771 from 10.10.8.112 |
| 08:46:33 | Repeated wrong-password Kerberos failure from second source | Security Event 4771 from 10.10.8.112 |
| 09:08:14 | Administrative account recovery action recorded | Security Event 4722 by FINBRIDGE\helpdesk-admin |
| 09:09:01 | Successful interactive logon on affected workstation | Security Event 4624 on DESKTOP-FB022 |
| 09:09 | Incident resolved and user verified working | Operations verification |

---

## 5. Hypothesis Elimination Summary

Initial hypotheses were tested against the supplied event evidence.

1. Incorrect password entry or account lockout
- Status: Supported and confirmed.
- Basis: explicit wrong-password indicators in Event 4776 and Event 4771, followed by Event 4740 lockout and successful recovery after admin action.

2. Account state issue (disabled/expired/restricted sign-in)
- Status: Contradicted.
- Basis: evidence shows bad-password and lockout progression rather than expiry or restriction signals.

3. MFA or Conditional Access challenge failure
- Status: Contradicted.
- Basis: supplied evidence is Windows authentication failure telemetry with no MFA or CA block evidence.

4. Endpoint-side credential/session issue on cthompson device
- Status: Partially supported as a contributing path, not the final root cause.
- Basis: DESKTOP-FB022 originated the initial failed interactive attempts, but a second source IP also submitted wrong credentials.

5. Isolated identity service path/transient affecting only this account context
- Status: Contradicted.
- Basis: failure codes are explicit and consistent, not transient or ambiguous service-side errors.

---

## 6. Confirmed Root Cause

Root cause:
- FINBRIDGE\cthompson was unable to log in because repeated wrong-password submissions caused the account to become locked out.

Direct technical evidence:
- Event 4776 at 08:44:01 recorded wrong-password credential validation failure.
- Event 4625 at 08:44:03, 08:44:28, and 08:44:55 recorded repeated interactive bad-password failures.
- Event 4740 at 08:44:56 recorded the account lockout.
- Event 4625 at 08:45:10 recorded continued denial because the account was locked out.
- Event 4624 at 09:09:01 confirmed the account could log in successfully after the recovery action.

Contributing factors:
- DESKTOP-FB022 was the source of the initial failed interactive attempts.
- A second source, 10.10.8.112, continued generating wrong-password Kerberos pre-authentication failures, indicating stale stored credentials or an additional session/device using an outdated password.

What is confirmed versus inferred:
- Confirmed: wrong password caused lockout and prevented login.
- Strongly inferred: at least one additional source retained stale credentials and continued replaying the wrong password after the initial lockout.

---

## 7. Resolution Implemented

### 7.1 Recovery Actions

- The account state was reviewed and administrative action was taken by FINBRIDGE\helpdesk-admin.
- Event 4722 at 09:08:14 recorded the account being enabled as part of recovery.
- The user's credential state was corrected through the applied service-desk process.

### 7.2 Validation Actions

- The user retried interactive sign-in on DESKTOP-FB022.
- Event 4624 at 09:09:01 confirmed successful interactive logon for FINBRIDGE\cthompson.
- User access to host was verified.
- No further issues were reported after successful logon.

### 7.3 Resolution Confirmation

- Incident marked resolved at 09:09.
- Login was verified on the affected host.
- No post-resolution symptom recurrence was reported in the provided scope.

---

## 8. Five Why Analysis

Problem statement:
- FINBRIDGE\cthompson could not log in to DESKTOP-FB022.

Why 1:
- Why could the user not log in?
- Because the account was locked out at the time of sign-in.

Evidence:
- Security Event 4740 at 08:44:56 and Security Event 4625 at 08:45:10.

Why 2:
- Why was the account locked out?
- Because multiple wrong-password attempts were submitted in a short period.

Evidence:
- Security Event 4776 at 08:44:01 and Security Event 4625 at 08:44:03, 08:44:28, and 08:44:55.

Why 3:
- Why were multiple wrong-password attempts being submitted?
- Because at least one interactive logon path and likely one additional Kerberos source were using incorrect credentials for the same user.

Evidence:
- Interactive failures from DESKTOP-FB022 and Kerberos pre-authentication failures from 10.10.8.112 at 08:45:44, 08:46:01, and 08:46:33.

Why 4:
- Why were incorrect credentials still being used by more than one source?
- Because stale cached or stored credentials were likely present on one or more devices, sessions, or services after a password mismatch or prior password change.

Evidence:
- Repeated wrong-password failures continued from a second source after the initial workstation-driven lockout sequence.

Why 5:
- Why did stale or incorrect credentials persist long enough to cause user impact?
- Because there was no preventive control in place to identify and clear bad stored credentials before repeated authentication failures reached the account lockout threshold.

Evidence:
- The account reached lockout before intervention, and additional wrong-password attempts continued afterward from another source.

Underlying process root cause:
- Credential hygiene and lockout-prevention controls were insufficient to detect and suppress repeated bad-password submissions from stored or replayed credentials before user-facing lockout occurred.

---

## 9. Preventive and Corrective Actions (CAPA)

### 9.1 Immediate Preventive Controls

1. Identify and remediate the asset at 10.10.8.112.
- Determine whether it is a workstation, mobile device, service, scheduled task, or persistent session.
- Remove or update any stored credentials for FINBRIDGE\cthompson.

2. Clear cached credentials on DESKTOP-FB022.
- Review Credential Manager, mapped drives, VPN clients, Outlook profiles, browser-stored auth prompts, and scheduled tasks.

3. Verify no residual lockout loop exists.
- Monitor for renewed Event 4776, 4771, 4625, or 4740 activity for the account after remediation.

### 9.2 Structural Corrective Actions

4. Add a standard lockout triage checklist.
- Require review of all recent bad-password source hosts and IPs before closure.

5. Improve stale credential detection.
- Where tooling allows, alert when the same user account generates repeated wrong-password failures from multiple sources in a short time window.

6. Update service-desk recovery procedure.
- Include validation that secondary devices, services, and background sessions are checked after unlocking or resetting user credentials.

7. Review password-change communication and user guidance.
- Ensure users know to update saved credentials on mobile devices, line-of-business apps, and persistent mapped resources after password changes.

### 9.3 Monitoring and Reporting

8. Add reporting on repeated account lockouts.
- Trend lockout events by user, source workstation, and source IP to identify recurring stale-credential patterns.

9. Escalate repeated multi-source failures to problem management.
- If the same pattern recurs, investigate systemic causes such as misconfigured services, sync agents, or enterprise applications retaining expired credentials.

---

## 10. Lessons Learned

- Explicit authentication failure codes are strong discriminators and should be weighted early in user logon triage.
- Single-user impact with Event 4776, 4625, and 4740 in sequence is highly indicative of credential-driven lockout rather than platform outage.
- A successful recovery action is not enough on its own; secondary sources of stale credentials must be identified to prevent immediate relock.

---

## 11. Closure Statement

The incident was resolved at 09:09 on 2024-03-15 after the account recovery action was applied. Supporting evidence shows the user was blocked by account lockout following repeated wrong-password submissions. Successful interactive logon was verified on DESKTOP-FB022, and no further issues were reported in the validated period.
