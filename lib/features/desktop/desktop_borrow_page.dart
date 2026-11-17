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
          badge: 'Ruang kerja peminjaman',
          title: 'Pinjamkan barang dengan antrean yang lebih rapi dan pilihan pindai yang lebih jelas.',
          description:
              'Mulai dari kamera meja atau ponsel yang tersambung, lalu kirim setiap pindaian ke satu alur peminjaman yang terstruktur sebelum memilih line tujuan.',
          primaryLabel: 'Buka antrean pinjam',
          primaryIcon: Icons.call_made_rounded,
          primaryAction: onBorrow,
          secondaryLabel: pairingSession == null ? 'Sambungkan ponsel di dasbor' : 'Ponsel tersambung dan siap',
          secondaryIcon: Icons.phonelink_ring_rounded,
          statusTitle: 'Stasiun peminjaman',
          statusValue: pairingSession == null ? 'Hanya pemindai meja' : 'Dibantu ponsel',
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
                    const _DesktopTransactionPanelHeader(
                      title: 'Pilih cara barang masuk ke antrean',
                      caption: 'Kedua cara masuk ke antrean pinjam yang sama, sehingga meja cukup melakukan satu langkah tinjau dan kirim.',
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _DesktopActionCard(
                            title: 'Pemindai meja',
                            description: 'Paling cocok saat barang diserahkan langsung ke ruang peralatan. Cepat, langsung, dan ideal untuk operator tetap.',
                            icon: Icons.qr_code_scanner_rounded,
                            buttonLabel: 'Pindai di PC ini',
                            onTap: onBorrow,
                            primary: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DesktopActionCard(
                            title: 'Pemindai ponsel tersambung',
                            description: pairingSession == null
                                ? 'Sambungkan ponsel terlebih dahulu jika ingin memindai sambil berkeliling dan tetap masuk ke antrean pinjam yang sama.'
                                : 'Ponsel ${pairingSession!.connectedDeviceName ?? 'pemindai'} dapat berkeliling ruangan dan terus mengirim pindaian pinjam ke sini.',
                            icon: Icons.smartphone_rounded,
                            buttonLabel: pairingSession == null ? 'Belum tersambung' : 'Gunakan ponsel tersambung',
                            onTap: pairingSession == null ? null : onBorrow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _DesktopProcessStrip(
                      steps: <String>[
                        'Pindai QR barang',
                        'Tinjau setiap baris di antrean',
                        'Pilih line peminjam',
                        'Konfirmasi peminjaman',
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
                    const _DesktopTransactionPanelHeader(
                      title: 'Ringkasan sambungan ponsel',
                      caption: 'Ponsel yang tersambung dapat terus memindai sementara meja meninjau dan mengirim antrean.',
                    ),
                    const SizedBox(height: 18),
                    _DesktopPairingSummary(
                      pairingSession: pairingSession,
                      emptyMessage: 'Belum ada ponsel yang tersambung. Mulai sambungan dari dasbor untuk menampilkan QR desktop dan menghubungkan pemindai ponsel.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (role == UserRole.viewer)
          const DesktopPanel(
            child: Text(
              'Akun ini dapat memantau dan meninjau aktivitas peminjaman, tetapi tidak dapat memulai antrean pinjam. Gunakan akun operator atau admin untuk transaksi.',
            ),
          ),
      ],
    );
  }
}
