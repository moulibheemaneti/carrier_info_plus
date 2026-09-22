// The single source of truth for the platform boundary.
//
// Everything in this file is a *declaration*. Running `dart run pigeon --input
// pigeons/messages.dart` generates the Dart, Kotlin and Swift sides from it, so
// the three can never disagree about names, types or nullability.
//
// Naming follows flutter/packages: data classes and enums carry a `Platform`
// prefix, API classes do not. The prefix keeps these types from colliding with
// the public models in `lib/src/models/`, which is what apps actually see.
//
// Generated types are an internal implementation detail and are never
// exported. Pigeon's own documentation is explicit that putting generated code
// in a public API is a mistake, because it reserves the right to change that
// code between releases. The hand-written models are the stable surface; these
// are just the wire format.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/com/moulibheemaneti/carrier_info_plus/Messages.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.moulibheemaneti.carrier_info_plus',
    ),
    swiftOut: 'ios/carrier_info_plus/Sources/carrier_info_plus/Messages.swift',
  ),
)
/// Pigeon equivalent of [SimState].
enum PlatformSimState {
  unknown,
  absent,
  pinRequired,
  pukRequired,
  networkLocked,
  ready,
  notReady,
  permanentlyDisabled,
  cardIoError,
  cardRestricted,
}

/// Pigeon equivalent of [RadioAccessTechnology].
///
/// The mapping from a radio technology to a network generation is deliberately
/// absent here: it is pure derivation, so it lives in Dart where both platforms
/// get the same answer and it can be tested without a device.
enum PlatformRadioAccessTechnology {
  unknown,
  gprs,
  edge,
  gsm,
  oneXrtt,
  cdma,
  iden,
  umts,
  hsdpa,
  hsupa,
  hspa,
  hspap,
  evdo0,
  evdoA,
  evdoB,
  ehrpd,
  tdScdma,
  lte,
  lteCa,
  iwlan,
  nr,
}

/// Pigeon equivalent of [CellularDataState].
enum PlatformCellularDataState { unknown, restricted, notRestricted }

/// Pigeon equivalent of [DataLimitation].
enum PlatformDataLimitation {
  none,
  permissionNotGranted,
  platformRemovedApi,
  noTelephonyHardware,
}

/// Pigeon equivalent of [SimCard].
class PlatformSimCard {
  PlatformSimCard({
    required this.isEmbedded,
    required this.isRoaming,
    required this.simState,
    this.subscriptionId,
    this.slotIndex,
    this.carrierName,
    this.displayName,
    this.mobileCountryCode,
    this.mobileNetworkCode,
    this.countryIso,
    this.carrierId,
  });

  /// Android's stable per-subscription identifier. Null on iOS, and null on
  /// Android when read without the per-SIM permission.
  final int? subscriptionId;

  /// Physical or logical slot. Null when the SIM could not be enumerated.
  final int? slotIndex;

  final String? carrierName;
  final String? displayName;
  final String? mobileCountryCode;
  final String? mobileNetworkCode;
  final String? countryIso;
  final int? carrierId;

  final bool isEmbedded;
  final bool isRoaming;
  final PlatformSimState simState;
}

/// Pigeon equivalent of [TelephonyCapabilities].
class PlatformTelephonyCapabilities {
  PlatformTelephonyCapabilities({
    required this.isVoiceCapable,
    required this.isSmsCapable,
    required this.isDataCapable,
    required this.isDataEnabled,
    required this.isMultiSimSupported,
    required this.supportsEmbeddedSim,
  });

  final bool isVoiceCapable;
  final bool isSmsCapable;
  final bool isDataCapable;
  final bool isDataEnabled;
  final bool isMultiSimSupported;
  final bool supportsEmbeddedSim;
}

/// Pigeon equivalent of [NetworkInfo].
class PlatformNetworkInfo {
  PlatformNetworkInfo({
    required this.radioTechnologies,
    required this.cellularDataState,
    this.operatorName,
    this.countryIso,
  });

  /// One entry per active data subscription. Empty when nothing is readable.
  final List<PlatformRadioAccessTechnology> radioTechnologies;

  final String? operatorName;
  final String? countryIso;
  final PlatformCellularDataState cellularDataState;
}

/// Pigeon equivalent of [PlatformSupport].
///
/// Named with an `Info` suffix because the public model is already called
/// `PlatformSupport`; the usual `Platform` prefix would produce
/// `PlatformPlatformSupport`.
class PlatformSupportInfo {
  PlatformSupportInfo({
    required this.carrierIdentityAvailable,
    required this.perSimDataAvailable,
    required this.permissionGranted,
    required this.limitation,
  });

  /// Whether carrier name, MCC, MNC and country could be read at all.
  final bool carrierIdentityAvailable;

  /// Whether every SIM could be enumerated, rather than just the active one.
  final bool perSimDataAvailable;

  final bool permissionGranted;

  /// Why anything above is false. This is the field that tells an app whether
  /// to prompt or to hide the UI.
  final PlatformDataLimitation limitation;
}

/// Pigeon equivalent of [CarrierInfo].
class PlatformCarrierInfo {
  PlatformCarrierInfo({
    required this.simCards,
    required this.capabilities,
    required this.network,
    required this.support,
  });

  final List<PlatformSimCard> simCards;
  final PlatformTelephonyCapabilities capabilities;
  final PlatformNetworkInfo network;
  final PlatformSupportInfo support;
}

/// Calls into the host platform.
@HostApi()
abstract class CarrierInfoApi {
  /// Reads a fresh snapshot of the device's cellular state.
  ///
  /// Never throws for missing data: anything unreadable comes back null and is
  /// explained through [PlatformCarrierInfo.support].
  PlatformCarrierInfo getCarrierInfo();

  /// Whether the permission guarding per-SIM data has been granted.
  ///
  /// Always true on iOS, which has no equivalent permission.
  bool hasPermission();

  /// Prompts for the permission guarding per-SIM data.
  ///
  /// Asynchronous because Android answers through an activity callback rather
  /// than a return value.
  @async
  bool requestPermission();
}
