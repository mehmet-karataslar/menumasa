import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';
import '../models/product.dart';
import '../models/category.dart' as business_category;
import '../../data/models/order.dart' as app_order;
import '../../customer/models/waiter_call.dart';
import '../services/business_firestore_service.dart';
import '../../core/services/url_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/waiter_call_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../widgets/notification_dialog.dart';
import 'business_profile_page.dart';
import 'product_management_page.dart';
import 'category_management_page.dart';
import 'order_management_page.dart';
import 'qr_management_page.dart';
import 'menu_management_page.dart';
import 'discount_management_page.dart';
import 'waiter_management_page.dart';
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
  final WaiterCallService _waiterCallService = WaiterCallService();

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
  
  // Waiter calls
  List<WaiterCall> _activeWaiterCalls = [];
  List<WaiterCall> _recentWaiterCalls = [];

  late TabController _tabController;
  int _currentIndex = 0;

  // Tab routes for URL
  final List<String> _tabRoutes = [
    'genel-bakis',
    'siparisler',
    'menu-yonetimi',
    'kategoriler',
    'urunler',
    'garsonlar',
    'indirimler',
    'qr-kodlar',
    'ayarlar',
  ];

  final List<String> _tabTitles = [
    'Genel Bakış',
    'Siparişler',
    'Menü Yönetimi',
    'Kategoriler',
    'Ürünler',
    'Garsonlar',
    'İndirimler',
    'QR Kodlar',
    'Ayarlar',
  ];

  final List<IconData> _tabIcons = [
    Icons.dashboard_rounded,
    Icons.receipt_long_rounded,
    Icons.restaurant_menu_outlined,
    Icons.category_rounded,
    Icons.inventory_rounded,
    Icons.people_rounded,
    Icons.local_offer_rounded,
    Icons.qr_code_rounded,
    Icons.settings_rounded,
  ];

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _setInitialTab();
    _tabController.addListener(_onTabChanged);
    _loadBusinessData();
    _setupNotificationListener();
    _loadWaiterCalls();
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

  Future<void> _loadWaiterCalls() async {
    try {
      final activeCalls = await _waiterCallService.getBusinessActiveCalls(widget.businessId);
      final recentCalls = await _waiterCallService.getBusinessCallHistory(
        widget.businessId,
        limit: 10,
      );
      
      if (mounted) {
        setState(() {
          _activeWaiterCalls = activeCalls;
          _recentWaiterCalls = recentCalls;
        });
      }
    } catch (e) {
      print('Garson çağrıları yüklenirken hata: $e');
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
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
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
        backgroundColor: const Color(0xFFF5F7FA),
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
    return AppBar(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      toolbarHeight: 80,
      title: Row(
        children: [
          if (_business?.logoUrl != null)
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _business!.logoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: 28,
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
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'İşletme Yönetim Paneli',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.notifications_rounded, color: AppColors.primary),
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$_unreadNotificationCount',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showNotificationsDialog,
            tooltip: 'Bildirimler',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.refresh_rounded, color: AppColors.info),
            ),
            onPressed: _loadBusinessData,
            tooltip: 'Yenile',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            ),
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  leading: Icon(Icons.business_rounded, color: AppColors.primary),
                  title: Text('İşletme Profili'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout_rounded, color: AppColors.error),
                  title: Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.divider.withOpacity(0.3),
        ),
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
        isScrollable: false,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withBlue(180)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        tabs: List.generate(
          _tabTitles.length,
              (index) => Tab(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_tabIcons[index], size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _tabTitles[index],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (index == 1 && _pendingOrders > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_pendingOrders',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
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
        MenuManagementPage(businessId: widget.businessId),
        CategoryManagementPage(businessId: widget.businessId),
        ProductManagementPage(businessId: widget.businessId),
        WaiterManagementPage(businessId: widget.businessId),
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
          _buildWaiterCallsSection(),
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
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          title: 'Bugünkü Siparişler',
          value: _todayOrders.toString(),
          icon: Icons.today_rounded,
          color: const Color(0xFF6C63FF),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _buildStatCard(
          title: 'Bekleyen Siparişler',
          value: _pendingOrders.toString(),
          icon: Icons.pending_actions_rounded,
          color: _pendingOrders > 0 ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4),
          gradient: LinearGradient(
            colors: _pendingOrders > 0
                ? [const Color(0xFFFF6B6B), const Color(0xFFFF8787)]
                : [const Color(0xFF4ECDC4), const Color(0xFF6FE6DD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _buildStatCard(
          title: 'Toplam Ürünler',
          value: _totalProducts.toString(),
          icon: Icons.restaurant_menu_rounded,
          color: const Color(0xFF4E9FF7),
          gradient: const LinearGradient(
            colors: [Color(0xFF4E9FF7), Color(0xFF6DB3FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _buildStatCard(
          title: 'Toplam Gelir',
          value: '₺${_totalRevenue.toStringAsFixed(0)}',
          icon: Icons.payments_rounded,
          color: const Color(0xFF1DD1A1),
          gradient: const LinearGradient(
            colors: [Color(0xFF1DD1A1), Color(0xFF3DDBB7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: AppColors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Son Siparişler',
                      style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToTab(1),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    children: const [
                      Text('Tümünü Gör'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_recentOrders.isEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Henüz sipariş yok',
                    message: 'İlk siparişinizi bekliyoruz',
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentOrders.take(5).length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildOrderItem(_recentOrders[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(app_order.Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(order.status),
                  _getStatusColor(order.status).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'M${order.tableNumber}',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                  order.customerName,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusText(order.status),
                  style: AppTypography.bodySmall.copyWith(
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${order.totalAmount.toStringAsFixed(2)}',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flash_on_rounded, color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Hızlı İşlemler',
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildQuickActionButton(
              title: 'Yeni Ürün Ekle',
              icon: Icons.add_circle_rounded,
              color: const Color(0xFF1DD1A1),
              onTap: () => _navigateToTab(3),
            ),
            const SizedBox(height: 12),
            _buildQuickActionButton(
              title: 'Kategori Ekle',
              icon: Icons.category_rounded,
              color: const Color(0xFF6C63FF),
              onTap: () => _navigateToTab(2),
            ),
            const SizedBox(height: 12),
            _buildQuickActionButton(
              title: 'İndirim Oluştur',
              icon: Icons.local_offer_rounded,
              color: const Color(0xFFFFA502),
              onTap: () => _navigateToTab(4),
            ),
            const SizedBox(height: 12),
            _buildQuickActionButton(
              title: 'QR Kod Oluştur',
              icon: Icons.qr_code_rounded,
              color: const Color(0xFF4E9FF7),
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularProducts() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.star_rounded, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Popüler Ürünler',
                      style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToTab(3),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    children: const [
                      Text('Tümünü Gör'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_popularProducts.isEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: EmptyState(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Henüz ürün yok',
                    message: 'İlk ürününüzü ekleyin',
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _popularProducts.take(5).length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildProductItem(_popularProducts[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      product.imageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.restaurant_rounded, 
                        color: AppColors.textSecondary, 
                        size: 24
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Icon(Icons.restaurant_rounded, color: AppColors.textSecondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₺${product.price.toStringAsFixed(2)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: product.isAvailable
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: product.isAvailable
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.error.withOpacity(0.3),
              ),
            ),
            child: Text(
              product.isAvailable ? 'Mevcut' : 'Tükendi',
              style: TextStyle(
                color: product.isAvailable ? AppColors.success : AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesOverview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.category_rounded, color: AppColors.info, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Kategoriler',
                      style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToTab(2),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    children: const [
                      Text('Yönet'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_categories.isEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: EmptyState(
                    icon: Icons.category_rounded,
                    title: 'Henüz kategori yok',
                    message: 'İlk kategorinizi ekleyin',
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.take(5).length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildCategoryItem(_categories[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(business_category.Category category) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withBlue(180),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.category_rounded, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.categoryName,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (category.description != null && category.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    category.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: category.isActive
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: category.isActive
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.error.withOpacity(0.3),
              ),
            ),
            child: Text(
              category.isActive ? 'Aktif' : 'Pasif',
              style: TextStyle(
                color: category.isActive ? AppColors.success : AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return const Color(0xFFFFA502);
      case app_order.OrderStatus.confirmed:
      case app_order.OrderStatus.inProgress:
        return const Color(0xFF4E9FF7);
      case app_order.OrderStatus.preparing:
        return const Color(0xFFFFA502);
      case app_order.OrderStatus.ready:
      case app_order.OrderStatus.delivered:
      case app_order.OrderStatus.completed:
        return const Color(0xFF1DD1A1);
      case app_order.OrderStatus.cancelled:
        return const Color(0xFFFF6B6B);
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

  Widget _buildWaiterCallsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _activeWaiterCalls.isNotEmpty 
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.room_service_rounded,
                    color: _activeWaiterCalls.isNotEmpty 
                        ? AppColors.error
                        : AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Garson Çağrıları',
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _activeWaiterCalls.isNotEmpty 
                            ? '${_activeWaiterCalls.length} aktif çağrı var'
                            : 'Tüm çağrılar halledildi',
                        style: AppTypography.bodyMedium.copyWith(
                          color: _activeWaiterCalls.isNotEmpty 
                              ? AppColors.error
                              : AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadWaiterCalls,
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          
          // Active calls or empty state
          if (_activeWaiterCalls.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktif Çağrılar',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._activeWaiterCalls.take(3).map((call) => _buildWaiterCallCard(call)),
                  if (_activeWaiterCalls.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            // Navigate to full waiter calls page
                          },
                          child: Text('${_activeWaiterCalls.length - 3} çağrı daha göster'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 48,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tüm çağrılar halledildi!',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'Şu anda bekleyen garson çağrısı bulunmuyor.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Statistics
          if (_recentWaiterCalls.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCallStat(
                      'Bugün',
                      '${_recentWaiterCalls.where((c) => _isToday(c.createdAt)).length}',
                      Icons.today_rounded,
                      AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildCallStat(
                      'Ort. Yanıt',
                      '${_calculateAverageResponseTime()} dk',
                      Icons.access_time_rounded,
                      AppColors.info,
                    ),
                  ),
                  Expanded(
                    child: _buildCallStat(
                      'Tamamlanan',
                      '${_recentWaiterCalls.where((c) => c.status == WaiterCallStatus.completed).length}',
                      Icons.check_circle_rounded,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCallStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWaiterCallCard(WaiterCall call) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyLighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: call.isOverdue ? AppColors.error : AppColors.greyLight,
          width: call.isOverdue ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF${call.priorityColorCode.substring(1)}')).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCallTypeIcon(call.requestType),
              color: Color(int.parse('0xFF${call.priorityColorCode.substring(1)}')),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Masa ${call.tableNumber}',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF${call.statusColorCode.substring(1)}')).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        call.status.displayName,
                        style: AppTypography.caption.copyWith(
                          color: Color(int.parse('0xFF${call.statusColorCode.substring(1)}')),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  call.requestType.displayName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${call.waitingTimeMinutes} dakika önce',
                      style: AppTypography.caption.copyWith(
                        color: call.isOverdue ? AppColors.error : AppColors.textSecondary,
                        fontWeight: call.isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (call.isOverdue) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.warning_rounded,
                        size: 14,
                        color: AppColors.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _handleWaiterCall(call),
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            iconSize: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  IconData _getCallTypeIcon(WaiterCallType type) {
    switch (type) {
      case WaiterCallType.service:
        return Icons.room_service_rounded;
      case WaiterCallType.order:
        return Icons.restaurant_menu_rounded;
      case WaiterCallType.payment:
        return Icons.receipt_rounded;
      case WaiterCallType.complaint:
        return Icons.report_problem_rounded;
      case WaiterCallType.assistance:
        return Icons.help_rounded;
      case WaiterCallType.bill:
        return Icons.receipt_rounded;
      case WaiterCallType.help:
        return Icons.help_rounded;
      case WaiterCallType.cleaning:
        return Icons.cleaning_services_rounded;
      case WaiterCallType.emergency:
        return Icons.emergency_rounded;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  int _calculateAverageResponseTime() {
    final completedCalls = _recentWaiterCalls
        .where((c) => c.status == WaiterCallStatus.completed && c.responseTimeMinutes != null)
        .toList();
    
    if (completedCalls.isEmpty) return 0;
    
    final totalTime = completedCalls
        .map((c) => c.responseTimeMinutes!)
        .reduce((a, b) => a + b);
    
    return (totalTime / completedCalls.length).round();
  }

  void _handleWaiterCall(WaiterCall call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Masa ${call.tableNumber} - ${call.requestType.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Durum', call.status.displayName),
            _buildInfoRow('Öncelik', call.priority.displayName),
            if (call.message != null && call.message!.isNotEmpty)
              _buildInfoRow('Mesaj', call.message!),
            _buildInfoRow('Çağrı Zamanı', _formatDateTime(call.createdAt)),
            if (call.waiterName != null)
              _buildInfoRow('Atanan Garson', call.waiterName!),
            if (call.isOverdue)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Bu çağrı gecikmiş!',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          if (call.status == WaiterCallStatus.pending)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _acknowledgeCall(call);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Onayla'),
            ),
          if (call.status == WaiterCallStatus.acknowledged ||
              call.status == WaiterCallStatus.inProgress)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _completeCall(call);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Tamamla'),
            ),
        ],
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
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledgeCall(WaiterCall call) async {
    try {
      await _waiterCallService.acknowledgeCall(
        call.callId,
        waiterId: 'business_manager',
        waiterName: 'İşletme Yöneticisi',
      );
      _loadWaiterCalls();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çağrı onaylandı'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çağrı onaylanırken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _completeCall(WaiterCall call) async {
    try {
      await _waiterCallService.completeCall(
        call.callId,
        responseNotes: 'İşletme yöneticisi tarafından tamamlandı',
      );
      _loadWaiterCalls();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çağrı tamamlandı'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çağrı tamamlanırken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}