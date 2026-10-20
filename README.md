# carrier_info_plus

**Cellular carrier, SIM and network information for Flutter.**

[![pub version](https://img.shields.io/pub/v/carrier_info_plus.svg?style=flat-square&color=0175C2&labelColor=1a1a2e)](https://pub.dev/packages/carrier_info_plus)
[![license](https://img.shields.io/badge/license-MIT-0175C2?style=flat-square&labelColor=1a1a2e)](LICENSE)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-ready-0175C2?style=flat-square&labelColor=1a1a2e)](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)

A maintained replacement for the unmaintained [`carrier_info`](https://pub.dev/packages/carrier_info),
built for Flutter 3.47.5+ with Swift Package Manager support, AGP 9-ready Gradle
config on Flutter's built-in Kotlin, and typed enums instead of stringly-typed
fields.

> [!IMPORTANT]
> **This is not a drop-in replacement.** The `_plus` suffix usually signals a
> compatible fork; this one is a ground-up rewrite with a different API. The old
> package advertised a lot of fields that modern Android and iOS no longer
> populate, and carrying those forward would have meant shipping a contract we
> could not honour. See [Migrating](#migrating-from-carrier_info) below.

---

## What each platform can actually tell you

This is the part most carrier packages gloss over. Apple removed `CTCarrier` in
iOS 16, so carrier identity is gone there for **every** app, no matter how well
maintained the plugin is.

| | Android | iOS 16+ |
|---|:---:|:---:|
| Carrier name | ✅ | ❌ removed by Apple |
| MCC / MNC | ✅ | ❌ removed by Apple |
| Country ISO | ✅ | ❌ removed by Apple |
| Per-SIM enumeration (dual SIM) | ✅ | ❌ count only |
| Which SIM is default for data / voice | ✅ | ❌ |
| SIM state | ✅ | ❌ |
| Roaming | ✅ | ❌ |
| Radio technology (LTE / 5G NR) | ✅ | ✅ |
| Network generation | ✅ | ✅ |
| eSIM support | ✅ | ⚠️ carrier apps only |
| SMS / voice capability | ✅ | ✅ |
| Cellular data availability | ✅ | ✅ |

Rather than handing you a struct full of unexplained nulls, every result carries
a `support` block telling you **what was answerable and why not**:

```dart
final info = await CarrierInfoPlus.get();

if (info.support.carrierIdentityAvailable) {
  showCarrier(info.primarySim?.carrierName);
} else if (info.support.limitation.isRecoverable) {
  showPermissionPrompt();   // Android, READ_PHONE_STATE not granted
} else {
  hideCarrierRow();         // iOS 16+, nothing to show and nothing to ask for
}
```

That distinction — *"the user said no"* versus *"this OS will never answer"* —
is the whole reason this package exists. They look identical in the data and
mean completely different things in a UI.

---

## Install

```bash
flutter pub add carrier_info_plus
```

**No iOS setup required.** SwiftPM and CocoaPods are both supported, so it works
whether or not your app has migrated.

**No Android Gradle setup required either.** This package applies no Kotlin
Gradle plugin of its own, so it builds whichever way your app is configured:

| Your app's `android.builtInKotlin` | Who compiles this package's Kotlin |
| --- | --- |
| `true` | AGP 9, directly |
| `false` (what `flutter create` writes today) | Flutter, by applying KGP for us |

### Android permissions

This package **declares no permissions of its own**. `READ_PHONE_STATE` is a
runtime permission that appears in the Play Console and obliges you to file a
data-safety declaration, so it's your call, not the package's.

Without any permission you still get: network operator, SIM state, the active
SIM's MCC/MNC and country, and the device's capabilities. For per-SIM data on a
dual-SIM device, add:

```xml
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

Then request it at runtime — either with your existing `permission_handler`
setup, or with the built-in helper:

```dart
if (!await CarrierInfoPlus.hasPermission()) {
  await CarrierInfoPlus.requestPermission();
}
```

One optional extra: `capabilities.isDataEnabled` and `network.cellularDataState`
are read through an API that accepts `ACCESS_NETWORK_STATE` rather than
`READ_PHONE_STATE`. That one is install-time and never prompts, so declare it if
you want those two fields:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

---

## Usage

```dart
import 'package:carrier_info_plus/carrier_info_plus.dart';

final info = await CarrierInfoPlus.get();

// Network — works on both platforms
print(info.generation);                   // NetworkGeneration.fiveG
print(info.network.radioTechnologies);    // [RadioAccessTechnology.nr]
print(info.network.cellularDataState);    // CellularDataState.notRestricted

// Device capabilities
print(info.capabilities.isMultiSimSupported);  // bool, not a String
print(info.capabilities.supportsEmbeddedSim);

// The SIM your data actually runs over — not merely the first one
print(info.primarySim?.carrierName);
print(info.voiceSim?.carrierName);             // often a different SIM

// Per-SIM — Android
for (final sim in info.simCards) {
  print('${sim.slotIndex}: ${sim.carrierName} (${sim.plmn})');
  print('eSIM: ${sim.isEmbedded}, roaming: ${sim.isRoaming}');
}

// How many SIMs exist, which can exceed how many could be described
print(info.simCount);
```

`get()` returns a **snapshot**, not a live view. Nothing is cached, because SIM
and network state change underneath you — re-read after a SIM swap or when
returning from the background.

It never throws for the ordinary "cannot answer" cases. An unsupported platform,
a missing permission and a device with no radio all come back as a populated
`CarrierInfo` whose `support` block explains the gap. A `PlatformException`
still propagates, because that means something genuinely broke.

### `simCount` versus `simCards.length`

They answer different questions, and on iOS they differ:

```dart
info.simCount        // 2  — the platform knows there are two services
info.simCards.length // 0  — it will not describe either of them
```

Use `simCount` (or `isDualSimActive`, which prefers it) when asking *how many*.
Use `simCards` when you need to render something about each one.

---

## Migrating from 1.x

The shape is unchanged; four things moved.

| Change | Why |
|---|---|
| `primarySim` is now the SIM flagged `isDefaultData`, falling back to the first | 1.x returned `simCards.first`, which names the wrong carrier on a dual-SIM phone running data on slot 2 |
| `voiceSim`, `SimCard.isDefaultData`, `SimCard.isDefaultVoice` added | Voice and data routinely use different SIMs |
| `CarrierInfo.simCount` added; iOS no longer emits placeholder `SimCard`s | iOS can count services without identifying them. 1.x returned entries with every field null; now the list is empty and the count is real |
| `RadioAccessTechnology.lteCa` removed, `nrNsa` added | `lteCa` had no public constant on either platform and could never be reported. `nrNsa` is non-standalone 5G, which iOS names and Android reports as `lte` |

The minimum SDK is now Flutter 3.47.5 / Dart 3.13.4.

---

## Migrating from `carrier_info`

The platform split is gone. Both `getAndroidInfo()` and `getIosInfo()` map to
the same `CarrierInfoPlus.get()`.

| `carrier_info` | `carrier_info_plus` |
|---|---|
| `CarrierInfo.getAndroidInfo()` | `CarrierInfoPlus.get()` |
| `CarrierInfo.getIosInfo()` | `CarrierInfoPlus.get()` |
| `AndroidCarrierData.subscriptionsInfo` | `CarrierInfo.simCards` |
| `AndroidCarrierData.isMultiSimSupported` *(String)* | `capabilities.isMultiSimSupported` *(bool)* |
| `TelephonyInfo.networkGeneration` *(String)* | `network.generation` *(`NetworkGeneration`)* |
| `TelephonyInfo.radioType` *(String)* | `network.radioTechnologies` *(`List<RadioAccessTechnology>`)* |
| `TelephonyInfo.simState` *(String)* | `SimCard.state` *(`SimState`)* |
| `IosCarrierData.carrierRadioAccessTechnologyTypeList` | `network.radioTechnologies` |
| `IosCarrierData.supportsEmbeddedSIM` | `capabilities.supportsEmbeddedSim` |
| `IosCarrierData.isSIMInserted` | `CarrierInfo.hasSim` |
| `toMap()['_ios_version_info']` | `CarrierInfo.support` |

The platform difference hasn't vanished — it moved out of the *type* and into
the *data*. iOS returns fewer populated fields, and `support` says why. You can
still branch on `Platform.isIOS`, but `info.support.carrierIdentityAvailable` is
the better condition: it tests the thing you care about rather than a proxy for
it.

### Fields with no replacement

Removed because they no longer return data on a current OS:

| Removed | Why |
|---|---|
| `simSerialNo` | Null since Android 10 for non-privileged apps |
| `phoneNumber` | Empty on most carriers even with `READ_PHONE_NUMBERS` |
| `cellId` / `lac` | Needs location permission for a GSM-only legacy path |
| iOS `subscriberIdentifiers`, `carrierTokens` | Not obtainable on modern iOS |

You can also **delete five permissions** from your manifest. This package needs
only `READ_PHONE_STATE`, and only for per-SIM data. In particular drop
`READ_PRIVILEGED_PHONE_STATE` — it is signature-level, so no Play Store app can
ever hold it, and listing it invites Play Console review questions for nothing.

---

## Why iOS returns so little

Apple deprecated `CTCarrier` in iOS 16. `carrierName` returns `"--"`,
`mobileCountryCode` and `mobileNetworkCode` return nil, and
`serviceSubscriberCellularProviders` went with them.

This package deliberately ships **no deprecated fallback** for older iOS. Two
reasons: behaviour shouldn't silently change under your users as they update,
and calling deprecated CoreTelephony API is a build break waiting to happen when
Apple finally removes it. iOS reports carrier identity as unavailable on every
version, consistently.

What remains genuinely readable on iOS is real and useful: radio access
technology per active service, how many services there are, whether the device
has a modem at all, SMS capability, and whether your app may use cellular data.

eSIM support is the exception. The API this package reads it from,
`CTCellularPlanProvisioning.supportsCellularPlan()`, answers true only to apps
holding Apple's carrier entitlement, so for everyone else
`capabilities.supportsEmbeddedSim` is false on iOS whatever the device.

---

## Development

Run the example app to see every field this package exposes against your own
device:

```bash
cd example && flutter run
```

The **Android emulator** ships a fake T-Mobile SIM (MCC 310, MNC 260) and
reports a carrier, country, SIM state and radio technology, so most development
needs no hardware. It does not emulate dual-SIM, eSIM or roaming, and reports
`isMultiSimSupported` and `supportsEmbeddedSim` as false regardless.

The **iOS Simulator** has no cellular hardware at all, so every field is empty
and `limitation` is `noTelephonyHardware`. iOS behaviour has to be checked on a
device.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full setup.

## Contributing

Issues and pull requests welcome. The package is small on purpose — if you're
adding a field, please include what OS versions actually populate it.

## License

MIT — see [LICENSE](LICENSE).
