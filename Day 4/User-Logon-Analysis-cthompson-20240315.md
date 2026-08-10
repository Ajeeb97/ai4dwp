# User Logon Incident Analysis and Hypothesis - cthompson

Date saved: 2026-08-10
Analyst context: Scope-facts-only differential analysis; no single root cause committed.

## Scope Facts
- Symptom: User cthompson not able to login.
- Who: cthompson only (single-user impact).
- Since: About 08:40 this morning.
- Change: Nil.

## Ranked Most Likely Causes (Most Probable First)

### 1) Incorrect password entry or account lockout
Why this fits the scope facts:
- Single-user login failures most commonly come from user-credential issues rather than platform-wide faults.
- No reported environment change supports a local/authentication path issue first.

Single fastest check:
- Check latest authentication events for cthompson (failed reason and lockout state) and verify whether the account is currently locked.

### 2) Account state issue (disabled/expired/restricted sign-in)
Why this fits the scope facts:
- A user-specific account status problem would affect only cthompson.
- Sudden onset this morning can occur when account status transitions are enforced at sign-in.

Single fastest check:
- Inspect directory account properties for cthompson (enabled state, expiry, sign-in restrictions) and compare with a known-working user.

### 3) MFA or Conditional Access challenge failure for this user
Why this fits the scope facts:
- CA/MFA failures can be isolated to one user if their registration/session/compliance context differs.
- No broad impact reported, which keeps this as a plausible user-specific control failure.

Single fastest check:
- Review cthompson sign-in logs for policy result and MFA outcome on the failed attempts.

### 4) Endpoint-side credential/session issue on cthompson device
Why this fits the scope facts:
- Single-user impact with no change can come from stale cached credentials, token/session corruption, or local client state on one device.
- The issue start time could align with first login attempt after device wake/reconnect.

Single fastest check:
- Attempt sign-in for cthompson from a second known-good device/path; if successful there, isolate issue to the original endpoint/session state.

### 5) Isolated identity service path/transient affecting only this account context
Why this fits the scope facts:
- Lower probability, but possible when one account hits a transient backend condition while others are unaffected.
- No declared change means a transient service-side anomaly remains a residual hypothesis.

Single fastest check:
- Correlate timestamped failed attempts for cthompson with identity service health and retry after a short interval to confirm transient behavior.

## Notes
- This ranking intentionally avoids anchoring and does not assert final cause.
- Ranking is based only on the stated scope facts: single-user impact, start time around 08:40, and no declared change.
- Next step is evidence-led elimination using authentication logs, account state, and cross-device sign-in validation.

## Evidence Assessment Against Each Hypothesis

Evidence set reviewed:
- Security log on DESKTOP-FB022 from 08:44 to 09:12.
- Repeated wrong-password failures for FINBRIDGE\cthompson.
- Lockout recorded at 08:44:56.
- Additional Kerberos pre-authentication failures from a second source IP, 10.10.8.112.

### 1) Incorrect password entry or account lockout
Judgement:
- Supported.

Why:
- Event 4776 at 08:44:01 shows credential validation failed with error code 0xC000006A, which is wrong password.
- Event 4625 at 08:44:03, 08:44:28, and 08:44:55 records bad-password interactive logon failures from DESKTOP-FB022.
- Event 4740 at 08:44:56 confirms the account was locked out.
- Event 4625 at 08:45:10 then shows a follow-on failure because the account was locked out, which is consistent with the prior sequence.

Determining evidence:
- 4776 at 08:44:01
- 4625 at 08:44:03, 08:44:28, 08:44:55
- 4740 at 08:44:56
- 4625 at 08:45:10

### 2) Account state issue (disabled/expired/restricted sign-in)
Judgement:
- Contradicted.

Why:
- The observed failures are explicitly wrong-password and lockout events, not disabled-account, expired-account, or sign-in-restriction failures.
- Event 4776 at 08:44:01 points to bad credentials rather than an account status control.
- Event 4740 at 08:44:56 shows the account became locked due to failed attempts, which explains the later denial more directly than a pre-existing disabled or expired state.

Determining evidence:
- 4776 at 08:44:01
- 4740 at 08:44:56
- 4625 at 08:45:10

### 3) MFA or Conditional Access challenge failure for this user
Judgement:
- Contradicted.

Why:
- The evidence sits in Windows Security log authentication failure events tied to wrong password and lockout conditions.
- No supplied event indicates MFA denial, Conditional Access block, or token challenge failure.
- Event 4771 at 08:45:44, 08:46:01, and 08:46:33 is still wrong-password Kerberos pre-authentication failure, not an MFA or CA signal.

Determining evidence:
- 4776 at 08:44:01
- 4771 at 08:45:44, 08:46:01, 08:46:33

### 4) Endpoint-side credential/session issue on cthompson device
Judgement:
- Supported.

Why:
- DESKTOP-FB022 is directly tied to the bad-password and lockout sequence via Event 4776, repeated 4625 failures, and Event 4740 caller computer field.
- That said, the second source IP 10.10.8.112 also generates wrong-password Kerberos failures after the lockout window, so the evidence does not isolate the issue exclusively to DESKTOP-FB022.
- The evidence supports endpoint-side involvement, but not yet a single-endpoint-only conclusion.

Determining evidence:
- 4776 at 08:44:01 from DESKTOP-FB022
- 4625 at 08:44:03, 08:44:28, 08:44:55 from DESKTOP-FB022
- 4740 at 08:44:56 caller computer DESKTOP-FB022
- 4771 at 08:45:44, 08:46:01, 08:46:33 from 10.10.8.112

### 5) Isolated identity service path/transient affecting only this account context
Judgement:
- Contradicted.

Why:
- The failures are specific, repeatable, and semantically consistent: wrong password followed by lockout.
- There is no sign here of a transient service-side fault, timeout, or ambiguous backend rejection.
- Event 4776 at 08:44:01 and Event 4771 at 08:45:44 onward both return explicit wrong-password indicators, which points away from a generic identity service transient.

Determining evidence:
- 4776 at 08:44:01
- 4771 at 08:45:44, 08:46:01, 08:46:33

## Evidence Handling Note
- This section scores each hypothesis against the supplied evidence only.
- It does not select a final winner, even where one hypothesis is strongly supported relative to the others.

## Surviving Hypothesis

Confirmed best-fit hypothesis:
- Incorrect password entry leading to account lockout.

Why this is the surviving hypothesis:
- It is the only hypothesis directly and repeatedly evidenced by explicit authentication failure codes.
- Event 4776 at 08:44:01 shows wrong password during credential validation.
- Event 4625 at 08:44:03, 08:44:28, and 08:44:55 shows repeated bad-password logon failures.
- Event 4740 at 08:44:56 confirms those failures progressed into account lockout.
- Event 4625 at 08:45:10 then shows the account remained unusable because it was locked out.
- The endpoint-side hypothesis remains a possible contributing path for where the bad credentials were being submitted, but it does not outperform the credential-and-lockout hypothesis as the direct cause of the login failure symptom.

## Resolution Steps

1. Confirm the account lockout state in AD or the relevant identity platform for FINBRIDGE\cthompson.
2. Unlock the account using the standard service-desk or identity-admin process.
3. Verify the user knows the current correct password; if there is any doubt, perform a password reset and communicate the temporary or updated credential through the approved channel.
4. Ask the user to sign in once interactively on DESKTOP-FB022 using the confirmed password.
5. If login succeeds, immediately check for any saved or stale credentials on the workstation and remove them from Credential Manager, mapped drives, cached application prompts, VPN clients, Outlook profiles, mobile mail clients, and scheduled tasks that may still be replaying the old password.
6. Investigate the secondary source shown in Event 4771 from IP 10.10.8.112 and identify what service, device, or session is still attempting Kerberos pre-authentication with the wrong password.
7. Stop or update the process on 10.10.8.112 that is using stale credentials; otherwise the account may relock after being unlocked.
8. Recheck authentication logs for 10 to 15 minutes after remediation to confirm there are no further 4776, 4625, 4740, or 4771 failures for cthompson.
9. Ask the user to perform a final sign-in test and confirm normal access is restored.
10. Record the incident closure note as user lockout caused by repeated bad password submissions, with stale credentials on one or more sources reviewed and cleared as required.

## Validation After Resolution

- Success condition 1: no new Event 4740 lockouts for FINBRIDGE\cthompson.
- Success condition 2: no new Event 4776 or 4771 wrong-password failures after credential cleanup.
- Success condition 3: successful user logon from the intended workstation.

## Addendum - Event Details, Surviving Hypothesis, and Resolution

Date appended: 2026-08-10
Purpose: Preserve the supplied event evidence and final elimination outcome as an appended update without altering the earlier analysis record.

### Event Details Reviewed

Security Event Log source:
- Host: DESKTOP-FB022
- Incident window reviewed: 2024-03-15 08:44 to 09:12

Observed events:
- 08:44:01, Security Event 4776, Audit Failure
	- Domain credential validation attempted for FINBRIDGE\cthompson
	- Error code: 0xC000006A
	- Interpretation: wrong password
	- Source workstation: DESKTOP-FB022
- 08:44:03, Security Event 4625, Audit Failure
	- Account: FINBRIDGE\cthompson
	- Failure reason: unknown user name or bad password
	- Logon type: 2 (interactive)
	- Source: DESKTOP-FB022
- 08:44:28, Security Event 4625, Audit Failure
	- Account: FINBRIDGE\cthompson
	- Failure reason: unknown user name or bad password
	- Logon type: 2 (interactive)
	- Source: DESKTOP-FB022
- 08:44:55, Security Event 4625, Audit Failure
	- Account: FINBRIDGE\cthompson
	- Failure reason: unknown user name or bad password
	- Logon type: 2 (interactive)
	- Source: DESKTOP-FB022
- 08:44:56, Security Event 4740, Audit Failure
	- Account: FINBRIDGE\cthompson
	- Account locked out
	- Caller computer: DESKTOP-FB022
- 08:45:10, Security Event 4625, Audit Failure
	- Account: FINBRIDGE\cthompson
	- Failure reason: account locked out
	- Logon type: 7 (unlock attempt)
	- Source: DESKTOP-FB022
- 08:45:44, Security Event 4771, Audit Failure
	- Kerberos pre-authentication failed for FINBRIDGE\cthompson
	- Failure code: 0x18
	- Interpretation: wrong password
	- Source IP: 10.10.8.112
- 08:46:01, Security Event 4771, Audit Failure
	- Kerberos pre-authentication failed for FINBRIDGE\cthompson
	- Failure code: 0x18
	- Source IP: 10.10.8.112
- 08:46:33, Security Event 4771, Audit Failure
	- Kerberos pre-authentication failed for FINBRIDGE\cthompson
	- Failure code: 0x18
	- Source IP: 10.10.8.112

### Surviving Hypothesis

- Incorrect password entry leading to account lockout.

Why it survived the elimination:
- The evidence explicitly shows wrong-password failures first and lockout second.
- The decisive sequence is Event 4776 at 08:44:01, repeated Event 4625 failures at 08:44:03, 08:44:28, and 08:44:55, then Event 4740 at 08:44:56, followed by locked-out failure Event 4625 at 08:45:10.
- Event 4771 at 08:45:44, 08:46:01, and 08:46:33 shows continued wrong-password submissions from a second source after the initial lockout sequence.

### Resolution Summary

1. Confirmed the account status and clear the lockout for FINBRIDGE\cthompson.
2. Verified the correct password with the user, or reset it if confidence in the current password is low.
3. Retested interactive sign-in on DESKTOP-FB022 using the confirmed credential.
4. Removed stale saved credentials from DESKTOP-FB022 if present.
5. Traced the secondary source at 10.10.8.112 and updated or stopped any service, session, or device using the old password.
6. Monitored follow-on authentication events to confirm the account did not relock and that no further wrong-password submissions occurred.
7. Completed a final user login validation and recorded the incident as a credential lockout caused by repeated bad password submissions.
