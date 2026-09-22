# carrier_info_plus

**Cellular carrier, SIM and network information for Flutter.**

[![pub version](https://img.shields.io/pub/v/carrier_info_plus.svg?style=flat-square&color=0175C2&labelColor=1a1a2e)](https://pub.dev/packages/carrier_info_plus)
[![license](https://img.shields.io/badge/license-MIT-0175C2?style=flat-square&labelColor=1a1a2e)](LICENSE)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-ready-0175C2?style=flat-square&labelColor=1a1a2e)](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)

A maintained replacement for the unmaintained [`carrier_info`](https://pub.dev/packages/carrier_info),
built for Flutter 3.24+ with Swift Package Manager support, AGP 9-ready Gradle
config, and typed enums instead of stringly-typed fields.

> [!IMPORTANT]
> **This is not a drop-in replacement.** The `_plus` suffix usually signals a
> compatible fork; this one is a ground-up rewrite with a different API. The
> old package advertised a lot of fields that modern Android and iOS no longer
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
| SIM state | ✅ | ⚠️ inferred |
| Roaming | ✅ | ❌ |
| Radio technology (LTE / 5G NR) | ✅ | ✅ |
| Network generation | ✅ | ✅ |
| eSIM support | ✅ | ✅ |
| SMS / voice capability | ✅ | ✅ |
| Cellular data availability | ✅ | ✅ |

Rather than handing you a struct full of unexplained nulls, every result
carries a `support` block telling you **what was answerable and why**:

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

```yaml
dependencies:
  carrier_info_plus: ^1.0.0
```

**No iOS setup required.** SwiftPM and CocoaPods are both supported, so it
works whether or not your app has migrated.

### Android permissions

This package **declares no permissions of its own**. `READ_PHONE_STATE` is a
runtime permission that appears in the Play Console and obliges you to file a
data-safety declaration, so it's your call, not the package's.

Without any permission you still get: network operator, SIM state, and the
active SIM's MCC/MNC and country. For per-SIM data on a dual-SIM device, add:

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

// Per-SIM — Android
for (final sim in info.simCards) {
  print('${sim.slotIndex}: ${sim.carrierName} (${sim.plmn})');
  print('eSIM: ${sim.isEmbedded}, roaming: ${sim.isRoaming}');
}
```

`get()` returns a **snapshot**, not a live view. Nothing is cached, because SIM
and network state change underneath you — re-read after a SIM swap or when
returning from the background.

It never throws for the ordinary "cannot answer" cases. An unsupported
platform, a missing permission and a device with no radio all come back as a
populated `CarrierInfo` whose `support` block explains the gap. A
`PlatformException` still propagates, because that means something genuinely
broke.

---

## Migrating from `carrier_info`

The platform split is gone — one call covers both platforms:

| `carrier_info` | `carrier_info_plus` |
|---|---|
| `CarrierInfo.getAndroidInfo()` | `CarrierInfoPlus.get()` |
| `CarrierInfo.getIosInfo()` | `CarrierInfoPlus.get()` |
| `AndroidCarrierData.subscriptionsInfo` | `CarrierInfo.simCards` |
| `AndroidCarrierData.telephonyInfo` | `CarrierInfo.network` + `CarrierInfo.simCards` |
| `AndroidCarrierData.isMultiSimSupported` *(String)* | `capabilities.isMultiSimSupported` *(bool)* |
| `AndroidCarrierData.isVoiceCapable` | `capabilities.isVoiceCapable` |
| `TelephonyInfo.networkGeneration` *(String)* | `network.generation` *(`NetworkGeneration`)* |
| `TelephonyInfo.radioType` *(String)* | `network.radioTechnologies` *(`List<RadioAccessTechnology>`)* |
| `TelephonyInfo.simState` *(String)* | `SimCard.state` *(`SimState`)* |
| `IosCarrierData.carrierRadioAccessTechnologyTypeList` | `network.radioTechnologies` |
| `IosCarrierData.supportsEmbeddedSIM` | `capabilities.supportsEmbeddedSim` |
| `IosCarrierData.isSIMInserted` | `CarrierInfo.hasSim` |
| `toMap()['_ios_version_info']` | `CarrierInfo.support` |

### Fields with no replacement

These were removed because they no longer return data on a current OS:

| Removed | Why |
|---|---|
| `simSerialNo` | Null since Android 10 for non-privileged apps |
| `phoneNumber` | Empty on most carriers even with `READ_PHONE_NUMBERS` |
| `cellId` / `lac` | Needs location permission for a GSM-only legacy path |
| iOS `subscriberIdentifiers`, `carrierTokens` | Not obtainable on modern iOS |

You can also **delete five permissions** from your manifest. This package needs
only `READ_PHONE_STATE`, and only if you want per-SIM data. In particular, drop
`READ_PRIVILEGED_PHONE_STATE` — it is signature-level, so no Play Store app can
ever hold it, and listing it invites Play Console review questions for nothing.

---

## Why iOS returns so little

Apple deprecated `CTCarrier` in iOS 16. `carrierName` returns `"--"`,
`mobileCountryCode` and `mobileNetworkCode` return nil, and
`serviceSubscriberCellularProviders` went with them.

This package deliberately ships **no deprecated fallback** for iOS 13-15. Two
reasons: behaviour shouldn't silently change under your users as they update,
and calling deprecated CoreTelephony API is a build break waiting to happen
when Apple finally removes it. iOS reports carrier identity as unavailable on
every version, consistently.

What remains genuinely readable on iOS is real and useful: radio access
technology per active service, eSIM provisioning support, SMS capability, and
whether your app may use cellular data.

---

## Contributing

Issues and pull requests welcome. The package is small on purpose — if you're
adding a field, please include what OS versions actually populate it.

## License

MIT — see [LICENSE](LICENSE).
