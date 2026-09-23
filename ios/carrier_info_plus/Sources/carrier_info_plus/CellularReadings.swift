import Foundation

/// Every raw value one snapshot is derived from.
///
/// `CarrierInfoPlusPlugin` reads these out of CoreTelephony, MessageUI and the
/// kernel; this file decides what they mean. Nothing here touches a framework,
/// so the decisions can be tested by describing a device as plain values — a
/// Simulator, a Wi-Fi-only iPad, an iPhone with no SIM — rather than by owning
/// one of each.
struct CellularReadings {
  /// The radio of each active cellular service, from
  /// `serviceCurrentRadioAccessTechnology`.
  ///
  /// Empty with no SIM, in airplane mode and out of coverage, so on its own it
  /// cannot say whether the device has a modem.
  var serviceRadios: [PlatformRadioAccessTechnology]

  /// `CTCellularPlanProvisioning.supportsCellularPlan()`.
  ///
  /// Apple only returns true to an app holding the carrier entitlement
  /// `com.apple.CommCenter.fine-grained` with `public-cellular-plan`, on a
  /// device whose activation policy allows eSIM installation. Every other app
  /// gets false on every device, eSIM or not.
  var supportsCellularPlan: Bool

  /// How many entries `CTSubscriberInfo.subscribers()` returned.
  ///
  /// These are subscriber slots, not SIMs: an iPhone with no SIM in it has been
  /// observed reporting two, and the Simulator reports none.
  var subscriberCount: Int

  /// Whether the hardware is an iPhone, judged from its model identifier.
  var isPhone: Bool

  /// `MFMessageComposeViewController.canSendText()`.
  ///
  /// Not a sign of a modem: iMessage makes a Wi-Fi-only iPad answer true.
  var smsCapable: Bool

  /// `CTCellularData.restrictedState`, mapped.
  var cellularDataState: PlatformCellularDataState
}

extension CellularReadings {
  /// Whether the device has a cellular modem at all.
  ///
  /// iOS has no API that answers this, so four readings are combined. Each one
  /// can prove a modem exists but none can prove it missing, which is why any
  /// single one is enough:
  ///
  ///  - The device is an iPhone. Every iPhone has a modem, so this holds with
  ///    no SIM, in airplane mode and out of coverage, where the others may not.
  ///  - A cellular service is active.
  ///  - eSIM provisioning is supported, which only a carrier's app ever sees.
  ///  - A subscriber slot exists. This is the one that catches a cellular iPad
  ///    with no SIM in it.
  ///
  /// The Simulator reports none of the four. A Wi-Fi-only iPad has no baseband
  /// to report a service or a slot from, so it should report none either.
  var hasCellularModem: Bool {
    return isPhone || !serviceRadios.isEmpty || supportsCellularPlan || subscriberCount > 0
  }

  /// How many cellular services are active, or nil when none are.
  ///
  /// Nil rather than zero, because no active service does not mean no SIM: a
  /// SIM in airplane mode or out of coverage has no service either, and iOS
  /// gives an ordinary app no way to tell that apart from an empty tray.
  /// Reporting zero would claim more than the platform told us.
  var serviceCount: Int64? {
    return serviceRadios.isEmpty ? nil : Int64(serviceRadios.count)
  }

  func carrierInfo() -> PlatformCarrierInfo {
    let hasModem = hasCellularModem

    return PlatformCarrierInfo(
      // Deliberately empty rather than one all-null entry per service. iOS can
      // count its services without identifying any of them, and simCount is
      // the field that says so. Emitting placeholder SIMs would claim more
      // than the platform told us.
      simCards: [],
      simCount: serviceCount,
      capabilities: PlatformTelephonyCapabilities(
        // Only an iPhone places calls. A cellular iPad has a modem but iOS
        // gives it no cellular voice, and every iPhone has a modem, so this
        // needs no other reading.
        isVoiceCapable: isPhone,
        isSmsCapable: smsCapable,
        isDataCapable: hasModem,
        // iOS exposes no equivalent of Android's mobile-data switch. The
        // nearest signal is per-app rather than device-wide, and it is
        // reported through network.cellularDataState instead.
        isDataEnabled: false,
        // iOS exposes no dual-SIM capability query, only what is active right
        // now, so this is a floor rather than the hardware's true capability:
        // a dual-SIM iPhone with one line active reports false.
        isMultiSimSupported: serviceRadios.count > 1,
        supportsEmbeddedSim: supportsCellularPlan
      ),
      network: PlatformNetworkInfo(
        radioTechnologies: serviceRadios,
        // iOS reports no serving-network identity. Both are Android-only.
        operatorName: nil,
        countryIso: nil,
        cellularDataState: cellularDataState
      ),
      support: PlatformSupportInfo(
        carrierIdentityAvailable: false,
        // Services can be counted, never identified.
        perSimDataAvailable: false,
        // No permission exists to grant.
        permissionGranted: true,
        limitation: hasModem ? .platformRemovedApi : .noTelephonyHardware
      )
    )
  }
}
