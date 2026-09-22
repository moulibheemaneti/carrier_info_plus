import 'enums.dart';

/// The network the device is currently attached to.
final class NetworkInfo {
  /// Creates a [NetworkInfo].
  const NetworkInfo({
    this.radioTechnologies = const <RadioAccessTechnology>[],
    this.operatorName,
    this.countryIso,
    this.cellularDataState = CellularDataState.unknown,
  });

  /// The radio technologies currently in use.
  ///
  /// A property of the device, not of any one SIM: neither platform reliably
  /// says which radio belongs to which subscription.
  final List<RadioAccessTechnology> radioTechnologies;

  /// The registered operator's name, which can differ from the SIM's carrier
  /// name while roaming.
  final String? operatorName;

  /// ISO 3166-1 alpha-2 country code of the registered network, lowercase.
  final String? countryIso;

  /// Whether this app may use cellular data.
  final CellularDataState cellularDataState;

  /// The fastest generation among [radioTechnologies].
  ///
  /// On a dual-SIM device attached over both LTE and 5G this reports
  /// [NetworkGeneration.fiveG] — the best the device currently has.
  NetworkGeneration get generation {
    var best = NetworkGeneration.unknown;
    for (final technology in radioTechnologies) {
      if (technology.generation.index > best.index) {
        best = technology.generation;
      }
    }
    return best;
  }

  /// Whether any cellular radio is currently attached.
  bool get isConnected => radioTechnologies.any(
    (RadioAccessTechnology technology) =>
        technology != RadioAccessTechnology.unknown,
  );

  @override
  String toString() =>
      'NetworkInfo(operator: $operatorName, country: $countryIso, '
      'generation: ${generation.name}, data: ${cellularDataState.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkInfo &&
          _sameTechnologies(other.radioTechnologies) &&
          other.operatorName == operatorName &&
          other.countryIso == countryIso &&
          other.cellularDataState == cellularDataState;

  bool _sameTechnologies(List<RadioAccessTechnology> other) {
    if (other.length != radioTechnologies.length) return false;
    for (var i = 0; i < other.length; i++) {
      if (other[i] != radioTechnologies[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(radioTechnologies),
    operatorName,
    countryIso,
    cellularDataState,
  );
}
