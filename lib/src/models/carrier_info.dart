import 'enums.dart';
import 'network_info.dart';
import 'platform_support.dart';
import 'sim_card.dart';
import 'telephony_capabilities.dart';

/// A snapshot of the device's cellular carrier, SIM and network state.
///
/// Nothing here is cached. SIM and network state change underneath you, so
/// re-read after a SIM swap or when returning from the background.
final class CarrierInfo {
  /// Creates a [CarrierInfo].
  const CarrierInfo({
    this.simCards = const <SimCard>[],
    this.capabilities = const TelephonyCapabilities(),
    this.network = const NetworkInfo(),
    this.support = const PlatformSupport(),
    this.simCount,
  });

  /// Every SIM the platform was able to describe.
  ///
  /// Can be shorter than [simCount] when a platform knows a SIM exists but
  /// will not say anything about it.
  final List<SimCard> simCards;

  /// What the device's cellular hardware can do.
  final TelephonyCapabilities capabilities;

  /// The network currently attached.
  final NetworkInfo network;

  /// What the platform was able to answer, and why anything is missing.
  ///
  /// Check this before rendering any carrier field.
  final PlatformSupport support;

  /// How many SIMs the platform says are present, or null when it will not say.
  ///
  /// Prefer this over `simCards.length` when asking how many SIMs a device has.
  final int? simCount;

  /// The SIM mobile data runs over, or the first one if the platform cannot
  /// say, or null when no SIM was described.
  ///
  /// The fallback matters: iOS reports no default line, so there the first
  /// entry is the best available answer. On Android it is the real default.
  SimCard? get primarySim {
    if (simCards.isEmpty) return null;
    for (final sim in simCards) {
      if (sim.isDefaultData) return sim;
    }
    return simCards.first;
  }

  /// The SIM calls are placed over, or null when the platform cannot say.
  SimCard? get voiceSim {
    for (final sim in simCards) {
      if (sim.isDefaultVoice) return sim;
    }
    return null;
  }

  /// Whether the device has at least one SIM.
  bool get hasSim => simCards.isNotEmpty || (simCount ?? 0) > 0;

  /// Whether more than one SIM is currently active.
  ///
  /// Uses [simCount] where available, so this stays correct on a platform that
  /// can count SIMs without describing them.
  bool get isDualSimActive => (simCount ?? simCards.length) > 1;

  /// The fastest network generation currently attached.
  ///
  /// Shorthand for `network.generation`.
  NetworkGeneration get generation => network.generation;

  @override
  String toString() =>
      'CarrierInfo(sims: ${simCards.length}, count: $simCount, '
      '$network, $support)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarrierInfo &&
          _sameSims(other.simCards) &&
          other.capabilities == capabilities &&
          other.network == network &&
          other.support == support &&
          other.simCount == simCount;

  bool _sameSims(List<SimCard> other) {
    if (other.length != simCards.length) return false;
    for (var i = 0; i < other.length; i++) {
      if (other[i] != simCards[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(simCards),
    capabilities,
    network,
    support,
    simCount,
  );
}
