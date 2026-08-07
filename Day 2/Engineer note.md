Engineer note:
Root cause:
- Win11 upgrade removed legacy VPN client.
- Intune did not trigger re-deployment of new VPN client due to detection-rule gap.

Exact action taken:
- Manually removed stale VPN registry entries under HKLM\SOFTWARE\<vendor>.
- Force-triggered Intune sync.
- New VPN client deployed.
- Split-tunnel config applied.

Config detail:
- Registry cleanup path: HKLM\SOFTWARE\<vendor> (stale legacy VPN entries removed).
- Post-deploy configuration: split-tunnel enabled/applied on the new client.

Verification:
- Connectivity confirmed to all internal subnets.
- No data loss.

Preventive action needed:
- Close the Intune detection-rule gap so Win11 upgrade scenarios trigger automatic new-client re-deployment.