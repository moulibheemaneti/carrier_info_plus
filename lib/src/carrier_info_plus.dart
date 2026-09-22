import 'package:flutter/foundation.dart';

import 'mapping.dart';
import 'messages.g.dart';
import 'models/carrier_info.dart';

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
/// Android reports the full picture, given `READ_PHONE_STATE`. iOS 16 removed
/// `CTCarrier`, so carrier identity is unavailable there and only radio
/// technology, eSIM support and cellular-data availability remain. Rather than
/// returning blanks with no explanation, every result carries a
/// [CarrierInfo.support] saying what was answerable — check it before rendering
/// carrier fields.
abstract final class CarrierInfoPlus {
  const CarrierInfoPlus._();

  /// The generated host API.
  ///
  /// Exposed so tests can substitute a fake, which is what pigeon recommends in
  /// place of generated test harnesses. Not part of the supported surface: the
  /// type is generated, and pigeon reserves the right to change it.
  @visibleForTesting
  static CarrierInfoApi api = CarrierInfoApi();

  /// Reads a fresh snapshot of the device's cellular state.
  ///
  /// Never throws for missing data. Anything the platform declined to answer
  /// comes back null, explained by [CarrierInfo.support].
  static Future<CarrierInfo> get() async =>
      carrierInfoFromPigeon(await api.getCarrierInfo());

  /// Whether the permission guarding per-SIM data is currently granted.
  ///
  /// Always true on iOS, which needs no permission for what it still exposes.
  static Future<bool> hasPermission() => api.hasPermission();

  /// Prompts for the permission guarding per-SIM data, returning whether it was
  /// granted.
  ///
  /// Returns true immediately if it was already granted. Only worth calling
  /// when [DataLimitation.isRecoverable] is true — on iOS there is nothing to
  /// ask for.
  static Future<bool> requestPermission() => api.requestPermission();
}
