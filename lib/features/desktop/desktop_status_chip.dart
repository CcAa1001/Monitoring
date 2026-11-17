part of 'desktop_shell_screen_v2.dart';

class DesktopStatusChip extends StatelessWidget {
  const DesktopStatusChip({
    super.key,
    required this.label,
    this.tone,
    this.color,
  });

  final String label;

  /// Explicit status tone; when null it is derived from [label].
  final StatusTone? tone;

  /// Non-status accent (e.g. a count badge). Overrides [tone] when set.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(context);
    final resolved = tone ?? statusToneForLabel(label);
    final fg = color ?? colors.color(resolved);
    final bg = color?.withValues(alpha: colors.backgroundAlpha) ?? colors.background(resolved);

    return Container(
      constraints: const BoxConstraints(minWidth: 110, minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
