import 'package:carrier_info_plus/carrier_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A full Android payload with READ_PHONE_STATE granted and two SIMs.
const Map<String, Object?> _androidDualSim = <String, Object?>{
  'simCards': <Object?>[
    <String, Object?>{
      'subscriptionId': 1,
      'slotIndex': 0,
      'carrierName': 'Airtel',
      'displayName': 'Work',
      'mobileCountryCode': '404',
      'mobileNetworkCode': '10',
      'countryIso': 'in',
      'carrierId': 1234,
      'isEmbedded': false,
      'isRoaming': false,
      'simState': 'ready',
    },
    <String, Object?>{
      'subscriptionId': 2,
      'slotIndex': 1,
      'carrierName': 'Jio',
      'displayName': 'Personal',
      'mobileCountryCode': '405',
      'mobileNetworkCode': '857',
      'countryIso': 'in',
      'carrierId': 5678,
      'isEmbedded': true,
      'isRoaming': true,
      'simState': 'ready',
    },
  ],
  'capabilities': <String, Object?>{
    'isVoiceCapable': true,
    'isSmsCapable': true,
    'isDataCapable': true,
    'isDataEnabled': true,
    'isMultiSimSupported': true,
    'supportsEmbeddedSim': true,
  },
  'network': <String, Object?>{
    'radioTechnologies': <Object?>['lte', 'nr'],
    'operatorName': 'Airtel',
    'countryIso': 'in',
    'cellularDataState': 'notRestricted',
  },
  'support': <String, Object?>{
    'carrierIdentityAvailable': true,
    'perSimDataAvailable': true,
    'permissionGranted': true,
    'limitation': 'none',
  },
};

/// What iOS 16+ returns: one active service, no identity behind it.
const Map<String, Object?> _ios = <String, Object?>{
  'simCards': <Object?>[
    <String, Object?>{
      'subscriptionId': null,
      'slotIndex': null,
      'carrierName': null,
      'displayName': null,
      'mobileCountryCode': null,
      'mobileNetworkCode': null,
      'countryIso': null,
      'carrierId': null,
      'isEmbedded': false,
      'isRoaming': false,
      'simState': 'ready',
    },
  ],
  'capabilities': <String, Object?>{
    'isVoiceCapable': true,
    'isSmsCapable': true,
    'isDataCapable': true,
    'isDataEnabled': false,
    'isMultiSimSupported': false,
    'supportsEmbeddedSim': true,
  },
  'network': <String, Object?>{
    'radioTechnologies': <Object?>['lte'],
    'operatorName': null,
    'countryIso': null,
    'cellularDataState': 'notRestricted',
  },
  'support': <String, Object?>{
    'carrierIdentityAvailable': false,
    'perSimDataAvailable': false,
    'permissionGranted': true,
    'limitation': 'platformRemovedApi',
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mockChannel(Future<Object?>? Function(MethodCall call)? handler) {
    messenger.setMockMethodCallHandler(CarrierInfoPlus.channel, handler);
  }

  tearDown(() => mockChannel(null));

  group('decoding an Android payload', () {
    setUp(() => mockChannel((MethodCall call) async => _androidDualSim));

    test('reads both SIMs in slot order', () async {
      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.simCards, hasLength(2));
      expect(info.isDualSimActive, isTrue);
      expect(info.primarySim?.carrierName, 'Airtel');
      expect(info.simCards[1].carrierName, 'Jio');
      expect(info.simCards[1].isEmbedded, isTrue);
      expect(info.simCards[1].isRoaming, isTrue);
    });

    test('joins MCC and MNC into a PLMN', () async {
      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.primarySim?.plmn, '40410');
      expect(info.simCards[1].plmn, '405857');
    });

    test('parses stringly-typed platform values into enums', () async {
      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.primarySim?.state, SimState.ready);
      expect(info.network.radioTechnologies, <RadioAccessTechnology>[
        RadioAccessTechnology.lte,
        RadioAccessTechnology.nr,
      ]);
      expect(info.network.cellularDataState, CellularDataState.notRestricted);
      expect(info.support.limitation, DataLimitation.none);
    });

    test('reports the fastest generation across active radios', () async {
      final CarrierInfo info = await CarrierInfoPlus.get();

      // LTE and NR are both attached; 5G is the honest answer.
      expect(info.generation, NetworkGeneration.fiveG);
    });

    test('exposes multi-SIM support as a bool', () async {
      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.capabilities.isMultiSimSupported, isTrue);
    });
  });

  group('decoding an iOS payload', () {
    setUp(() => mockChannel((MethodCall call) async => _ios));

    test('keeps the service count while reporting no identity', () async {
      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.hasSim, isTrue);
      expect(info.simCards, hasLength(1));
      expect(info.primarySim?.carrierName, isNull);
      expect(info.primarySim?.hasIdentity, isFalse);
      expect(info.primarySim?.plmn, isNull);
    });

    test('explains the gap as unrecoverable', () async {
      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.support.carrierIdentityAvailable, isFalse);
      expect(info.support.limitation, DataLimitation.platformRemovedApi);
      expect(info.support.limitation.isRecoverable, isFalse);
      expect(info.support.isComplete, isFalse);
    });

    test('still reports the radio', () async {
      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.generation, NetworkGeneration.fourG);
      expect(info.network.isConnected, isTrue);
    });
  });

  group('degrading gracefully', () {
    test('an unsupported platform yields a no-hardware snapshot', () async {
      mockChannel((MethodCall call) async => throw MissingPluginException());

      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.hasSim, isFalse);
      expect(info.support.limitation, DataLimitation.noTelephonyHardware);
      expect(info.generation, NetworkGeneration.unknown);
    });

    test('a null reply yields a no-hardware snapshot', () async {
      mockChannel((MethodCall call) async => null);

      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.support.limitation, DataLimitation.noTelephonyHardware);
    });

    test('a partial payload fills in defaults rather than throwing', () async {
      mockChannel(
        (MethodCall call) async => <String, Object?>{
          'simCards': <Object?>[
            <String, Object?>{'carrierName': 'Vi'},
          ],
        },
      );

      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.primarySim?.carrierName, 'Vi');
      expect(info.primarySim?.state, SimState.unknown);
      expect(info.capabilities.isVoiceCapable, isFalse);
      expect(info.network.radioTechnologies, isEmpty);
    });

    test('an unrecognised enum name falls back instead of throwing', () async {
      mockChannel(
        (MethodCall call) async => <String, Object?>{
          'simCards': <Object?>[
            <String, Object?>{'simState': 'someFutureAndroidState'},
          ],
          'network': <String, Object?>{
            'radioTechnologies': <Object?>['6g'],
          },
        },
      );

      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.primarySim?.state, SimState.unknown);
      expect(info.network.radioTechnologies, <RadioAccessTechnology>[
        RadioAccessTechnology.unknown,
      ]);
    });

    test('empty strings from the platform read as null', () async {
      mockChannel(
        (MethodCall call) async => <String, Object?>{
          'simCards': <Object?>[
            <String, Object?>{'carrierName': '', 'countryIso': ''},
          ],
        },
      );

      final CarrierInfo info = await CarrierInfoPlus.get();

      expect(info.primarySim?.carrierName, isNull);
      expect(info.primarySim?.countryIso, isNull);
    });

    test('a genuine platform failure still propagates', () async {
      mockChannel(
        (MethodCall call) async => throw PlatformException(code: 'boom'),
      );

      expect(CarrierInfoPlus.get(), throwsA(isA<PlatformException>()));
    });
  });

  group('permissions', () {
    test('hasPermission forwards the platform answer', () async {
      mockChannel((MethodCall call) async => call.method == 'hasPermission');

      expect(await CarrierInfoPlus.hasPermission(), isTrue);
    });

    test('requestPermission is safe on platforms without the plugin', () async {
      mockChannel((MethodCall call) async => throw MissingPluginException());

      expect(await CarrierInfoPlus.requestPermission(), isFalse);
      expect(await CarrierInfoPlus.hasPermission(), isFalse);
    });
  });

  group('value semantics', () {
    test('identical payloads compare equal', () async {
      mockChannel((MethodCall call) async => _androidDualSim);
      final CarrierInfo first = await CarrierInfoPlus.get();
      final CarrierInfo second = await CarrierInfoPlus.get();

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
    });

    test('a changed SIM breaks equality', () {
      const SimCard a = SimCard(carrierName: 'Airtel', slotIndex: 0);
      const SimCard b = SimCard(carrierName: 'Jio', slotIndex: 0);

      expect(a, isNot(equals(b)));
    });
  });

  group('generation mapping', () {
    test('each radio maps to the right generation', () {
      expect(RadioAccessTechnology.edge.generation, NetworkGeneration.twoG);
      expect(RadioAccessTechnology.hsdpa.generation, NetworkGeneration.threeG);
      expect(RadioAccessTechnology.lte.generation, NetworkGeneration.fourG);
      expect(RadioAccessTechnology.nr.generation, NetworkGeneration.fiveG);
    });

    test('Wi-Fi calling is not a cellular generation', () {
      expect(RadioAccessTechnology.iwlan.generation, NetworkGeneration.unknown);
    });

    test('no radios means unknown, not 2G', () {
      const NetworkInfo empty = NetworkInfo();

      expect(empty.generation, NetworkGeneration.unknown);
      expect(empty.isConnected, isFalse);
    });
  });
}
