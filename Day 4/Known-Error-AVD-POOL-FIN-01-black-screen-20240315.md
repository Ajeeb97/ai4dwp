Symptom: Users in the Finance AVD pool see a black screen immediately after sign-in. For some users it clears after about 30 seconds; for others the session disconnects and may loop through reconnect attempts.

Cause: The verified root cause is an overnight image update applied to POOL-FIN-01 that introduced post-logon display instability. On affected hosts, Desktop Window Manager (dwm.exe) crashes in igdumd64.dll.

Scope: The incident affected approximately 40% of users in POOL-FIN-01 (Finance desktop pool). POOL-FIN-02 (IT desktop pool), which was not included in the update wave, was unaffected.

Workaround: Pause rollout of the same image and set impacted POOL-FIN-01 hosts to drain mode to stop new user placement on unstable hosts. Keep known-good hosts available so users can continue signing in while remediation is performed.

Permanent fix: Apply the approved remediation path for the affected display stack/image baseline on impacted POOL-FIN-01 hosts, then reboot the remediated hosts. Validate stable sign-in and no recurring crash signature before returning hosts to rotation.

How to spot it: Look for the repeated pattern on affected hosts: Event 21 (session logon succeeded), then Application Error Event 1000 for dwm.exe faulting module igdumd64.dll (exception 0xc0000005), followed by Event 40 (session disconnected) and DWM Event 9009. In the unaffected comparison pool, DWM Event 9011 appears with no matching Event 1000 in the same window.
