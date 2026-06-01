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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2236) : const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A314B) : const Color(0xFFECEFF6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF5B39EA).withValues(alpha: isDark ? 0.22 : 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.widgets_rounded,
              color: Color(0xFF5B39EA),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2533),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6A738A),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 132,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (onHistory != null)
                  IconButton(
                    onPressed: onHistory,
                    icon: const Icon(Icons.history_rounded, size: 20),
                    tooltip: 'History',
                  ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    tooltip: 'Edit',
                  ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DesktopStatusChip(label: status),
        ],
      ),
    );
  }
}
