/// What the device's cellular hardware can do, independent of any SIM.
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

  /// Whether the device can place circuit-switched calls.
  ///
  /// False on tablets and Wi-Fi-only devices. On iOS only an iPhone answers
  /// true: a cellular iPad has a modem but no cellular voice.
  final bool isVoiceCapable;

  /// Whether the device can send SMS.
  final bool isSmsCapable;

  /// Whether the device has a cellular data radio at all.
  ///
  /// A property of the hardware, so it holds with no SIM inserted.
  final bool isDataCapable;

  /// Whether mobile data is currently switched on by the user.
  ///
  /// On Android this needs one of `ACCESS_NETWORK_STATE`, `MODIFY_PHONE_STATE`
  /// or `READ_BASIC_PHONE_STATE` — notably *not* `READ_PHONE_STATE` — and is
  /// false when the app declares none of them. Always false on iOS, which
  /// exposes no equivalent; use [NetworkInfo.cellularDataState] there.
  final bool isDataEnabled;

  /// Whether the hardware supports more than one active SIM.
  ///
  /// This is the capability, not the current state: a dual-SIM phone with one
  /// card in it still reports true.
  ///
  /// On Android, `READ_PHONE_STATE` adds whether the carrier allows it; without
  /// the permission this reports the modem's capability alone. On iOS, which
  /// has no capability query, it is true only while two services are active.
  final bool isMultiSimSupported;

  /// Whether the device supports eSIM.
  ///
  /// On iOS this is only ever true for an app holding Apple's carrier
  /// entitlement (`com.apple.CommCenter.fine-grained` with
  /// `public-cellular-plan`). Every other app sees false, whatever the device.
  final bool supportsEmbeddedSim;

  @override
  String toString() =>
      'TelephonyCapabilities(voice: $isVoiceCapable, sms: $isSmsCapable, '
      'data: $isDataCapable, dataEnabled: $isDataEnabled, '
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
