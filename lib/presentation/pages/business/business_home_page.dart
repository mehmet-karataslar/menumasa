import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/business.dart';
import '../../../data/models/order.dart' as app_order;
import '../../../data/models/product.dart';
import '../../../data/models/category.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import '../../widgets/shared/empty_state.dart';
import 'business_profile_page.dart';
import 'category_management_page.dart';
import 'product_management_page.dart';
import 'order_management_page.dart';
import 'menu_settings_page.dart';
import 'discount_management_page.dart';
import 'qr_management_page.dart';
import 'dart:html' as html;

class BusinessHomePage extends StatefulWidget {
  final String businessId;
  final String? initialTab; // Add support for initial tab

  const BusinessHomePage({
    Key? key, 
    required this.businessId,
    this.initialTab,
  }) : super(key: key);

  @override
  State<BusinessHomePage> createState() => _BusinessHomePageState();
}

class _BusinessHomePageState extends State<BusinessHomePage>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  Business? _business;
  List<app_order.Order> _recentOrders = [];
  List<Product> _popularProducts = [];
  List<Category> _categories = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  
  // İstatistikler
  int _totalOrders = 0;
  int _totalProducts = 0;
  int _totalCategories = 0;
  double _totalRevenue = 0.0;
  int _todayOrders = 0;
  double _todayRevenue = 0.0;
  int _pendingOrders = 0;

  late TabController _tabController;

  // Tab names for URL routing
  final List<String> _tabRoutes = [
    'genel-bakis',
    'siparisler', 
    'kategoriler',
    'urunler',
    'indirimler',
    'qr-kodlar',
    'ayarlar',
  ];

  final List<String> _tabTitles = [
    'Genel Bakış',
    'Siparişler',
    'Kategoriler', 
    'Ürünler',
    'İndirimler',
    'QR Kodlar',
    'Ayarlar',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    
    // Set initial tab based on URL
    _setInitialTab();
    
    // Listen to tab changes for URL updates
    _tabController.addListener(_onTabChanged);
    
    _loadBusinessData();
    _setupOrderListener();
  }

  void _setInitialTab() {
    if (widget.initialTab != null) {
      final tabIndex = _tabRoutes.indexOf(widget.initialTab!);
      if (tabIndex != -1) {
        _tabController.index = tabIndex;
      }
    }
    
    // Update URL on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUrl();
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _updateUrl();
    }
  }

  void _updateUrl() {
    final currentRoute = _tabRoutes[_tabController.index];
    final newUrl = '/business/${widget.businessId}/$currentRoute';
    
    // Update browser URL without reloading the page
    html.window.history.pushState(null, _tabTitles[_tabController.index], newUrl);
    
    // Update page title
    html.document.title = '${_business?.businessName ?? "İşletme"} - ${_tabTitles[_tabController.index]} | MasaMenu';
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _setupOrderListener() {
    // No need for periodic refresh anymore - using real-time Firestore updates
    // The order statistics will be updated through the order listener in individual pages
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // İşletme bilgilerini yükle
      final business = await _firestoreService.getBusiness(widget.businessId);
      if (business == null) {
        throw Exception('İşletme bulunamadı');
      }

      // Son siparişleri yükle
      final orders = await _firestoreService.getBusinessOrders(
        widget.businessId,
        limit: 5,
      );

      // Kategorileri yükle
      final categories = await _firestoreService.getBusinessCategories(
        widget.businessId,
      );

      // Ürünleri yükle
      final products = await _firestoreService.getBusinessProducts(
        widget.businessId,
        limit: 10,
      );

      // İstatistikleri hesapla
      final stats = await _calculateStats();

      setState(() {
        _business = business;
        _recentOrders = orders;
        _categories = categories;
        _popularProducts = products;
        _totalOrders = stats['totalOrders'] ?? 0;
        _totalProducts = stats['totalProducts'] ?? 0;
        _totalCategories = stats['totalCategories'] ?? 0;
        _totalRevenue = stats['totalRevenue'] ?? 0.0;
        _todayOrders = stats['todayOrders'] ?? 0;
        _todayRevenue = stats['todayRevenue'] ?? 0.0;
        _pendingOrders = stats['pendingOrders'] ?? 0;
      });

      // Update page title with business name
      html.document.title = '${business.businessName} - ${_tabTitles[_tabController.index]} | MasaMenu';
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

  Future<Map<String, dynamic>> _calculateStats() async {
    try {
      // Toplam sipariş sayısı
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('businessId', isEqualTo: widget.businessId)
          .get();

      final totalOrders = ordersQuery.docs.length;
      double totalRevenue = 0.0;
      int pendingOrders = 0;

      // Toplam gelir ve bekleyen siparişleri hesapla
      for (var doc in ordersQuery.docs) {
        final orderData = doc.data();
        if (orderData['status'] == 'completed') {
          totalRevenue += (orderData['totalAmount'] ?? 0.0).toDouble();
        }
        if (orderData['status'] == 'pending') {
          pendingOrders++;
        }
      }

      // Bugünkü siparişler
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todayOrdersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('businessId', isEqualTo: widget.businessId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('createdAt', isLessThan: endOfDay.toIso8601String())
          .get();

      final todayOrders = todayOrdersQuery.docs.length;
      double todayRevenue = 0.0;

      for (var doc in todayOrdersQuery.docs) {
        final orderData = doc.data();
        if (orderData['status'] == 'completed') {
          todayRevenue += (orderData['totalAmount'] ?? 0.0).toDouble();
        }
      }

      // Toplam ürün sayısı
      final productsQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('businessId', isEqualTo: widget.businessId)
          .get();

      // Toplam kategori sayısı
      final categoriesQuery = await FirebaseFirestore.instance
          .collection('categories')
          .where('businessId', isEqualTo: widget.businessId)
          .get();

      return {
        'totalOrders': totalOrders,
        'totalProducts': productsQuery.docs.length,
        'totalCategories': categoriesQuery.docs.length,
        'totalRevenue': totalRevenue,
        'todayOrders': todayOrders,
        'todayRevenue': todayRevenue,
        'pendingOrders': pendingOrders,
      };
    } catch (e) {
      print('İstatistik hesaplama hatası: $e');
      return {};
    }
  }

  // Navigate to specific tab programmatically
  void navigateToTab(String tabRoute) {
    final tabIndex = _tabRoutes.indexOf(tabRoute);
    if (tabIndex != -1) {
      _tabController.animateTo(tabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('İşletme Yönetimi'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: Center(child: ErrorMessage(message: _errorMessage!)),
      );
    }

    if (_business == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('İşletme Yönetimi'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
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
          // Tab Bar
          _buildTabBar(),
          // Tab View
          Expanded(
            child: _buildTabView(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: Row(
        children: [
          if (_business?.logoUrl != null)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _business!.logoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.business, color: AppColors.primary),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _business?.businessName ?? 'İşletme',
                  style: AppTypography.h6.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _tabTitles[_tabController.index],
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
                if (_pendingOrders > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_pendingOrders bekleyen sipariş',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Notification icon with pending orders badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                navigateToTab('siparisler'); // Use new navigation method
              },
            ),
            if (_pendingOrders > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _pendingOrders.toString(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadBusinessData,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                navigateToTab('ayarlar'); // Use new navigation method
                break;
              case 'logout':
                Navigator.pushReplacementNamed(context, '/');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.business),
                title: Text('İşletme Profili'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: AppColors.error),
                title: Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.bodyMedium,
        tabs: [
          Tab(
            icon: Icon(Icons.dashboard),
            text: 'Genel Bakış',
          ),
          Tab(
            icon: Stack(
              children: [
                Icon(Icons.receipt_long),
                if (_pendingOrders > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
            text: 'Siparişler',
          ),
          Tab(
            icon: Icon(Icons.category),
            text: 'Kategoriler',
          ),
          Tab(
            icon: Icon(Icons.restaurant_menu),
            text: 'Ürünler',
          ),
          Tab(
            icon: Icon(Icons.local_offer),
            text: 'İndirimler',
          ),
          Tab(
            icon: Icon(Icons.qr_code),
            text: 'QR Kodlar',
          ),
          Tab(
            icon: Icon(Icons.settings),
            text: 'Ayarlar',
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        OrderManagementPage(businessId: widget.businessId),
        CategoryManagementPage(businessId: widget.businessId),
        ProductManagementPage(businessId: widget.businessId),
        DiscountManagementPage(businessId: widget.businessId),
        QRManagementPage(businessId: widget.businessId),
        BusinessProfilePage(businessId: widget.businessId),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İstatistik kartları
          _buildStatsGrid(),

          const SizedBox(height: 24),

          // Son siparişler ve hızlı işlemler
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Son siparişler
              Expanded(
                flex: 2,
                child: _buildRecentOrders(),
              ),
              const SizedBox(width: 16),
              // Hızlı işlemler
              Expanded(
                child: _buildQuickActions(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Popüler ürünler ve kategoriler
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildPopularProducts(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoriesOverview(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'Bugünkü Siparişler',
          value: _todayOrders.toString(),
          icon: Icons.today,
          color: AppColors.primary,
          subtitle: '${_todayRevenue.toStringAsFixed(2)} TL',
        ),
        _buildStatCard(
          title: 'Bekleyen Siparişler',
          value: _pendingOrders.toString(),
          icon: Icons.pending,
          color: _pendingOrders > 0 ? AppColors.warning : AppColors.success,
          subtitle: 'Aktif',
        ),
        _buildStatCard(
          title: 'Toplam Ürünler',
          value: _totalProducts.toString(),
          icon: Icons.restaurant_menu,
          color: AppColors.info,
          subtitle: '$_totalCategories kategori',
        ),
        _buildStatCard(
          title: 'Toplam Gelir',
          value: '${_totalRevenue.toStringAsFixed(0)} TL',
          icon: Icons.attach_money,
          color: AppColors.success,
          subtitle: '$_totalOrders sipariş',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
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
                  'Son Siparişler',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => navigateToTab('siparisler'),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentOrders.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long,
                title: 'Henüz sipariş yok',
                message: 'İlk siparişinizi bekliyoruz',
              )
            else
              ...(_recentOrders.take(3).map((order) => _buildOrderItem(order))),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(app_order.Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(order.status),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(order.status),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masa ${order.tableNumber} - ${order.customerName}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${order.totalAmount.toStringAsFixed(2)} TL - ${_getStatusText(order.status)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(order.createdAt),
            style: AppTypography.caption.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return AppColors.warning;
      case app_order.OrderStatus.inProgress:
        return AppColors.info;
      case app_order.OrderStatus.completed:
        return AppColors.success;
      case app_order.OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getStatusText(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return 'Bekliyor';
      case app_order.OrderStatus.inProgress:
        return 'Hazırlanıyor';
      case app_order.OrderStatus.completed:
        return 'Tamamlandı';
      case app_order.OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}dk';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s';
    } else {
      return '${difference.inDays}g';
    }
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hızlı İşlemler',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActionButton(
              title: 'Yeni Ürün Ekle',
              icon: Icons.add,
              color: AppColors.success,
              onTap: () => navigateToTab('urunler'),
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              title: 'Kategori Ekle',
              icon: Icons.category,
              color: AppColors.primary,
              onTap: () => navigateToTab('kategoriler'),
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              title: 'İndirim Oluştur',
              icon: Icons.local_offer,
              color: AppColors.warning,
              onTap: () => navigateToTab('indirimler'),
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              title: 'QR Kod Oluştur',
              icon: Icons.qr_code,
              color: AppColors.info,
              onTap: () => navigateToTab('qr-kodlar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularProducts() {
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
                  'Popüler Ürünler',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => navigateToTab('urunler'),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_popularProducts.isEmpty)
              const EmptyState(
                icon: Icons.restaurant_menu,
                title: 'Henüz ürün yok',
                message: 'İlk ürününüzü ekleyin',
              )
            else
              ...(_popularProducts.take(5).map((product) => _buildProductItem(product))),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (product.imageUrl != null)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.greyLight,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.restaurant, color: AppColors.textSecondary),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${product.price.toStringAsFixed(2)} TL',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: product.isAvailable ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product.isAvailable ? 'Mevcut' : 'Tükendi',
              style: AppTypography.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesOverview() {
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
                  'Kategoriler',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => navigateToTab('kategoriler'),
                  child: const Text('Yönet'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_categories.isEmpty)
              const EmptyState(
                icon: Icons.category,
                title: 'Henüz kategori yok',
                message: 'İlk kategorinizi ekleyin',
              )
            else
              ...(_categories.take(4).map((category) => _buildCategoryItem(category))),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(Category category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.categoryName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${category.description ?? 'Açıklama yok'}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: category.isActive ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category.isActive ? 'Aktif' : 'Pasif',
              style: AppTypography.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 