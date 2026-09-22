import 'parsing.dart';

/// Why a platform could not supply carrier identity.
///
/// Carrier data goes missing for reasons you can fix and reasons you cannot,
/// and the difference decides what you show the user. A missing permission is
/// worth a prompt; an API Apple deleted is not.
enum DataLimitation {
  /// Everything this platform can report was reported.
  none,

  /// Android only. `READ_PHONE_STATE` has not been granted, so per-SIM data is
  /// unavailable. Recoverable — call `CarrierInfoPlus.requestPermission()`.
  permissionNotGranted,

  /// iOS 16+. Apple removed `CTCarrier`, so carrier name, MCC, MNC and country
  /// are gone for good. Not recoverable by any app.
  platformRemovedApi,

  /// The device has no cellular hardware — a Wi-Fi-only tablet or a simulator.
  noTelephonyHardware;

  /// Resolves a platform-supplied name, falling back to [none].
  static DataLimitation fromName(String? name) {
    if (name == null) return DataLimitation.none;
    for (final value in DataLimitation.values) {
      if (value.name == name) return value;
    }
    return DataLimitation.none;
  }

  /// Whether the app can do something about this limitation.
  ///
  /// Only [permissionNotGranted] is recoverable. Use this to decide between
  /// showing a "grant access" button and quietly hiding the carrier UI.
  bool get isRecoverable => this == DataLimitation.permissionNotGranted;

  /// A short explanation, suitable for a debug screen.
  ///
  /// Not localised — do not put this in front of end users.
  String get explanation => switch (this) {
        DataLimitation.none => 'All available data was reported.',
        DataLimitation.permissionNotGranted =>
          'READ_PHONE_STATE has not been granted, so per-SIM data is '
              'unavailable.',
        DataLimitation.platformRemovedApi =>
          'Apple removed CTCarrier in iOS 16, so carrier identity is no longer '
              'available to any app.',
        DataLimitation.noTelephonyHardware =>
          'This device has no cellular hardware.',
      };
}

/// What the current platform was actually able to answer.
///
/// Read this before rendering any carrier field. It is the difference between
/// "this user has no carrier" and "this OS will not tell us", which look
/// identical in the data but mean very different things in a UI.
final class PlatformSupport {
  /// Creates a [PlatformSupport].
  const PlatformSupport({
    this.carrierIdentityAvailable = false,
    this.perSimDataAvailable = false,
    this.permissionGranted = false,
    this.limitation = DataLimitation.none,
  });

  /// Decodes from a platform channel map.
  factory PlatformSupport.fromMap(Map<String, Object?> map) => PlatformSupport(
        carrierIdentityAvailable: asBool(map['carrierIdentityAvailable']),
        perSimDataAvailable: asBool(map['perSimDataAvailable']),
        permissionGranted: asBool(map['permissionGranted']),
        limitation: DataLimitation.fromName(asString(map['limitation'])),
      );

  /// Whether carrier name, MCC, MNC and country could be read.
  ///
  /// Always false on iOS 16 and later.
  final bool carrierIdentityAvailable;

  /// Whether individual SIMs could be enumerated.
  ///
  /// True on Android with `READ_PHONE_STATE`; false on iOS, which reports
  /// active services without identifying the SIM behind each one.
  final bool perSimDataAvailable;

  /// Whether `READ_PHONE_STATE` is currently granted.
  ///
  /// Always true on iOS, which needs no permission for what it still exposes.
  final bool permissionGranted;

  /// Why data is missing, if any is.
  final DataLimitation limitation;

  /// Whether this result is as complete as the platform allows.
  bool get isComplete => limitation == DataLimitation.none;

  @override
  String toString() => 'PlatformSupport(identity: $carrierIdentityAvailable, '
      'perSim: $perSimDataAvailable, permission: $permissionGranted, '
      'limitation: ${limitation.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformSupport &&
          other.carrierIdentityAvailable == carrierIdentityAvailable &&
          other.perSimDataAvailable == perSimDataAvailable &&
          other.permissionGranted == permissionGranted &&
          other.limitation == limitation;

  @override
  int get hashCode => Object.hash(carrierIdentityAvailable, perSimDataAvailable,
      permissionGranted, limitation);
}
