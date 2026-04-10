import 'package:flutter/material.dart';

import 'app.dart';
import 'data/inventory_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await InventoryRepositoryFactory.create();
  runApp(MonitoringApp(repository: repository));
}
