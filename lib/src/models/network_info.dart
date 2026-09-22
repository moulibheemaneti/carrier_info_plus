import 'enums.dart';
import 'parsing.dart';

/// The cellular network the device is attached to right now.
///
/// Unlike [SimCard], which describes what is in the device, this describes what
/// the device is connected to — the two differ while roaming.
final class NetworkInfo {
  /// Creates a [NetworkInfo].
  const NetworkInfo({
    this.radioTechnologies = const <RadioAccessTechnology>[],
    this.operatorName,
    this.countryIso,
    this.cellularDataState = CellularDataState.unknown,
  });

  /// Decodes from a platform channel map.
  factory NetworkInfo.fromMap(Map<String, Object?> map) => NetworkInfo(
    radioTechnologies: <RadioAccessTechnology>[
      for (final name in asStringList(map['radioTechnologies']))
        RadioAccessTechnology.fromName(name),
    ],
    operatorName: asString(map['operatorName']),
    countryIso: asString(map['countryIso']),
    cellularDataState: CellularDataState.fromName(
      asString(map['cellularDataState']),
    ),
  );

  /// Active radio technologies, one per active cellular service.
  ///
  /// A dual-SIM device using both subscriptions reports two entries. Empty when
  /// the device has no cellular service, or on Android when `READ_PHONE_STATE`
  /// has not been granted.
  final List<RadioAccessTechnology> radioTechnologies;

  /// Name of the network currently serving the device.
  ///
  /// While roaming this is the visited network, not the SIM's home carrier.
  /// Null on iOS.
  final String? operatorName;

  /// ISO 3166-1 alpha-2 country code of the serving network, lowercase.
  ///
  /// Null on iOS.
  final String? countryIso;

  /// Whether this app may use cellular data.
  final CellularDataState cellularDataState;

  /// The fastest generation among [radioTechnologies].
  ///
  /// On a dual-SIM device connected over both LTE and 5G this reports
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
      'NetworkInfo(generation: ${generation.name}, '
      'radios: ${radioTechnologies.map((RadioAccessTechnology t) => t.name).toList()}, '
      'operator: $operatorName, data: ${cellularDataState.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkInfo &&
          other.operatorName == operatorName &&
          other.countryIso == countryIso &&
          other.cellularDataState == cellularDataState &&
          _listEquals(other.radioTechnologies, radioTechnologies);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(radioTechnologies),
    operatorName,
    countryIso,
    cellularDataState,
  );
}

bool _listEquals(List<RadioAccessTechnology> a, List<RadioAccessTechnology> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
