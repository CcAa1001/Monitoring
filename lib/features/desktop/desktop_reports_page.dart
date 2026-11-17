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
      SnackBar(content: Text(tr('{label} disalin sebagai CSV.', {'label': label}))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mostBorrowed = _reports.mostBorrowedItems(movements);
    final activeUsers = _reports.mostActiveUsers(movements);
    final activeLocations = _reports.locationActivity(movements);
    return ListView(
      children: <Widget>[
        DesktopSectionHeader(
          title: tr('Laporan'),
          subtitle: tr('Ekspor catatan operasional dan tinjau pola pergerakan peralatan harian.'),
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(
              child: DesktopMetricCard(
                title: tr('Tersedia'),
                value: '${_reports.readyCount(items)}',
                icon: Icons.inventory_2_rounded, tone: StatusTone.available,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesktopMetricCard(
                title: tr('Dipinjam'),
                value: '${_reports.borrowedCount(items)}',
                icon: Icons.call_made_rounded, tone: StatusTone.borrowed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesktopMetricCard(
                title: tr('Segera jatuh tempo'),
                value: '${_reports.dueSoonCount(items)}',
                icon: Icons.schedule_rounded, tone: StatusTone.borrowed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesktopMetricCard(
                title: tr('Terlambat'),
                value: '${_reports.overdueCount(items)}',
                icon: Icons.warning_amber_rounded, tone: StatusTone.overdue,
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
                title: tr('Barang paling sering dipinjam'),
                rows: mostBorrowed,
                emptyText: tr('Belum ada aktivitas peminjaman yang tercatat.'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportListPanel(
                title: tr('Pengguna paling aktif'),
                rows: activeUsers,
                emptyText: tr('Belum ada aktivitas pengguna yang tercatat.'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ReportListPanel(
                title: tr('Pergerakan lokasi'),
                rows: activeLocations,
                emptyText: tr('Belum ada pergerakan lokasi yang tercatat.'),
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
                tr('Ekspor'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                tr('Salin data CSV untuk laporan spreadsheet, audit, dan ringkasan bulanan.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () => _copy(context, _reports.historyCsv(movements), tr('Riwayat pergerakan')),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(tr('Ekspor riwayat')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copy(context, _reports.itemsCsv(items), tr('Katalog barang')),
                    icon: const Icon(Icons.inventory_2_rounded),
                    label: Text(tr('Ekspor barang')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copy(context, _reports.usersCsv(users), tr('Daftar pengguna')),
                    icon: const Icon(Icons.people_alt_rounded),
                    label: Text(tr('Ekspor pengguna')),
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
                    DesktopStatusChip(label: '${row.value}x', color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
