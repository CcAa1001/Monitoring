enum PairingSessionStatus {
  idle,
  waitingForPhone,
  connected,
  scanned,
}

enum PairActionMode {
  borrow,
  returnItem,
  registerItem,
}

class PairingScanEntry {
  const PairingScanEntry({
    required this.qrCode,
    required this.mode,
    required this.scannedAt,
    this.scannedBy,
  });

  final String qrCode;
  final PairActionMode mode;
  final DateTime scannedAt;
  final String? scannedBy;

  PairingScanEntry copyWith({
    String? qrCode,
    PairActionMode? mode,
    DateTime? scannedAt,
    String? scannedBy,
  }) {
    return PairingScanEntry(
      qrCode: qrCode ?? this.qrCode,
      mode: mode ?? this.mode,
      scannedAt: scannedAt ?? this.scannedAt,
      scannedBy: scannedBy ?? this.scannedBy,
    );
  }
}

class PairingSession {
  const PairingSession({
    required this.code,
    required this.status,
    this.connectedDeviceName,
    this.lastScannedQr,
    this.activeMode,
    this.pendingScans = const <PairingScanEntry>[],
  });

  final String code;
  final PairingSessionStatus status;
  final String? connectedDeviceName;
  final String? lastScannedQr;
  final PairActionMode? activeMode;
  final List<PairingScanEntry> pendingScans;

  PairingSession copyWith({
    String? code,
    PairingSessionStatus? status,
    String? connectedDeviceName,
    String? lastScannedQr,
    PairActionMode? activeMode,
    List<PairingScanEntry>? pendingScans,
  }) {
    return PairingSession(
      code: code ?? this.code,
      status: status ?? this.status,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      lastScannedQr: lastScannedQr ?? this.lastScannedQr,
      activeMode: activeMode ?? this.activeMode,
      pendingScans: pendingScans ?? this.pendingScans,
    );
  }
}
