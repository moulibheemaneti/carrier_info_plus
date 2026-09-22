# Changelog

## [2.0.0](https://github.com/moulibheemaneti/carrier_info_plus/compare/carrier_info_plus-v1.1.0...carrier_info_plus-v2.0.0) (2026-09-22)


### ⚠ BREAKING CHANGES

* carrier_info_plus 2.0.0 is a ground-up rewrite with a different API surface.

### Features

* **android:** migrate to Flutter's built-in Kotlin ([#3](https://github.com/moulibheemaneti/carrier_info_plus/issues/3)) ([a89d722](https://github.com/moulibheemaneti/carrier_info_plus/commit/a89d7221925daa80120231c0a0daade2efb43716))
* initial release of carrier_info_plus 1.0.0 ([35d14cb](https://github.com/moulibheemaneti/carrier_info_plus/commit/35d14cb1c33f6eaca5b4c5974c4eef359da13f9f))
* rewrite on pigeon with a typed cross-platform contract ([#4](https://github.com/moulibheemaneti/carrier_info_plus/issues/4)) ([a8b38c2](https://github.com/moulibheemaneti/carrier_info_plus/commit/a8b38c2010bb0099832d4478d12b43524d8fcdeb))


### Bug Fixes

* satisfy dart format and the analyzer ([2e6006a](https://github.com/moulibheemaneti/carrier_info_plus/commit/2e6006a54e3cd23ca58655d4bddb29223e482be7))


### Miscellaneous

* **main:** release 1.1.0 ([fe41b21](https://github.com/moulibheemaneti/carrier_info_plus/commit/fe41b212df70f2740049df8003d4f7674e642c7d))


### Documentation

* add pub.dev links to README and pubspec ([#2](https://github.com/moulibheemaneti/carrier_info_plus/issues/2)) ([b16f718](https://github.com/moulibheemaneti/carrier_info_plus/commit/b16f718079a3667cb6a41183ff3b3d2254559c46))
* explain why both platform calls map to one ([69214ab](https://github.com/moulibheemaneti/carrier_info_plus/commit/69214ab694f6f236ec9a48353c63955697945e7d))


### CI

* add release automation and repo standards from sibling packages ([#1](https://github.com/moulibheemaneti/carrier_info_plus/issues/1)) ([b16ef3c](https://github.com/moulibheemaneti/carrier_info_plus/commit/b16ef3c0e62dbbbdf0ab0f2c502414050e0f4daa))

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
