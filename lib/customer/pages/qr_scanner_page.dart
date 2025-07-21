import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/url_service.dart';
import 'qr_menu_page.dart';

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
  
  bool _isScanning = false;
  String? _scannedCode;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateURL();
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

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
    });

    HapticFeedback.mediumImpact();
    
    // Simulated QR scanning - gerçekte kamera entegrasyonu gerekir
    await Future.delayed(const Duration(seconds: 2));
    
    // Demo QR kod - gerçekte kameradan gelecek
    final demoBusinessId = 'demo_business_123';
    final demoQRCode = 'masamenu_${demoBusinessId}_table_5';
    
    await _handleQRCodeDetected(demoQRCode, demoBusinessId);
  }

  Future<void> _handleQRCodeDetected(String qrCode, String businessId) async {
    setState(() {
      _scannedCode = qrCode;
      _isScanning = false;
    });

    HapticFeedback.heavyImpact();

    // QR kod başarıyla tarandı, menü sayfasına yönlendir
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dynamicRoute = '/qr-menu/$businessId?t=$timestamp&qr=$qrCode';
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QRMenuPage(
            businessId: businessId,
            userId: widget.userId,
            qrCode: qrCode,
          ),
          settings: RouteSettings(
            name: dynamicRoute,
            arguments: {
              'businessId': businessId,
              'userId': widget.userId,
              'qrCode': qrCode,
              'timestamp': timestamp,
              'referrer': 'qr_scanner',
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
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // QR tarama frame
                  _buildScanFrame(),
                  
                  const SizedBox(height: 48),
                  
                  // Tarama butonu
                  _buildScanButton(),
                  
                  const SizedBox(height: 24),
                  
                  // Manuel giriş butonu
                  OutlinedButton.icon(
                    onPressed: _handleManualEntry,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Manuel Kod Girişi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        // Arka plan
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'QR Kod Başarıyla Tarandı',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isScanning ? null : _startScanning,
      icon: _isScanning
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            )
          : const Icon(Icons.qr_code_scanner_rounded),
      label: Text(_isScanning ? 'Taranıyor...' : 'QR Kodu Tara'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    );
  }
} 