import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/inventory_repository.dart';
import 'l10n/app_language.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Date names for both UI languages (id_ID and en_US); see l10n/app_language.dart.
  await initializeDateFormatting();
  await loadSavedLanguage();
  final repository = await InventoryRepositoryFactory.create();
  runApp(MonitoringApp(repository: repository));
}
