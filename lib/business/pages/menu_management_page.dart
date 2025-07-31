import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/web_safe_image.dart';
import '../models/business.dart';
import '../models/product.dart';
import '../models/category.dart' as business_category;
import '../services/business_firestore_service.dart';
import '../../core/services/url_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../widgets/menu_preview_widget.dart';
import '../widgets/menu_design_widget.dart';
import '../widgets/menu_analytics_widget.dart';
import 'category_management_page.dart';
import 'product_management_page.dart';

/// Kapsamlı Menü Yönetim Sistemi
class MenuManagementPage extends StatefulWidget {
  final String businessId;

  const MenuManagementPage({
    super.key,
    required this.businessId,
  });

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage>
    with SingleTickerProviderStateMixin {
  final BusinessFirestoreService _businessService = BusinessFirestoreService();
  final UrlService _urlService = UrlService();

  Business? _business;
  List<Product> _products = [];
  List<business_category.Category> _categories = [];

  bool _isLoading = true;
  String? _errorMessage;

  late TabController _tabController;
  int _currentIndex = 0;

  // Tab routes for URL
  final List<String> _menuTabRoutes = [
    'genel-bakis',
    'kategoriler',
    'urunler',
    'tasarim',
    'on-izleme',
    'analitik',
  ];

  final List<String> _menuTabTitles = [
    'Genel Bakış',
    'Kategoriler',
    'Ürünler',
    'Tasarım',
    'Ön İzleme',
    'Analitik',
  ];

  final List<IconData> _menuTabIcons = [
    Icons.dashboard_rounded,
    Icons.category_rounded,
    Icons.restaurant_menu_rounded,
    Icons.palette_rounded,
    Icons.preview_rounded,
    Icons.analytics_rounded,
  ];

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMenuData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() => _currentIndex = _tabController.index);
      _updateUrl();
    }
  }

  void _updateUrl() {
    final currentTab = _menuTabRoutes[_currentIndex];
    final businessName = _business?.businessName;
    _urlService.updateBusinessUrl(
      widget.businessId,
      'menu/$currentTab',
      businessName: businessName,
    );
  }

  Future<void> _loadMenuData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final business = await _businessService.getBusiness(widget.businessId);
      if (business == null) throw Exception('İşletme bulunamadı');

      final categories =
      await _businessService.getCategories(businessId: widget.businessId);
      final products =
      await _businessService.getProducts(businessId: widget.businessId);

      setState(() {
        _business = business;
        _categories = categories.where((c) => c.isActive).toList();
        _products = products.where((p) => p.isActive).toList();
      });

      _updateUrl();
    } catch (e) {
      setState(() => _errorMessage = 'Menü verileri yüklenirken hata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadMenuData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Menü Yönetimi'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: Center(
          child: ErrorMessage(
            message: _errorMessage!,
            onRetry: _loadMenuData,
          ),
        ),
      );
    }

    if (_business == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Menü Yönetimi'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: const Center(
          child: EmptyState(
            icon: Icons.restaurant_menu,
            title: 'İşletme Bulunamadı',
            message: 'İşletme bilgileri yüklenemedi',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildTabView()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
        height: 1,
        color: AppColors.divider.withOpacity(0.3),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: _isMobile,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.secondary.withBlue(200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        tabs: List.generate(_menuTabTitles.length, (index) {
          return Tab(
            height: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_menuTabIcons[index], size: 20),
                  if (!_isMobile) ...[
                    const SizedBox(width: 8),
                    Text(
                      _menuTabTitles[index],
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Genel Bakış
        _buildOverviewTab(),

        // Kategoriler - Mevcut kategori yönetim sayfasını kullan
        CategoryManagementPage(businessId: widget.businessId),

        // Ürünler - Mevcut ürün yönetim sayfasını kullan
        ProductManagementPage(businessId: widget.businessId),

        // Tasarım
        MenuDesignWidget(
          businessId: widget.businessId,
          business: _business!,
          onDesignChanged: _refreshData,
        ),

        // Ön İzleme
        MenuPreviewWidget(
          business: _business!,
          categories: _categories,
          products: _products,
        ),

        // Analitik
        MenuAnalyticsWidget(
          businessId: widget.businessId,
          categories: _categories,
          products: _products,
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final totalCategories = _categories.length;
    final totalProducts = _products.length;
    final availableProducts = _products.where((p) => p.isAvailable).length;
    final avgPrice = _products.isNotEmpty
        ? (_products.map((p) => p.currentPrice).reduce((a, b) => a + b) / _products.length)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Text(
            'Menü Genel Bakış',
            style: AppTypography.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Menünüzün genel durumu ve hızlı erişim araçları',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // İstatistik Kartları
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1, // Taşmayı engellemek için küçültüldü
            padding: EdgeInsets.zero,
            children: [
              _buildStatCard(
                'Toplam Kategori',
                totalCategories.toString(),
                Icons.category_rounded,
                AppColors.primary,
                    () => _tabController.animateTo(1),
              ),
              _buildStatCard(
                'Toplam Ürün',
                totalProducts.toString(),
                Icons.restaurant_menu_rounded,
                AppColors.secondary,
                    () => _tabController.animateTo(2),
              ),
              _buildStatCard(
                'Aktif Ürün',
                availableProducts.toString(),
                Icons.check_circle_rounded,
                AppColors.success,
                    () => _tabController.animateTo(2),
              ),
              _buildStatCard(
                'Ortalama Fiyat',
                '${avgPrice.toStringAsFixed(0)} ₺',
                Icons.monetization_on_rounded,
                AppColors.info,
                    () => _tabController.animateTo(5),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Hızlı Eylemler
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildQuickActions(),
          ),

          const SizedBox(height: 24),

          // Son Güncellenen Ürünler
          _buildRecentProducts(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 20 → 16
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20), // 24 → 20
              ),
              const SizedBox(height: 8), // 12 → 8
              Text(
                value,
                style: AppTypography.h4.copyWith( // h3 → h4
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // 4 → 2
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11, // Küçük ekranlarda daha uygun
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16), // Mobilde daha küçük boşluk
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12), // Daha doğal yuvarlaklık
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08), // Biraz daha belirgin gölge
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text(
            'Hızlı Eylemler',
            style: AppTypography.h5.copyWith( // Mobil için biraz küçük başlık
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12), // Daha sıkı boşluk

          // Mobil için tek sütun, ancak butonlar tıklanabilir alan büyük olmalı
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 1, // Mobilde her zaman 1 sütun
            crossAxisSpacing: 0,
            mainAxisSpacing: 12, // Butonlar arası dikey boşluk
            childAspectRatio: 4.0, // Genişliği yüksekliğe oranı (yatayda daha dengeli)
            children: [
              _buildActionButton(
                'Yeni Kategori',
                'Kategori ekle',
                Icons.add_rounded,
                AppColors.primary,
                    () => _showAddCategoryDialog(),
              ),
              _buildActionButton(
                'Yeni Ürün',
                'Ürün ekle',
                Icons.restaurant_menu_rounded,
                AppColors.secondary,
                    () => _showAddProductDialog(),
              ),
              _buildActionButton(
                'Menüyü Paylaş',
                'QR kod ile paylaş',
                Icons.qr_code_rounded,
                AppColors.info,
                    () => _showQRCodeDialog(),
              ),
              _buildActionButton(
                'Menü İndir',
                'PDF olarak kaydet',
                Icons.download_rounded,
                AppColors.success,
                    () => _downloadMenuPDF(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProducts() {
    final recentProducts = _products.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Ürünler',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentProducts.isEmpty)
            const EmptyState(
              icon: Icons.restaurant_menu,
              title: 'Henüz ürün yok',
              message: 'İlk ürününüzü ekleyin',
            )
          else
            ...recentProducts.map((product) => _buildProductItem(product)),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Ürün resmi
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: product.images.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: WebSafeImage(
                imageUrl: product.images.first.url,
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) => Icon(
                  Icons.restaurant_menu,
                  color: AppColors.primary,
                ),
              ),
            )
                : Icon(
              Icons.restaurant_menu,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 16),

          // Ürün bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Fiyat ve durum
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.currentPrice.toStringAsFixed(0)} ₺',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.isAvailable
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.isAvailable ? 'Aktif' : 'Pasif',
                  style: AppTypography.bodySmall.copyWith(
                    color: product.isAvailable
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action metodları
  void _showMenuSettings() {
    Navigator.pushNamed(
      context,
      '/business/menu-settings',
      arguments: {'businessId': widget.businessId},
    );
  }

  void _showAddCategoryDialog() {
    // Kategori ekleme dialog'u
    _tabController.animateTo(1);
  }

  void _showAddProductDialog() {
    // Ürün ekleme dialog'u
    _tabController.animateTo(2);
  }

  void _showQRCodeDialog() {
    // QR kod dialog'u
    Navigator.pushNamed(
      context,
      '/business/qr-management',
      arguments: {'businessId': widget.businessId},
    );
  }

  void _downloadMenuPDF() {
    // PDF indirme işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.download_rounded, color: AppColors.white),
            const SizedBox(width: 8),
            Text('Menü PDF olarak indiriliyor...'),
          ],
        ),
        backgroundColor: AppColors.info,
      ),
    );
  }
}