part of 'desktop_shell_screen_v2.dart';

class DesktopStatusChip extends StatelessWidget {
  const DesktopStatusChip({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color fg = const Color(0xFF5B39EA);
    Color bg = isDark ? const Color(0x334C35D8) : const Color(0x22B39DFF);
    if (label == 'Ready' || label == 'Active') {
      fg = const Color(0xFF16C098);
      bg = isDark ? const Color(0x3320B78C) : const Color(0x2216C098);
    } else if (label == 'Borrowed' || label == 'Inactive' || label == 'Overdue') {
      fg = const Color(0xFFEA5455);
      bg = isDark ? const Color(0x33C4494A) : const Color(0x22EA5455);
    } else if (label == 'Due soon') {
      fg = const Color(0xFFF59E0B);
      bg = isDark ? const Color(0x33B7791F) : const Color(0x22F59E0B);
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 110, minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
