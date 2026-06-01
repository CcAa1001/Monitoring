part of 'desktop_shell_screen_v2.dart';

class DesktopSectionHeader extends StatelessWidget {
  const DesktopSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF5B39EA).withValues(alpha: isDark ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5B39EA),
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2533),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6C748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
