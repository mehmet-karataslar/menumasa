import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';


import '../../../core/services/qr_service.dart';
import '../models/business.dart';
import '../models/qr_code.dart';
import '../services/business_firestore_service.dart';

class QRManagementPage extends StatefulWidget {
  final String businessId;

  const QRManagementPage({Key? key, required this.businessId})
    : super(key: key);

  @override
  State<QRManagementPage> createState() => _QRManagementPageState();
}

class _QRManagementPageState extends State<QRManagementPage>
    with TickerProviderStateMixin {
  final BusinessFirestoreService _businessFirestoreService = BusinessFirestoreService();
  final QRService _qrService = QRService();

  Business? _business;
  List<QRCode> _qrCodes = [];
  QRCode? _businessQR;
  List<QRCode> _tableQRs = [];
  Map<String, dynamic> _qrStats = {};
  
  bool _isLoading = true;
  bool _isCreatingQRs = false;
  String? _errorMessage;
  
  late TabController _tabController;
  int _tableCount = 10;
  
  final TextEditingController _tableCountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tableCountController.text = _tableCount.toString();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tableCountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load business data
      final business = await _businessFirestoreService.getBusiness(widget.businessId);
      if (business == null) {
        throw Exception('İşletme bulunamadı');
      }

      // Load QR codes
      final qrCodes = await _qrService.getBusinessQRCodes(widget.businessId);
      final businessQR = await _qrService.getBusinessQRCode(widget.businessId);
      final tableQRs = await _qrService.getTableQRCodes(widget.businessId);
      final qrStats = await _qrService.getBusinessQRStats(widget.businessId);

      setState(() {
        _business = business;
        _qrCodes = qrCodes;
        _businessQR = businessQR;
        _tableQRs = tableQRs;
        _qrStats = qrStats;
        _tableCount = tableQRs.length > 0 ? tableQRs.length : 10;
        _tableCountController.text = _tableCount.toString();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Veriler yüklenirken hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBusinessQR() async {
    if (_business == null) return;

    setState(() {
      _isCreatingQRs = true;
    });

    try {
      final qrCode = await _qrService.createBusinessQRCode(
        businessId: widget.businessId,
        businessName: _business!.businessName,
      );

      setState(() {
        _businessQR = qrCode;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşletme QR kodu oluşturuldu'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      await _loadData(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR kod oluşturulurken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingQRs = false;
      });
    }
  }

  Future<void> _createTableQRs() async {
    if (_business == null) return;

    setState(() {
      _isCreatingQRs = true;
    });

    try {
      final tableQRs = await _qrService.createTableQRCodes(
        businessId: widget.businessId,
        businessName: _business!.businessName,
        tableCount: _tableCount,
        replaceExisting: true,
      );

      setState(() {
        _tableQRs = tableQRs;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tableQRs.length} adet masa QR kodu oluşturuldu'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      await _loadData(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Masa QR kodları oluşturulurken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingQRs = false;
      });
    }
  }

  Future<void> _createAllQRs() async {
    if (_business == null) return;

    setState(() {
      _isCreatingQRs = true;
    });

    try {
      final package = await _qrService.createBusinessQRPackage(
        businessId: widget.businessId,
        businessName: _business!.businessName,
        tableCount: _tableCount,
        replaceExisting: true,
      );

      setState(() {
        _businessQR = package.businessQR;
        _tableQRs = package.tableQRs;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${package.totalQRCodes} adet QR kod oluşturuldu'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      await _loadData(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR kodları oluşturulurken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingQRs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: _buildAppBar(),
        body: Center(child: ErrorMessage(message: _errorMessage!)),
      );
    }

    if (_business == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: _buildAppBar(),
        body: const Center(
          child: EmptyState(
            icon: Icons.business,
            title: 'İşletme Bulunamadı',
            message: 'İşletme bilgileri yüklenemedi',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Statistics overview
          _buildStatsOverview(),
          // Tab bar
          _buildTabBar(),
          // Tab view
          Expanded(
            child: _buildTabView(),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: Row(
        children: [
          const Icon(Icons.qr_code, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QR Kod Yönetimi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_business != null)
                  Text(
                    _business!.businessName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
        ),
        IconButton(
          icon: const Icon(Icons.help),
          onPressed: _showHelpDialog,
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            'Toplam QR',
            (_qrStats['totalQRCodes'] ?? 0).toString(),
            Icons.qr_code,
            AppColors.primary,
          ),
          _buildStatItem(
            'Tarama',
            (_qrStats['totalScans'] ?? 0).toString(),
            Icons.visibility,
            AppColors.success,
          ),
          _buildStatItem(
            'Bugün',
            (_qrStats['todayScans'] ?? 0).toString(),
            Icons.today,
            AppColors.info,
          ),
          _buildStatItem(
            'Masa QR',
            (_qrStats['tableQRCount'] ?? 0).toString(),
            Icons.table_restaurant,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.business),
            text: 'İşletme QR',
          ),
          Tab(
            icon: Icon(Icons.table_restaurant),
            text: 'Masa QR Kodları',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: 'İstatistikler',
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildBusinessQRTab(),
        _buildTableQRTab(),
        _buildStatsTab(),
      ],
    );
  }

  Widget _buildBusinessQRTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_businessQR != null)
            _buildBusinessQRCard()
          else
            _buildCreateBusinessQRCard(),
          const SizedBox(height: 16),
          _buildBusinessQRActions(),
        ],
      ),
    );
  }

  Widget _buildBusinessQRCard() {
    if (_businessQR == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // QR Code display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.greyLight, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _business!.businessName,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                    ),
                    child: _qrService.createQRWidget(_businessQR!, overrideSize: 280),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Menümüze ulaşmak için QR kodu tarayın',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // URL display
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
                      _businessQR!.url,
                      style: AppTypography.bodySmall.copyWith(
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _copyToClipboard(_businessQR!.url),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _qrService.shareBusinessQR(widget.businessId),
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
                    onPressed: () => _qrService.openQRUrl(_businessQR!.url),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Test Et'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateBusinessQRCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.qr_code,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'İşletme QR Kodu Oluştur',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Müşterilerinizin menünüze kolayca erişmesi için işletme QR kodu oluşturun',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isCreatingQRs ? null : _createBusinessQR,
              icon: _isCreatingQRs 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isCreatingQRs ? 'Oluşturuluyor...' : 'QR Kod Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessQRActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QR Kod İşlemleri',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.print, color: AppColors.primary),
              ),
              title: const Text('QR Kodu Yazdır'),
              subtitle: const Text('Fiziksel kopyalar için yazdırın'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _businessQR != null ? _printBusinessQR : null,
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.download, color: AppColors.success),
              ),
              title: const Text('QR Kodu İndir'),
              subtitle: const Text('PNG formatında kaydet'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _businessQR != null ? _downloadBusinessQR : null,
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.refresh, color: AppColors.warning),
              ),
              title: const Text('QR Kodu Yenile'),
              subtitle: const Text('Mevcut QR kodu güncelle'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _isCreatingQRs ? null : _createBusinessQR,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableQRTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTableCountSelector(),
          const SizedBox(height: 16),
          if (_tableQRs.isNotEmpty)
            _buildTableQRGrid()
          else
            _buildCreateTableQRsCard(),
        ],
      ),
    );
  }

  Widget _buildTableCountSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masa Sayısı Ayarı',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tableCountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Masa Sayısı',
                      hintText: 'Örn: 20',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.table_restaurant),
                    ),
                    onChanged: (value) {
                      final count = int.tryParse(value);
                      if (count != null && count > 0 && count <= 100) {
                        setState(() {
                          _tableCount = count;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isCreatingQRs ? null : _createTableQRs,
                  icon: _isCreatingQRs 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.create),
                  label: Text(_isCreatingQRs ? 'Oluşturuluyor...' : 'Oluştur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Not: Mevcut masa QR kodları silinip yeniden oluşturulacaktır.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableQRGrid() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Masa QR Kodları (${_tableQRs.length})',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _printAllTableQRs,
                  icon: const Icon(Icons.print),
                  label: const Text('Tümünü Yazdır'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _tableQRs.length,
              itemBuilder: (context, index) {
                final qr = _tableQRs[index];
                final tableNumber = qr.data.tableNumber ?? (index + 1);
                
                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.white,
                          AppColors.primary.withOpacity(0.02),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Table number header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Masa $tableNumber',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // QR Code
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _qrService.createQRWidget(qr, overrideSize: 120),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _qrService.shareTableQR(
                                    widget.businessId,
                                    tableNumber,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Icon(Icons.share, size: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _copyToClipboard(qr.url),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: AppColors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Icon(Icons.copy, size: 16),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTableQRsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.table_restaurant,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Masa QR Kodları Oluştur',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Her masa için ayrı QR kodlar oluşturun. Müşteriler hangi masada oturduklarını belirtmek zorunda kalmayacak.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isCreatingQRs ? null : _createTableQRs,
              icon: _isCreatingQRs 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isCreatingQRs ? 'Oluşturuluyor...' : 'Masa QR Kodları Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDetailedStats(),
          const SizedBox(height: 16),
          _buildQRCodesList(),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detaylı İstatistikler',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Tarama',
                    (_qrStats['totalScans'] ?? 0).toString(),
                    Icons.visibility,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Bu Hafta',
                    (_qrStats['weeklyScans'] ?? 0).toString(),
                    Icons.date_range,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Bu Ay',
                    (_qrStats['monthlyScans'] ?? 0).toString(),
                    Icons.calendar_month,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'QR Kod Sayısı',
                    (_qrStats['totalQRCodes'] ?? 0).toString(),
                    Icons.qr_code_2,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tüm QR Kodları',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_qrCodes.isEmpty)
              const EmptyState(
                icon: Icons.qr_code,
                title: 'QR Kod Bulunamadı',
                message: 'Henüz hiç QR kod oluşturulmamış',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _qrCodes.length,
                itemBuilder: (context, index) {
                  final qr = _qrCodes[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: qr.type == QRCodeType.business 
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        qr.type == QRCodeType.business 
                            ? Icons.business 
                            : Icons.table_restaurant,
                        color: qr.type == QRCodeType.business 
                            ? AppColors.primary 
                            : AppColors.success,
                      ),
                    ),
                    title: Text(qr.title),
                    subtitle: Text(
                      '${qr.stats.totalScans} tarama • ${qr.type.displayName}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'share':
                            _shareQR(qr);
                            break;
                          case 'copy':
                            _copyToClipboard(qr.url);
                            break;
                          case 'test':
                            _qrService.openQRUrl(qr.url);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: ListTile(
                            leading: Icon(Icons.share),
                            title: Text('Paylaş'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: ListTile(
                            leading: Icon(Icons.copy),
                            title: Text('Linki Kopyala'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'test',
                          child: ListTile(
                            leading: Icon(Icons.open_in_new),
                            title: Text('Test Et'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _isCreatingQRs ? null : _createAllQRs,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      icon: _isCreatingQRs 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(
                strokeWidth: 2, 
                color: AppColors.white,
              ),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(_isCreatingQRs ? 'Oluşturuluyor...' : 'Tüm QR Kodları'),
    );
  }

  // Action methods
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link kopyalandı'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _shareQR(QRCode qr) {
    if (qr.type == QRCodeType.business) {
      _qrService.shareBusinessQR(widget.businessId);
    } else if (qr.type == QRCodeType.table && qr.data.tableNumber != null) {
      _qrService.shareTableQR(widget.businessId, qr.data.tableNumber!);
    }
  }

  void _printBusinessQR() {
    // Implementation for printing business QR
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR kod yazdırma özelliği yakında eklenecek'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _downloadBusinessQR() {
    // Implementation for downloading business QR
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR kod indirme özelliği yakında eklenecek'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _printAllTableQRs() {
    // Implementation for printing all table QRs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toplu QR kod yazdırma özelliği yakında eklenecek'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Kod Yönetimi Yardımı'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QR kodları müşterilerinizin menünüze kolayca erişmesini sağlar.\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• İşletme QR Kodu: Genel menüyü gösterir'),
              Text('• Masa QR Kodları: Belirli masa numarası ile menüyü gösterir'),
              Text('• QR kodları yazdırıp masalarınıza yapıştırabilirsiniz'),
              Text('• Müşteriler telefon kamerası ile QR kodu tarayabilir'),
              Text('• İstatistikler ile QR kod kullanımını takip edebilirsiniz'),
            ],
          ),
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
}
