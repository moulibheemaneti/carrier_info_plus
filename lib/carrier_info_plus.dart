
import 'carrier_info_plus_platform_interface.dart';

class CarrierInfoPlus {
  Future<String?> getPlatformVersion() {
    return CarrierInfoPlusPlatform.instance.getPlatformVersion();
  }
}
