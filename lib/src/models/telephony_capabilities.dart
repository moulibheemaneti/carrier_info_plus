import 'parsing.dart';

/// What the device's telephony hardware and settings allow.
///
/// These describe the device, not any particular SIM, and none of them require
/// a SIM to be present.
final class TelephonyCapabilities {
  /// Creates a [TelephonyCapabilities].
  const TelephonyCapabilities({
    this.isVoiceCapable = false,
    this.isSmsCapable = false,
    this.isDataCapable = false,
    this.isDataEnabled = false,
    this.isMultiSimSupported = false,
    this.supportsEmbeddedSim = false,
  });

  /// Decodes from a platform channel map.
  factory TelephonyCapabilities.fromMap(Map<String, Object?> map) =>
      TelephonyCapabilities(
        isVoiceCapable: asBool(map['isVoiceCapable']),
        isSmsCapable: asBool(map['isSmsCapable']),
        isDataCapable: asBool(map['isDataCapable']),
        isDataEnabled: asBool(map['isDataEnabled']),
        isMultiSimSupported: asBool(map['isMultiSimSupported']),
        supportsEmbeddedSim: asBool(map['supportsEmbeddedSim']),
      );

  /// Whether the device can place circuit-switched calls.
  ///
  /// False on tablets and Wi-Fi-only devices.
  final bool isVoiceCapable;

  /// Whether the device can send SMS.
  final bool isSmsCapable;

  /// Whether the device has a cellular data radio at all.
  final bool isDataCapable;

  /// Whether mobile data is currently switched on by the user.
  ///
  /// Requires `READ_PHONE_STATE` on Android; false when not granted. Always
  /// false on iOS, which exposes no equivalent — use
  /// `CarrierInfo.network.cellularDataState` there instead.
  final bool isDataEnabled;

  /// Whether the hardware supports more than one active SIM.
  ///
  /// This is the capability, not the current state: a dual-SIM phone with one
  /// card in it still reports true.
  final bool isMultiSimSupported;

  /// Whether the device can provision an eSIM profile.
  final bool supportsEmbeddedSim;

  @override
  String toString() =>
      'TelephonyCapabilities(voice: $isVoiceCapable, '
      'sms: $isSmsCapable, data: $isDataCapable, dataEnabled: $isDataEnabled, '
      'multiSim: $isMultiSimSupported, eSIM: $supportsEmbeddedSim)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TelephonyCapabilities &&
          other.isVoiceCapable == isVoiceCapable &&
          other.isSmsCapable == isSmsCapable &&
          other.isDataCapable == isDataCapable &&
          other.isDataEnabled == isDataEnabled &&
          other.isMultiSimSupported == isMultiSimSupported &&
          other.supportsEmbeddedSim == supportsEmbeddedSim;

  @override
  int get hashCode => Object.hash(
    isVoiceCapable,
    isSmsCapable,
    isDataCapable,
    isDataEnabled,
    isMultiSimSupported,
    supportsEmbeddedSim,
  );
}
