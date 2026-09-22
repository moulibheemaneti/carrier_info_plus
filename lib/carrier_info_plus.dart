/// Cellular carrier, SIM and network information for Flutter.
///
/// A maintained, 2026-current replacement for the unmaintained `carrier_info`
/// package. See the README for the migration table.
library;

export 'src/carrier_info_plus.dart' show CarrierInfoPlus;
export 'src/models/carrier_info.dart' show CarrierInfo;
export 'src/models/enums.dart'
    show CellularDataState, NetworkGeneration, RadioAccessTechnology, SimState;
export 'src/models/network_info.dart' show NetworkInfo;
export 'src/models/platform_support.dart' show DataLimitation, PlatformSupport;
export 'src/models/sim_card.dart' show SimCard;
export 'src/models/telephony_capabilities.dart' show TelephonyCapabilities;
