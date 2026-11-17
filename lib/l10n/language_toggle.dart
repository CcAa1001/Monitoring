import 'package:flutter/material.dart';

import 'app_language.dart';

/// Switches the UI between Indonesian and English. Shows the active language.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({
    super.key,
    this.color,
    this.compact = false,
  });

  /// Text/icon color; defaults to the theme's button color.
  final Color? color;

  /// Compact shows only "ID"/"EN" in a 48x48 button (e.g. the desktop sidebar).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final code = isEnglish ? 'EN' : 'ID';
    final style = TextButton.styleFrom(
      foregroundColor: color,
      minimumSize: const Size(48, 48),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
    );
    return Tooltip(
      message: tr('Ganti bahasa'),
      child: compact
          ? TextButton(onPressed: toggleAppLanguage, style: style, child: Text(code))
          : TextButton.icon(
              onPressed: toggleAppLanguage,
              style: style,
              icon: const Icon(Icons.translate_rounded, size: 20),
              label: Text(isEnglish ? 'English' : 'Bahasa Indonesia'),
            ),
    );
  }
}
