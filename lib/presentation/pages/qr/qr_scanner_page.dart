import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/qr_service.dart';

// QR Scanner sayfası
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final QRService _qrService = QRService();
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _flashEnabled = false;
  bool _hasScanned = false;
  String _scanStatusText = 'QR kod taramak için kamerayı QR koda doğrultun';

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
      autoStart: true,
    );

    setState(() {
      _isScanning = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('QR Kod Tarayıcı'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          // Flash Toggle
          IconButton(
            icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          // Manual URL Input
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showManualInputDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Scanner
          if (_isScanning && _scannerController != null)
            MobileScanner(
              controller: _scannerController!,
              onDetect: _onQRCodeDetected,
            ),

          // Scanning Overlay
          _buildScanningOverlay(),

          // Bottom Info Panel
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      decoration: BoxDecoration(color: AppColors.black.withOpacity(0.5)),
      child: Stack(
        children: [
          // Scanning Frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hasScanned ? AppColors.success : AppColors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  ...List.generate(4, (index) {
                    final isTop = index < 2;
                    final isLeft = index % 2 == 0;
                    return Positioned(
                      top: isTop ? 0 : null,
                      bottom: isTop ? null : 0,
                      left: isLeft ? 0 : null,
                      right: isLeft ? null : 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _hasScanned
                              ? AppColors.success
                              : AppColors.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isTop && isLeft ? 10 : 0),
                            topRight: Radius.circular(
                              isTop && !isLeft ? 10 : 0,
                            ),
                            bottomLeft: Radius.circular(
                              !isTop && isLeft ? 10 : 0,
                            ),
                            bottomRight: Radius.circular(
                              !isTop && !isLeft ? 10 : 0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Success Icon
                  if (_hasScanned)
                    const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 50,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Status Text
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _scanStatusText,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openQRTestPage,
                icon: const Icon(Icons.qr_code),
                label: const Text('QR Kod Test Et'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Demo Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openDemoMenu,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Demo Menüyü Görüntüle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Help Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'QR kodu taramak için kamerayı QR koda doğrultun',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null) return;

    setState(() {
      _hasScanned = true;
      _scanStatusText = 'QR kod başarıyla tarandı!';
    });

    // Vibration feedback
    HapticFeedback.lightImpact();

    // Process QR code
    _processQRCode(qrData);
  }

  Future<void> _processQRCode(String qrData) async {
    try {
      // Parse QR code using QR service
      final scanResult = _qrService.parseQRCode(qrData);

      if (scanResult != null) {
        // QR servisinin parseQRCode sonucunu kullan
        _showQRCodeInfo(scanResult);

        // Navigate to menu after showing info
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/menu',
              arguments: {
                'businessId': scanResult.businessId,
                'tableNumber': scanResult.tableNumber,
              },
            );
          }
        });
      } else {
        // Try to parse as regular URL
        final uri = Uri.tryParse(qrData);
        if (uri != null &&
            uri.pathSegments.length >= 2 &&
            uri.pathSegments[0] == 'menu') {
          final businessId = uri.pathSegments[1];
          final tableNumber = uri.queryParameters['table'];

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/menu',
              arguments: {'businessId': businessId, 'tableNumber': tableNumber},
            );
          }
        } else {
          throw Exception('Bu QR kod desteklenmiyor');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasScanned = false;
          _scanStatusText = 'QR kod okunamadı. Tekrar deneyin.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR kod hatası: $e'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Tekrar Dene',
              onPressed: () {
                setState(() {
                  _hasScanned = false;
                  _scanStatusText =
                      'QR kod taramak için kamerayı QR koda doğrultun';
                });
              },
            ),
          ),
        );
      }
    }
  }

  void _showQRCodeInfo(QRScanResult scanResult) {
    final message = scanResult.tableNumber != null
        ? 'Masa ${scanResult.tableNumber} QR kodu tarandı'
        : 'İşletme QR kodu tarandı';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFlash() {
    if (_scannerController != null) {
      _scannerController!.toggleTorch();
      setState(() {
        _flashEnabled = !_flashEnabled;
      });
    }
  }

  void _showManualInputDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Kod URL\'i Girin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'QR Kod URL\'i',
                hintText: 'https://masamenu.app/menu/...',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            // Demo URL butonu
            TextButton(
              onPressed: () {
                urlController.text = _qrService.generateTableQRUrl(
                  'demo-business-001',
                  '01',
                );
              },
              child: const Text('Demo URL Ekle'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (urlController.text.isNotEmpty) {
                _processQRCode(urlController.text.trim());
              }
            },
            child: const Text('Menüyü Aç'),
          ),
        ],
      ),
    );
  }

  void _openDemoMenu() {
    Navigator.pushReplacementNamed(
      context,
      '/menu',
      arguments: {'businessId': 'demo-business-001'},
    );
  }

  void _openQRTestPage() {
    Navigator.pushNamed(
      context,
      '/qr-test',
      arguments: {'businessId': 'demo-business-001', 'tableNumber': '01'},
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }
}
