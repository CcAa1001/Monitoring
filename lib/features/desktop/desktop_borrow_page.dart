part of 'desktop_shell_screen_v2.dart';

class DesktopBorrowPage extends StatelessWidget {
  const DesktopBorrowPage({
    super.key,
    required this.pairingSession,
    required this.onBorrow,
    required this.role,
  });

  final PairingSession? pairingSession;
  final VoidCallback? onBorrow;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        _DesktopTransactionHero(
          accentColors: const <Color>[Color(0xFF6D52F5), Color(0xFF4E35D8)],
          badge: tr('Ruang kerja peminjaman'),
          title: tr('Pinjamkan barang dengan antrean yang lebih rapi dan pilihan pindai yang lebih jelas.'),
          description:
              tr('Mulai dari kamera meja atau ponsel yang tersambung, lalu kirim setiap pindaian ke satu alur peminjaman yang terstruktur sebelum memilih line tujuan.'),
          primaryLabel: tr('Buka antrean pinjam'),
          primaryIcon: Icons.call_made_rounded,
          primaryAction: onBorrow,
          secondaryLabel: pairingSession == null ? tr('Sambungkan ponsel di dasbor') : tr('Ponsel tersambung dan siap'),
          secondaryIcon: Icons.phonelink_ring_rounded,
          statusTitle: tr('Stasiun peminjaman'),
          statusValue: pairingSession == null ? tr('Hanya pemindai meja') : tr('Dibantu ponsel'),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 7,
              child: DesktopPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _DesktopTransactionPanelHeader(
                      title: tr('Pilih cara barang masuk ke antrean'),
                      caption: tr('Kedua cara masuk ke antrean pinjam yang sama, sehingga meja cukup melakukan satu langkah tinjau dan kirim.'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _DesktopActionCard(
                            title: tr('Pemindai meja'),
                            description: tr('Paling cocok saat barang diserahkan langsung ke ruang peralatan. Cepat, langsung, dan ideal untuk operator tetap.'),
                            icon: Icons.qr_code_scanner_rounded,
                            buttonLabel: tr('Pindai di PC ini'),
                            onTap: onBorrow,
                            primary: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DesktopActionCard(
                            title: tr('Pemindai ponsel tersambung'),
                            description: pairingSession == null
                                ? tr('Sambungkan ponsel terlebih dahulu jika ingin memindai sambil berkeliling dan tetap masuk ke antrean pinjam yang sama.')
                                : tr('Ponsel {device} dapat berkeliling ruangan dan terus mengirim pindaian pinjam ke sini.', {'device': pairingSession!.connectedDeviceName ?? tr('pemindai')}),
                            icon: Icons.smartphone_rounded,
                            buttonLabel: pairingSession == null ? tr('Belum tersambung') : tr('Gunakan ponsel tersambung'),
                            onTap: pairingSession == null ? null : onBorrow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _DesktopProcessStrip(
                      steps: <String>[
                        tr('Pindai QR barang'),
                        tr('Tinjau setiap baris di antrean'),
                        tr('Pilih line peminjam'),
                        tr('Konfirmasi peminjaman'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: DesktopPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _DesktopTransactionPanelHeader(
                      title: tr('Ringkasan sambungan ponsel'),
                      caption: tr('Ponsel yang tersambung dapat terus memindai sementara meja meninjau dan mengirim antrean.'),
                    ),
                    const SizedBox(height: 18),
                    _DesktopPairingSummary(
                      pairingSession: pairingSession,
                      emptyMessage: tr('Belum ada ponsel yang tersambung. Mulai sambungan dari dasbor untuk menampilkan QR desktop dan menghubungkan pemindai ponsel.'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (role == UserRole.viewer)
          DesktopPanel(
            child: Text(
              tr('Akun ini dapat memantau dan meninjau aktivitas peminjaman, tetapi tidak dapat memulai antrean pinjam. Gunakan akun operator atau admin untuk transaksi.'),
            ),
          ),
      ],
    );
  }
}
