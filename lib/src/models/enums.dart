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

  /// LTE.
  fourG,

  /// 5G NR, standalone or non-standalone.
  fiveG,
}

/// A cellular radio access technology.
///
/// Values are the union of what Android's `TelephonyManager.NETWORK_TYPE_*`
/// and iOS's `CTRadioAccessTechnology*` constants can report. A technology one
/// platform cannot report simply never appears in that platform's results.
enum RadioAccessTechnology {
  /// Reported, but not a technology this package recognises.
  unknown(NetworkGeneration.unknown),

  /// General Packet Radio Service.
  gprs(NetworkGeneration.twoG),

  /// Enhanced Data rates for GSM Evolution.
  edge(NetworkGeneration.twoG),

  /// Global System for Mobile Communications. Android only.
  gsm(NetworkGeneration.twoG),

  /// CDMA2000 1xRTT.
  oneXrtt(NetworkGeneration.twoG),

  /// CDMA IS-95. Android only.
  cdma(NetworkGeneration.twoG),

  /// Integrated Digital Enhanced Network. Android only.
  iden(NetworkGeneration.twoG),

  /// UMTS, reported as WCDMA on iOS.
  umts(NetworkGeneration.threeG),

  /// High Speed Downlink Packet Access.
  hsdpa(NetworkGeneration.threeG),

  /// High Speed Uplink Packet Access.
  hsupa(NetworkGeneration.threeG),

  /// HSDPA and HSUPA combined. Android only.
  hspa(NetworkGeneration.threeG),

  /// Evolved HSPA, marketed as HSPA+. Android only.
  hspap(NetworkGeneration.threeG),

  /// EV-DO Revision 0.
  evdo0(NetworkGeneration.threeG),

  /// EV-DO Revision A.
  evdoA(NetworkGeneration.threeG),

  /// EV-DO Revision B.
  evdoB(NetworkGeneration.threeG),

  /// Evolved High Rate Packet Data.
  ehrpd(NetworkGeneration.threeG),

  /// TD-SCDMA. Android only.
  tdScdma(NetworkGeneration.threeG),

  /// Long Term Evolution.
  lte(NetworkGeneration.fourG),

  /// Wi-Fi calling. Android only.
  ///
  /// Carried over the cellular stack but not a cellular radio, so it maps to
  /// [NetworkGeneration.unknown] rather than to a generation it never had.
  iwlan(NetworkGeneration.unknown),

  /// 5G New Radio, standalone.
  nr(NetworkGeneration.fiveG),

  /// 5G New Radio, non-standalone: a 5G radio on a 4G core. iOS only.
  ///
  /// Android has no equivalent network type and reports non-standalone 5G as
  /// [lte], so this value never appears in an Android result.
  nrNsa(NetworkGeneration.fiveG);

  const RadioAccessTechnology(this.generation);

  /// The network generation this technology belongs to.
  final NetworkGeneration generation;
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
  cardRestricted,
}

/// Whether the app is allowed to use cellular data.
///
/// On iOS this mirrors `CTCellularData.restrictedState`. Android has no per-app
/// equivalent, so it reflects whether mobile data is enabled for the device.
enum CellularDataState {
  /// The platform has not resolved a state yet, or could not be asked.
  unknown,

  /// Cellular data is unavailable to this app.
  restricted,

  /// Cellular data is available to this app.
  notRestricted,
}
