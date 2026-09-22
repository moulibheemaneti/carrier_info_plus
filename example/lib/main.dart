// A live reference for everything carrier_info_plus exposes.
//
// Every public field, getter and enum in the package appears on this screen,
// so the example doubles as a way to see what a given device actually answers
// rather than what the API merely offers.

import 'dart:async';

import 'package:carrier_info_plus/carrier_info_plus.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CarrierInfoApp());
}

/// The example application.
class CarrierInfoApp extends StatelessWidget {
  /// Creates a [CarrierInfoApp].
  const CarrierInfoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'carrier_info_plus',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: const CarrierInfoPage(),
  );
}

/// Reads a snapshot and renders the whole public API against it.
class CarrierInfoPage extends StatefulWidget {
  /// Creates a [CarrierInfoPage].
  const CarrierInfoPage({super.key});

  @override
  State<CarrierInfoPage> createState() => _CarrierInfoPageState();
}

class _CarrierInfoPageState extends State<CarrierInfoPage> {
  CarrierInfo? _info;
  bool? _permission;
  Object? _error;
  DateTime? _readAt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Both public read APIs, called side by side so the screen can show that
      // support.permissionGranted and hasPermission() agree.
      final info = await CarrierInfoPlus.get();
      final permission = await CarrierInfoPlus.hasPermission();
      if (!mounted) return;
      setState(() {
        _info = info;
        _permission = permission;
        _readAt = DateTime.now();
        _error = null;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    try {
      final granted = await CarrierInfoPlus.requestPermission();
      if (!mounted) return;
      if (!granted) {
        // Android denies silently, with no dialog at all, when the permission
        // is missing from the manifest or has been permanently denied. Saying
        // so beats a button that looks broken.
        _report(
          'Not granted. If no dialog appeared, Android is refusing to ask '
          'again — grant it from the app settings.',
        );
      }
    } on Object catch (error) {
      // Without this the plugin's own errors, such as being called with no
      // foreground activity, vanish into an unhandled async exception.
      if (!mounted) return;
      _report('requestPermission() failed: $error');
    }
    await _load();
  }

  void _report(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      appBar: AppBar(
        title: const Text('carrier_info_plus'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-read',
          ),
        ],
      ),
      body: switch ((_loading, _error, info)) {
        (true, _, _) => const Center(child: CircularProgressIndicator()),
        (_, final Object error, _) => _ErrorView(error: error, onRetry: _load),
        (_, _, final CarrierInfo info) => _ApiView(
          info: info,
          permission: _permission,
          readAt: _readAt,
          onRequestPermission: _requestPermission,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 12),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _ApiView extends StatelessWidget {
  const _ApiView({
    required this.info,
    required this.permission,
    required this.readAt,
    required this.onRequestPermission,
  });

  final CarrierInfo info;
  final bool? permission;
  final DateTime? readAt;
  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final support = info.support;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _Section(
          title: 'CarrierInfoPlus',
          subtitle: 'The three static entry points.',
          children: <Widget>[
            _Row('get()', readAt == null ? '—' : 'read at ${_time(readAt!)}'),
            _Row('hasPermission()', _bool(permission)),
            _Row(
              'requestPermission()',
              support.limitation.isRecoverable
                  ? 'available'
                  : 'nothing to ask for',
            ),
            if (support.limitation.isRecoverable)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  onPressed: onRequestPermission,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('requestPermission()'),
                ),
              ),
          ],
        ),

        // First, because every null below only means something once you know
        // whether the platform was even asked.
        _Section(
          title: 'PlatformSupport',
          subtitle: 'What the platform could answer, and why not.',
          children: <Widget>[
            _Row(
              'carrierIdentityAvailable',
              _bool(support.carrierIdentityAvailable),
            ),
            _Row('perSimDataAvailable', _bool(support.perSimDataAvailable)),
            _Row('permissionGranted', _bool(support.permissionGranted)),
            _Row('limitation', support.limitation.name),
            _Row(
              'limitation.isRecoverable',
              _bool(support.limitation.isRecoverable),
            ),
            _Row('isComplete', _bool(support.isComplete)),
            _Note(support.limitation.explanation),
          ],
        ),

        _Section(
          title: 'CarrierInfo',
          subtitle: 'Top-level fields and derived getters.',
          children: <Widget>[
            _Row('simCards.length', '${info.simCards.length}'),
            _Row('simCount', info.simCount?.toString() ?? 'null'),
            _Row('hasSim', _bool(info.hasSim)),
            _Row('isDualSimActive', _bool(info.isDualSimActive)),
            _Row('generation', info.generation.name),
            _Row('primarySim', _simLabel(info.primarySim)),
            _Row('voiceSim', _simLabel(info.voiceSim)),
            if (info.simCount != null && info.simCount! > info.simCards.length)
              const _Note(
                'More SIMs are present than could be described. That gap is '
                'the reason simCount exists.',
              ),
          ],
        ),

        _Section(
          title: 'NetworkInfo',
          subtitle: 'A property of the device, not of any one SIM.',
          children: <Widget>[
            _Row('operatorName', info.network.operatorName ?? 'null'),
            _Row('countryIso', info.network.countryIso ?? 'null'),
            _Row(
              'radioTechnologies',
              info.network.radioTechnologies.isEmpty
                  ? '[]'
                  : info.network.radioTechnologies
                        .map((RadioAccessTechnology t) => t.name)
                        .join(', '),
            ),
            _Row('cellularDataState', info.network.cellularDataState.name),
            _Row('generation', info.network.generation.name),
            _Row('isConnected', _bool(info.network.isConnected)),
          ],
        ),

        _Section(
          title: 'TelephonyCapabilities',
          subtitle: 'Hardware capability, independent of any SIM.',
          children: <Widget>[
            _Row('isVoiceCapable', _bool(info.capabilities.isVoiceCapable)),
            _Row('isSmsCapable', _bool(info.capabilities.isSmsCapable)),
            _Row('isDataCapable', _bool(info.capabilities.isDataCapable)),
            _Row('isDataEnabled', _bool(info.capabilities.isDataEnabled)),
            _Row(
              'isMultiSimSupported',
              _bool(info.capabilities.isMultiSimSupported),
            ),
            _Row(
              'supportsEmbeddedSim',
              _bool(info.capabilities.supportsEmbeddedSim),
            ),
          ],
        ),

        _Section(
          title: 'SimCard  ×${info.simCards.length}',
          subtitle: 'Every field, per SIM.',
          children: <Widget>[
            if (info.simCards.isEmpty)
              const _Note('No SIM could be described.')
            else
              for (final SimCard sim in info.simCards) _SimTile(sim: sim),
          ],
        ),

        const _EnumReference(),
      ],
    );
  }

  static String _bool(bool? value) => switch (value) {
    null => 'unknown',
    true => 'true',
    false => 'false',
  };

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:'
      '${value.second.toString().padLeft(2, '0')}';

  static String _simLabel(SimCard? sim) {
    if (sim == null) return 'null';
    return sim.carrierName ?? sim.displayName ?? 'slot ${sim.slotIndex}';
  }
}

class _SimTile extends StatelessWidget {
  const _SimTile({required this.sim});

  final SimCard sim;

  @override
  Widget build(BuildContext context) {
    final badges = <String>[
      if (sim.isDefaultData) 'default data',
      if (sim.isDefaultVoice) 'default voice',
      if (sim.isEmbedded) 'eSIM',
      if (sim.isRoaming) 'roaming',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              sim.carrierName ?? sim.displayName ?? 'Slot ${sim.slotIndex}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (badges.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: -8,
                  children: <Widget>[
                    for (final String badge in badges)
                      Chip(
                        label: Text(badge),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            _Row('subscriptionId', sim.subscriptionId?.toString() ?? 'null'),
            _Row('slotIndex', sim.slotIndex?.toString() ?? 'null'),
            _Row('carrierName', sim.carrierName ?? 'null'),
            _Row('displayName', sim.displayName ?? 'null'),
            _Row('mobileCountryCode', sim.mobileCountryCode ?? 'null'),
            _Row('mobileNetworkCode', sim.mobileNetworkCode ?? 'null'),
            _Row('countryIso', sim.countryIso ?? 'null'),
            _Row('carrierId', sim.carrierId?.toString() ?? 'null'),
            _Row('isEmbedded', '${sim.isEmbedded}'),
            _Row('isRoaming', '${sim.isRoaming}'),
            _Row('isDefaultData', '${sim.isDefaultData}'),
            _Row('isDefaultVoice', '${sim.isDefaultVoice}'),
            _Row('state', sim.state.name),
            _Row('plmn', sim.plmn ?? 'null'),
            _Row('hasIdentity', '${sim.hasIdentity}'),
            if (!sim.hasIdentity)
              const _Note(
                'Counted but not identified. On iOS 16+ this is every SIM.',
              ),
          ],
        ),
      ),
    );
  }
}

/// Every enum the package exports, with the getters defined on them.
class _EnumReference extends StatelessWidget {
  const _EnumReference();

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Enums',
    subtitle: 'Exported values, and what a device can never report.',
    children: <Widget>[
      ExpansionTile(
        title: const Text('RadioAccessTechnology'),
        subtitle: Text(
          '${RadioAccessTechnology.values.length} values, '
          'each carrying .generation',
        ),
        tilePadding: EdgeInsets.zero,
        children: <Widget>[
          for (final RadioAccessTechnology value
              in RadioAccessTechnology.values)
            _Row(value.name, value.generation.name),
        ],
      ),
      ExpansionTile(
        title: const Text('SimState'),
        subtitle: Text('${SimState.values.length} values'),
        tilePadding: EdgeInsets.zero,
        children: <Widget>[
          for (final SimState value in SimState.values)
            _Row(value.name, value == SimState.ready ? 'fields populated' : ''),
        ],
      ),
      ExpansionTile(
        title: const Text('DataLimitation'),
        subtitle: Text(
          '${DataLimitation.values.length} values, '
          'each with .isRecoverable and .explanation',
        ),
        tilePadding: EdgeInsets.zero,
        children: <Widget>[
          for (final DataLimitation value in DataLimitation.values)
            _Row(
              value.name,
              value.isRecoverable ? 'recoverable' : 'not recoverable',
            ),
        ],
      ),
      ExpansionTile(
        title: const Text('NetworkGeneration / CellularDataState'),
        tilePadding: EdgeInsets.zero,
        children: <Widget>[
          _Row(
            'NetworkGeneration',
            NetworkGeneration.values
                .map((NetworkGeneration v) => v.name)
                .join(', '),
          ),
          _Row(
            'CellularDataState',
            CellularDataState.values
                .map((CellularDataState v) => v.name)
                .join(', '),
          ),
        ],
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null)
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const Divider(),
          ...children,
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 190,
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}
