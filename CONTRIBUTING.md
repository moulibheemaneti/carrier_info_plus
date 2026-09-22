# Contributing to `carrier_info_plus`

Thanks for taking the time to contribute! This document covers everything you need to know to submit a change that lands cleanly.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](./CODE_OF_CONDUCT.md). By participating, you agree to uphold it.

## Reporting bugs / requesting features

Use the [issue templates](https://github.com/moulibheemaneti/carrier_info_plus/issues/new/choose). Bug reports without a Flutter version, repro steps, and expected vs. actual behavior will be slow to triage.

Because this package reports what the *device* says, a bug report is much more useful with the device model, OS version, and carrier setup (single vs. dual SIM) included.

## Development setup

```bash
# Clone
git clone https://github.com/moulibheemaneti/carrier_info_plus.git
cd carrier_info_plus

# This repo uses FVM to pin the Flutter version (see .fvmrc)
fvm install
fvm flutter pub get

# Run tests
fvm flutter test

# Run the example app
cd example && fvm flutter run
```

The Android emulator ships a fake T-Mobile SIM (MCC 310, MNC 260) and reports a
carrier, country, SIM state and radio technology, so most development needs no
hardware at all. What it does not emulate is dual-SIM, eSIM or roaming, and it
reports `isMultiSimSupported` and `supportsEmbeddedSim` as false regardless of
what the host machine can do.

The iOS Simulator is the opposite case: it has no cellular hardware, so every
cellular field is empty there. iOS behaviour has to be checked on a device.

If you don't use FVM, plain `flutter` works too — just make sure your version satisfies the SDK constraint in `pubspec.yaml`.

## Project structure

```
lib/
  carrier_info_plus.dart       # public barrel
  src/
    carrier_info_plus.dart     # CarrierInfoPlus entry point + method channel
    models/
      carrier_info.dart        # top-level snapshot
      sim_card.dart            # per-SIM data
      network_info.dart        # operator / radio / generation
      telephony_capabilities.dart
      platform_support.dart    # what the platform could answer, and why not
      enums.dart               # SimState, RadioAccessTechnology, …
      parsing.dart             # platform payload -> models
android/                       # CarrierInfoPlusPlugin.kt
ios/                           # CarrierInfoPlusPlugin.swift (SwiftPM + CocoaPods)
test/                          # unit tests over decoded platform payloads
example/                       # runnable demo app
```

Platform code is deliberately thin: it collects raw values and ships them over
the method channel. Derivation (e.g. mapping a radio technology to a network
generation) lives in Dart so both platforms behave identically and stays
testable without a device.

## Pre-commit hooks

This repo uses [`dart_husky`](https://pub.dev/packages/dart_husky). On every commit the following run automatically:

| Hook | Command |
|---|---|
| `format` | `dart format --set-exit-if-changed .` |
| `analyze` | `flutter analyze .` |
| `test` | `flutter test` |

If any hook fails, the commit is blocked. Fix the issue and re-stage — don't `--no-verify`.

## Continuous integration

`ci.yaml` runs on every PR to `main`:

- `dart format --set-exit-if-changed`
- `flutter analyze --fatal-infos`
- `flutter test`
- `pana` with `--exit-code-threshold 0` (a perfect pub score is required)
- a debug Android build of `example/`
- a no-codesign iOS build of `example/`, against Swift Package Manager

## Commit messages

We follow [Conventional Commits](https://www.conventionalcommits.org/). The PR title is linted in CI by `pr_title.yml`, and release-please reads merged commits to decide the next version — so the type prefix is what drives releases, not a manual bump.

Accepted types:

- `feat:` — new user-facing feature (minor bump)
- `fix:` — bug fix (patch bump)
- `docs:` — README / dartdoc / CHANGELOG only
- `style:` — formatting (no logic change)
- `refactor:` — code change that is neither a fix nor a feature
- `test:` — adding or fixing tests
- `chore:` — tooling, deps, build (no `lib/` change)
- `ci:` — workflow files
- `wip:` — work-in-progress (allowed locally; do not merge to `main`)
- `release:` — version bump / changelog cut

A `!` after the type (or a `BREAKING CHANGE:` footer) triggers a major bump.

Examples:

```
feat(android): expose carrier aggregation state per SIM
fix(ios): return unknown instead of "--" for the deprecated carrier name
chore(deps): bump flutter_lints to 6.1.0
```

## Pull request checklist

Before opening a PR, make sure:

- [ ] `fvm flutter analyze .` is clean
- [ ] `fvm flutter test` passes locally
- [ ] New public APIs have dartdoc comments
- [ ] New behavior has a test in `test/`
- [ ] Platform-specific behavior is verified — the Android emulator covers the
      single-SIM path; dual-SIM, eSIM, roaming and anything on iOS need hardware
- [ ] PR title follows Conventional Commits

You do **not** need to bump `pubspec.yaml` or edit `CHANGELOG.md` — release-please does both.

## Releasing (maintainers)

Releases are automated:

1. Merge conventional commits into `main`.
2. `release-please.yml` opens (or updates) a release PR bumping `pubspec.yaml` and `CHANGELOG.md`.
3. Merge that PR. Release-please tags `carrier_info_plus-vX.Y.Z`.
4. `publish.yml` fires on that tag and publishes to pub.dev via OIDC — no token needed, but the package must have [automated publishing](https://dart.dev/tools/pub/automated-publishing) enabled on pub.dev for this repo and tag pattern.

## Questions?

Open a [discussion](https://github.com/moulibheemaneti/carrier_info_plus/discussions) or ping `@moulibheemaneti` on an existing issue.
