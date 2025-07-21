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

class BusinessDashboardMobile extends StatefulWidget {
  final String businessId;
  final String? initialTab;

  const BusinessDashboardMobile({
    super.key,
    required this.businessId,
    this.initialTab,
  });

  @override
  State<BusinessDashboardMobile> createState() => _BusinessDashboardMobileState();
}

class _BusinessDashboardMobileState extends State<BusinessDashboardMobile> {
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

  int _currentIndex = 0;
  PageController _pageController = PageController();

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

  @override
  void initState() {
    super.initState();
    _setInitialTab();
    _loadBusinessData();
    _setupNotificationListener();
  }

  void _setInitialTab() {
    if (widget.initialTab != null) {
      final tabIndex = _tabRoutes.indexOf(widget.initialTab!);
      if (tabIndex != -1) {
        _currentIndex = tabIndex;
        _pageController = PageController(initialPage: tabIndex);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUrl();
    });
  }

  void _updateUrl() {
    final currentTab = _tabRoutes[_currentIndex];
    final businessName = _business?.businessName;

    _urlService.updateBusinessUrl(
      widget.businessId,
      currentTab,
      businessName: businessName,
    );
  }

  void _setupNotificationListener() {
    _notificationService.addNotificationListener(
        widget.businessId, _onNotificationsChanged);
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
      if (business == null) {
        throw Exception('İşletme bulunamadı');
      }

      final orders = await _businessFirestoreService.getBusinessOrders(
        widget.businessId,
        limit: 5,
      );

      final categories = await _businessFirestoreService.getBusinessCategories(widget.businessId);
      final products = await _businessFirestoreService.getBusinessProducts(
        widget.businessId,
        limit: 10,
      );

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
            const SnackBar(
              content: Text('Çıkış yapıldı'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Çıkış hatası: $e'),
              backgroundColor: AppColors.error,
            ),
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
        onMarkAllRead: () {
          _notificationService.markAllAsRead(widget.businessId);
        },
      ),
    );
  }

  void _navigateToTab(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.jumpToPage(index);
    _updateUrl();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notificationService.removeNotificationListener(
        widget.businessId, _onNotificationsChanged);
    super.dispose();
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _updateUrl();
        },
        children: [
          _buildOverviewPage(),
          OrderManagementPage(businessId: widget.businessId),
          CategoryManagementPage(businessId: widget.businessId),
          ProductManagementPage(businessId: widget.businessId),
          DiscountManagementPage(businessId: widget.businessId),
          QRManagementPage(businessId: widget.businessId),
          BusinessProfilePage(businessId: widget.businessId),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 1,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _business?.businessName ?? 'İşletme',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _tabTitles[_currentIndex],
            style: AppTypography.caption.copyWith(
              color: AppColors.white.withOpacity(0.9),
              fontSize: 11,
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
              case 'logout':
                _handleLogout();
                break;
            }
          },
          itemBuilder: (context) => [
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

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _navigateToTab,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 10,
      ),
      unselectedLabelStyle: AppTypography.caption.copyWith(fontSize: 9),
      elevation: 8,
      items: List.generate(
        _tabTitles.length,
        (index) => BottomNavigationBarItem(
          icon: _buildNavIcon(_tabIcons[index], index),
          label: _getShortLabel(index),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    final badge = index == 1 ? _pendingOrders : null;

    return Stack(
      children: [
        Icon(
          icon,
          size: isSelected ? 24 : 20,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        if (badge != null && badge > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                badge.toString(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  String _getShortLabel(int index) {
    const shortLabels = [
      'Genel',
      'Sipariş',
      'Kategori',
      'Ürün',
      'İndirim',
      'QR',
      'Ayarlar',
    ];
    return shortLabels[index];
  }

  Widget _buildOverviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsSection(),
          const SizedBox(height: 24),
          _buildQuickActionsSection(),
          const SizedBox(height: 24),
          _buildRecentOrdersSection(),
          const SizedBox(height: 24),
          _buildPopularProductsSection(),
          const SizedBox(height: 100), // Bottom padding for floating nav
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İstatistikler',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                title: 'Bugün',
                value: _todayOrders.toString(),
                subtitle: 'Sipariş',
                icon: Icons.today,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileStatCard(
                title: 'Bekleyen',
                value: _pendingOrders.toString(),
                subtitle: 'Sipariş',
                icon: Icons.pending,
                color: _pendingOrders > 0 ? AppColors.warning : AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                title: 'Ürünler',
                value: _totalProducts.toString(),
                subtitle: '$_totalCategories Kategori',
                icon: Icons.restaurant_menu,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileStatCard(
                title: 'Toplam Gelir',
                value: _totalRevenue > 1000
                    ? '${(_totalRevenue / 1000).toStringAsFixed(1)}K'
                    : '${_totalRevenue.toStringAsFixed(0)}',
                subtitle: 'TL',
                icon: Icons.attach_money,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.textLight,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildQuickActionCard(
              title: 'Ürün Ekle',
              icon: Icons.add_business,
              color: AppColors.success,
              onTap: () => _navigateToTab(3),
            ),
            _buildQuickActionCard(
              title: 'Kategori',
              icon: Icons.category,
              color: AppColors.primary,
              onTap: () => _navigateToTab(2),
            ),
            _buildQuickActionCard(
              title: 'İndirim',
              icon: Icons.local_offer,
              color: AppColors.warning,
              onTap: () => _navigateToTab(4),
            ),
            _buildQuickActionCard(
              title: 'QR Kod',
              icon: Icons.qr_code,
              color: AppColors.info,
              onTap: () => _navigateToTab(5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
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
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Son Siparişler',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToTab(1),
              child: const Text('Tümü'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentOrders.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: EmptyState(
                  icon: Icons.receipt_long,
                  title: 'Henüz sipariş yok',
                  message: 'İlk siparişinizi bekliyoruz',
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentOrders.take(3).length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = _recentOrders[index];
              return _buildMobileOrderCard(order);
            },
          ),
      ],
    );
  }

  Widget _buildMobileOrderCard(app_order.Order order) {
    return Card(
      elevation: 1,
      child: ListTile(
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
      ),
    );
  }

  Widget _buildPopularProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popüler Ürünler',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToTab(3),
              child: const Text('Tümü'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_popularProducts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: EmptyState(
                  icon: Icons.restaurant_menu,
                  title: 'Henüz ürün yok',
                  message: 'İlk ürününüzü ekleyin',
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _popularProducts.take(4).length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = _popularProducts[index];
              return _buildMobileProductCard(product);
            },
          ),
      ],
    );
  }

  Widget _buildMobileProductCard(Product product) {
    return Card(
      elevation: 1,
      child: ListTile(
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
        title: Text(
          product.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
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
        return AppColors.info;
      case app_order.OrderStatus.preparing:
        return AppColors.warning;
      case app_order.OrderStatus.ready:
        return AppColors.success;
      case app_order.OrderStatus.delivered:
        return AppColors.success;
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
      case app_order.OrderStatus.confirmed:
        return 'Onaylandı';
      case app_order.OrderStatus.preparing:
        return 'Hazırlanıyor';
      case app_order.OrderStatus.ready:
        return 'Hazır';
      case app_order.OrderStatus.delivered:
        return 'Teslim Edildi';
      case app_order.OrderStatus.inProgress:
        return 'Hazırlanıyor';
      case app_order.OrderStatus.completed:
        return 'Tamamlandı';
      case app_order.OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }
} 