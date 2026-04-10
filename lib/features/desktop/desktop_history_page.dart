part of 'desktop_shell_screen_v2.dart';

class DesktopHistoryPage extends StatefulWidget {
  const DesktopHistoryPage({
    super.key,
    required this.movements,
  });

  final List<MovementRecord> movements;

  @override
  State<DesktopHistoryPage> createState() => _DesktopHistoryPageState();
}

class _DesktopHistoryPageState extends State<DesktopHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MovementRecord> get _filteredMovements {
    final query = _searchController.text.trim().toLowerCase();
    return widget.movements.where((record) {
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Borrow' && record.action == MovementAction.borrow) ||
          (_filter == 'Return' && record.action == MovementAction.returnItem);
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return record.itemName.toLowerCase().contains(query) ||
          record.itemQrCode.toLowerCase().contains(query) ||
          record.actorName.toLowerCase().contains(query) ||
          record.fromLocation.toLowerCase().contains(query) ||
          record.toLocation.toLowerCase().contains(query) ||
          (record.description ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _copyCsv() async {
    final rows = <String>[
      'item_name,item_qr,action,borrower,initial_location,moved_from,moved_to,time,description',
      ..._filteredMovements.map((record) {
        final actionLabel = record.action == MovementAction.borrow ? 'Borrow' : 'Return';
        return '"${record.itemName}","${record.itemQrCode}","$actionLabel","${record.actorName}","${record.fromLocation}","${record.fromLocation}","${record.toLocation}","${record.createdAt.toIso8601String()}","${record.description ?? ''}"';
      }),
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History CSV copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    final rows = _filteredMovements;
    return ListView(
      children: <Widget>[
        const DesktopSectionHeader(
          title: 'History',
          subtitle: 'Detailed movement records.',
        ),
        const SizedBox(height: 18),
        DesktopPanel(
          title: 'Movement log',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Search item, QR, borrower, location, or description',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      initialValue: _filter,
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'Borrow', child: Text('Borrow')),
                        DropdownMenuItem(value: 'Return', child: Text('Return')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _filter = value;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Filter'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _copyCsv,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 1200),
                    child: DataTable(
                      columns: const <DataColumn>[
                        DataColumn(label: Text('Item name')),
                        DataColumn(label: Text('QR')),
                        DataColumn(label: Text('Initial location')),
                        DataColumn(label: Text('Borrower')),
                        DataColumn(label: Text('From')),
                        DataColumn(label: Text('To')),
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('Description')),
                      ],
                      rows: rows.map((record) {
                        return DataRow(
                          cells: <DataCell>[
                            DataCell(Text(record.itemName)),
                            DataCell(Text(record.itemQrCode)),
                            DataCell(Text(record.fromLocation)),
                            DataCell(Text(record.actorName)),
                            DataCell(Text(record.fromLocation)),
                            DataCell(Text(record.toLocation)),
                            DataCell(Text(formatter.format(record.createdAt))),
                            DataCell(Text(record.description ?? '-')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
