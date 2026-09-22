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
/// Values are named after the radio technology itself, not after either
/// platform's constant, because the two disagree on spelling for the same
/// thing. Android sources these from `TelephonyManager.NETWORK_TYPE_*`, iOS
/// from `CTRadioAccessTechnology*`, and neither platform reports every value.
///
/// The mapping from a technology to a network generation is deliberately
/// absent here: it is pure derivation, so it lives in Dart where both
/// platforms get the same answer and it can be tested without a device.
enum PlatformRadioAccessTechnology {
  /// Nothing readable, or a technology neither platform names.
  unknown,

  /// General Packet Radio Service: 2G packet data.
  ///
  /// Android `NETWORK_TYPE_GPRS`, iOS `CTRadioAccessTechnologyGPRS`.
  gprs,

  /// Enhanced Data rates for GSM Evolution: 2.5G, GPRS with more throughput.
  ///
  /// Android `NETWORK_TYPE_EDGE`, iOS `CTRadioAccessTechnologyEdge`.
  edge,

  /// Global System for Mobile Communications: 2G circuit-switched.
  ///
  /// Android `NETWORK_TYPE_GSM`. Android only -- iOS describes the same
  /// radio through its data technology, GPRS or Edge.
  gsm,

  /// CDMA2000 1x Radio Transmission Technology: 2G data on CDMA networks.
  ///
  /// Android `NETWORK_TYPE_1xRTT`, iOS `CTRadioAccessTechnologyCDMA1x`.
  oneXrtt,

  /// Code Division Multiple Access (IS-95): 2G, effectively retired.
  ///
  /// Android `NETWORK_TYPE_CDMA`. Android only.
  cdma,

  /// Integrated Digital Enhanced Network: Motorola's 2G push-to-talk network.
  ///
  /// Android `NETWORK_TYPE_IDEN`. Android only, and shut down in practice --
  /// present because the constant still exists, not because you will see it.
  iden,

  /// Universal Mobile Telecommunications System: baseline 3G.
  ///
  /// Android `NETWORK_TYPE_UMTS`, iOS `CTRadioAccessTechnologyWCDMA` -- WCDMA
  /// is the air interface UMTS runs over, so the two name the same network.
  umts,

  /// High Speed Downlink Packet Access: 3.5G, faster downlink.
  ///
  /// Android `NETWORK_TYPE_HSDPA`, iOS `CTRadioAccessTechnologyHSDPA`.
  hsdpa,

  /// High Speed Uplink Packet Access: 3.5G, faster uplink.
  ///
  /// Android `NETWORK_TYPE_HSUPA`, iOS `CTRadioAccessTechnologyHSUPA`.
  hsupa,

  /// High Speed Packet Access: HSDPA and HSUPA reported together.
  ///
  /// Android `NETWORK_TYPE_HSPA`. Android only -- iOS reports the two halves
  /// separately and never combines them.
  hspa,

  /// Evolved HSPA, marketed as HSPA+: 3.75G.
  ///
  /// Android `NETWORK_TYPE_HSPAP`. Android only.
  hspap,

  /// CDMA2000 EV-DO Revision 0: first-generation 3G data on CDMA.
  ///
  /// Android `NETWORK_TYPE_EVDO_0`, iOS `CTRadioAccessTechnologyCDMAEVDORev0`.
  evdo0,

  /// EV-DO Revision A: Revision 0 with a usable uplink.
  ///
  /// Android `NETWORK_TYPE_EVDO_A`, iOS `CTRadioAccessTechnologyCDMAEVDORevA`.
  evdoA,

  /// EV-DO Revision B: multi-carrier EV-DO.
  ///
  /// Android `NETWORK_TYPE_EVDO_B`, iOS `CTRadioAccessTechnologyCDMAEVDORevB`.
  evdoB,

  /// Evolved High Rate Packet Data: the bridge that let CDMA carriers reach
  /// LTE without a hard cutover.
  ///
  /// Android `NETWORK_TYPE_EHRPD`, iOS `CTRadioAccessTechnologyeHRPD`.
  ehrpd,

  /// Time Division Synchronous CDMA: 3G, deployed almost entirely in China.
  ///
  /// Android `NETWORK_TYPE_TD_SCDMA`. Android only.
  tdScdma,

  /// Long Term Evolution: 4G.
  ///
  /// Android `NETWORK_TYPE_LTE`, iOS `CTRadioAccessTechnologyLTE`.
  lte,

  /// Wi-Fi calling: voice and data over IEEE 802.11 rather than a cellular
  /// radio.
  ///
  /// Android `NETWORK_TYPE_IWLAN`. Android only. Note that this is not a
  /// cellular generation at all, so it derives to an unknown generation
  /// rather than to 4G or 5G -- the device is on Wi-Fi, not on a mobile
  /// network, and treating it as either would misreport the connection.
  iwlan,

  /// 5G New Radio, standalone: a 5G core with a 5G radio.
  ///
  /// Android `NETWORK_TYPE_NR`, iOS `CTRadioAccessTechnologyNR`.
  nr,

  /// 5G New Radio, non-standalone: a 5G radio anchored to a 4G core, which is
  /// how most "5G" coverage is actually deployed.
  ///
  /// iOS `CTRadioAccessTechnologyNRNSA`. iOS only: Android does not give NSA
  /// its own network type, reporting it as [lte] plus a separate NR state,
  /// so an Android device on non-standalone 5G comes back as [lte] here.
  nrNsa,
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
