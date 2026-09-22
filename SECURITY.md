# Security Policy

## Supported Versions

Only the latest minor release of `carrier_info_plus` receives security fixes.

| Version  | Supported          |
| -------- | ------------------ |
| 1.1.x    | :white_check_mark: |
| < 1.1    | :x:                |

## Reporting a Vulnerability

`carrier_info_plus` reads carrier, SIM and network identifiers from the device
and hands them to the calling app. It performs no network calls and stores
nothing, but it does touch data that is personal under most privacy regimes —
so if you believe you've found a way to read more than the declared permissions
should allow, or a way to leak a value the package is supposed to withhold,
please **do not open a public issue**.

Report it privately via GitHub Security Advisories:

➡️ [Report a vulnerability](https://github.com/moulibheemaneti/carrier_info_plus/security/advisories/new)

You can expect:
- An acknowledgement within **7-14 days**.
- A status update within **30-45 days**.
- If accepted, a fix will land in the next patch release and you'll be credited in the release notes (unless you prefer to remain anonymous).
- If declined, you'll receive an explanation of why.
