# Triage Summary — Issue 02

## Summary (one line)
User cannot connect to VDI today; connection attempt shows "cannot connect," and it worked on Friday.

## Impact (who/how many/ business urgency)
- Who: One end user (to confirm)
- How many: 1 reported affected user (to confirm)
- Business urgency: To confirm (user currently unable to access VDI)

## known facts
- User reports they "can't get on the VDI" today.
- Error shown is "cannot connect" (exact wording to confirm).
- VDI access was working on Friday.
- User is working from home on Wi-Fi.

## Missing information to gather
- Exact error message text and any error code/screenshot.
- Whether VPN is connected (if required for this VDI path) (to confirm).
- Whether issue occurs on all VDI pools/desktop options or one specific target.
- Whether other remote users are reporting the same issue (to confirm).
- User location details and whether home internet is otherwise stable.
- Device details (managed laptop/hostname) and recent restart status.
- Time issue started and whether any local changes occurred since Friday.

## likely catagory
- VDI connectivity/authentication incident (to confirm)
- Possible network path issue from home connection (to confirm)

## Suggest first diagnostic step
Capture the exact VDI error (text/code) and immediately verify basic connectivity from the user device (internet + required VPN connected if applicable), then retry one fresh VDI login attempt.