# Changelog

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
