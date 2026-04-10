import 'package:flutter_test/flutter_test.dart';

import 'package:factory_monitoring_app/app.dart';
import 'package:factory_monitoring_app/data/mock_inventory_repository.dart';

void main() {
  testWidgets('app opens login flow', (WidgetTester tester) async {
    await tester.pumpWidget(
      MonitoringApp(
        repository: MockInventoryRepository.seeded(),
      ),
    );

    expect(find.text('Equipment-room sign in'), findsOneWidget);
  });
}
