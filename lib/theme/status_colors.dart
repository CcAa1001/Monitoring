import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../models/item.dart';

/// Visual tone for anything that shows an item or record status.
enum StatusTone { available, borrowed, overdue, neutral }

/// The single source of status colors for the whole app.
///
/// available = green, borrowed (incl. due soon) = amber, overdue = red,
/// neutral = grey (e.g. inactive records). Registered on both themes in
/// `app.dart`; read it with [StatusColors.of].
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.available,
    required this.borrowed,
    required this.overdue,
    required this.neutral,
    required this.backgroundAlpha,
  });

  final Color available;
  final Color borrowed;
  final Color overdue;
  final Color neutral;

  /// Opacity used for tinted chip/pill backgrounds behind the status color.
  final double backgroundAlpha;

  static const StatusColors light = StatusColors(
    available: Color(0xFF15803D),
    borrowed: Color(0xFFB45309),
    overdue: Color(0xFFDC2626),
    neutral: Color(0xFF64748B),
    backgroundAlpha: 0.12,
  );

  static const StatusColors dark = StatusColors(
    available: Color(0xFF4ADE80),
    borrowed: Color(0xFFFBBF24),
    overdue: Color(0xFFF87171),
    neutral: Color(0xFF94A3B8),
    backgroundAlpha: 0.18,
  );

  static StatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<StatusColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  Color color(StatusTone tone) {
    switch (tone) {
      case StatusTone.available:
        return available;
      case StatusTone.borrowed:
        return borrowed;
      case StatusTone.overdue:
        return overdue;
      case StatusTone.neutral:
        return neutral;
    }
  }

  Color background(StatusTone tone) => color(tone).withValues(alpha: backgroundAlpha);

  @override
  StatusColors copyWith({
    Color? available,
    Color? borrowed,
    Color? overdue,
    Color? neutral,
    double? backgroundAlpha,
  }) {
    return StatusColors(
      available: available ?? this.available,
      borrowed: borrowed ?? this.borrowed,
      overdue: overdue ?? this.overdue,
      neutral: neutral ?? this.neutral,
      backgroundAlpha: backgroundAlpha ?? this.backgroundAlpha,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      available: Color.lerp(available, other.available, t)!,
      borrowed: Color.lerp(borrowed, other.borrowed, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      backgroundAlpha: backgroundAlpha + (other.backgroundAlpha - backgroundAlpha) * t,
    );
  }
}

/// Display tone for an item: overdue wins, then borrowed, then available.
StatusTone itemStatusTone(Item item) {
  if (item.isOverdue) return StatusTone.overdue;
  return item.status == ItemStatus.available ? StatusTone.available : StatusTone.borrowed;
}

/// Display label for an item status in the active UI language (not a stored value).
String itemStatusLabel(Item item) {
  if (item.isOverdue) return tr('Terlambat');
  if (item.isDueSoon) return tr('Segera jatuh tempo');
  return item.status == ItemStatus.available ? tr('Tersedia') : tr('Dipinjam');
}

/// Maps a status label shown in a chip to its tone. Accepts the Indonesian
/// key or its translation, so chips keep their color in either language.
StatusTone statusToneForLabel(String label) {
  bool matches(List<String> keys) => keys.any((key) => label == key || label == tr(key));
  if (matches(const <String>['Tersedia', 'Aktif'])) return StatusTone.available;
  if (matches(const <String>['Dipinjam', 'Segera jatuh tempo'])) return StatusTone.borrowed;
  if (matches(const <String>['Terlambat'])) return StatusTone.overdue;
  return StatusTone.neutral;
}
