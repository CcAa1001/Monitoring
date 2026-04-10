import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    this.allowContinuous = false,
    this.onDetected,
  });

  final bool allowContinuous;
  final Future<bool> Function(String qrCode)? onDetected;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _hasDetected = false;
  bool _isProcessing = false;
  String? _statusText;

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_hasDetected || _isProcessing) return;

    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final rawValue = barcode?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    if (widget.allowContinuous && widget.onDetected != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final success = await widget.onDetected!(rawValue);
        if (!mounted) return;
        setState(() {
          _statusText = success ? 'Scan success' : 'Scan failed';
        });
        await Future<void>.delayed(const Duration(milliseconds: 900));
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusText = null;
          });
        }
      }
      return;
    }

    _hasDetected = true;
    Navigator.of(context).pop(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFE58F2A),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          if (_statusText != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: _statusText == 'Scan success' ? const Color(0xFF16C098) : const Color(0xFFEA5455),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.allowContinuous
                    ? 'Point the camera at each QR code. The scanner will stay open after every successful scan.'
                    : 'Point the camera at the QR code. The app will continue automatically after a successful scan.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
