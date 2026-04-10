part of 'desktop_shell_screen_v2.dart';

class DesktopSimpleTile extends StatelessWidget {
  const DesktopSimpleTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.onEdit,
    this.onDelete,
    this.onHistory,
  });

  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2238) : const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1F2533))),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
          if (onHistory != null)
            IconButton(
              onPressed: onHistory,
              icon: const Icon(Icons.history_rounded),
              tooltip: 'History',
            ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit',
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
            ),
          DesktopStatusChip(label: status),
        ],
      ),
    );
  }
}
