import 'package:flutter/material.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/business.dart';

class AdminDashboardPage extends StatefulWidget {
  final String businessId;

  const AdminDashboardPage({Key? key, required this.businessId})
    : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Business? _business;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    // Simulate loading business data
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _business = _createSampleBusiness();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: _isLoading ? const LoadingIndicator() : _buildDashboardContent(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'İşletme Yönetimi',
        style: AppTypography.h3.copyWith(color: AppColors.white),
      ),
      backgroundColor: AppColors.primary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: AppColors.white),
          onPressed: () {
            // Notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: AppColors.white),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/admin/menu-settings',
              arguments: {'businessId': widget.businessId},
            );
          },
        ),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: AppDimensions.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business overview
          _buildBusinessOverview(),

          const SizedBox(height: 24),

          // Statistics cards
          _buildStatisticsSection(),

          const SizedBox(height: 24),

          // Quick actions
          _buildQuickActions(),

          const SizedBox(height: 24),

          // Management sections
          _buildManagementSections(),
        ],
      ),
    );
  }

  Widget _buildBusinessOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_business?.logoUrl != null)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.white,
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _business?.businessName ?? 'İşletme Adı',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _business?.businessDescription ?? 'Açıklama',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildOverviewItem(
                  icon: Icons.qr_code,
                  label: 'QR Menü',
                  value: 'Aktif',
                  color: AppColors.success,
                ),
                const SizedBox(width: 24),
                _buildOverviewItem(
                  icon: Icons.visibility,
                  label: 'Görüntülenme',
                  value: '1.2K',
                  color: AppColors.info,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.white.withOpacity(0.8),
              ),
            ),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bu Ay İstatistikleri', style: AppTypography.h4),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.9,
          children: [
            _buildStatCard(
              title: 'Toplam Görüntülenme',
              value: '2.4K',
              icon: Icons.visibility,
              color: AppColors.info,
              trend: '+12%',
            ),
            _buildStatCard(
              title: 'Popüler Ürün',
              value: 'Adana Kebap',
              icon: Icons.star,
              color: AppColors.warning,
              trend: '45 görüntülenme',
            ),
            _buildStatCard(
              title: 'Aktif Ürün',
              value: '24',
              icon: Icons.restaurant_menu,
              color: AppColors.success,
              trend: '+3 bu ay',
            ),
            _buildStatCard(
              title: 'Kategori',
              value: '6',
              icon: Icons.category,
              color: AppColors.primary,
              trend: 'Sabit',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trend,
                      style: AppTypography.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.h3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hızlı İşlemler', style: AppTypography.h4),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.add,
                label: 'Ürün Ekle',
                color: AppColors.success,
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/admin/products',
                  arguments: {'businessId': widget.businessId},
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.category,
                label: 'Kategori Ekle',
                color: AppColors.primary,
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/admin/categories',
                  arguments: {'businessId': widget.businessId},
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.share,
                label: 'QR Paylaş',
                color: AppColors.info,
                onPressed: _shareQRCode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Yönetim Paneli', style: AppTypography.h4),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: [
            _buildManagementCard(
              title: 'Siparişler',
              subtitle: 'Gelen siparişler',
              icon: Icons.receipt_long,
              color: AppColors.warning,
              onTap: () => Navigator.pushNamed(
                context,
                '/admin/orders',
                arguments: {'businessId': widget.businessId},
              ),
            ),
            _buildManagementCard(
              title: 'Ürün Yönetimi',
              subtitle: '24 aktif ürün',
              icon: Icons.restaurant_menu,
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(
                context,
                '/admin/products',
                arguments: {'businessId': widget.businessId},
              ),
            ),
            _buildManagementCard(
              title: 'Kategori Yönetimi',
              subtitle: '6 kategori',
              icon: Icons.category,
              color: AppColors.success,
              onTap: () => Navigator.pushNamed(
                context,
                '/admin/categories',
                arguments: {'businessId': widget.businessId},
              ),
            ),
            _buildManagementCard(
              title: 'QR Kod Yönetimi',
              subtitle: 'QR kodları oluştur',
              icon: Icons.qr_code,
              color: AppColors.secondary,
              onTap: () => Navigator.pushNamed(
                context,
                '/admin/qr-codes',
                arguments: {'businessId': widget.businessId},
              ),
            ),
            _buildManagementCard(
              title: 'İşletme Bilgileri',
              subtitle: 'Profil & İletişim',
              icon: Icons.business,
              color: AppColors.info,
              onTap: () => Navigator.pushNamed(
                context,
                '/admin/business-info',
                arguments: {'businessId': widget.businessId},
              ),
            ),
            _buildManagementCard(
              title: 'Menü Ayarları',
              subtitle: 'Tema & Görünüm',
              icon: Icons.settings,
              color: AppColors.warning,
              onTap: () => Navigator.pushNamed(
                context,
                '/admin/menu-settings',
                arguments: {'businessId': widget.businessId},
              ),
            ),
            _buildManagementCard(
              title: 'İndirim Yönetimi',
              subtitle: 'Kampanya & İndirimler',
              icon: Icons.local_offer,
              color: AppColors.error,
              onTap: () => Navigator.pushNamed(
                context,
                '/admin/discounts',
                arguments: {'businessId': widget.businessId},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Kod Paylaş'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'QR KOD\nBURASI',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bu QR kodu müşterilerinizle paylaşarak menünüze erişim sağlayabilirsiniz.',
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
                  content: Text('QR kod paylaşıldı!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Paylaş'),
          ),
        ],
      ),
    );
  }

  Business _createSampleBusiness() {
    return Business(
      businessId: widget.businessId,
      ownerId: 'sample-owner',
      businessName: 'Lezzet Durağı',
      businessDescription: 'Geleneksel Türk mutfağının en lezzetli örnekleri',
      logoUrl: 'https://picsum.photos/200/200?random=logo',
      address: Address(
        street: 'Atatürk Caddesi No:123',
        city: 'İstanbul',
        district: 'Beyoğlu',
        postalCode: '34000',
      ),
      contactInfo: ContactInfo(
        phone: '+90 212 123 45 67',
        email: 'info@lezzetduragi.com',
        website: 'www.lezzetduragi.com',
      ),
      menuSettings: MenuSettings(
        theme: 'default',
        primaryColor: '#2C1810',
        fontFamily: 'Poppins',
        fontSize: 16.0,
        showPrices: true,
        showImages: true,
        imageSize: 'medium',
        language: 'tr',
      ),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
 