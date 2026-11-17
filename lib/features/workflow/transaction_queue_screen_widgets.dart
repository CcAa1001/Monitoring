part of 'transaction_queue_screen.dart';

class _QueuedItemDraft {
  _QueuedItemDraft({
    required this.item,
    required this.fromPairing,
    required this.actorName,
  }) : descriptionController = TextEditingController();

  final Item item;
  final bool fromPairing;
  final String actorName;
  final TextEditingController descriptionController;
  String? selectedLocation;

  void dispose() {
    descriptionController.dispose();
  }
}

/// Three-step progress: Pindai aset → Pilih tujuan → Konfirmasi.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  /// 0-based index of the step the user is on.
  final int currentStep;

  static const List<String> _labels = <String>['Pindai aset', 'Pilih tujuan', 'Konfirmasi'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final done = StatusColors.of(context).available;
    final children = <Widget>[];
    for (var i = 0; i < _labels.length; i++) {
      final isDone = i < currentStep;
      final isActive = i == currentStep;
      final color = isDone ? done : (isActive ? colorScheme.primary : colorScheme.onSurfaceVariant);
      children.add(
        Expanded(
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isActive ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: isDone
                    ? Icon(Icons.check_rounded, size: 18, color: colorScheme.surface)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isActive ? colorScheme.onPrimary : color,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  tr(_labels[i]),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (i < _labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: isDone ? done : colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(children: children),
    );
  }
}

/// Compact scan controls + pairing status (secondary to the scanned list).
class _ScanToolbar extends StatelessWidget {
  const _ScanToolbar({
    required this.currentUser,
    required this.pairingSession,
    required this.isRefreshingPair,
    required this.onRefreshPairing,
    required this.onScanDesktop,
  });

  final AppUser currentUser;
  final PairingSession? pairingSession;
  final bool isRefreshingPair;
  final Future<void> Function() onRefreshPairing;
  final VoidCallback onScanDesktop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pairText = pairingSession == null
        ? tr('Belum ada ponsel yang tersambung. Anda tetap dapat memindai di PC ini.')
        : tr('Kode sambungan {code} tersambung ke {device}.', {'code': pairingSession!.code, 'device': pairingSession!.connectedDeviceName ?? tr('sebuah ponsel')});
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: <Widget>[
          FilledButton.icon(
            onPressed: onScanDesktop,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(tr('Pindai di PC ini')),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pairText,
                  style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  tr('Pindaian PC dicatat atas nama {name}; pindaian ponsel memakai nama pengguna ponsel.', {'name': currentUser.name}),
                  style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: tr('Perbarui status sambungan'),
            onPressed: pairingSession == null || isRefreshingPair ? null : () => onRefreshPairing(),
            icon: isRefreshingPair
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

/// The main element of the screen: every scanned asset in the queue.
class _ScannedItemsSection extends StatelessWidget {
  const _ScannedItemsSection({
    required this.isBorrow,
    required this.drafts,
    required this.racks,
    required this.onLocationSelected,
    required this.onDescriptionChanged,
    required this.onRemove,
  });

  final bool isBorrow;
  final List<_QueuedItemDraft> drafts;
  final List<AllowedLocation> racks;
  final void Function(_QueuedItemDraft draft, String location) onLocationSelected;
  final VoidCallback onDescriptionChanged;
  final Future<void> Function(_QueuedItemDraft draft) onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.45), width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  tr('Aset dipindai'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tr('{count} aset', {'count': drafts.length}),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isBorrow
                ? tr('Semua aset di bawah akan dipinjamkan ke line yang sama saat dikonfirmasi.')
                : tr('Pilih rak tujuan untuk setiap aset yang dikembalikan.'),
            style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (drafts.isEmpty)
            _EmptyQueue(
              text: isBorrow
                  ? tr('Belum ada aset di antrean pinjam. Pindai dari ponsel atau dari PC ini.')
                  : tr('Belum ada aset di antrean kembali. Pindai dari ponsel atau dari PC ini.'),
            )
          else
            ...drafts.map(
              (draft) => _QueuedItemTile(
                draft: draft,
                racks: isBorrow ? null : racks,
                onLocationSelected: (location) => onLocationSelected(draft, location),
                onChanged: onDescriptionChanged,
                onRemove: () {
                  onRemove(draft);
                },
                descriptionHint: isBorrow
                    ? tr('Contoh: untuk setup, dicek sebelum dikeluarkan')
                    : tr('Contoh: gagang sudah dicek, dikembalikan setelah dibersihkan'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Borrow step 2: destination line and optional due date.
class _BorrowDestinationCard extends StatelessWidget {
  const _BorrowDestinationCard({
    required this.selectedLine,
    required this.lines,
    required this.expectedReturnAt,
    required this.onLineSelected,
    required this.onDueDateSelected,
  });

  final String? selectedLine;
  final List<AllowedLocation> lines;
  final DateTime? expectedReturnAt;
  final ValueChanged<String> onLineSelected;
  final ValueChanged<DateTime?> onDueDateSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            tr('Tujuan peminjaman'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedLine,
            items: lines
                .map(
                  (line) => DropdownMenuItem<String>(
                    value: line.code,
                    child: Text(line.code),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onLineSelected(value);
              }
            },
            decoration: InputDecoration(
              labelText: tr('Line tujuan'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(labelText: tr('Batas pengembalian')),
                  child: Text(
                    expectedReturnAt == null
                        ? tr('Tanpa batas waktu')
                        : DateFormat('dd MMM yyyy', dateLocale).format(expectedReturnAt!),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: expectedReturnAt ?? DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selected != null) {
                    onDueDateSelected(selected);
                  }
                },
                icon: const Icon(Icons.event_rounded),
                label: Text(tr('Atur batas waktu')),
              ),
              if (expectedReturnAt != null) ...<Widget>[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => onDueDateSelected(null),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: tr('Hapus batas waktu'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QueuedItemTile extends StatelessWidget {
  const _QueuedItemTile({
    required this.draft,
    required this.racks,
    required this.onLocationSelected,
    required this.onChanged,
    required this.onRemove,
    required this.descriptionHint,
  });

  final _QueuedItemDraft draft;

  /// Rack choices for return mode; null in borrow mode.
  final List<AllowedLocation>? racks;
  final ValueChanged<String> onLocationSelected;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final String descriptionHint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _QueuedItemHeader(
            draft: draft,
            onRemove: onRemove,
          ),
          if (racks != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              tr('Rak tujuan'),
              style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: racks!.map((rack) {
                final selected = draft.selectedLocation == rack.code;
                return ChoiceChip(
                  label: Text(rack.code),
                  selected: selected,
                  onSelected: (_) => onLocationSelected(rack.code),
                  selectedColor: colorScheme.primary,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  labelStyle: TextStyle(
                    color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: draft.descriptionController,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: tr('Keterangan atau catatan (opsional)'),
              hintText: descriptionHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueuedItemHeader extends StatelessWidget {
  const _QueuedItemHeader({
    required this.draft,
    required this.onRemove,
  });

  final _QueuedItemDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColors = StatusColors.of(context);
    final tone = itemStatusTone(draft.item);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                draft.item.name,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'QR ${draft.item.qrCode} · ${draft.item.currentLocation} · ${draft.actorName}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _Pill(
                    label: itemStatusLabel(draft.item),
                    foreground: statusColors.color(tone),
                    background: statusColors.background(tone),
                  ),
                  _Pill(
                    label: draft.fromPairing ? tr('Pindai ponsel') : tr('Pindai PC'),
                    foreground: colorScheme.onSurfaceVariant,
                    background: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: tr('Hapus dari antrean'),
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.qr_code_scanner_rounded, size: 40, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Bottom bar with the confirm button and, when it is disabled, why.
class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.label,
    required this.isSubmitting,
    required this.hint,
    required this.onConfirm,
  });

  final String label;
  final bool isSubmitting;
  final String? hint;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _queueMaxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (hint != null) ...<Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.info_outline_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hint!,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
