# carrier_info_plus

**Cellular carrier, SIM and network information for Flutter.**

[![pub version](https://img.shields.io/pub/v/carrier_info_plus.svg?style=flat-square&color=0175C2&labelColor=1a1a2e)](https://pub.dev/packages/carrier_info_plus)
[![license](https://img.shields.io/badge/license-MIT-0175C2?style=flat-square&labelColor=1a1a2e)](LICENSE)

> [!NOTE]
> The next major version is a ground-up rewrite and is still in progress. This
> README is deliberately minimal and will grow as the API lands. For the
> currently published API, see the
> [1.1.0 docs on pub.dev](https://pub.dev/documentation/carrier_info_plus/1.1.0/).

## Installation

```sh
flutter pub add carrier_info_plus
```

## Platforms

| Platform | Supported |
| -------- | :-------: |
| Android  |     ✅     |
| iOS      |     ✅     |

What each platform can actually report differs a great deal — Apple removed
`CTCarrier` in iOS 16, so carrier identity is unavailable there for every app.
The platform-by-platform table will be documented here as the rewrite lands.

## Contributing

Contributions are welcome. Please read:

- [CONTRIBUTING.md](CONTRIBUTING.md) — development setup, commit convention, PR checklist
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) — the Contributor Covenant this project follows
- [SECURITY.md](SECURITY.md) — how to report a vulnerability privately

## License

MIT — see [LICENSE](LICENSE).
