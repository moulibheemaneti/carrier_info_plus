import 'enums.dart';
import 'parsing.dart';

/// One cellular subscription: a physical SIM, or an active eSIM profile.
///
/// Every identity field is nullable, and on iOS 16+ all of them are null —
/// Apple removed the API that supplied them. Check
/// `CarrierInfo.support.carrierIdentityAvailable` before showing these to a
/// user, so you can render a fallback instead of a row of blanks.
final class SimCard {
  /// Creates a [SimCard]. Normally you receive these from the platform rather
  /// than constructing them, but the constructor is public so you can build
  /// fixtures in tests.
  const SimCard({
    this.subscriptionId,
    this.slotIndex,
    this.carrierName,
    this.displayName,
    this.mobileCountryCode,
    this.mobileNetworkCode,
    this.countryIso,
    this.carrierId,
    this.isEmbedded = false,
    this.isRoaming = false,
    this.state = SimState.unknown,
  });

  /// Decodes a [SimCard] from a platform channel map.
  factory SimCard.fromMap(Map<String, Object?> map) => SimCard(
    subscriptionId: asInt(map['subscriptionId']),
    slotIndex: asInt(map['slotIndex']),
    carrierName: asString(map['carrierName']),
    displayName: asString(map['displayName']),
    mobileCountryCode: asString(map['mobileCountryCode']),
    mobileNetworkCode: asString(map['mobileNetworkCode']),
    countryIso: asString(map['countryIso']),
    carrierId: asInt(map['carrierId']),
    isEmbedded: asBool(map['isEmbedded']),
    isRoaming: asBool(map['isRoaming']),
    state: SimState.fromName(asString(map['simState'])),
  );

  /// Android subscription id, stable while the SIM stays in the device.
  ///
  /// Always null on iOS.
  final int? subscriptionId;

  /// Zero-based slot the SIM occupies. Always null on iOS.
  final int? slotIndex;

  /// Carrier name as reported by the SIM, for example `Airtel`.
  ///
  /// Null on iOS 16+.
  final String? carrierName;

  /// User-editable label for the subscription, set in Android settings.
  ///
  /// Falls back to the carrier name when the user has not renamed it, and is
  /// always null on iOS.
  final String? displayName;

  /// Mobile Country Code, three digits. For example `404` for India.
  final String? mobileCountryCode;

  /// Mobile Network Code, two or three digits.
  final String? mobileNetworkCode;

  /// ISO 3166-1 alpha-2 country code for the subscription, lowercase.
  final String? countryIso;

  /// Android's canonical carrier id, stable across MVNOs sharing a network.
  ///
  /// Null below Android 10 and on iOS.
  final int? carrierId;

  /// Whether this is an eSIM profile rather than a physical card.
  ///
  /// Android only. iOS cannot attribute an eSIM to a specific service, so this
  /// is always false there — use `TelephonyCapabilities.supportsEmbeddedSim`
  /// for the device-level answer instead.
  final bool isEmbedded;

  /// Whether the subscription is currently roaming.
  final bool isRoaming;

  /// State of the slot. Identity fields are only meaningful when this is
  /// [SimState.ready].
  final SimState state;

  /// The PLMN identifier — [mobileCountryCode] followed by
  /// [mobileNetworkCode] — or null if either part is missing.
  ///
  /// This is the value you want when matching against a carrier database.
  String? get plmn {
    final mcc = mobileCountryCode;
    final mnc = mobileNetworkCode;
    if (mcc == null || mnc == null) return null;
    return '$mcc$mnc';
  }

  /// Whether any carrier identity field on this SIM was populated.
  ///
  /// False for every SIM on iOS 16+.
  bool get hasIdentity =>
      carrierName != null || mobileCountryCode != null || countryIso != null;

  @override
  String toString() =>
      'SimCard(slot: $slotIndex, carrier: $carrierName, '
      'plmn: $plmn, embedded: $isEmbedded, state: ${state.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimCard &&
          other.subscriptionId == subscriptionId &&
          other.slotIndex == slotIndex &&
          other.carrierName == carrierName &&
          other.displayName == displayName &&
          other.mobileCountryCode == mobileCountryCode &&
          other.mobileNetworkCode == mobileNetworkCode &&
          other.countryIso == countryIso &&
          other.carrierId == carrierId &&
          other.isEmbedded == isEmbedded &&
          other.isRoaming == isRoaming &&
          other.state == state;

  @override
  int get hashCode => Object.hash(
    subscriptionId,
    slotIndex,
    carrierName,
    displayName,
    mobileCountryCode,
    mobileNetworkCode,
    countryIso,
    carrierId,
    isEmbedded,
    isRoaming,
    state,
  );
}
