// The one place generated types are converted into public ones.
//
// Kept out of the models deliberately. Pigeon's documentation is explicit that
// generated code should not appear in a public API, and a `fromPigeon` factory
// on an exported model is exactly that: its signature names a generated type,
// so anyone importing the package sees it. Confining the conversion here keeps
// `lib/src/models/` free of any dependency on `messages.g.dart`, which also
// means the models can be constructed and tested without it.

import 'messages.g.dart';
import 'models/carrier_info.dart';
import 'models/enums.dart';
import 'models/network_info.dart';
import 'models/platform_support.dart';
import 'models/sim_card.dart';
import 'models/telephony_capabilities.dart';

/// Converts a platform snapshot into the public model.
CarrierInfo carrierInfoFromPigeon(PlatformCarrierInfo message) => CarrierInfo(
  simCards: message.simCards.map(_simCardFromPigeon).toList(growable: false),
  capabilities: _capabilitiesFromPigeon(message.capabilities),
  network: _networkFromPigeon(message.network),
  support: _supportFromPigeon(message.support),
  simCount: message.simCount,
);

SimCard _simCardFromPigeon(PlatformSimCard message) => SimCard(
  subscriptionId: message.subscriptionId,
  slotIndex: message.slotIndex,
  carrierName: message.carrierName,
  displayName: message.displayName,
  mobileCountryCode: message.mobileCountryCode,
  mobileNetworkCode: message.mobileNetworkCode,
  countryIso: message.countryIso,
  carrierId: message.carrierId,
  isEmbedded: message.isEmbedded,
  isRoaming: message.isRoaming,
  isDefaultData: message.isDefaultData,
  isDefaultVoice: message.isDefaultVoice,
  state: _simStateFromPigeon(message.simState),
);

TelephonyCapabilities _capabilitiesFromPigeon(
  PlatformTelephonyCapabilities message,
) => TelephonyCapabilities(
  isVoiceCapable: message.isVoiceCapable,
  isSmsCapable: message.isSmsCapable,
  isDataCapable: message.isDataCapable,
  isDataEnabled: message.isDataEnabled,
  isMultiSimSupported: message.isMultiSimSupported,
  supportsEmbeddedSim: message.supportsEmbeddedSim,
);

NetworkInfo _networkFromPigeon(PlatformNetworkInfo message) => NetworkInfo(
  radioTechnologies: message.radioTechnologies
      .map(_radioFromPigeon)
      .toList(growable: false),
  operatorName: message.operatorName,
  countryIso: message.countryIso,
  cellularDataState: _dataStateFromPigeon(message.cellularDataState),
);

PlatformSupport _supportFromPigeon(PlatformSupportInfo message) =>
    PlatformSupport(
      carrierIdentityAvailable: message.carrierIdentityAvailable,
      perSimDataAvailable: message.perSimDataAvailable,
      permissionGranted: message.permissionGranted,
      limitation: _limitationFromPigeon(message.limitation),
    );

// Every enum switch below is exhaustive on purpose: adding a value to the
// pigeon contract breaks compilation here rather than silently degrading to
// `unknown` on a user's device.

SimState _simStateFromPigeon(PlatformSimState value) => switch (value) {
  PlatformSimState.unknown => SimState.unknown,
  PlatformSimState.absent => SimState.absent,
  PlatformSimState.pinRequired => SimState.pinRequired,
  PlatformSimState.pukRequired => SimState.pukRequired,
  PlatformSimState.networkLocked => SimState.networkLocked,
  PlatformSimState.ready => SimState.ready,
  PlatformSimState.notReady => SimState.notReady,
  PlatformSimState.permanentlyDisabled => SimState.permanentlyDisabled,
  PlatformSimState.cardIoError => SimState.cardIoError,
  PlatformSimState.cardRestricted => SimState.cardRestricted,
};

RadioAccessTechnology _radioFromPigeon(PlatformRadioAccessTechnology value) =>
    switch (value) {
      PlatformRadioAccessTechnology.unknown => RadioAccessTechnology.unknown,
      PlatformRadioAccessTechnology.gprs => RadioAccessTechnology.gprs,
      PlatformRadioAccessTechnology.edge => RadioAccessTechnology.edge,
      PlatformRadioAccessTechnology.gsm => RadioAccessTechnology.gsm,
      PlatformRadioAccessTechnology.oneXrtt => RadioAccessTechnology.oneXrtt,
      PlatformRadioAccessTechnology.cdma => RadioAccessTechnology.cdma,
      PlatformRadioAccessTechnology.iden => RadioAccessTechnology.iden,
      PlatformRadioAccessTechnology.umts => RadioAccessTechnology.umts,
      PlatformRadioAccessTechnology.hsdpa => RadioAccessTechnology.hsdpa,
      PlatformRadioAccessTechnology.hsupa => RadioAccessTechnology.hsupa,
      PlatformRadioAccessTechnology.hspa => RadioAccessTechnology.hspa,
      PlatformRadioAccessTechnology.hspap => RadioAccessTechnology.hspap,
      PlatformRadioAccessTechnology.evdo0 => RadioAccessTechnology.evdo0,
      PlatformRadioAccessTechnology.evdoA => RadioAccessTechnology.evdoA,
      PlatformRadioAccessTechnology.evdoB => RadioAccessTechnology.evdoB,
      PlatformRadioAccessTechnology.ehrpd => RadioAccessTechnology.ehrpd,
      PlatformRadioAccessTechnology.tdScdma => RadioAccessTechnology.tdScdma,
      PlatformRadioAccessTechnology.lte => RadioAccessTechnology.lte,
      PlatformRadioAccessTechnology.iwlan => RadioAccessTechnology.iwlan,
      PlatformRadioAccessTechnology.nr => RadioAccessTechnology.nr,
      PlatformRadioAccessTechnology.nrNsa => RadioAccessTechnology.nrNsa,
    };

CellularDataState _dataStateFromPigeon(PlatformCellularDataState value) =>
    switch (value) {
      PlatformCellularDataState.unknown => CellularDataState.unknown,
      PlatformCellularDataState.restricted => CellularDataState.restricted,
      PlatformCellularDataState.notRestricted =>
        CellularDataState.notRestricted,
    };

DataLimitation _limitationFromPigeon(PlatformDataLimitation value) =>
    switch (value) {
      PlatformDataLimitation.none => DataLimitation.none,
      PlatformDataLimitation.permissionNotGranted =>
        DataLimitation.permissionNotGranted,
      PlatformDataLimitation.platformRemovedApi =>
        DataLimitation.platformRemovedApi,
      PlatformDataLimitation.noTelephonyHardware =>
        DataLimitation.noTelephonyHardware,
    };
