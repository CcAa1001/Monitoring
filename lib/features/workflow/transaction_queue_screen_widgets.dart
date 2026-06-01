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

class _SessionBanner extends StatelessWidget {
  const _SessionBanner({
    required this.isBorrow,
    required this.currentUser,
    required this.pairingSession,
    required this.isRefreshingPair,
    required this.onRefreshPairing,
  });

  final bool isBorrow;
  final AppUser currentUser;
  final PairingSession? pairingSession;
  final bool isRefreshingPair;
  final Future<void> Function() onRefreshPairing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? <Color>[const Color(0xFF111827), const Color(0xFF181B2F)]
              : <Color>[Colors.white, const Color(0xFFF8F6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            isBorrow ? 'Borrow queue' : 'Return queue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Desktop scans use ${currentUser.name}. Phone scans keep the paired mobile user name when they are submitted.',
            style: TextStyle(
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  pairingSession == null
                      ? 'No phone paired right now. You can still scan on this PC.'
                      : 'Pair code ${pairingSession!.code} is connected to ${pairingSession!.connectedDeviceName ?? 'a phone'}.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
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
        ],
      ),
    );
  }
}

class _ScanControlCard extends StatelessWidget {
  const _ScanControlCard({
    required this.isBorrow,
    required this.queueCount,
    required this.onScanDesktop,
  });

  final bool isBorrow;
  final int queueCount;
  final VoidCallback onScanDesktop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            isBorrow ? 'Scan items to borrow' : 'Scan items to return',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isBorrow
                ? 'Phone scans and desktop scans will keep adding items into one borrow queue. Pick the line after all items are scanned.'
                : 'Each scanned item creates its own return row. You can keep scanning even while another description field is active.',
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onScanDesktop,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan on this PC'),
                ),
              ),
              const SizedBox(width: 12),
              _CountPill(label: '$queueCount item${queueCount == 1 ? '' : 's'}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BorrowQueueCard extends StatelessWidget {
  const _BorrowQueueCard({
    required this.drafts,
    required this.selectedLine,
    required this.lines,
    required this.expectedReturnAt,
    required this.onLineSelected,
    required this.onDueDateSelected,
    required this.onDescriptionChanged,
    required this.onRemove,
  });

  final List<_QueuedItemDraft> drafts;
  final String? selectedLine;
  final List<AllowedLocation> lines;
  final DateTime? expectedReturnAt;
  final ValueChanged<String> onLineSelected;
  final ValueChanged<DateTime?> onDueDateSelected;
  final VoidCallback onDescriptionChanged;
  final Future<void> Function(_QueuedItemDraft draft) onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Borrow queue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'All scanned items below will be borrowed to the same line when you confirm.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 16),
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
            decoration: const InputDecoration(
              labelText: 'Destination line',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Expected return'),
                  child: Text(
                    expectedReturnAt == null
                        ? 'No due date'
                        : '${expectedReturnAt!.day.toString().padLeft(2, '0')}/${expectedReturnAt!.month.toString().padLeft(2, '0')}/${expectedReturnAt!.year}',
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
                label: const Text('Set due date'),
              ),
              if (expectedReturnAt != null) ...<Widget>[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => onDueDateSelected(null),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Clear due date',
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (drafts.isEmpty)
            const _EmptyQueue(
              text: 'No items in the borrow queue yet. Scan from the phone or from this PC.',
            ),
          ...drafts.map(
            (draft) => _QueuedItemTile(
              draft: draft,
              onChanged: onDescriptionChanged,
              onRemove: () {
                onRemove(draft);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnQueueCard extends StatelessWidget {
  const _ReturnQueueCard({
    required this.drafts,
    required this.racks,
    required this.onLocationSelected,
    required this.onDescriptionChanged,
    required this.onRemove,
  });

  final List<_QueuedItemDraft> drafts;
  final List<AllowedLocation> racks;
  final void Function(_QueuedItemDraft draft, String location) onLocationSelected;
  final VoidCallback onDescriptionChanged;
  final Future<void> Function(_QueuedItemDraft draft) onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        if (drafts.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.55)),
            ),
            child: const _EmptyQueue(
              text: 'No items in the return queue yet. Scan from the phone or from this PC.',
            ),
          ),
        ...drafts.map(
          (draft) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.55)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _QueuedItemHeader(
                    draft: draft,
                    onRemove: () {
                      onRemove(draft);
                    },
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: racks.map((rack) {
                      final selected = draft.selectedLocation == rack.code;
                      return ChoiceChip(
                        label: Text(rack.code),
                        selected: selected,
                        onSelected: (_) => onLocationSelected(draft, rack.code),
                        selectedColor: colorScheme.primary,
                        labelStyle: TextStyle(
                          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: draft.descriptionController,
                    onChanged: (_) => onDescriptionChanged(),
                    decoration: const InputDecoration(
                      labelText: 'Description or note (optional)',
                      hintText: 'Example: handle checked, returned after cleaning',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QueuedItemTile extends StatelessWidget {
  const _QueuedItemTile({
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final _QueuedItemDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: <Widget>[
          _QueuedItemHeader(
            draft: draft,
            onRemove: onRemove,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: draft.descriptionController,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Description or note (optional)',
              hintText: 'Example: needed for setup, checked before release',
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
    final isAvailable = draft.item.status == ItemStatus.available;
    final colorScheme = Theme.of(context).colorScheme;
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
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text('QR: ${draft.item.qrCode}'),
              const SizedBox(height: 2),
              Text('Current location: ${draft.item.currentLocation}'),
              const SizedBox(height: 2),
              Text('Recorded as: ${draft.actorName}'),
              const SizedBox(height: 6),
              _CountPill(label: isAvailable ? 'Available' : 'Borrowed'),
            ],
          ),
        ),
        Column(
          children: <Widget>[
            _CountPill(label: draft.fromPairing ? 'Phone scan' : 'PC scan'),
            const SizedBox(height: 8),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
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
    return Text(
      text,
      style: TextStyle(
        height: 1.5,
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
