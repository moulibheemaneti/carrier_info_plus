import XCTest

// If your plugin has been explicitly set to "type: .dynamic" in the Package.swift,
// you will need to add your plugin as a dependency of RunnerTests within Xcode.

@testable import carrier_info_plus

/// Covers the decisions `CellularReadings` makes, one device shape per test.
///
/// Each shape is built from readings taken on real hardware where we have
/// them, so these run on the Simulator but describe devices it cannot be.
/// Run from Xcode, or with `xcodebuild test` against the Runner scheme once
/// `flutter build ios --config-only` has generated the workspace.
class RunnerTests: XCTestCase {

  private func readings(
    serviceRadios: [PlatformRadioAccessTechnology] = [],
    supportsCellularPlan: Bool = false,
    subscriberCount: Int = 0,
    isPhone: Bool = false,
    smsCapable: Bool = false,
    cellularDataState: PlatformCellularDataState = .unknown
  ) -> CellularReadings {
    return CellularReadings(
      serviceRadios: serviceRadios,
      supportsCellularPlan: supportsCellularPlan,
      subscriberCount: subscriberCount,
      isPhone: isPhone,
      smsCapable: smsCapable,
      cellularDataState: cellularDataState
    )
  }

  // MARK: - Hardware present, no service

  /// The regression: a real iPhone with no SIM, as measured. No service and
  /// no eSIM provisioning, which 2.0.1 read as no modem at all.
  func testIPhoneWithNoSimHasAModem() {
    let info = readings(
      subscriberCount: 2,
      isPhone: true,
      smsCapable: true,
      cellularDataState: .notRestricted
    ).carrierInfo()

    XCTAssertEqual(info.support.limitation, .platformRemovedApi)
    XCTAssertTrue(info.capabilities.isVoiceCapable)
    XCTAssertTrue(info.capabilities.isDataCapable)
    XCTAssertTrue(info.capabilities.isSmsCapable)
    XCTAssertEqual(info.network.cellularDataState, .notRestricted)
  }

  /// No service does not mean no SIM, so the count is withheld, not zeroed.
  func testNoServiceLeavesSimCountUnknown() {
    let info = readings(subscriberCount: 2, isPhone: true).carrierInfo()

    XCTAssertNil(info.simCount)
    XCTAssertTrue(info.simCards.isEmpty)
    XCTAssertTrue(info.network.radioTechnologies.isEmpty)
    XCTAssertFalse(info.capabilities.isMultiSimSupported)
  }

  /// Being an iPhone is enough on its own, so the fix does not rest on
  /// `CTSubscriberInfo` behaving the same on every iOS release.
  func testIPhoneHasAModemWithoutAnySubscriber() {
    let info = readings(isPhone: true).carrierInfo()

    XCTAssertEqual(info.support.limitation, .platformRemovedApi)
    XCTAssertTrue(info.capabilities.isVoiceCapable)
    XCTAssertTrue(info.capabilities.isDataCapable)
  }

  /// A cellular iPad with no SIM: only the subscriber slot gives the modem
  /// away. It carries data but places no calls.
  func testCellularIPadWithNoSimIsDataOnly() {
    let info = readings(subscriberCount: 1, smsCapable: true).carrierInfo()

    XCTAssertEqual(info.support.limitation, .platformRemovedApi)
    XCTAssertTrue(info.capabilities.isDataCapable)
    XCTAssertFalse(info.capabilities.isVoiceCapable)
  }

  /// Only a carrier's app ever sees eSIM provisioning support, but when it
  /// does, it proves a modem too.
  func testCellularPlanSupportProvesAModem() {
    let info = readings(supportsCellularPlan: true).carrierInfo()

    XCTAssertEqual(info.support.limitation, .platformRemovedApi)
    XCTAssertTrue(info.capabilities.isDataCapable)
    XCTAssertTrue(info.capabilities.supportsEmbeddedSim)
  }

  // MARK: - No hardware

  /// The Simulator, as measured: nothing at all.
  func testSimulatorHasNoModem() {
    let info = readings().carrierInfo()

    XCTAssertEqual(info.support.limitation, .noTelephonyHardware)
    XCTAssertFalse(info.capabilities.isVoiceCapable)
    XCTAssertFalse(info.capabilities.isDataCapable)
    XCTAssertFalse(info.capabilities.isSmsCapable)
    XCTAssertNil(info.simCount)
    XCTAssertEqual(info.network.cellularDataState, .unknown)
  }

  /// A Wi-Fi-only iPad signed into iMessage can send texts. That must not be
  /// mistaken for a modem.
  func testWiFiOnlyIPadHasNoModemEvenWithIMessage() {
    let info = readings(smsCapable: true).carrierInfo()

    XCTAssertEqual(info.support.limitation, .noTelephonyHardware)
    XCTAssertFalse(info.capabilities.isVoiceCapable)
    XCTAssertFalse(info.capabilities.isDataCapable)
    XCTAssertTrue(info.capabilities.isSmsCapable)
  }

  // MARK: - Active service

  func testActiveServiceIsCountedAndReported() {
    let info = readings(
      serviceRadios: [.nrNsa],
      subscriberCount: 2,
      isPhone: true,
      smsCapable: true,
      cellularDataState: .notRestricted
    ).carrierInfo()

    XCTAssertEqual(info.simCount, 1)
    XCTAssertTrue(info.simCards.isEmpty)
    XCTAssertEqual(info.network.radioTechnologies, [.nrNsa])
    XCTAssertEqual(info.support.limitation, .platformRemovedApi)
    XCTAssertFalse(info.capabilities.isMultiSimSupported)
  }

  func testTwoActiveServicesAreMultiSim() {
    let info = readings(serviceRadios: [.lte, .nr], subscriberCount: 2, isPhone: true)
      .carrierInfo()

    XCTAssertEqual(info.simCount, 2)
    XCTAssertTrue(info.capabilities.isMultiSimSupported)
  }

  /// An active service proves a modem even with no other reading, which is
  /// how a cellular iPad on a data plan shows up.
  func testActiveServiceAloneProvesAModem() {
    let info = readings(serviceRadios: [.lte]).carrierInfo()

    XCTAssertEqual(info.support.limitation, .platformRemovedApi)
    XCTAssertTrue(info.capabilities.isDataCapable)
    XCTAssertFalse(info.capabilities.isVoiceCapable)
  }

  // MARK: - Always

  /// Whatever the hardware, iOS identifies no carrier and asks no permission.
  func testCarrierIdentityIsNeverAvailable() {
    for shape in [readings(), readings(isPhone: true), readings(serviceRadios: [.lte])] {
      let support = shape.carrierInfo().support

      XCTAssertFalse(support.carrierIdentityAvailable)
      XCTAssertFalse(support.perSimDataAvailable)
      XCTAssertTrue(support.permissionGranted)
    }
  }
}
