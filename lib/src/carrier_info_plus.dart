import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models/carrier_info.dart';
import 'models/platform_support.dart';

/// Reads the device's cellular carrier, SIM and network state.
///
/// ```dart
/// final info = await CarrierInfoPlus.get();
/// if (info.support.carrierIdentityAvailable) {
///   print(info.primarySim?.carrierName);
/// }
/// print(info.generation); // NetworkGeneration.fiveG
/// ```
///
/// Every call returns a fresh snapshot. Nothing is cached, because SIM and
/// network state change underneath you — re-read after a SIM swap or when
/// returning from the background.
///
/// ## Platform reality
///
/// Android reports the full picture. iOS 16 removed `CTCarrier`, so carrier
/// identity is unavailable there and only radio technology, eSIM support and
/// cellular-data availability remain. Rather than returning blanks with no
/// explanation, every result carries a [PlatformSupport] saying what was
/// answerable — check it before rendering carrier fields.
abstract final class CarrierInfoPlus {
  const CarrierInfoPlus._();

  /// The platform channel. Exposed so tests can install a mock handler.
  @visibleForTesting
  static const MethodChannel channel = MethodChannel('carrier_info_plus');

  /// The snapshot returned on platforms with no cellular support at all.
  static const CarrierInfo _unsupported = CarrierInfo(
    support: PlatformSupport(limitation: DataLimitation.noTelephonyHardware),
  );

  /// Reads a fresh snapshot of the device's cellular state.
  ///
  /// Never throws for the ordinary "this platform cannot answer" cases: an
  /// unsupported platform, a missing permission and a device with no radio all
  /// come back as a populated [CarrierInfo] whose [CarrierInfo.support]
  /// explains the gap. A [PlatformException] still propagates, since that
  /// means the platform side genuinely failed.
  ///
  /// On Android, call this without [requestPermission] first if you like — you
  /// get the permission-free subset (network operator, SIM state, MCC/MNC of
  /// the active SIM) rather than an error.
  static Future<CarrierInfo> get() async {
    try {
      final result = await channel.invokeMapMethod<String, Object?>(
        'getCarrierInfo',
      );
      if (result == null) return _unsupported;
      return CarrierInfo.fromMap(result);
    } on MissingPluginException {
      // Web, desktop, or an app that has not rebuilt since adding the plugin.
      return _unsupported;
    }
  }

  /// Whether `READ_PHONE_STATE` is currently granted.
  ///
  /// Always true on iOS, which needs no permission for what it still exposes.
  static Future<bool> hasPermission() async {
    try {
      return await channel.invokeMethod<bool>('hasPermission') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Requests `READ_PHONE_STATE`, returning whether it ended up granted.
  ///
  /// Shows the system dialog on Android and completes when the user answers.
  /// Returns the current state immediately if the permission is already
  /// granted, or if the user has permanently denied it — Android gives no
  /// dialog in either case.
  ///
  /// Always returns true on iOS. Safe to call on any platform, so you do not
  /// need to guard it behind a platform check.
  ///
  /// If your app already uses `permission_handler`, prefer that so all your
  /// permission prompts flow through one place; this exists so the package
  /// stays usable on its own.
  static Future<bool> requestPermission() async {
    try {
      return await channel.invokeMethod<bool>('requestPermission') ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
