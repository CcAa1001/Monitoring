part of 'desktop_shell_screen_v2.dart';

class DesktopStatusChip extends StatelessWidget {
  const DesktopStatusChip({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    Color fg = const Color(0xFF5B39EA);
    Color bg = const Color(0x22B39DFF);
    if (label == 'Ready' || label == 'Active') {
      fg = const Color(0xFF16C098);
      bg = const Color(0x2216C098);
    } else if (label == 'Borrowed' || label == 'Inactive') {
      fg = const Color(0xFFEA5455);
      bg = const Color(0x22EA5455);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
