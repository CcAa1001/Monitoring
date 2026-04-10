part of 'action_flow_screen.dart';

class _FlowBanner extends StatelessWidget {
  const _FlowBanner({
    required this.isBorrow,
  });

  final bool isBorrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF8F6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECEFF6)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFF0ECFF),
            foregroundColor: const Color(0xFF5B39EA),
            child: Icon(
              isBorrow ? Icons.call_made_rounded : Icons.assignment_return_rounded,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isBorrow
                  ? 'Borrowing starts with a scan, then one tap for the correct line.'
                  : 'Returning starts with a scan, then one tap for the correct rack.',
              style: const TextStyle(
                color: Color(0xFF183A37),
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessNotice extends StatelessWidget {
  const _ReadinessNotice({
    required this.isBorrow,
    required this.item,
  });

  final bool isBorrow;
  final Item item;

  @override
  Widget build(BuildContext context) {
    final canProceed = isBorrow ? item.status == ItemStatus.available : item.status == ItemStatus.borrowed;
    final accent = canProceed ? const Color(0xFF16C098) : const Color(0xFFEA5455);

    String message;
    if (canProceed) {
      message = isBorrow
          ? 'This item is available and can be borrowed now.'
          : 'This item is currently out, so it can be returned to a rack.';
    } else {
      message = isBorrow
          ? 'This item is already borrowed. Ask the operator to return it before borrowing again.'
          : 'This item is already marked as available in the equipment room.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}

class _SubmitPreview extends StatelessWidget {
  const _SubmitPreview({
    required this.title,
    required this.message,
    required this.isReady,
    required this.item,
    required this.actorName,
    required this.selectedLocation,
    required this.isBorrow,
  });

  final String title;
  final String message;
  final bool isReady;
  final Item? item;
  final String? actorName;
  final String? selectedLocation;
  final bool isBorrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isReady ? const Color(0xFFF3F9F7) : const Color(0xFFFFF6F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isReady ? const Color(0xFFBCE9D9) : const Color(0xFFFFDCCB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF183A37),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              height: 1.5,
              color: Color(0xFF4D635F),
            ),
          ),
          if (item != null || actorName != null || selectedLocation != null) ...<Widget>[
            const SizedBox(height: 14),
            if (item != null) _SummaryRow(label: 'Item', value: item!.name),
            if (actorName != null) _SummaryRow(label: isBorrow ? 'Borrower' : 'Returner', value: actorName!),
            if (selectedLocation != null)
              _SummaryRow(
                label: isBorrow ? 'Destination line' : 'Rack location',
                value: selectedLocation!,
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF5D7470),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF183A37),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PairingStatusCard extends StatelessWidget {
  const _PairingStatusCard({
    required this.session,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final PairingSession session;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  String get _statusLabel {
    switch (session.status) {
      case PairingSessionStatus.waitingForPhone:
        return 'Waiting for phone';
      case PairingSessionStatus.connected:
        return 'Phone connected';
      case PairingSessionStatus.scanned:
        return 'Scan received';
      case PairingSessionStatus.idle:
        return 'Idle';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.phonelink_ring_rounded, color: Color(0xFF5B39EA)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Phone pairing: ${session.code}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183A37),
                  ),
                ),
              ),
              IconButton(
                onPressed: isRefreshing ? null : () => onRefresh(),
                icon: isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Status: $_statusLabel',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            session.connectedDeviceName == null
                ? 'No phone connected yet.'
                : 'Connected device: ${session.connectedDeviceName}',
          ),
          const SizedBox(height: 6),
          Text(
            session.lastScannedQr == null || session.lastScannedQr!.isEmpty
                ? 'No incoming QR scan yet.'
                : 'Latest incoming QR: ${session.lastScannedQr}',
            style: TextStyle(
              color: session.lastScannedQr == null || session.lastScannedQr!.isEmpty
                  ? const Color(0xFF5E6B82)
                  : const Color(0xFF5B39EA),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String number;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECEFF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF5B39EA),
                foregroundColor: Colors.white,
                child: Text(
                  number,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF183A37),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5D7470),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ScannedItemCard extends StatelessWidget {
  const _ScannedItemCard({
    required this.item,
  });

  final Item item;

  @override
  Widget build(BuildContext context) {
    final available = item.status == ItemStatus.available;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEFF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF183A37),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (available ? const Color(0xFF16C098) : const Color(0xFFEA5455)).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  available ? 'Available' : 'Borrowed',
                  style: TextStyle(
                    color: available ? const Color(0xFF16C098) : const Color(0xFFEA5455),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'QR: ${item.qrCode}',
            style: const TextStyle(color: Color(0xFF5D7470)),
          ),
          const SizedBox(height: 4),
          Text(
            'Current location: ${item.currentLocation}',
            style: const TextStyle(color: Color(0xFF5D7470)),
          ),
          if (item.lastBorrowerName != null && item.lastBorrowerName!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Latest borrower: ${item.lastBorrowerName}',
              style: const TextStyle(color: Color(0xFF5D7470)),
            ),
          ],
        ],
      ),
    );
  }
}
