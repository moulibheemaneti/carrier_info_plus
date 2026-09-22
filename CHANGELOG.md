# Changelog

## 2.0.0 (2026-09-22)

A ground-up rewrite. The package is now built on a single pigeon contract that
generates the Dart, Kotlin and Swift sides from one file, so the three cannot
disagree about names, types or nullability.

See [Migrating from 1.x](https://github.com/moulibheemaneti/carrier_info_plus#migrating-from-1x)
for the upgrade path.

### ⚠ BREAKING CHANGES

* `RadioAccessTechnology.lteCa` is removed. No public constant exists for it on
  either platform — Android exposes only `NETWORK_TYPE_BITMASK_LTE_CA`, which
  belongs to a different API — so it could never be reported.
* `CarrierInfo.primarySim` now returns the SIM flagged `isDefaultData`, falling
  back to the first entry. 1.x always returned `simCards.first`, which names the
  wrong carrier on a dual-SIM device running data on slot two.
* iOS no longer emits placeholder `SimCard` entries. `simCards` is empty there
  and `simCount` carries the service count, so `simCards.length` can now be
  smaller than `simCount`.
* The minimum SDK is Flutter 3.47.5 / Dart 3.13.4.

### Features

* rewrite on pigeon with a typed cross-platform contract ([#4](https://github.com/moulibheemaneti/carrier_info_plus/pull/4)) ([a8b38c2](https://github.com/moulibheemaneti/carrier_info_plus/commit/a8b38c2010bb0099832d4478d12b43524d8fcdeb))
* add `SimCard.isDefaultData`, `SimCard.isDefaultVoice` and `CarrierInfo.voiceSim`,
  so the SIM carrying data and the one carrying calls can be told apart
* add `CarrierInfo.simCount`, which reports how many SIMs a platform says exist
  even when it will not describe them
* add `RadioAccessTechnology.nrNsa` for non-standalone 5G, which iOS names and
  Android reports as `lte`

### Bug Fixes

* read Android's mobile-data switch once per snapshot, so
  `capabilities.isDataEnabled` and `network.cellularDataState` can no longer
  contradict each other ([56bf298](https://github.com/moulibheemaneti/carrier_info_plus/commit/56bf298))
* correct four Android API-level guards that were more conservative than the
  platform requires, switching features off on devices that support them

## 1.1.0

Android now builds on Flutter's built-in Kotlin.

### Changed

- The Android module no longer applies the Kotlin Gradle plugin. Kotlin comes
  from AGP 9 directly, or from the KGP that Flutter applies on the package's
  behalf while `android.builtInKotlin=false`. Apps that depend on this package
  no longer see Flutter's "plugins that apply KGP" build warning, and will keep
  building once Flutter removes KGP support entirely.
- **The minimum supported SDK is now Flutter 3.47.5 / Dart 3.13.4**, up from
  Flutter 3.24 / Dart 3.5. Flutter 3.44 is where the Gradle plugin began
  applying KGP on behalf of plugins that no longer apply it themselves, and
  3.47 is where enabling `android.builtInKotlin=true` became supported. Apps on
  an older Flutter should stay on 1.0.0.
- `android/settings.gradle` pins AGP 9.4.1 for standalone builds of `android/`.
  This does not affect consuming apps, which resolve AGP through their own
  `settings.gradle`.

The Dart API is unchanged.

## 1.0.0

First release.

`carrier_info_plus` is a ground-up rewrite rather than a fork, so the API does
not match `carrier_info`. See the migration table in the README.

### Added

- `CarrierInfoPlus.get()` returning a single `CarrierInfo` snapshot for both
  platforms, replacing the old `getAndroidInfo()` / `getIosInfo()` split.
- `PlatformSupport` on every result, reporting what the platform could actually
  answer and why anything is missing — distinguishing a recoverable missing
  permission from an API Apple removed.
- Typed enums for values the old package returned as strings:
  `SimState`, `RadioAccessTechnology`, `NetworkGeneration`, `CellularDataState`.
- `NetworkGeneration` derived in Dart, so both platforms classify a given radio
  identically.
- Built-in permission handling: `hasPermission()` and `requestPermission()`,
  removing the need for a separate permission package.
- Graceful degradation on Android: without `READ_PHONE_STATE` you get the
  permission-free subset rather than an error.
- Swift Package Manager support alongside CocoaPods.
- An iOS privacy manifest (`PrivacyInfo.xcprivacy`).

### Changed from `carrier_info`

- `isMultiSimSupported` is a `bool`. It was typed `String`.
- iOS carrier identity is reported as unavailable on every iOS version, rather
  than working on iOS 13-15 and silently emptying out on 16. No deprecated
  CoreTelephony API is called.

### Removed

Fields that no longer return data on a current OS, and which the old package
still advertised:

- `simSerialNo` — null since Android 10 for non-privileged apps.
- `phoneNumber` — empty on most carriers even with `READ_PHONE_NUMBERS`.
- `cellId` / `lac` — needs location permission for a GSM-only legacy path.
- iOS `subscriberIdentifiers` and `carrierTokens` — not obtainable on modern iOS.

The plugin also no longer asks apps to declare `READ_PRIVILEGED_PHONE_STATE`,
a signature-level permission no Play Store app can ever hold.
