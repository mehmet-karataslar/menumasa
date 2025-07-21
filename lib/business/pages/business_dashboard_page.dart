import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';
import '../models/product.dart';
import '../models/category.dart' as business_category;
import '../../data/models/order.dart' as app_order;
import '../services/business_firestore_service.dart';
import '../../core/services/url_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../widgets/notification_dialog.dart';
import 'business_profile_page.dart';
import 'product_management_page.dart';
import 'category_management_page.dart';
import 'order_management_page.dart';
import 'qr_management_page.dart';
import 'menu_settings_page.dart';
import 'discount_management_page.dart';
import 'business_dashboard_mobile.dart';

class BusinessDashboard extends StatefulWidget {
  final String businessId;
  final String? initialTab;

  const BusinessDashboard({
    super.key,
    required this.businessId,
    this.initialTab,
  });

  @override
  State<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard>
    with SingleTickerProviderStateMixin {
  final BusinessFirestoreService _businessFirestoreService = BusinessFirestoreService();
  final UrlService _urlService = UrlService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  Business? _business;
  List<app_order.Order> _recentOrders = [];
  List<Product> _popularProducts = [];
  List<business_category.Category> _categories = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Statistics
  int _totalOrders = 0;
  int _totalProducts = 0;
  int _totalCategories = 0;
  double _totalRevenue = 0.0;
  int _todayOrders = 0;
  int _pendingOrders = 0;

  // Notifications
  List<NotificationModel> _notifications = [];
  int _unreadNotificationCount = 0;

  late TabController _tabController;
  int _currentIndex = 0;

  // Tab routes for URL
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

  final List<IconData> _tabIcons = [
    Icons.dashboard,
    Icons.receipt_long,
    Icons.category,
    Icons.restaurant_menu,
    Icons.local_offer,
    Icons.qr_code,
    Icons.settings,
  ];

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _setInitialTab();
    _tabController.addListener(_onTabChanged);
    _loadBusinessData();
    _setupNotificationListener();
  }

  void _setInitialTab() {
    if (widget.initialTab != null) {
      final tabIndex = _tabRoutes.indexOf(widget.initialTab!);
      if (tabIndex != -1) {
        _tabController.index = tabIndex;
        _currentIndex = tabIndex;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateUrl());
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() => _currentIndex = _tabController.index);
      _updateUrl();
    }
  }

  void _updateUrl() {
    final currentTab = _tabRoutes[_currentIndex];
    final businessName = _business?.businessName;
    _urlService.updateBusinessUrl(widget.businessId, currentTab, businessName: businessName);
  }

  void _setupNotificationListener() {
    _notificationService.addNotificationListener(widget.businessId, _onNotificationsChanged);
  }

  void _onNotificationsChanged(List<NotificationModel> notifications) {
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _unreadNotificationCount = notifications.length;
      });
    }
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final business = await _businessFirestoreService.getBusiness(widget.businessId);
      if (business == null) throw Exception('İşletme bulunamadı');

      final orders = await _businessFirestoreService.getBusinessOrders(widget.businessId, limit: 5);
      final categories = await _businessFirestoreService.getBusinessCategories(widget.businessId);
      final products = await _businessFirestoreService.getBusinessProducts(widget.businessId, limit: 10);
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
        _pendingOrders = stats['pendingOrders'] ?? 0;
      });

      _updateUrl();
    } catch (e) {
      setState(() => _errorMessage = 'Veriler yüklenirken hata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _calculateStats() async {
    try {
      final dailyStats = await _businessFirestoreService.getDailyOrderStats(widget.businessId);
      final allOrders = await _businessFirestoreService.getOrdersByBusiness(widget.businessId);

      double totalRevenue = 0.0;
      int pendingOrders = 0;

      for (var order in allOrders) {
        if (order.status == app_order.OrderStatus.completed) {
          totalRevenue += order.totalAmount;
        }
        if (order.status == app_order.OrderStatus.pending) {
          pendingOrders++;
        }
      }

      return {
        'totalOrders': allOrders.length,
        'totalProducts': _popularProducts.length,
        'totalCategories': _categories.length,
        'totalRevenue': totalRevenue,
        'todayOrders': dailyStats['total'] ?? 0,
        'pendingOrders': pendingOrders,
      };
    } catch (e) {
      print('İstatistik hesaplama hatası: $e');
      return {};
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          _urlService.updateUrl('/', customTitle: 'MasaMenu - Dijital Menü Çözümü');
          Navigator.pushReplacementNamed(context, '/');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Çıkış yapıldı'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Çıkış hatası: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => NotificationDialog(
        businessId: widget.businessId,
        notifications: _notifications,
        onNotificationTap: (notification) {
          Navigator.of(context).pop();
          _notificationService.markAsRead(notification.id);
          if (notification.type == NotificationType.newOrder) {
            _navigateToTab(1);
          }
        },
        onMarkAllRead: () => _notificationService.markAllAsRead(widget.businessId),
      ),
    );
  }

  void _navigateToTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _tabController.animateTo(index);
    _updateUrl();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _notificationService.removeNotificationListener(widget.businessId, _onNotificationsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mobile: Use dedicated mobile dashboard
    if (_isMobile) {
      return BusinessDashboardMobile(
        businessId: widget.businessId,
        initialTab: widget.initialTab,
      );
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
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
        backgroundColor: AppColors.backgroundLight,
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

    // Desktop/Tablet Layout
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 1,
      toolbarHeight: 70,
      title: Row(
        children: [
          if (_business?.logoUrl != null)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _business!.logoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _business?.businessName ?? 'İşletme',
                  style: AppTypography.h5.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'İşletme Yönetim Paneli',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotificationCount',
                      style: const TextStyle(
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
          onPressed: _showNotificationsDialog,
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
                _navigateToTab(6);
                break;
              case 'logout':
                _handleLogout();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.business, color: AppColors.primary),
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
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.bodyMedium,
        tabs: List.generate(
          _tabTitles.length,
          (index) => Tab(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_tabIcons[index], size: 18),
                const SizedBox(width: 8),
                Text(_tabTitles[index]),
                if (index == 1 && _pendingOrders > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_pendingOrders',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRecentOrders()),
              const SizedBox(width: 24),
              Expanded(child: _buildQuickActions()),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPopularProducts()),
              const SizedBox(width: 24),
              Expanded(child: _buildCategoriesOverview()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'Bugünkü Siparişler',
          value: _todayOrders.toString(),
          icon: Icons.today,
          color: AppColors.primary,
        ),
        _buildStatCard(
          title: 'Bekleyen Siparişler',
          value: _pendingOrders.toString(),
          icon: Icons.pending,
          color: _pendingOrders > 0 ? AppColors.warning : AppColors.success,
        ),
        _buildStatCard(
          title: 'Toplam Ürünler',
          value: _totalProducts.toString(),
          icon: Icons.restaurant_menu,
          color: AppColors.info,
        ),
        _buildStatCard(
          title: 'Toplam Gelir',
          value: '${_totalRevenue.toStringAsFixed(0)} TL',
          icon: Icons.attach_money,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.h4.copyWith(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son Siparişler',
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _navigateToTab(1),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentOrders.isEmpty)
              const SizedBox(
                height: 200,
                child: EmptyState(
                  icon: Icons.receipt_long,
                  title: 'Henüz sipariş yok',
                  message: 'İlk siparişinizi bekliyoruz',
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentOrders.take(5).length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) => _buildOrderItem(_recentOrders[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(app_order.Order order) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(order.status),
        child: Text(
          order.tableNumber.toString(),
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(order.customerName),
      subtitle: Text(_getStatusText(order.status)),
      trailing: Text(
        '${order.totalAmount.toStringAsFixed(2)} TL',
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.success,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hızlı İşlemler',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildQuickActionButton(
              title: 'Yeni Ürün Ekle',
              icon: Icons.add,
              color: AppColors.success,
              onTap: () => _navigateToTab(3),
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              title: 'Kategori Ekle',
              icon: Icons.category,
              color: AppColors.primary,
              onTap: () => _navigateToTab(2),
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              title: 'İndirim Oluştur',
              icon: Icons.local_offer,
              color: AppColors.warning,
              onTap: () => _navigateToTab(4),
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              title: 'QR Kod Oluştur',
              icon: Icons.qr_code,
              color: AppColors.info,
              onTap: () => _navigateToTab(5),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.6), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularProducts() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popüler Ürünler',
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _navigateToTab(3),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_popularProducts.isEmpty)
              const SizedBox(
                height: 200,
                child: EmptyState(
                  icon: Icons.restaurant_menu,
                  title: 'Henüz ürün yok',
                  message: 'İlk ürününüzü ekleyin',
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _popularProducts.take(5).length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) => _buildProductItem(_popularProducts[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.greyLight,
        child: product.imageUrl != null
            ? ClipOval(
                child: Image.network(
                  product.imageUrl!,
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.restaurant, color: AppColors.textSecondary),
                ),
              )
            : const Icon(Icons.restaurant, color: AppColors.textSecondary),
      ),
      title: Text(product.productName),
      subtitle: Text('${product.price.toStringAsFixed(2)} TL'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: product.isAvailable ? AppColors.success : AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          product.isAvailable ? 'Mevcut' : 'Tükendi',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesOverview() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kategoriler',
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _navigateToTab(2),
                  child: const Text('Yönet'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_categories.isEmpty)
              const SizedBox(
                height: 200,
                child: EmptyState(
                  icon: Icons.category,
                  title: 'Henüz kategori yok',
                  message: 'İlk kategorinizi ekleyin',
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.take(5).length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) => _buildCategoryItem(_categories[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(business_category.Category category) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Icon(Icons.category, color: AppColors.white),
      ),
      title: Text(category.categoryName),
      subtitle: Text(category.description ?? 'Açıklama yok'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: category.isActive ? AppColors.success : AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          category.isActive ? 'Aktif' : 'Pasif',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return AppColors.warning;
      case app_order.OrderStatus.confirmed:
      case app_order.OrderStatus.inProgress:
        return AppColors.info;
      case app_order.OrderStatus.preparing:
        return AppColors.warning;
      case app_order.OrderStatus.ready:
      case app_order.OrderStatus.delivered:
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
      case app_order.OrderStatus.confirmed:
        return 'Onaylandı';
      case app_order.OrderStatus.preparing:
      case app_order.OrderStatus.inProgress:
        return 'Hazırlanıyor';
      case app_order.OrderStatus.ready:
        return 'Hazır';
      case app_order.OrderStatus.delivered:
        return 'Teslim Edildi';
      case app_order.OrderStatus.completed:
        return 'Tamamlandı';
      case app_order.OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }
}
 