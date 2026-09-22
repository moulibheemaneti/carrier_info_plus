import 'enums.dart';

/// A single SIM, physical or embedded.
///
/// Every identity field is nullable because a platform may decline to answer.
/// A null is not "this SIM has no carrier" — check
/// [CarrierInfo.support] to find out which it is.
final class SimCard {
  /// Creates a [SimCard].
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
    this.isDefaultData = false,
    this.isDefaultVoice = false,
    this.state = SimState.unknown,
  });

  /// Android's stable identifier for this subscription.
  ///
  /// Null on iOS, and null on Android without `READ_PHONE_STATE`.
  final int? subscriptionId;

  /// The slot this SIM occupies, zero-based.
  final int? slotIndex;

  /// The carrier's name as the SIM reports it.
  final String? carrierName;

  /// The user-visible label for this subscription, if the user renamed it.
  final String? displayName;

  /// Mobile country code, three digits.
  final String? mobileCountryCode;

  /// Mobile network code, two or three digits.
  final String? mobileNetworkCode;

  /// ISO 3166-1 alpha-2 country code, lowercase.
  final String? countryIso;

  /// Android's carrier id, stable across rebrands. Null on iOS.
  final int? carrierId;

  /// Whether this is an eSIM rather than a physical card.
  final bool isEmbedded;

  /// Whether this subscription is currently roaming.
  final bool isRoaming;

  /// Whether mobile data runs over this subscription.
  ///
  /// On a dual-SIM device this is frequently not the same SIM as
  /// [isDefaultVoice], which is why [CarrierInfo.primarySim] uses this rather
  /// than simply taking the first entry.
  final bool isDefaultData;

  /// Whether calls are placed over this subscription.
  final bool isDefaultVoice;

  /// The slot's current state.
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
      'SimCard(slot: $slotIndex, carrier: $carrierName, plmn: $plmn, '
      'embedded: $isEmbedded, state: ${state.name})';

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
          other.isDefaultData == isDefaultData &&
          other.isDefaultVoice == isDefaultVoice &&
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
    isDefaultData,
    isDefaultVoice,
    state,
  );
}
