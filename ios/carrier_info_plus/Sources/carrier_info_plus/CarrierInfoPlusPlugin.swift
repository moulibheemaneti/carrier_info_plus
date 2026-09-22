import CoreTelephony
import Flutter
import MessageUI
import UIKit

/// Reads what CoreTelephony still exposes on modern iOS.
///
/// Apple deprecated `CTCarrier` in iOS 16: carrier name, MCC, MNC and ISO
/// country now return placeholders or nil for every app. This plugin does not
/// ship a deprecated fallback for iOS 13-15 — it reports carrier identity as
/// unavailable on all iOS versions, so behaviour does not silently change
/// under users as they update, and the package stays free of deprecated API
/// warnings that would eventually break the build.
///
/// What remains genuinely readable: radio access technology per active
/// service, eSIM provisioning support, SMS capability and whether this app may
/// use cellular data.
public class CarrierInfoPlusPlugin: NSObject, FlutterPlugin {

  private let networkInfo = CTTelephonyNetworkInfo()
  private let cellularData = CTCellularData()
  private let planProvisioning = CTCellularPlanProvisioning()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "carrier_info_plus",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(CarrierInfoPlusPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCarrierInfo":
      result(collect())
    case "hasPermission", "requestPermission":
      // iOS requires no permission for anything this plugin still reads.
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Collection

  private func collect() -> [String: Any] {
    let radios = radioTechnologies()
    let supportsESim = planProvisioning.supportsCellularPlan()
    // No API reports "does this device have a cellular modem". An active radio
    // or eSIM provisioning support is the closest reliable proxy: a cellular
    // iPhone in airplane mode still reports eSIM support, while a Wi-Fi-only
    // iPad reports neither.
    let hasCellularHardware = !radios.isEmpty || supportsESim

    // Assembled piece by piece rather than as one literal: Swift's type
    // checker copes badly with large heterogeneous dictionary literals, and
    // this keeps each value's type obvious.
    var payload: [String: Any] = [:]
    payload["simCards"] = simCards(serviceCount: radios.count)
    payload["capabilities"] = capabilities(
      hasCellularHardware: hasCellularHardware,
      supportsESim: supportsESim,
      serviceCount: radios.count
    )
    payload["network"] = network(radios: radios)
    payload["support"] = support(hasCellularHardware: hasCellularHardware)
    return payload
  }

  private func capabilities(
    hasCellularHardware: Bool,
    supportsESim: Bool,
    serviceCount: Int
  ) -> [String: Bool] {
    return [
      "isVoiceCapable": hasCellularHardware,
      "isSmsCapable": MFMessageComposeViewController.canSendText(),
      "isDataCapable": hasCellularHardware,
      // iOS exposes no equivalent of Android's mobile-data switch.
      "isDataEnabled": false,
      // iOS exposes no dual-SIM capability query, only what is active now, so
      // this is a floor rather than the hardware's true capability.
      "isMultiSimSupported": serviceCount > 1,
      "supportsEmbeddedSim": supportsESim,
    ]
  }

  private func network(radios: [String]) -> [String: Any] {
    var result: [String: Any] = [:]
    result["radioTechnologies"] = radios
    // iOS reports no serving-network identity; both are Android-only.
    result["operatorName"] = NSNull()
    result["countryIso"] = NSNull()
    result["cellularDataState"] = cellularDataState()
    return result
  }

  private func support(hasCellularHardware: Bool) -> [String: Any] {
    var result: [String: Any] = [:]
    result["carrierIdentityAvailable"] = false
    result["perSimDataAvailable"] = false
    result["permissionGranted"] = true
    result["limitation"] =
      hasCellularHardware ? "platformRemovedApi" : "noTelephonyHardware"
    return result
  }

  /// One placeholder entry per active cellular service.
  ///
  /// iOS cannot identify the SIM behind a service, so every identity field is
  /// null. The count is still real, which keeps `simCards.length` and `hasSim`
  /// meaningful across platforms; `support.carrierIdentityAvailable` is false
  /// to explain the nulls.
  private func simCards(serviceCount: Int) -> [[String: Any]] {
    guard serviceCount > 0 else { return [] }
    return (0..<serviceCount).map { _ -> [String: Any] in
      var sim: [String: Any] = [:]
      for key in [
        "subscriptionId", "slotIndex", "carrierName", "displayName",
        "mobileCountryCode", "mobileNetworkCode", "countryIso", "carrierId",
      ] {
        sim[key] = NSNull()
      }
      sim["isEmbedded"] = false
      sim["isRoaming"] = false
      // An attached radio implies a usable SIM behind it.
      sim["simState"] = "ready"
      return sim
    }
  }

  private func radioTechnologies() -> [String] {
    guard let current = networkInfo.serviceCurrentRadioAccessTechnology else {
      return []
    }
    return current.values.map { mapRadio($0) }
  }

  /// Whether this app may use cellular data.
  ///
  /// `restrictedState` is populated asynchronously, so the first call after
  /// launch can legitimately return unknown. Re-read if you need certainty.
  private func cellularDataState() -> String {
    switch cellularData.restrictedState {
    case .notRestricted:
      return "notRestricted"
    case .restricted:
      return "restricted"
    case .restrictedStateUnknown:
      return "unknown"
    @unknown default:
      return "unknown"
    }
  }

  // MARK: - Mapping

  private func mapRadio(_ value: String) -> String {
    if #available(iOS 14.1, *) {
      if value == CTRadioAccessTechnologyNR || value == CTRadioAccessTechnologyNRNSA {
        return "nr"
      }
    }
    switch value {
    case CTRadioAccessTechnologyGPRS: return "gprs"
    case CTRadioAccessTechnologyEdge: return "edge"
    case CTRadioAccessTechnologyWCDMA: return "umts"
    case CTRadioAccessTechnologyHSDPA: return "hsdpa"
    case CTRadioAccessTechnologyHSUPA: return "hsupa"
    case CTRadioAccessTechnologyCDMA1x: return "oneXrtt"
    case CTRadioAccessTechnologyCDMAEVDORev0: return "evdo0"
    case CTRadioAccessTechnologyCDMAEVDORevA: return "evdoA"
    case CTRadioAccessTechnologyCDMAEVDORevB: return "evdoB"
    case CTRadioAccessTechnologyeHRPD: return "ehrpd"
    case CTRadioAccessTechnologyLTE: return "lte"
    default: return "unknown"
    }
  }
}
