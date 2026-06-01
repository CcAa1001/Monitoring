part of 'desktop_shell_screen_v2.dart';

class DesktopPanel extends StatelessWidget {
  const DesktopPanel({
    super.key,
    this.title,
    required this.child,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF252B42) : const Color(0xFFECEFF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if ((title ?? '').isNotEmpty) ...<Widget>[
            Text(
              title!,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1F2533)),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}
