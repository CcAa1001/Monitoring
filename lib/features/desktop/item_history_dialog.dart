part of 'desktop_shell_screen_v2.dart';

class ItemHistoryDialog extends StatelessWidget {
  const ItemHistoryDialog({
    super.key,
    required this.item,
    required this.movements,
  });

  final Item item;
  final List<MovementRecord> movements;

  Future<void> _copyQrLabel(BuildContext context) async {
    final label = <String>[
      item.name,
      'QR: ${item.qrCode}',
      if ((item.serialNumber ?? '').isNotEmpty) tr('No. seri: {serial}', {'serial': item.serialNumber}),
      if ((item.brand ?? '').isNotEmpty) tr('Merek: {brand}', {'brand': item.brand}),
      if ((item.model ?? '').isNotEmpty) 'Model: ${item.model}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: label));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Teks label QR disalin.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm', dateLocale);
    final dueLabel = item.expectedReturnAt == null ? '-' : formatter.format(item.expectedReturnAt!);
    return AlertDialog(
      title: Text(item.name),
      content: SizedBox(
        width: 920,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (item.imageUrl ?? '').isEmpty
                        ? const Icon(Icons.inventory_2_rounded, size: 54)
                        : Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 54),
                          ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _ItemProfileFact(label: tr('Kode QR'), value: item.qrCode),
                        _ItemProfileFact(label: tr('No. seri'), value: item.serialNumber ?? '-'),
                        _ItemProfileFact(label: tr('Merek'), value: item.brand ?? '-'),
                        _ItemProfileFact(label: 'Model', value: item.model ?? '-'),
                        _ItemProfileFact(label: tr('Kategori'), value: item.category),
                        _ItemProfileFact(label: tr('Kondisi'), value: item.conditionLabel),
                        _ItemProfileFact(label: tr('Lokasi'), value: item.currentLocation),
                        _ItemProfileFact(label: tr('Batas pengembalian'), value: dueLabel),
                      ],
                    ),
                  ),
                ],
              ),
              if ((item.notes ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                Text(tr('Catatan perawatan'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(item.notes!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 22),
              Text(tr('Riwayat pergerakan'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (movements.isEmpty)
                Text(tr('Belum ada riwayat pergerakan untuk barang ini.'))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: <DataColumn>[
                      DataColumn(label: Text(tr('Waktu'))),
                      DataColumn(label: Text(tr('Aksi'))),
                      DataColumn(label: Text(tr('Pelaku'))),
                      DataColumn(label: Text(tr('Dari'))),
                      DataColumn(label: Text(tr('Ke'))),
                      DataColumn(label: Text(tr('Keterangan'))),
                    ],
                    rows: movements.map((movement) {
                      return DataRow(
                        cells: <DataCell>[
                          DataCell(Text(formatter.format(movement.createdAt))),
                          DataCell(Text(movement.action == MovementAction.borrow ? tr('Pinjam') : tr('Kembali'))),
                          DataCell(Text(movement.actorName)),
                          DataCell(Text(movement.fromLocation)),
                          DataCell(Text(movement.toLocation)),
                          DataCell(Text(movement.description ?? '-')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: () => _copyQrLabel(context),
          icon: const Icon(Icons.qr_code_2_rounded),
          label: Text(tr('Salin label QR')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Tutup')),
        ),
      ],
    );
  }
}

class _ItemProfileFact extends StatelessWidget {
  const _ItemProfileFact({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
