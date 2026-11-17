import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings_en.dart';

/// Languages the UI can be shown in. Indonesian is the default.
enum AppLanguage { id, en }

/// The active UI language. Change it with [setAppLanguage] / [toggleAppLanguage];
/// `MonitoringApp` listens to it and rebuilds every screen in place
/// (screen state such as the logged-in user or a scan queue is kept).
final ValueNotifier<AppLanguage> appLanguage = ValueNotifier<AppLanguage>(AppLanguage.id);

const String _languagePrefKey = 'ui_language';

/// Restores the language chosen in a previous session. Call once before runApp.
/// Falls back to Indonesian if nothing was saved or storage is unavailable.
Future<void> loadSavedLanguage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languagePrefKey);
    appLanguage.value = AppLanguage.values.firstWhere(
      (language) => language.name == saved,
      orElse: () => AppLanguage.id,
    );
  } catch (_) {
    appLanguage.value = AppLanguage.id;
  }
}

/// Switches the UI language immediately and remembers it for next launch.
void setAppLanguage(AppLanguage language) {
  appLanguage.value = language;
  SharedPreferences.getInstance()
      .then((prefs) => prefs.setString(_languagePrefKey, language.name))
      .catchError((Object _) => false);
}

void toggleAppLanguage() {
  setAppLanguage(appLanguage.value == AppLanguage.id ? AppLanguage.en : AppLanguage.id);
}

bool get isEnglish => appLanguage.value == AppLanguage.en;

/// Locale for Material widgets (date picker, tooltips) and for `DateFormat`.
Locale get appLocale => isEnglish ? const Locale('en', 'US') : const Locale('id', 'ID');

/// Pass to `DateFormat(pattern, dateLocale)` so dates follow the UI language.
String get dateLocale => isEnglish ? 'en_US' : 'id_ID';

/// Translates a UI string.
///
/// The Indonesian text is the key, so code stays readable and Indonesian
/// works with no lookup. Placeholders written as `{name}` are filled from
/// [args]. Unknown keys fall back to the key itself.
String tr(String indonesian, [Map<String, Object?>? args]) {
  var text = isEnglish ? (stringsEn[indonesian] ?? indonesian) : indonesian;
  if (args != null) {
    args.forEach((key, value) {
      text = text.replaceAll('{$key}', '${value ?? ''}');
    });
  }
  return text;
}
