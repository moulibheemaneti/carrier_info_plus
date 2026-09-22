import CoreTelephony
import Flutter
import MessageUI
import UIKit

/// Reads what CoreTelephony still exposes on modern iOS.
///
/// Apple deprecated `CTCarrier` in iOS 16: carrier name, MCC, MNC and ISO
/// country now return placeholders or nil for every app, however well written.
/// This plugin ships no deprecated fallback for older iOS — it reports carrier
/// identity as unavailable on every iOS version, so behaviour does not silently
/// change under users as they update, and the package stays free of deprecated
/// API warnings that would eventually break the build.
///
/// What remains genuinely readable: the radio access technology of each active
/// service, how many services there are, eSIM provisioning support, SMS
/// capability, and whether this app may use cellular data.
///
/// ## Threading
///
/// `getCarrierInfo` is bound to a background task queue, so everything it
/// touches must be safe off the main thread. CoreTelephony is; UIKit is not,
/// which is why SMS capability is sampled once during registration rather than
/// read on demand.
public class CarrierInfoPlusPlugin: NSObject, FlutterPlugin, CarrierInfoApi {

  private let networkInfo = CTTelephonyNetworkInfo()
  private let cellularData = CTCellularData()
  private let planProvisioning = CTCellularPlanProvisioning()

  /// Sampled on the main thread at registration.
  ///
  /// `MFMessageComposeViewController` is a UIViewController subclass, and
  /// `getCarrierInfo` runs on a background queue, so reading it there would be
  /// a main-thread violation. The answer is a device capability and does not
  /// change while the app runs, so sampling it once is not a compromise.
  private let smsCapable: Bool

  // Internal rather than private: narrowing the access level of an override
  // of NSObject.init() is the kind of thing that differs between Swift
  // versions, and internal already stops anything outside this module
  // constructing the plugin.
  override init() {
    smsCapable = MFMessageComposeViewController.canSendText()
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = CarrierInfoPlusPlugin()
    CarrierInfoApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    registrar.publish(instance)
  }

  // MARK: - Permission

  /// iOS requires no permission for anything this plugin still reads.
  func hasPermission() throws -> Bool {
    return true
  }

  /// Nothing to ask for, so this succeeds without prompting.
  func requestPermission() async throws -> Bool {
    return true
  }

  // MARK: - Reading

  func getCarrierInfo() throws -> PlatformCarrierInfo {
    // One entry per active cellular service. The keys identify services, not
    // SIMs — iOS will not say which SIM is behind one — so the count is all
    // that can be salvaged from this dictionary beyond the radio itself.
    let services = networkInfo.serviceCurrentRadioAccessTechnology ?? [:]
    let radios = services.values.map(Self.mapRadio)
    let supportsESim = planProvisioning.supportsCellularPlan()

    // No API reports "does this device have a cellular modem". An active radio
    // or eSIM provisioning support is the closest reliable proxy: a cellular
    // iPhone in airplane mode still reports eSIM support, while a Wi-Fi-only
    // iPad and the Simulator report neither.
    let hasCellularHardware = !services.isEmpty || supportsESim

    return PlatformCarrierInfo(
      // Deliberately empty rather than one all-null entry per service. iOS can
      // count its services without identifying any of them, and simCount is
      // the field that says so. Emitting placeholder SIMs would claim more
      // than the platform told us.
      simCards: [],
      simCount: hasCellularHardware ? Int64(services.count) : nil,
      capabilities: capabilities(
        hasCellularHardware: hasCellularHardware,
        supportsESim: supportsESim,
        serviceCount: services.count
      ),
      network: network(radios: radios),
      support: support(hasCellularHardware: hasCellularHardware)
    )
  }

  private func capabilities(
    hasCellularHardware: Bool,
    supportsESim: Bool,
    serviceCount: Int
  ) -> PlatformTelephonyCapabilities {
    return PlatformTelephonyCapabilities(
      isVoiceCapable: hasCellularHardware,
      isSmsCapable: smsCapable,
      isDataCapable: hasCellularHardware,
      // iOS exposes no equivalent of Android's mobile-data switch. The nearest
      // signal is per-app rather than device-wide, and it is reported through
      // network.cellularDataState instead.
      isDataEnabled: false,
      // iOS exposes no dual-SIM capability query, only what is active right
      // now, so this is a floor rather than the hardware's true capability: a
      // dual-SIM iPhone with one line active reports false.
      isMultiSimSupported: serviceCount > 1,
      supportsEmbeddedSim: supportsESim
    )
  }

  private func network(radios: [PlatformRadioAccessTechnology]) -> PlatformNetworkInfo {
    return PlatformNetworkInfo(
      radioTechnologies: radios,
      // iOS reports no serving-network identity. Both are Android-only.
      operatorName: nil,
      countryIso: nil,
      cellularDataState: cellularDataState()
    )
  }

  private func support(hasCellularHardware: Bool) -> PlatformSupportInfo {
    return PlatformSupportInfo(
      carrierIdentityAvailable: false,
      // Services can be counted, never identified.
      perSimDataAvailable: false,
      // No permission exists to grant.
      permissionGranted: true,
      limitation: hasCellularHardware ? .platformRemovedApi : .noTelephonyHardware
    )
  }

  /// Whether this app may use cellular data.
  ///
  /// `restrictedState` is populated asynchronously, so the first call after
  /// launch can legitimately return unknown. Re-read if you need certainty.
  private func cellularDataState() -> PlatformCellularDataState {
    switch cellularData.restrictedState {
    case .notRestricted:
      return .notRestricted
    case .restricted:
      return .restricted
    case .restrictedStateUnknown:
      return .unknown
    @unknown default:
      return .unknown
    }
  }

  // MARK: - Mapping

  /// Maps a `CTRadioAccessTechnology*` constant.
  ///
  /// `NRNSA` maps to its own value rather than collapsing into `nr`, because
  /// non-standalone 5G is a 5G radio on a 4G core and iOS is the only platform
  /// that names the distinction — Android reports the same situation as LTE.
  /// Losing it here would throw away the only place it is observable.
  ///
  /// The technologies with no constant on this platform — GSM, CDMA, iDEN,
  /// HSPA, HSPA+, TD-SCDMA and Wi-Fi calling — simply never appear.
  private static func mapRadio(_ value: String) -> PlatformRadioAccessTechnology {
    switch value {
    case CTRadioAccessTechnologyGPRS: return .gprs
    case CTRadioAccessTechnologyEdge: return .edge
    case CTRadioAccessTechnologyWCDMA: return .umts
    case CTRadioAccessTechnologyHSDPA: return .hsdpa
    case CTRadioAccessTechnologyHSUPA: return .hsupa
    case CTRadioAccessTechnologyCDMA1x: return .oneXrtt
    case CTRadioAccessTechnologyCDMAEVDORev0: return .evdo0
    case CTRadioAccessTechnologyCDMAEVDORevA: return .evdoA
    case CTRadioAccessTechnologyCDMAEVDORevB: return .evdoB
    case CTRadioAccessTechnologyeHRPD: return .ehrpd
    case CTRadioAccessTechnologyLTE: return .lte
    case CTRadioAccessTechnologyNR: return .nr
    case CTRadioAccessTechnologyNRNSA: return .nrNsa
    default: return .unknown
    }
  }
}
