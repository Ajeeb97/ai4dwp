# Known Error Record - User Logon Lockout

Symptom: FINBRIDGE\cthompson is unable to log in on DESKTOP-FB022. The failed sign-in window began at approximately 08:40 on 2024-03-15.

Cause: The verified root cause is repeated wrong-password submissions that caused the FINBRIDGE\cthompson account to become locked out. The RCA confirms this with Event 4776, repeated Event 4625 failures, and Event 4740 lockout evidence.

Scope: The verified impact was limited to a single user, FINBRIDGE\cthompson. The affected host was DESKTOP-FB022, within the user authentication and workstation logon service scope.

Workaround: Apply the helpdesk account recovery process to correct the account state, then have the user retry interactive sign-in on DESKTOP-FB022. In the verified incident, this restored access by 09:09.

Permanent fix: Trace and remediate the secondary source at 10.10.8.112, and clear stale saved credentials on DESKTOP-FB022 and any linked device or session using old credentials. Monitor afterward for renewed Event 4776, 4771, 4625, or 4740 activity for the account.

How to spot it: Look for Event 4776 with error code 0xC000006A, repeated Event 4625 entries with "unknown user name or bad password," and Event 4740 showing the account lockout for FINBRIDGE\cthompson on DESKTOP-FB022. Additional signals in this incident were Event 4625 with "account locked out," Event 4771 with failure code 0x18 from 10.10.8.112, and Event 4624 confirming successful recovery sign-in at 09:09:01.
