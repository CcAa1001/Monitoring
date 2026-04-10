part of 'desktop_shell_screen_v2.dart';

class DesktopMetricCard extends StatelessWidget {
  const DesktopMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            backgroundColor: const Color(0xFFF0ECFF),
            foregroundColor: const Color(0xFF5B39EA),
            child: Icon(icon),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1F2533)),
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
