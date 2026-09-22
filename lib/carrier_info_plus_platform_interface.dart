import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'carrier_info_plus_method_channel.dart';

abstract class CarrierInfoPlusPlatform extends PlatformInterface {
  /// Constructs a CarrierInfoPlusPlatform.
  CarrierInfoPlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static CarrierInfoPlusPlatform _instance = MethodChannelCarrierInfoPlus();

  /// The default instance of [CarrierInfoPlusPlatform] to use.
  ///
  /// Defaults to [MethodChannelCarrierInfoPlus].
  static CarrierInfoPlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CarrierInfoPlusPlatform] when
  /// they register themselves.
  static set instance(CarrierInfoPlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
