import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/business.dart';
import '../../../core/services/data_service.dart';
import '../../../core/services/qr_service.dart';

class QRCodeManagementPage extends StatefulWidget {
  final String businessId;

  const QRCodeManagementPage({Key? key, required this.businessId})
    : super(key: key);

  @override
  State<QRCodeManagementPage> createState() => _QRCodeManagementPageState();
}

class _QRCodeManagementPageState extends State<QRCodeManagementPage> {
  final DataService _dataService = DataService();
  final QRService _qrService = QRService();

  Business? _business;
  bool _isLoading = true;
  int _tableCount = 20;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _dataService.initialize();
      final business = await _dataService.getBusiness(widget.businessId);

      setState(() {
        _business = business;
        _isLoading = false;
      });

      // Update QR code URL if not exists
      if (business != null && business.qrCodeUrl == null) {
        await _qrService.updateBusinessQRCode(widget.businessId);
        setState(() {
          _business = business.copyWith(
            qrCodeUrl: _qrService.generateBusinessQRUrl(widget.businessId),
          );
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? const LoadingIndicator() : _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'QR Kod Yönetimi',
        style: AppTypography.h3.copyWith(color: AppColors.white),
      ),
      backgroundColor: AppColors.primary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.help, color: AppColors.white),
          onPressed: _showHelpDialog,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_business == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: AppColors.error),
            SizedBox(height: 16),
            Text('İşletme Bulunamadı', style: AppTypography.h4),
            SizedBox(height: 8),
            Text(
              'İşletme bilgileri yüklenemedi.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: AppDimensions.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business QR Section
          _buildBusinessQRSection(),

          const SizedBox(height: 24),

          // Table QR Section
          _buildTableQRSection(),

          const SizedBox(height: 24),

          // QR Settings Section
          _buildQRSettingsSection(),

          const SizedBox(height: 24),

          // QR Usage Guide
          _buildUsageGuide(),
        ],
      ),
    );
  }

  Widget _buildBusinessQRSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('İşletme QR Kodu', style: AppTypography.h4),
                      Text(
                        'Genel menü erişimi için',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // QR Code Display
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
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _qrService.createBusinessQRWidget(
                  businessId: widget.businessId,
                  size: 200,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // QR URL Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _qrService.generateBusinessQRUrl(widget.businessId),
                      style: AppTypography.bodySmall.copyWith(
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _copyToClipboard(
                      _qrService.generateBusinessQRUrl(widget.businessId),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _qrService.shareBusinessQR(widget.businessId),
                    icon: const Icon(Icons.share),
                    label: const Text('Paylaş'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _printBusinessQR,
                    icon: const Icon(Icons.print),
                    label: const Text('Yazdır'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableQRSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.table_restaurant,
                  color: AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Masa QR Kodları', style: AppTypography.h4),
                      Text(
                        'Masa bazlı menü erişimi',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Table Count Selector
            Row(
              children: [
                Text('Masa Sayısı:', style: AppTypography.bodyMedium),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _tableCount.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: _tableCount.toString(),
                    onChanged: (value) {
                      setState(() {
                        _tableCount = value.round();
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _tableCount.toString(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateTableQRs,
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('QR Kodları Oluştur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showTableQRPreview,
                    icon: const Icon(Icons.preview),
                    label: const Text('Önizleme'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: AppColors.warning, size: 28),
                const SizedBox(width: 12),
                Text('QR Kod Ayarları', style: AppTypography.h4),
              ],
            ),

            const SizedBox(height: 20),

            // QR Code Style Settings
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('QR Kod Stili'),
              subtitle: const Text('Renk ve görünüm ayarları'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showStyleSettings,
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Dil Ayarları'),
              subtitle: const Text('QR kod yönlendirme dili'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showLanguageSettings,
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('İstatistikler'),
              subtitle: const Text('QR kod tarama istatistikleri'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showQRStatistics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageGuide() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: AppColors.info, size: 28),
                const SizedBox(width: 12),
                Text('Kullanım Kılavuzu', style: AppTypography.h4),
              ],
            ),

            const SizedBox(height: 16),

            _buildGuideStep(
              '1',
              'QR Kod Oluşturun',
              'İşletmeniz için genel QR kodu veya masa bazlı QR kodlar oluşturun.',
            ),

            _buildGuideStep(
              '2',
              'Yazdırın ve Yapıştırın',
              'QR kodları yazdırıp masalarınıza veya işletmenizde görünür yerlere yapıştırın.',
            ),

            _buildGuideStep(
              '3',
              'Müşteriler Tarasın',
              'Müşteriler telefon kamerası ile QR kodu tarayarak menünüze erişir.',
            ),

            _buildGuideStep(
              '4',
              'Dijital Menü',
              'Müşteriler dokunmatik menünüzü görüntüleyebilir ve siparişlerini verebilir.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _generateAllQRs,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Tüm QR Kodları'),
    );
  }

  // Action Methods
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR kod linki kopyalandı'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _printBusinessQR() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Kod Yazdır'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _qrService.createBusinessQRWidget(
              businessId: widget.businessId,
              size: 150,
            ),
            const SizedBox(height: 16),
            Text(
              _business?.businessName ?? 'İşletme',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu QR kodu tarayarak menümüze ulaşabilirsiniz',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Yazdırma işlemi başlatıldı'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Yazdır'),
          ),
        ],
      ),
    );
  }

  void _generateTableQRs() {
    final package = _qrService.createPrintableQRPackage(
      widget.businessId,
      tableCount: _tableCount,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masa QR Kodları'),
        content: Text(
          '${package.totalQRCodes} adet QR kod oluşturuldu.\n\n'
          '• 1 adet genel QR kod\n'
          '• $_tableCount adet masa QR kodu\n\n'
          'Bu QR kodları yazdırmak istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showTableQRGrid(package);
            },
            child: const Text('Önizleme'),
          ),
        ],
      ),
    );
  }

  void _showTableQRPreview() {
    final package = _qrService.createPrintableQRPackage(
      widget.businessId,
      tableCount: _tableCount,
    );
    _showTableQRGrid(package);
  }

  void _showTableQRGrid(QRCodePackage package) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Masa QR Kodları', style: AppTypography.h4),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: package.tableQRs.length,
                  itemBuilder: (context, index) {
                    final qrData = package.tableQRs[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Expanded(
                              child: _qrService.createTableQRWidget(
                                businessId: widget.businessId,
                                tableNumber: qrData.tableNumber!,
                                size: 80,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              qrData.displayName,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Masa QR kodları yazdırma işlemi başlatıldı',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                child: const Text('Tümünü Yazdır'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateAllQRs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm QR Kodları Oluştur'),
        content: const Text(
          'İşletmeniz için tüm QR kodları (genel + masa kodları) oluşturmak istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateTableQRs();
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Kod Yardımı'),
        content: const Text(
          'QR kodları müşterilerinizin menünüze kolayca erişmesini sağlar.\n\n'
          '• Genel QR kod: Tüm menüyü gösterir\n'
          '• Masa QR kodları: Masa numarası ile menüyü gösterir\n'
          '• QR kodları yazdırıp masalarınıza yapıştırabilirsiniz\n'
          '• Müşteriler telefon kamerası ile QR kodu tarayabilir',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  void _showStyleSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR kod stil ayarları yakında eklenecek'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showLanguageSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dil ayarları yakında eklenecek'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showQRStatistics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR kod istatistikleri yakında eklenecek'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}
