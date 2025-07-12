import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/qr_service.dart';
import '../customer/menu_page.dart';

// QR Menü sayfası - QR kod taramasından gelen kullanıcılar için özel sayfa
class QRMenuPage extends StatefulWidget {
  final String businessId;
  final String? tableNumber;

  const QRMenuPage({Key? key, required this.businessId, this.tableNumber})
    : super(key: key);

  @override
  State<QRMenuPage> createState() => _QRMenuPageState();
}

class _QRMenuPageState extends State<QRMenuPage> {
  final DataService _dataService = DataService();
  final QRService _qrService = QRService();

  bool _isLoading = true;
  bool _businessExists = false;
  String? _businessName;
  String? _businessDescription;

  @override
  void initState() {
    super.initState();
    _verifyBusiness();
  }

  Future<void> _verifyBusiness() async {
    try {
      await _dataService.initialize();
      await _dataService.initializeSampleData();

      final business = await _dataService.getBusiness(widget.businessId);

      setState(() {
        _businessExists = business != null && business.isActive;
        _businessName = business?.businessName;
        _businessDescription = business?.businessDescription;
        _isLoading = false;
      });

      if (_businessExists) {
        _showQRWelcomeMessage();
        _updateBusinessQRCode();
      }
    } catch (e) {
      setState(() {
        _businessExists = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBusinessQRCode() async {
    // QR servisini kullanarak işletme QR kodunu güncelle
    await _qrService.updateBusinessQRCode(widget.businessId);
  }

  void _showQRWelcomeMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        String message;
        IconData icon;
        Color color;

        if (widget.tableNumber != null) {
          message = 'Masa ${widget.tableNumber} menüsüne hoş geldiniz!';
          icon = Icons.table_restaurant;
          color = AppColors.success;
        } else {
          message = 'Dijital menümüze hoş geldiniz!';
          icon = Icons.qr_code;
          color = AppColors.primary;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: AppColors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: color,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Paylaş',
              textColor: AppColors.white,
              onPressed: _shareQRCode,
            ),
          ),
        );
      }
    });
  }

  Future<void> _shareQRCode() async {
    try {
      if (widget.tableNumber != null) {
        await _qrService.shareTableQR(widget.businessId, widget.tableNumber!);
      } else {
        await _qrService.shareBusinessQR(widget.businessId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingPage();
    }

    if (!_businessExists) {
      return _buildErrorPage();
    }

    return _buildMenuPage();
  }

  Widget _buildLoadingPage() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR kod animasyonu
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Menü yükleniyor...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (widget.tableNumber != null) ...[
              const SizedBox(height: 8),
              Text(
                'Masa ${widget.tableNumber}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPage() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hata'),
        backgroundColor: AppColors.error,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _verifyBusiness();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'İşletme Bulunamadı',
                style: AppTypography.h3.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              const Text(
                'Taradığınız QR kod geçersiz veya işletme artık aktif değil.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Yeniden dene butonu
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _verifyBusiness();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Yeniden Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // QR tarama butonu
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/qr-scanner'),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Başka QR Tara'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Ana sayfa butonu
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/customer-login'),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuPage() {
    return MenuPage(businessId: widget.businessId);
  }
}

// QR servisini kullanarak QR kod URL'ini test etme sayfası
class QRTestPage extends StatefulWidget {
  final String businessId;
  final String? tableNumber;

  const QRTestPage({Key? key, required this.businessId, this.tableNumber})
    : super(key: key);

  @override
  State<QRTestPage> createState() => _QRTestPageState();
}

class _QRTestPageState extends State<QRTestPage> {
  final QRService _qrService = QRService();

  @override
  Widget build(BuildContext context) {
    final qrUrl = widget.tableNumber != null
        ? _qrService.generateTableQRUrl(widget.businessId, widget.tableNumber!)
        : _qrService.generateBusinessQRUrl(widget.businessId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _qrService.openQRUrl(qrUrl),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // QR kod widget
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.tableNumber != null
                    ? _qrService.createTableQRWidget(
                        businessId: widget.businessId,
                        tableNumber: widget.tableNumber!,
                        size: 250,
                      )
                    : _qrService.createBusinessQRWidget(
                        businessId: widget.businessId,
                        size: 250,
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // QR kod bilgileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QR Kod Bilgileri', style: AppTypography.h4),
                    const SizedBox(height: 12),
                    _buildInfoRow('İşletme ID', widget.businessId),
                    if (widget.tableNumber != null)
                      _buildInfoRow('Masa No', widget.tableNumber!),
                    _buildInfoRow('URL', qrUrl),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Aksiyon butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _shareQRCode();
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Paylaş'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(qrUrl),
                    icon: const Icon(Icons.copy),
                    label: const Text('Kopyala'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }

  Future<void> _shareQRCode() async {
    try {
      if (widget.tableNumber != null) {
        await _qrService.shareTableQR(widget.businessId, widget.tableNumber!);
      } else {
        await _qrService.shareBusinessQR(widget.businessId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL panoya kopyalandı'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
