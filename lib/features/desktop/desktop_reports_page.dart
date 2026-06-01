part of 'desktop_shell_screen_v2.dart';

class DesktopReportsPage extends StatelessWidget {
  const DesktopReportsPage({
    super.key,
    required this.items,
    required this.movements,
    required this.users,
  });

  final List<Item> items;
  final List<MovementRecord> movements;
  final List<AppUser> users;

  static const InventoryReportService _reports = InventoryReportService();

  Future<void> _copy(BuildContext context, String csv, String label) async {
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied as CSV.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mostBorrowed = _reports.mostBorrowedItems(movements);
    final activeUsers = _reports.mostActiveUsers(movements);
    final activeLocations = _reports.locationActivity(movements);
    return ListView(
      children: <Widget>[
        const DesktopSectionHeader(
          title: 'Reports',
          subtitle: 'Export operational records and review the patterns behind daily equipment movement.',
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(
              child: DesktopMetricCard(
                title: 'Ready',
                value: '${_reports.readyCount(items)}',
                icon: Icons.inventory_2_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesktopMetricCard(
                title: 'Borrowed',
                value: '${_reports.borrowedCount(items)}',
                icon: Icons.call_made_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesktopMetricCard(
                title: 'Due soon',
                value: '${_reports.dueSoonCount(items)}',
                icon: Icons.schedule_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesktopMetricCard(
                title: 'Overdue',
                value: '${_reports.overdueCount(items)}',
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _ReportListPanel(
                title: 'Most borrowed items',
                rows: mostBorrowed,
                emptyText: 'No borrow activity has been recorded yet.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportListPanel(
                title: 'Most active users',
                rows: activeUsers,
                emptyText: 'No user activity has been recorded yet.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportListPanel(
                title: 'Location movement',
                rows: activeLocations,
                emptyText: 'No location movement has been recorded yet.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        DesktopPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Exports',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Copy CSV data for spreadsheet reports, audits, and monthly summaries.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () => _copy(context, _reports.historyCsv(movements), 'Movement history'),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export history'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copy(context, _reports.itemsCsv(items), 'Item catalog'),
                    icon: const Icon(Icons.inventory_2_rounded),
                    label: const Text('Export items'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copy(context, _reports.usersCsv(users), 'User list'),
                    icon: const Icon(Icons.people_alt_rounded),
                    label: const Text('Export users'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportListPanel extends StatelessWidget {
  const _ReportListPanel({
    required this.title,
    required this.rows,
    required this.emptyText,
  });

  final String title;
  final List<MapEntry<String, int>> rows;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return DesktopPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            Text(emptyText, style: Theme.of(context).textTheme.bodyMedium)
          else
            ...rows.map((row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        row.key,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DesktopStatusChip(label: '${row.value}x'),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
