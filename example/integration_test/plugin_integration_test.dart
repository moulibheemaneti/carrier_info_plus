// Runs on a real device, where the platform side actually answers.
//
// Assertions are deliberately about coherence rather than about values: what a
// device reports depends on its SIMs, its carrier and the permissions granted,
// none of which a test can assume. What must always hold is that the support
// block agrees with the data beside it.

import 'package:carrier_info_plus/carrier_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reads a coherent snapshot from the device', (
    WidgetTester tester,
  ) async {
    final info = await CarrierInfoPlus.get();

    // Per-SIM data implies the permission that guards it.
    if (info.support.perSimDataAvailable) {
      expect(info.support.permissionGranted, isTrue);
    }

    // A described SIM count can never exceed what the platform admits to.
    final count = info.simCount;
    if (count != null) {
      expect(info.simCards.length, lessThanOrEqualTo(count));
    }

    // primarySim must be drawn from the list it summarises.
    final primary = info.primarySim;
    if (primary != null) {
      expect(info.simCards, contains(primary));
    }

    // A complete result has nothing to explain.
    expect(
      info.support.isComplete,
      info.support.limitation == DataLimitation.none,
    );
  });

  testWidgets('permission state is self-consistent', (
    WidgetTester tester,
  ) async {
    final granted = await CarrierInfoPlus.hasPermission();
    final info = await CarrierInfoPlus.get();

    expect(info.support.permissionGranted, granted);
  });
}
