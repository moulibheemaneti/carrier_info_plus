import 'package:carrier_info_plus/carrier_info_plus.dart';
import 'package:carrier_info_plus/carrier_info_plus_method_channel.dart';
import 'package:carrier_info_plus/carrier_info_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCarrierInfoPlusPlatform
    with MockPlatformInterfaceMixin
    implements CarrierInfoPlusPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CarrierInfoPlusPlatform initialPlatform =
      CarrierInfoPlusPlatform.instance;

  test('$MethodChannelCarrierInfoPlus is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCarrierInfoPlus>());
  });

  test('getPlatformVersion', () async {
    CarrierInfoPlus carrierInfoPlusPlugin = CarrierInfoPlus();
    MockCarrierInfoPlusPlatform fakePlatform = MockCarrierInfoPlusPlatform();
    CarrierInfoPlusPlatform.instance = fakePlatform;

    expect(await carrierInfoPlusPlugin.getPlatformVersion(), '42');
  });
}
