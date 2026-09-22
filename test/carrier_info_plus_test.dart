import 'package:carrier_info_plus/carrier_info_plus.dart';
import 'package:carrier_info_plus/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for the generated host API.
///
/// Pigeon recommends faking the generated Dart API rather than generating a
/// test harness, so the tests below exercise the real mapping layer against
/// payloads a platform could plausibly send.
class _FakeCarrierInfoApi extends CarrierInfoApi {
  _FakeCarrierInfoApi(this.info);

  final PlatformCarrierInfo info;
  bool granted = false;
  int requestCount = 0;

  @override
  Future<PlatformCarrierInfo> getCarrierInfo() async => info;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<bool> requestPermission() async {
    requestCount++;
    granted = true;
    return true;
  }
}

PlatformSimCard _sim({
  required int slot,
  String? carrier,
  String? mcc,
  String? mnc,
  bool defaultData = false,
  bool defaultVoice = false,
  PlatformSimState state = PlatformSimState.ready,
}) => PlatformSimCard(
  isEmbedded: false,
  isRoaming: false,
  simState: state,
  isDefaultData: defaultData,
  isDefaultVoice: defaultVoice,
  subscriptionId: slot + 1,
  slotIndex: slot,
  carrierName: carrier,
  mobileCountryCode: mcc,
  mobileNetworkCode: mnc,
);

PlatformCarrierInfo _payload({
  List<PlatformSimCard> sims = const <PlatformSimCard>[],
  List<PlatformRadioAccessTechnology> radios =
      const <PlatformRadioAccessTechnology>[],
  PlatformDataLimitation limitation = PlatformDataLimitation.none,
  bool perSim = true,
  int? simCount,
}) => PlatformCarrierInfo(
  simCards: sims,
  capabilities: PlatformTelephonyCapabilities(
    isVoiceCapable: true,
    isSmsCapable: true,
    isDataCapable: true,
    isDataEnabled: true,
    isMultiSimSupported: true,
    supportsEmbeddedSim: true,
  ),
  network: PlatformNetworkInfo(
    radioTechnologies: radios,
    cellularDataState: PlatformCellularDataState.notRestricted,
    operatorName: 'Test Operator',
    countryIso: 'in',
  ),
  support: PlatformSupportInfo(
    carrierIdentityAvailable: true,
    perSimDataAvailable: perSim,
    permissionGranted: perSim,
    limitation: limitation,
  ),
  simCount: simCount,
);

void main() {
  tearDown(() => CarrierInfoPlus.api = CarrierInfoApi());

  group('mapping', () {
    test('carries SIM identity across the boundary', () async {
      CarrierInfoPlus.api = _FakeCarrierInfoApi(
        _payload(
          sims: <PlatformSimCard>[
            _sim(slot: 0, carrier: 'Airtel', mcc: '404', mnc: '10'),
          ],
          simCount: 1,
        ),
      );

      final info = await CarrierInfoPlus.get();

      expect(info.simCards, hasLength(1));
      expect(info.primarySim?.carrierName, 'Airtel');
      expect(info.primarySim?.plmn, '40410');
      expect(info.primarySim?.hasIdentity, isTrue);
      expect(info.primarySim?.state, SimState.ready);
      expect(info.network.operatorName, 'Test Operator');
      expect(info.support.isComplete, isTrue);
    });

    test(
      'maps an unpopulated SIM to no identity rather than empty strings',
      () async {
        CarrierInfoPlus.api = _FakeCarrierInfoApi(
          _payload(sims: <PlatformSimCard>[_sim(slot: 0)]),
        );

        final info = await CarrierInfoPlus.get();

        expect(info.primarySim?.hasIdentity, isFalse);
        expect(info.primarySim?.plmn, isNull);
      },
    );
  });

  group('primarySim', () {
    test('is the default data SIM, not simply the first', () async {
      // The regression this field exists for: on a dual-SIM device running
      // data on slot two, "the first SIM" names the wrong carrier.
      CarrierInfoPlus.api = _FakeCarrierInfoApi(
        _payload(
          sims: <PlatformSimCard>[
            _sim(slot: 0, carrier: 'Slot One', defaultVoice: true),
            _sim(slot: 1, carrier: 'Slot Two', defaultData: true),
          ],
          simCount: 2,
        ),
      );

      final info = await CarrierInfoPlus.get();

      expect(info.primarySim?.carrierName, 'Slot Two');
      expect(info.voiceSim?.carrierName, 'Slot One');
    });

    test('falls back to the first SIM when no default is flagged', () async {
      // iOS reports no default line, so the first entry is the best answer.
      CarrierInfoPlus.api = _FakeCarrierInfoApi(
        _payload(
          sims: <PlatformSimCard>[
            _sim(slot: 0, carrier: 'Only One'),
            _sim(slot: 1, carrier: 'Second'),
          ],
        ),
      );

      final info = await CarrierInfoPlus.get();

      expect(info.primarySim?.carrierName, 'Only One');
      expect(info.voiceSim, isNull);
    });

    test('is null when no SIM was described', () async {
      CarrierInfoPlus.api = _FakeCarrierInfoApi(_payload());

      final info = await CarrierInfoPlus.get();

      expect(info.primarySim, isNull);
      expect(info.hasSim, isFalse);
    });
  });

  group('simCount', () {
    test('drives isDualSimActive when SIMs cannot be described', () async {
      // The iOS 16 shape: the platform can count its cellular services without
      // saying anything about them.
      CarrierInfoPlus.api = _FakeCarrierInfoApi(
        _payload(simCount: 2, perSim: false),
      );

      final info = await CarrierInfoPlus.get();

      expect(info.simCards, isEmpty);
      expect(info.simCount, 2);
      expect(info.hasSim, isTrue);
      expect(info.isDualSimActive, isTrue);
    });

    test(
      'falls back to the list length when the platform will not say',
      () async {
        CarrierInfoPlus.api = _FakeCarrierInfoApi(
          _payload(sims: <PlatformSimCard>[_sim(slot: 0), _sim(slot: 1)]),
        );

        final info = await CarrierInfoPlus.get();

        expect(info.simCount, isNull);
        expect(info.isDualSimActive, isTrue);
      },
    );
  });

  group('network generation', () {
    test('reports the fastest radio attached', () async {
      CarrierInfoPlus.api = _FakeCarrierInfoApi(
        _payload(
          radios: <PlatformRadioAccessTechnology>[
            PlatformRadioAccessTechnology.lte,
            PlatformRadioAccessTechnology.nr,
          ],
        ),
      );

      final info = await CarrierInfoPlus.get();

      expect(info.generation, NetworkGeneration.fiveG);
      expect(info.network.isConnected, isTrue);
    });

    test('treats Wi-Fi calling as no cellular generation', () async {
      // iwlan is carried over the cellular stack but is not a cellular radio,
      // so calling it 4G would misreport the connection.
      CarrierInfoPlus.api = _FakeCarrierInfoApi(
        _payload(
          radios: <PlatformRadioAccessTechnology>[
            PlatformRadioAccessTechnology.iwlan,
          ],
        ),
      );

      final info = await CarrierInfoPlus.get();

      expect(info.generation, NetworkGeneration.unknown);
    });

    test('maps non-standalone 5G to fiveG', () async {
      CarrierInfoPlus.api = _FakeCarrierInfoApi(
        _payload(
          radios: <PlatformRadioAccessTechnology>[
            PlatformRadioAccessTechnology.nrNsa,
          ],
        ),
      );

      final info = await CarrierInfoPlus.get();

      expect(
        info.network.radioTechnologies.single,
        RadioAccessTechnology.nrNsa,
      );
      expect(info.generation, NetworkGeneration.fiveG);
    });
  });

  group('support', () {
    test('marks a missing permission as recoverable', () async {
      CarrierInfoPlus.api = _FakeCarrierInfoApi(
        _payload(
          limitation: PlatformDataLimitation.permissionNotGranted,
          perSim: false,
        ),
      );

      final info = await CarrierInfoPlus.get();

      expect(info.support.limitation, DataLimitation.permissionNotGranted);
      expect(info.support.limitation.isRecoverable, isTrue);
      expect(info.support.perSimDataAvailable, isFalse);
      expect(info.support.isComplete, isFalse);
    });

    test('marks a removed platform API as not recoverable', () async {
      CarrierInfoPlus.api = _FakeCarrierInfoApi(
        _payload(limitation: PlatformDataLimitation.platformRemovedApi),
      );

      final info = await CarrierInfoPlus.get();

      expect(info.support.limitation.isRecoverable, isFalse);
      expect(info.support.limitation.explanation, contains('CTCarrier'));
    });
  });

  group('permission', () {
    test('requestPermission delegates to the host once', () async {
      final api = _FakeCarrierInfoApi(_payload());
      CarrierInfoPlus.api = api;

      expect(await CarrierInfoPlus.hasPermission(), isFalse);
      expect(await CarrierInfoPlus.requestPermission(), isTrue);
      expect(await CarrierInfoPlus.hasPermission(), isTrue);
      expect(api.requestCount, 1);
    });
  });

  group('value semantics', () {
    test('equal payloads produce equal models', () async {
      CarrierInfoPlus.api = _FakeCarrierInfoApi(
        _payload(sims: <PlatformSimCard>[_sim(slot: 0, carrier: 'A')]),
      );
      final first = await CarrierInfoPlus.get();
      final second = await CarrierInfoPlus.get();

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
    });
  });
}
