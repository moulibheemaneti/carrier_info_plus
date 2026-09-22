/// Broad cellular network generation.
///
/// Derived from [RadioAccessTechnology] in Dart rather than on each platform,
/// so Android and iOS always classify the same radio the same way.
enum NetworkGeneration {
  /// No cellular radio reported, or the radio is not recognised.
  unknown,

  /// GPRS, EDGE, CDMA 1x.
  twoG,

  /// UMTS, HSPA family, EV-DO, TD-SCDMA.
  threeG,

  /// LTE and LTE-Advanced.
  fourG,

  /// 5G NR, standalone or non-standalone.
  fiveG,
}

/// A cellular radio access technology.
///
/// Values are the union of what Android's `TelephonyManager.NETWORK_TYPE_*`
/// and iOS's `CTRadioAccessTechnology*` constants can report. A technology one
/// platform can never report simply never appears in that platform's results.
enum RadioAccessTechnology {
  /// Reported, but not a technology this package recognises.
  unknown(NetworkGeneration.unknown),
  gprs(NetworkGeneration.twoG),
  edge(NetworkGeneration.twoG),
  gsm(NetworkGeneration.twoG),
  oneXrtt(NetworkGeneration.twoG),
  cdma(NetworkGeneration.twoG),
  iden(NetworkGeneration.twoG),
  umts(NetworkGeneration.threeG),
  hsdpa(NetworkGeneration.threeG),
  hsupa(NetworkGeneration.threeG),
  hspa(NetworkGeneration.threeG),
  hspap(NetworkGeneration.threeG),
  evdo0(NetworkGeneration.threeG),
  evdoA(NetworkGeneration.threeG),
  evdoB(NetworkGeneration.threeG),
  ehrpd(NetworkGeneration.threeG),
  tdScdma(NetworkGeneration.threeG),
  lte(NetworkGeneration.fourG),
  lteCa(NetworkGeneration.fourG),

  /// Wi-Fi calling. Carried over the cellular stack but not a cellular radio,
  /// so it maps to [NetworkGeneration.unknown].
  iwlan(NetworkGeneration.unknown),

  /// 5G NR, both standalone and non-standalone (NRNSA on iOS).
  nr(NetworkGeneration.fiveG);

  const RadioAccessTechnology(this.generation);

  /// The network generation this technology belongs to.
  final NetworkGeneration generation;

  /// Resolves a platform-supplied name, falling back to [unknown].
  static RadioAccessTechnology fromName(String? name) {
    if (name == null) return RadioAccessTechnology.unknown;
    for (final value in RadioAccessTechnology.values) {
      if (value.name == name) return value;
    }
    return RadioAccessTechnology.unknown;
  }
}

/// The state of a single SIM slot.
///
/// Only [ready] guarantees that the slot's carrier fields are populated.
enum SimState {
  /// The platform did not report a state.
  unknown,

  /// No SIM is present in the slot.
  absent,

  /// Locked, awaiting the user's PIN.
  pinRequired,

  /// Locked, awaiting the PUK.
  pukRequired,

  /// Locked by a network personalisation (carrier lock).
  networkLocked,

  /// Present, unlocked and usable.
  ready,

  /// Present but not yet initialised.
  notReady,

  /// Permanently disabled, usually after too many failed PUK attempts.
  permanentlyDisabled,

  /// The slot reported an I/O error.
  cardIoError,

  /// The card is restricted and cannot be used.
  cardRestricted;

  /// Resolves a platform-supplied name, falling back to [unknown].
  static SimState fromName(String? name) {
    if (name == null) return SimState.unknown;
    for (final value in SimState.values) {
      if (value.name == name) return value;
    }
    return SimState.unknown;
  }
}

/// Whether the app is allowed to use cellular data.
///
/// On iOS this mirrors `CTCellularData.restrictedState`. On Android there is no
/// per-app equivalent, so it reflects whether mobile data is enabled for the
/// device, and is [unknown] when `READ_PHONE_STATE` has not been granted.
enum CellularDataState {
  /// The platform has not resolved a state yet, or could not be asked.
  unknown,

  /// Cellular data is unavailable to this app.
  restricted,

  /// Cellular data is available to this app.
  notRestricted;

  /// Resolves a platform-supplied name, falling back to [unknown].
  static CellularDataState fromName(String? name) {
    if (name == null) return CellularDataState.unknown;
    for (final value in CellularDataState.values) {
      if (value.name == name) return value;
    }
    return CellularDataState.unknown;
  }
}
