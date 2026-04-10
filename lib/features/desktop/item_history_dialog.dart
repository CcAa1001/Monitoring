part of 'desktop_shell_screen_v2.dart';

class ItemHistoryDialog extends StatelessWidget {
  const ItemHistoryDialog({
    super.key,
    required this.item,
    required this.movements,
  });

  final Item item;
  final List<MovementRecord> movements;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    return AlertDialog(
      title: Text('${item.name} history'),
      content: SizedBox(
        width: 860,
        child: movements.isEmpty
            ? const Text('No movement history found for this item yet.')
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Action')),
                    DataColumn(label: Text('Borrower')),
                    DataColumn(label: Text('From')),
                    DataColumn(label: Text('To')),
                    DataColumn(label: Text('Description')),
                  ],
                  rows: movements.map((movement) {
                    return DataRow(
                      cells: <DataCell>[
                        DataCell(Text(formatter.format(movement.createdAt))),
                        DataCell(Text(movement.action == MovementAction.borrow ? 'Borrow' : 'Return')),
                        DataCell(Text(movement.actorName)),
                        DataCell(Text(movement.fromLocation)),
                        DataCell(Text(movement.toLocation)),
                        DataCell(Text(movement.description ?? '-')),
                      ],
                    );
                  }).toList(),
                ),
              ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
