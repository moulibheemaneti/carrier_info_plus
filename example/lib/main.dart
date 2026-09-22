import 'package:carrier_info_plus/carrier_info_plus.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

/// Demo app showing everything the current platform can report.
class ExampleApp extends StatelessWidget {
  /// Creates the demo app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'carrier_info_plus',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF0175C2)),
    darkTheme: ThemeData(
      colorSchemeSeed: const Color(0xFF0175C2),
      brightness: Brightness.dark,
    ),
    home: const CarrierPage(),
  );
}

/// Shows a live snapshot, refreshable by pull-to-refresh.
class CarrierPage extends StatefulWidget {
  /// Creates the page.
  const CarrierPage({super.key});

  @override
  State<CarrierPage> createState() => _CarrierPageState();
}

class _CarrierPageState extends State<CarrierPage> {
  CarrierInfo? _info;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final CarrierInfo info = await CarrierInfoPlus.get();
      if (mounted) {
        setState(() {
          _info = info;
          _error = null;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _requestPermission() async {
    await CarrierInfoPlus.requestPermission();
    await _load();
  }

  Widget _body() {
    final Object? error = _error;
    if (error != null) {
      return _Message('Failed: $error');
    }
    final CarrierInfo? info = _info;
    if (info == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _Report(info: info, onRequestPermission: _requestPermission);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('carrier_info_plus')),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    children: <Widget>[
      Padding(padding: const EdgeInsets.all(24), child: Text(text)),
    ],
  );
}

class _Report extends StatelessWidget {
  const _Report({required this.info, required this.onRequestPermission});

  final CarrierInfo info;
  final Future<void> Function() onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final PlatformSupport support = info.support;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // The honest banner: say why anything is missing, and only offer a
        // prompt when the gap is actually recoverable.
        Card(
          color: support.isComplete
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  support.isComplete ? 'Complete' : 'Partial data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(support.limitation.explanation),
                if (support.limitation.isRecoverable) ...<Widget>[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onRequestPermission,
                    child: const Text('Grant READ_PHONE_STATE'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _Section('Network', <String, String>{
          'Generation': info.generation.name,
          'Radios': info.network.radioTechnologies
              .map((RadioAccessTechnology t) => t.name)
              .join(', '),
          'Operator': info.network.operatorName ?? '—',
          'Country': info.network.countryIso ?? '—',
          'Cellular data': info.network.cellularDataState.name,
        }),
        _Section('Capabilities', <String, String>{
          'Voice': '${info.capabilities.isVoiceCapable}',
          'SMS': '${info.capabilities.isSmsCapable}',
          'Data': '${info.capabilities.isDataCapable}',
          'Data enabled': '${info.capabilities.isDataEnabled}',
          'Multi-SIM': '${info.capabilities.isMultiSimSupported}',
          'eSIM': '${info.capabilities.supportsEmbeddedSim}',
        }),
        if (info.simCards.isEmpty)
          const _Section('SIMs', <String, String>{'': 'No SIM detected'})
        else
          for (int i = 0; i < info.simCards.length; i++)
            _Section('SIM ${info.simCards[i].slotIndex ?? i}', <String, String>{
              'Carrier': info.simCards[i].carrierName ?? '—',
              'Label': info.simCards[i].displayName ?? '—',
              'PLMN': info.simCards[i].plmn ?? '—',
              'Country': info.simCards[i].countryIso ?? '—',
              'State': info.simCards[i].state.name,
              'eSIM': '${info.simCards[i].isEmbedded}',
              'Roaming': '${info.simCards[i].isRoaming}',
            }),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.rows);

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          for (final MapEntry<String, String> row in rows.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 120, child: Text(row.key)),
                  Expanded(
                    child: Text(
                      row.value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
