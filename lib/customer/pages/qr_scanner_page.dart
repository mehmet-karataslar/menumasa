import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/url_service.dart';
import 'qr_menu_page.dart';
import '../../shared/pages/universal_qr_menu_page.dart';
import 'menu_page.dart';
import 'dart:convert'; // Added for jsonDecode

/// QR Kod Tarayıcı Sayfası
class QRScannerPage extends StatefulWidget {
  final String? userId;

  const QRScannerPage({
    super.key,
    this.userId,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with TickerProviderStateMixin {
  final UrlService _urlService = UrlService();

  late AnimationController _scanAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  MobileScannerController? _qrController;
  bool _isScanning = false;
  String? _scannedCode;
  bool _flashOn = false;
  bool _hasPermission = false;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateURL();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _qrController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: _flashOn,
      );

      setState(() {
        _hasPermission = true;
        _permissionError = null;
      });
    } catch (e) {
      print('Kamera başlatma hatası: $e');
      setState(() {
        _hasPermission = false;
        _permissionError = 'Kamera erişimi sağlanamadı: $e';
      });
    }
  }

  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _scanAnimationController.repeat();
    _pulseAnimationController.repeat(reverse: true);
  }

  void _updateURL() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/customer/${widget.userId}/qr-scanner?t=$timestamp';
    _urlService.updateUrl(dynamicRoute, customTitle: 'QR Tarayıcı | MasaMenu');
  }

  Widget _buildPermissionError() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.greyDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: AppColors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Kamera Erişimi Gerekli',
            style: AppTypography.h6.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _permissionError ??
                  'QR kod tarayabilmek için kamera erişimi gereklidir.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializeCamera,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _qrController?.dispose();
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
    });

    HapticFeedback.mediumImpact();

    // Kamera erişimini başlat
    if (_qrController != null && _hasPermission) {
      await _qrController!.start();
    }
  }

  void _onQRCodeDetected(BarcodeCapture barcodeCapture) {
    final barcode = barcodeCapture.barcodes.first;
    if (barcode.rawValue != null && !_isScanning) {
      _handleQRCodeFromCamera(barcode.rawValue!);
    }
  }

  Future<void> _handleQRCodeFromCamera(String qrCode) async {
    setState(() {
      _isScanning = true;
    });

    HapticFeedback.heavyImpact();

    // Kamera taramayı durdur
    if (_qrController != null) {
      await _qrController!.stop();
    }

    try {
      print('📱 QR Scanner: Processing external camera QR code: $qrCode');

      // Enhanced QR kod analizi ve business ID çıkarımı
      final analysisResult = _analyzeQRCode(qrCode);

      if (!analysisResult['isValid']) {
        throw Exception(analysisResult['error'] ?? 'Geçersiz QR kod formatı');
      }

      final businessId = analysisResult['businessId'] as String;
      final tableNumber = analysisResult['tableNumber'] as int?;

      print(
          '✅ QR Analysis successful - Business: $businessId, Table: $tableNumber');

      await _handleQRCodeDetected(qrCode, businessId, tableNumber: tableNumber);
    } catch (e) {
      print('❌ QR Scanner Error: $e');

      // Enhanced error handling with user-friendly messages
      String userMessage = _getQRErrorMessage(e.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(userMessage),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'QR Kod: ${qrCode.length > 50 ? qrCode.substring(0, 50) + '...' : qrCode}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Manuel Giriş',
              textColor: Colors.white,
              onPressed: () => _handleManualEntry(),
            ),
          ),
        );
      }

      setState(() {
        _isScanning = false;
      });

      // Kamera taramayı tekrar başlat
      if (_qrController != null && _hasPermission) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          await _qrController!.start();
        }
      }
    }
  }

  /// Enhanced QR code analysis with detailed logging
  Map<String, dynamic> _analyzeQRCode(String qrCode) {
    print('🔍 QR Analysis starting for: $qrCode');

    try {
      // Method 1: URL-based QR codes
      if (qrCode.startsWith('http://') || qrCode.startsWith('https://')) {
        return _analyzeUrlQRCode(qrCode);
      }

      // Method 2: Custom format QR codes (masamenu_businessId_table_X)
      if (qrCode.startsWith('masamenu_')) {
        return _analyzeCustomFormatQRCode(qrCode);
      }

      // Method 3: Direct business ID format
      if (_isDirectBusinessId(qrCode)) {
        return {
          'isValid': true,
          'businessId': qrCode.trim(),
          'tableNumber': null,
          'format': 'direct_business_id'
        };
      }

      // Method 4: JSON format QR codes
      if (qrCode.startsWith('{') && qrCode.endsWith('}')) {
        return _analyzeJsonQRCode(qrCode);
      }

      return {
        'isValid': false,
        'error': 'QR kod formatı tanımlanamadı',
        'details':
            'Supported formats: URL, masamenu_*, direct business ID, JSON'
      };
    } catch (e) {
      print('❌ QR Analysis error: $e');
      return {
        'isValid': false,
        'error': 'QR kod analiz hatası: $e',
      };
    }
  }

  /// Analyze URL-based QR codes
  Map<String, dynamic> _analyzeUrlQRCode(String qrCode) {
    try {
      print('🔗 Analyzing URL QR code');
      final uri = Uri.parse(qrCode);

      // Extract business ID from query parameters
      String? businessId =
          uri.queryParameters['business'] ?? uri.queryParameters['businessId'];

      // Extract from path if not in query params
      if (businessId == null) {
        if (uri.pathSegments.contains('qr-menu') &&
            uri.pathSegments.length > 1) {
          final index = uri.pathSegments.indexOf('qr-menu');
          if (index + 1 < uri.pathSegments.length) {
            businessId = uri.pathSegments[index + 1];
          }
        } else if (uri.pathSegments.contains('menu') &&
            uri.pathSegments.length > 1) {
          final index = uri.pathSegments.indexOf('menu');
          if (index + 1 < uri.pathSegments.length) {
            businessId = uri.pathSegments[index + 1];
          }
        }
      }

      // Extract table number
      int? tableNumber;
      final tableString =
          uri.queryParameters['table'] ?? uri.queryParameters['tableNumber'];
      if (tableString != null) {
        tableNumber = int.tryParse(tableString);
      }

      if (businessId == null || businessId.isEmpty) {
        return {
          'isValid': false,
          'error': 'URL\'de işletme bilgisi bulunamadı',
        };
      }

      return {
        'isValid': true,
        'businessId': businessId,
        'tableNumber': tableNumber,
        'format': 'url',
        'originalUrl': qrCode,
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': 'URL parse hatası: $e',
      };
    }
  }

  /// Analyze custom format QR codes (masamenu_*)
  Map<String, dynamic> _analyzeCustomFormatQRCode(String qrCode) {
    try {
      print('🏷️ Analyzing custom format QR code');
      final parts = qrCode.split('_');

      if (parts.length < 2) {
        return {
          'isValid': false,
          'error': 'Geçersiz masamenu formatı',
        };
      }

      final businessId = parts[1];
      int? tableNumber;

      // Look for table number
      if (parts.length >= 4 && parts[2] == 'table') {
        tableNumber = int.tryParse(parts[3]);
      }

      return {
        'isValid': true,
        'businessId': businessId,
        'tableNumber': tableNumber,
        'format': 'masamenu_custom',
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': 'Custom format parse hatası: $e',
      };
    }
  }

  /// Analyze JSON format QR codes
  Map<String, dynamic> _analyzeJsonQRCode(String qrCode) {
    try {
      print('📋 Analyzing JSON QR code');
      final Map<String, dynamic> jsonData = jsonDecode(qrCode);

      final businessId = jsonData['businessId'] ?? jsonData['business'];
      final tableNumber = jsonData['tableNumber'] ?? jsonData['table'];

      if (businessId == null) {
        return {
          'isValid': false,
          'error': 'JSON\'da işletme bilgisi bulunamadı',
        };
      }

      return {
        'isValid': true,
        'businessId': businessId.toString(),
        'tableNumber': tableNumber is int
            ? tableNumber
            : int.tryParse(tableNumber?.toString() ?? ''),
        'format': 'json',
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': 'JSON parse hatası: $e',
      };
    }
  }

  /// Check if QR code is a direct business ID
  bool _isDirectBusinessId(String qrCode) {
    // Business ID should be alphanumeric, 3-50 characters
    if (qrCode.length < 3 || qrCode.length > 50) return false;

    // Should not contain spaces or special characters (except _ and -)
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(qrCode)) return false;

    // Should not be a common word
    const commonWords = ['test', 'demo', 'admin', 'user', 'guest'];
    if (commonWords.contains(qrCode.toLowerCase())) return false;

    return true;
  }

  /// Get user-friendly error message
  String _getQRErrorMessage(String error) {
    if (error.contains('URL\'de işletme bilgisi bulunamadı')) {
      return 'QR kodunda işletme bilgisi eksik. Lütfen işletmeden yeni bir QR kod isteyin.';
    } else if (error.contains('Geçersiz QR kod formatı')) {
      return 'Bu QR kod desteklenmeyen bir formatta. Manuel kod girişini deneyin.';
    } else if (error.contains('parse hatası')) {
      return 'QR kod okunamadı. Kodu temiz ve düz bir yüzeyde tekrar taratın.';
    } else if (error.contains('formatı tanımlanamadı')) {
      return 'QR kod formatı tanınmıyor. Lütfen işletmeden yeni bir QR kod isteyin.';
    } else {
      return 'QR kod okunamadı. Lütfen tekrar deneyin veya manuel kod girişi yapın.';
    }
  }

  String _extractBusinessIdFromQR(String qrCode) {
    print('🔍 QR Kod analiz ediliyor: $qrCode');

    // Use the enhanced analysis method
    final analysis = _analyzeQRCode(qrCode);

    if (analysis['isValid']) {
      final businessId = analysis['businessId'] as String;
      print('✅ Business ID extracted: $businessId');
      return businessId;
    } else {
      print('❌ ${analysis['error']}');
      throw Exception(analysis['error']);
    }
  }

  int? _extractTableNumberFromQR(String qrCode) {
    try {
      print('🔍 Table number extraction: $qrCode');

      // Use the enhanced analysis method
      final analysis = _analyzeQRCode(qrCode);

      if (analysis['isValid']) {
        final tableNumber = analysis['tableNumber'] as int?;
        print('📋 Table number extracted: $tableNumber');
        return tableNumber;
      }

      return null;
    } catch (e) {
      print('❌ Table number extraction error: $e');
      return null;
    }
  }

  Future<void> _toggleFlash() async {
    if (_qrController == null || !_hasPermission) return;

    try {
      await _qrController!.toggleTorch();
      setState(() {
        _flashOn = !_flashOn;
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Flash toggle hatası: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_qrController == null || !_hasPermission) return;

    try {
      await _qrController!.switchCamera();
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Kamera değiştirme hatası: $e');
    }
  }

  Future<void> _handleQRCodeDetected(String qrCode, String businessId,
      {int? tableNumber}) async {
    setState(() {
      _scannedCode = qrCode;
      _isScanning = false;
    });

    HapticFeedback.heavyImpact();

    // QR kod başarıyla tarandı, direkt menü sayfasına yönlendir
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Direkt menu sayfasına yönlendir
      final dynamicRoute =
          '/menu/$businessId${tableNumber != null ? '?table=$tableNumber' : ''}?t=$timestamp';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MenuPage(businessId: businessId),
          settings: RouteSettings(
            name: dynamicRoute,
            arguments: {
              'businessId': businessId,
              'userId': widget.userId,
              'qrCode': qrCode,
              'tableNumber': tableNumber,
              'timestamp': timestamp,
              'referrer': 'qr_scanner',
              'scanMethod': 'external_camera',
            },
          ),
        ),
      );
    }
  }

  void _handleManualEntry() {
    _showManualEntryDialog();
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Manuel Giriş'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QR kodu okutamıyorsanız, işletme kodunu manuel olarak girebilirsiniz.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'İşletme Kodu',
                hintText: 'Örn: CAFE123',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.business_rounded),
              ),
              textCapitalization: TextCapitalization.characters,
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
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _handleManualCode(controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  void _handleManualCode(String code) {
    // Manuel kod ile işletme ID'si oluştur
    final businessId = 'manual_${code.toLowerCase()}';
    final qrCode = 'manual_entry_$code';

    _handleQRCodeDetected(qrCode, businessId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'QR Kod Tara',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _handleManualEntry,
            icon: const Icon(Icons.edit_rounded),
            color: AppColors.primary,
            tooltip: 'Manuel Giriş',
          ),
        ],
      ),
      body: Column(
        children: [
          // Üst açıklama
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: AppColors.white,
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'QR Kodu Tarayın',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masanızdaki QR kodu okutarak menüye anında erişin',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Tarama alanı
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // QR tarama frame
                  _buildScanFrame(),

                  const SizedBox(height: 32),

                  // Kamera kontrolleri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Flash butonu
                      IconButton(
                        onPressed: _toggleFlash,
                        icon: Icon(
                          _flashOn ? Icons.flash_on : Icons.flash_off,
                          color: _flashOn
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                        tooltip: 'Flash ${_flashOn ? 'Kapat' : 'Aç'}',
                      ),

                      const SizedBox(width: 16),

                      // Tarama durumu
                      _buildScanButton(),

                      const SizedBox(width: 16),

                      // Kamerayı değiştir butonu
                      IconButton(
                        onPressed: _flipCamera,
                        icon: const Icon(Icons.flip_camera_ios),
                        color: AppColors.textSecondary,
                        tooltip: 'Kamerayı Değiştir',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Manuel giriş butonu
                  OutlinedButton.icon(
                    onPressed: _handleManualEntry,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Manuel Kod Girişi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Alt bilgi
          Container(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'QR kodu bulamıyorsanız manuel kod girişi yapabilir veya garsona danışabilirsiniz.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFrame() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Kamera görünümü
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _scannedCode != null
                ? Container(
                    color: AppColors.success.withOpacity(0.1),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 80,
                      color: AppColors.success,
                    ),
                  )
                : _qrController == null || !_hasPermission
                    ? _buildPermissionError()
                    : MobileScanner(
                        controller: _qrController!,
                        onDetect: _onQRCodeDetected,
                        overlay:
                            Container(), // Kendi overlay'imizi kullanıyoruz
                      ),
          ),
        ),

        // Overlay ve border
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _scannedCode != null
                  ? AppColors.success
                  : _isScanning
                      ? AppColors.primary
                      : AppColors.greyLight,
              width: 3,
            ),
          ),
        ),

        // QR Tarama overlay çerçevesi
        if (_scannedCode == null)
          Container(
            width: 280,
            height: 280,
            child: CustomPaint(
              painter: QRScannerOverlayPainter(
                borderColor:
                    _isScanning ? AppColors.primary : AppColors.greyLight,
              ),
            ),
          ),

        // Köşe işaretleri
        Positioned.fill(
          child: Stack(
            children: [
              // Sol üst
              Positioned(
                top: 8,
                left: 8,
                child: _buildCornerIndicator(),
              ),
              // Sağ üst
              Positioned(
                top: 8,
                right: 8,
                child: Transform.rotate(
                  angle: 1.5708, // 90 derece
                  child: _buildCornerIndicator(),
                ),
              ),
              // Sol alt
              Positioned(
                bottom: 8,
                left: 8,
                child: Transform.rotate(
                  angle: -1.5708, // -90 derece
                  child: _buildCornerIndicator(),
                ),
              ),
              // Sağ alt
              Positioned(
                bottom: 8,
                right: 8,
                child: Transform.rotate(
                  angle: 3.14159, // 180 derece
                  child: _buildCornerIndicator(),
                ),
              ),
            ],
          ),
        ),

        // Tarama çizgisi
        if (_isScanning)
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Positioned(
                top: 40 + (200 * _scanAnimation.value),
                left: 40,
                right: 40,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.primary,
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),

        // İçerik
        if (_scannedCode != null)
          ScaleTransition(
            scale: _pulseAnimation,
            child: Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: AppColors.success,
            ),
          )
        else if (!_isScanning)
          Icon(
            Icons.qr_code_2_rounded,
            size: 80,
            color: AppColors.greyLight,
          ),
      ],
    );
  }

  Widget _buildCornerIndicator() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 4,
          ),
          top: BorderSide(
            color: AppColors.primary,
            width: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    if (_scannedCode != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Başarılı',
              style: AppTypography.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isScanning
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.greyLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isScanning ? AppColors.primary : AppColors.greyLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isScanning)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          else
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          const SizedBox(width: 4),
          Text(
            _isScanning ? 'Taranıyor...' : 'Kamera Aktif',
            style: AppTypography.caption.copyWith(
              color: _isScanning ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class QRScannerOverlayPainter extends CustomPainter {
  final Color borderColor;

  QRScannerOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;
    final cornerRadius = 8.0;

    // Sol üst köşe
    canvas.drawPath(
      Path()
        ..moveTo(cornerRadius, 0)
        ..lineTo(cornerLength, 0)
        ..moveTo(0, cornerRadius)
        ..lineTo(0, cornerLength),
      paint,
    );

    // Sağ üst köşe
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - cornerRadius, 0)
        ..moveTo(size.width, cornerRadius)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Sol alt köşe
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - cornerRadius)
        ..moveTo(cornerRadius, size.height)
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Sağ alt köşe
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - cornerLength)
        ..lineTo(size.width, size.height - cornerRadius)
        ..moveTo(size.width - cornerRadius, size.height)
        ..lineTo(size.width - cornerLength, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
