part of 'desktop_shell_screen_v2.dart';

class DesktopReturnPage extends StatelessWidget {
  const DesktopReturnPage({
    super.key,
    required this.pairingSession,
    required this.onReturn,
    required this.role,
  });

  final PairingSession? pairingSession;
  final VoidCallback? onReturn;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        _DesktopTransactionHero(
          accentColors: const <Color>[Color(0xFF14B8A6), Color(0xFF0F9A8A)],
          badge: 'Ruang kerja pengembalian',
          title: 'Kembalikan barang melalui alur meja yang lebih teliti dan modern.',
          description:
              'Kumpulkan setiap pengembalian dalam satu antrean, jaga alur pemindai ponsel dan desktop tetap konsisten, dan tempatkan setiap barang kembali ke rak yang benar dengan tampilan yang lebih rapi.',
          primaryLabel: 'Buka antrean kembali',
          primaryIcon: Icons.assignment_return_rounded,
          primaryAction: onReturn,
          secondaryLabel: pairingSession == null ? 'Sambungkan ponsel di dasbor' : 'Ponsel tersambung dan siap',
          secondaryIcon: Icons.phonelink_ring_rounded,
          statusTitle: 'Stasiun pengembalian',
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
                      title: 'Pilih cara barang kembali masuk ke antrean',
                      caption: 'Pemindaian pengembalian dapat dilakukan di meja atau di dalam ruangan, tetapi tetap masuk ke satu antrean terkontrol untuk penentuan rak akhir.',
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _DesktopActionCard(
                            title: 'Pemindai meja',
                            description: 'Paling cocok untuk barang yang dikembalikan langsung ke ruang peralatan. Cara tercepat saat operator sudah berada di meja.',
                            icon: Icons.qr_code_scanner_rounded,
                            buttonLabel: 'Pindai di PC ini',
                            onTap: onReturn,
                            primary: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DesktopActionCard(
                            title: 'Pemindai ponsel tersambung',
                            description: pairingSession == null
                                ? 'Sambungkan ponsel terlebih dahulu jika ingin memindai pengembalian di luar meja lalu mengirimnya ke sini.'
                                : 'Ponsel ${pairingSession!.connectedDeviceName ?? 'pemindai'} dapat berkeliling dan terus mengirim pindaian pengembalian ke antrean meja.',
                            icon: Icons.smartphone_rounded,
                            buttonLabel: pairingSession == null ? 'Belum tersambung' : 'Gunakan ponsel tersambung',
                            onTap: pairingSession == null ? null : onReturn,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _DesktopProcessStrip(
                      steps: <String>[
                        'Pindai QR barang yang dikembalikan',
                        'Tinjau setiap baris antrean',
                        'Pilih lokasi rak akhir',
                        'Konfirmasi pengembalian',
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
                      caption: 'Ponsel yang tersambung menjaga pengembalian tetap berjalan tanpa harus membawa semuanya ke meja terlebih dahulu.',
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
              'Akun ini dapat memantau dan meninjau aktivitas pengembalian, tetapi tidak dapat memulai antrean kembali. Gunakan akun operator atau admin untuk transaksi.',
            ),
          ),
      ],
    );
  }
}

class _DesktopTransactionHero extends StatelessWidget {
  const _DesktopTransactionHero({
    required this.accentColors,
    required this.badge,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.primaryAction,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.statusTitle,
    required this.statusValue,
  });

  final List<Color> accentColors;
  final String badge;
  final String title;
  final String description;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? primaryAction;
  final String secondaryLabel;
  final IconData secondaryIcon;
  final String statusTitle;
  final String statusValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: accentColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accentColors.first.withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFF0ECFF),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: primaryAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: accentColors.last,
                      ),
                      icon: Icon(primaryIcon),
                      label: Text(primaryLabel),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(secondaryIcon, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            secondaryLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Mode saat ini',
                    style: TextStyle(
                      color: Color(0xFFF0ECFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    statusTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _DesktopHeroMiniStat(
                    label: 'Gaya antrean',
                    value: 'Baris terstruktur',
                  ),
                  const SizedBox(height: 10),
                  const _DesktopHeroMiniStat(
                    label: 'Pengiriman',
                    value: 'Satu langkah tinjau',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTransactionPanelHeader extends StatelessWidget {
  const _DesktopTransactionPanelHeader({
    required this.title,
    required this.caption,
  });

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2533),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: TextStyle(
            height: 1.5,
            color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6C748B),
          ),
        ),
      ],
    );
  }
}

class _DesktopActionCard extends StatelessWidget {
  const _DesktopActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonLabel,
    this.onTap,
    this.primary = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2238) : const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2B3250) : const Color(0xFFECEFF6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: primary ? const Color(0xFF5B39EA) : const Color(0xFFF0ECFF),
            foregroundColor: primary ? Colors.white : const Color(0xFF5B39EA),
            child: Icon(icon),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1F2533),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              height: 1.6,
              color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6A738A),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: primary
                ? FilledButton.icon(
                    onPressed: onTap,
                    icon: Icon(icon),
                    label: Text(buttonLabel),
                  )
                : OutlinedButton.icon(
                    onPressed: onTap,
                    icon: Icon(icon),
                    label: Text(buttonLabel),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DesktopProcessStrip extends StatelessWidget {
  const _DesktopProcessStrip({
    required this.steps,
  });

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List<Widget>.generate(steps.length, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111726) : const Color(0xFFF5F7FC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF5B39EA).withValues(alpha: isDark ? 0.30 : 0.12),
                foregroundColor: const Color(0xFF5B39EA),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                steps[index],
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1F2533),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _DesktopPairingSummary extends StatelessWidget {
  const _DesktopPairingSummary({
    required this.pairingSession,
    required this.emptyMessage,
  });

  final PairingSession? pairingSession;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2238) : const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(22),
      ),
      child: pairingSession == null
          ? Text(
              emptyMessage,
              style: TextStyle(
                height: 1.5,
                color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6A738A),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DesktopPairingStat(label: 'Kode sambungan', value: pairingSession!.code),
                const SizedBox(height: 12),
                _DesktopPairingStat(
                  label: 'Perangkat',
                  value: (pairingSession!.connectedDeviceName ?? '').isEmpty
                      ? 'Menunggu ponsel'
                      : pairingSession!.connectedDeviceName!,
                ),
                const SizedBox(height: 12),
                _DesktopPairingStat(
                  label: 'Pindaian terakhir',
                  value: (pairingSession!.lastScannedQr ?? '').isEmpty ? '-' : pairingSession!.lastScannedQr!,
                ),
              ],
            ),
    );
  }
}

class _DesktopPairingStat extends StatelessWidget {
  const _DesktopPairingStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF7E8698),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1F2533),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DesktopHeroMiniStat extends StatelessWidget {
  const _DesktopHeroMiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF0ECFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
