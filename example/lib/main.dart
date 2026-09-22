import 'dart:async';

import 'package:carrier_info_plus/carrier_info_plus.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CarrierInfoApp());
}

/// Demonstrates reading carrier state and, crucially, reacting to what the
/// platform could not answer.
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

/// Shows a snapshot, with a refresh and a permission prompt.
class CarrierInfoPage extends StatefulWidget {
  /// Creates a [CarrierInfoPage].
  const CarrierInfoPage({super.key});

  @override
  State<CarrierInfoPage> createState() => _CarrierInfoPageState();
}

class _CarrierInfoPageState extends State<CarrierInfoPage> {
  CarrierInfo? _info;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final info = await CarrierInfoPlus.get();
      if (!mounted) return;
      setState(() {
        _info = info;
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
    await CarrierInfoPlus.requestPermission();
    await _load();
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
        (_, _, final CarrierInfo info) => _InfoView(
          info: info,
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

class _InfoView extends StatelessWidget {
  const _InfoView({required this.info, required this.onRequestPermission});

  final CarrierInfo info;
  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final support = info.support;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // The support block comes first on purpose. Every null below is only
        // meaningful once you know whether the platform was even asked.
        _Section(
          title: 'What the platform could answer',
          children: <Widget>[
            _Row('Carrier identity', _yesNo(support.carrierIdentityAvailable)),
            _Row('Per-SIM data', _yesNo(support.perSimDataAvailable)),
            _Row('Permission granted', _yesNo(support.permissionGranted)),
            _Row('Limitation', support.limitation.name),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                support.limitation.explanation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (support.limitation.isRecoverable)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  onPressed: onRequestPermission,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Grant READ_PHONE_STATE'),
                ),
              ),
          ],
        ),
        _Section(
          title: 'Network',
          children: <Widget>[
            _Row('Operator', info.network.operatorName ?? '—'),
            _Row('Country', info.network.countryIso ?? '—'),
            _Row('Generation', info.generation.name),
            _Row(
              'Radios',
              info.network.radioTechnologies.isEmpty
                  ? '—'
                  : info.network.radioTechnologies
                        .map((RadioAccessTechnology t) => t.name)
                        .join(', '),
            ),
            _Row('Cellular data', info.network.cellularDataState.name),
          ],
        ),
        _Section(
          title: 'SIMs (${info.simCount ?? info.simCards.length})',
          children: <Widget>[
            if (info.simCards.isEmpty)
              const Text('No SIM could be described.')
            else
              for (final SimCard sim in info.simCards) _SimTile(sim: sim),
          ],
        ),
        _Section(
          title: 'Capabilities',
          children: <Widget>[
            _Row('Voice', _yesNo(info.capabilities.isVoiceCapable)),
            _Row('SMS', _yesNo(info.capabilities.isSmsCapable)),
            _Row('Data radio', _yesNo(info.capabilities.isDataCapable)),
            _Row('Data enabled', _yesNo(info.capabilities.isDataEnabled)),
            _Row('Multi-SIM', _yesNo(info.capabilities.isMultiSimSupported)),
            _Row('eSIM', _yesNo(info.capabilities.supportsEmbeddedSim)),
          ],
        ),
      ],
    );
  }

  static String _yesNo(bool value) => value ? 'yes' : 'no';
}

class _SimTile extends StatelessWidget {
  const _SimTile({required this.sim});

  final SimCard sim;

  @override
  Widget build(BuildContext context) {
    final badges = <String>[
      if (sim.isDefaultData) 'data',
      if (sim.isDefaultVoice) 'voice',
      if (sim.isEmbedded) 'eSIM',
      if (sim.isRoaming) 'roaming',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
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
            _Row('Slot', '${sim.slotIndex ?? '—'}'),
            _Row('PLMN', sim.plmn ?? '—'),
            _Row('Country', sim.countryIso ?? '—'),
            _Row('State', sim.state.name),
            if (!sim.hasIdentity)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'This SIM was counted but not identified.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        ...children,
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: 150, child: Text(label)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    ),
  );
}
