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
/// service, how many services there are, whether the device has a modem at
/// all, SMS capability, and whether this app may use cellular data. eSIM
/// provisioning support is readable too, but only by a carrier's app.
///
/// This class only takes readings. What they mean is decided in
/// `CellularReadings`, which touches no framework and so can be unit tested.
///
/// ## Threading
///
/// `getCarrierInfo` is bound to a background task queue, so everything it
/// touches must be safe off the main thread. The CoreTelephony reads it makes
/// are; UIKit is not, which is why SMS capability is sampled once during
/// registration rather than read on demand. Subscriber slots are sampled there
/// too, for a different reason: see `subscriberCount`.
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

  /// How many subscriber slots CoreTelephony reports, sampled at registration.
  ///
  /// Only used to decide whether the device has a modem, which cannot change
  /// while the app runs. Apple documents no threading guarantee for
  /// `CTSubscriberInfo` either way, so it is read here on the main thread
  /// rather than trusted on the background queue.
  private let subscriberCount: Int

  /// Whether this hardware is an iPhone. Fixed for the life of the process.
  private let isPhone: Bool

  // Internal rather than private: narrowing the access level of an override
  // of NSObject.init() is the kind of thing that differs between Swift
  // versions, and internal already stops anything outside this module
  // constructing the plugin.
  override init() {
    smsCapable = MFMessageComposeViewController.canSendText()
    subscriberCount = CTSubscriberInfo.subscribers().count
    isPhone = CarrierInfoPlusPlugin.hardwareModel().hasPrefix("iPhone")
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
    return readings().carrierInfo()
  }

  private func readings() -> CellularReadings {
    // One entry per active cellular service. The keys identify services, not
    // SIMs — iOS will not say which SIM is behind one — so the count is all
    // that can be salvaged from this dictionary beyond the radio itself.
    let services = networkInfo.serviceCurrentRadioAccessTechnology ?? [:]

    return CellularReadings(
      serviceRadios: services.values.map(Self.mapRadio),
      supportsCellularPlan: planProvisioning.supportsCellularPlan(),
      subscriberCount: subscriberCount,
      isPhone: isPhone,
      smsCapable: smsCapable,
      cellularDataState: cellularDataState()
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

  /// The hardware model identifier, such as "iPhone15,2" or "iPad13,1".
  ///
  /// Read from the kernel rather than from `UIDevice`, whose interface idiom
  /// reports a phone when an iPhone-only app runs on an iPad. On the Simulator
  /// this is the host's architecture instead, which is the right answer here:
  /// the Simulator has no modem either.
  private static func hardwareModel() -> String {
    var info = utsname()
    uname(&info)
    return withUnsafeBytes(of: &info.machine) { bytes in
      String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
    }
  }
}
