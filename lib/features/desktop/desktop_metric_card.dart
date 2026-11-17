part of 'desktop_shell_screen_v2.dart';

class DesktopMetricCard extends StatelessWidget {
  const DesktopMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.tone,
  });

  final String title;
  final String value;
  final IconData icon;

  /// When set, the icon and value use this status color instead of the brand purple.
  final StatusTone? tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = StatusColors.of(context);
    final accent = tone == null ? const Color(0xFF5B39EA) : colors.color(tone!);
    final accentBg = tone == null
        ? (isDark ? const Color(0xFF231B4A) : const Color(0xFFF0ECFF))
        : colors.background(tone!);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF252B42) : const Color(0xFFECEFF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: accentBg,
            foregroundColor: accent,
            child: Icon(icon),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: tone == null ? (isDark ? Colors.white : const Color(0xFF1F2533)) : accent,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF7E8698), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
