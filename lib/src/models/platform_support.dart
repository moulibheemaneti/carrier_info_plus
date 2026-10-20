/// Why a platform could not supply carrier identity.
///
/// Carrier data goes missing for reasons you can fix and reasons you cannot,
/// and the difference decides what you show the user. A missing permission is
/// worth a prompt; an API Apple deleted is not.
enum DataLimitation {
  /// Everything this platform can report was reported.
  none,

  /// Android only. `READ_PHONE_STATE` has not been granted, so per-SIM data is
  /// unavailable. Recoverable — call [CarrierInfoPlus.requestPermission].
  permissionNotGranted,

  /// iOS 16+. Apple removed `CTCarrier`, so carrier name, MCC, MNC and country
  /// are gone for good. Not recoverable by any app.
  platformRemovedApi,

  /// The device has no cellular hardware — a Wi-Fi-only tablet, or the iOS
  /// Simulator. Note the Android emulator does *not* land here: it reports a
  /// fake T-Mobile SIM.
  noTelephonyHardware;

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
      'READ_PHONE_STATE has not been granted, so per-SIM data is unavailable.',
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

  /// Whether this platform can read carrier name, MCC, MNC and country.
  ///
  /// A capability, not a promise of data. Android reads identity without any
  /// permission from whatever SIM is present, so this is true there with or
  /// without `READ_PHONE_STATE`, and on a device with no SIM in it at all.
  /// Check `SimCard.hasIdentity` for whether any identity was actually found.
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
  String toString() =>
      'PlatformSupport(identity: $carrierIdentityAvailable, '
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
  int get hashCode => Object.hash(
    carrierIdentityAvailable,
    perSimDataAvailable,
    permissionGranted,
    limitation,
  );
}
