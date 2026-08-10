# User Logon Incident Communications Pack

Date: 2026-08-10
Source of truth: incident analysis and RCA for FINBRIDGE\cthompson logon incident (resolved at 09:09 on 2024-03-15).

## Audience 1 - Non-technical Executive
Access is restored and data are safe. One user, cthompson, could not sign in from about 08:40 because repeated wrong password attempts locked the account and another saved sign-in source kept using old details. Support corrected the account, and sign-in on DESKTOP-FB022 was verified at 09:09 with no further issues reported. No action is needed.

## Audience 2 - Affected End-User Team (10 people, non-technical)
Hi team, access is restored and data are safe. One user, cthompson, could not sign in from about 08:40 because repeated wrong password attempts locked the account and another saved sign-in source kept using old details. Support corrected the account, and sign-in on DESKTOP-FB022 was verified at 09:09 with no further issues reported. If you see the same issue, contact the Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note
Incident: access restored and data safe. One user, FINBRIDGE\cthompson, was unable to log in on DESKTOP-FB022 from approximately 08:40 on 2024-03-15. Resolved at 09:09 with no further issues reported.

Root cause:
- Repeated wrong-password submissions caused account lockout for FINBRIDGE\cthompson, and another saved sign-in source kept using old details.
- Direct evidence: Event 4776 at 08:44:01 with 0xC000006A on DESKTOP-FB022, followed by Event 4625 at 08:44:03, 08:44:28, and 08:44:55, then Event 4740 at 08:44:56, then Event 4625 at 08:45:10 showing lockout denial.
- Contributing factor: additional wrong-password Kerberos pre-auth failures from 10.10.8.112 at 08:45:44, 08:46:01, and 08:46:33, indicating stale stored credentials or a secondary session/device using outdated credentials.

Exact action taken:
- Helpdesk recovery action applied to correct the account.
- Event 4722 at 09:08:14 recorded the account being enabled by FINBRIDGE\helpdesk-admin.
- User retried interactive sign-in on DESKTOP-FB022.

Config/detail context:
- Affected user: FINBRIDGE\cthompson.
- Affected host: DESKTOP-FB022.
- Secondary source observed: 10.10.8.112.
- Scope: single-user impact only.

Verification step:
- Event 4624 at 09:09:01 confirmed successful interactive logon for FINBRIDGE\cthompson on DESKTOP-FB022.
- User login to host was verified.
- No further issues were reported after resolution.

Preventive action needed:
- Trace and remediate the source at 10.10.8.112.
- Clear any stale saved credentials on DESKTOP-FB022 and any secondary device, service, session, or app using old credentials.
- Monitor for renewed Event 4776, 4771, 4625, or 4740 activity for the account after remediation.
- Use the lockout triage checklist on recurrence to identify all credential sources before closure.
