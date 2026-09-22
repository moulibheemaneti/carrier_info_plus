import 'enums.dart';
import 'network_info.dart';
import 'parsing.dart';
import 'platform_support.dart';
import 'sim_card.dart';
import 'telephony_capabilities.dart';

/// A single snapshot of the device's cellular state.
///
/// This is a value, not a live view: it is accurate as of the moment
/// `CarrierInfoPlus.get()` returned. Re-read it after a SIM swap, a network
/// change, or returning from the background.
final class CarrierInfo {
  /// Creates a [CarrierInfo].
  const CarrierInfo({
    this.simCards = const <SimCard>[],
    this.capabilities = const TelephonyCapabilities(),
    this.network = const NetworkInfo(),
    this.support = const PlatformSupport(),
  });

  /// Decodes from a platform channel map.
  factory CarrierInfo.fromMap(Map<String, Object?> map) => CarrierInfo(
        simCards: <SimCard>[
          for (final sim in asMapList(map['simCards'])) SimCard.fromMap(sim),
        ],
        capabilities:
            TelephonyCapabilities.fromMap(asMap(map['capabilities'])),
        network: NetworkInfo.fromMap(asMap(map['network'])),
        support: PlatformSupport.fromMap(asMap(map['support'])),
      );

  /// Every active subscription, in slot order.
  ///
  /// Empty when no SIM is present. On iOS this contains one entry per active
  /// cellular service with all identity fields null.
  final List<SimCard> simCards;

  /// What the device's telephony hardware and settings allow.
  final TelephonyCapabilities capabilities;

  /// The network the device is attached to right now.
  final NetworkInfo network;

  /// What this platform was able to answer, and why anything is missing.
  ///
  /// Check this before rendering carrier fields.
  final PlatformSupport support;

  /// The SIM in the lowest-numbered slot, or null if no SIM is present.
  ///
  /// Convenient for single-SIM apps. Do not assume it is the subscription
  /// carrying data on a dual-SIM device — the user chooses that independently.
  SimCard? get primarySim => simCards.isEmpty ? null : simCards.first;

  /// Whether any SIM is present.
  bool get hasSim => simCards.isNotEmpty;

  /// Whether more than one subscription is currently active.
  bool get isDualSimActive => simCards.length > 1;

  /// The fastest generation the device is currently connected over.
  NetworkGeneration get generation => network.generation;

  @override
  String toString() => 'CarrierInfo(sims: ${simCards.length}, '
      'generation: ${generation.name}, support: $support)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarrierInfo &&
          other.capabilities == capabilities &&
          other.network == network &&
          other.support == support &&
          _simsEqual(other.simCards, simCards);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(simCards), capabilities, network, support);
}

bool _simsEqual(List<SimCard> a, List<SimCard> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
