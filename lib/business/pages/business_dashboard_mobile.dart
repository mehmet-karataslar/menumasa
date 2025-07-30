import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/web_safe_image.dart';
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
import 'order_management_page.dart';
import 'qr_management_page.dart';
import 'menu_management_page.dart';
import 'discount_management_page.dart';
import 'table_management_page.dart';
import 'staff_management_page.dart';
import 'coming_soon_features_page.dart';

class BusinessDashboardMobile extends StatefulWidget {
  final String businessId;
  final String? initialTab;

  const BusinessDashboardMobile({
    super.key,
    required this.businessId,
    this.initialTab,
  });

  @override
  State<BusinessDashboardMobile> createState() =>
      _BusinessDashboardMobileState();
}

class _BusinessDashboardMobileState extends State<BusinessDashboardMobile>
    with TickerProviderStateMixin {
  final BusinessFirestoreService _businessFirestoreService =
      BusinessFirestoreService();
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

  int _currentIndex = 0;

  // Yan menü kontrolü
  bool _isDrawerOpen = false;
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerAnimation;

  // Tab routes for URL
  final List<String> _tabRoutes = [
    'genel-bakis',
    'siparisler',
    'menu-yonetimi',
    'indirimler',
    'qr-kodlar',
    'masa-yonetimi',
    'personel-takibi',
    'gelecek-ozellikler',
    'ayarlar',
  ];

  final List<String> _tabTitles = [
    'Ana Sayfa',
    'Siparişler',
    'Menü Yönetimi',
    'İndirimler',
    'QR Kodlar',
    'Masa Yönetimi',
    'Personel Takibi',
    'Gelecek Özellikler',
    'Ayarlar',
  ];

  final List<IconData> _tabIcons = [
    Icons.dashboard_rounded,
    Icons.receipt_long_rounded,
    Icons.restaurant_menu_outlined,
    Icons.local_offer_rounded,
    Icons.qr_code_rounded,
    Icons.table_restaurant_rounded,
    Icons.group_rounded,
    Icons.rocket_launch_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _setInitialTab();
    _loadBusinessData();
    _setupNotificationListener();
    _loadWaiterCalls();

    // Drawer animasyonu
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _drawerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _drawerAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _setInitialTab() {
    if (widget.initialTab != null) {
      String initialTab = widget.initialTab!;

      // Eski tab route'larını yeni route'lara yönlendir
      if (initialTab == 'kategoriler' || initialTab == 'urunler') {
        initialTab = 'menu-yonetimi';
      }

      final tabIndex = _tabRoutes.indexOf(initialTab);
      if (tabIndex != -1) {
        _currentIndex = tabIndex;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUrl();
    });
  }

  void _updateUrl() {
    final currentTab = _tabRoutes[_currentIndex];
    final businessName = _business?.businessName;

    print('🌐 Updating URL to: $currentTab (index: $_currentIndex)');

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

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });

    if (_isDrawerOpen) {
      _drawerAnimationController.forward();
    } else {
      _drawerAnimationController.reverse();
    }
  }

  void _closeDrawer() {
    if (_isDrawerOpen) {
      setState(() {
        _isDrawerOpen = false;
      });
      _drawerAnimationController.reverse();
    }
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
      final activeCalls =
          await _waiterCallService.getBusinessActiveCalls(widget.businessId);
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
      final business =
          await _businessFirestoreService.getBusiness(widget.businessId);
      if (business == null) {
        throw Exception('İşletme bulunamadı');
      }

      final orders = await _businessFirestoreService.getBusinessOrders(
        widget.businessId,
        limit: 5,
      );

      final categories = await _businessFirestoreService
          .getBusinessCategories(widget.businessId);
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
      final dailyStats =
          await _businessFirestoreService.getDailyOrderStats(widget.businessId);
      final allOrders = await _businessFirestoreService
          .getOrdersByBusiness(widget.businessId);

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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Çıkış Yap',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
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
          _urlService.updateUrl('/',
              customTitle: 'MasaMenu - Dijital Menü Çözümü');
          Navigator.pushReplacementNamed(context, '/');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Çıkış yapıldı'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Çıkış hatası: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
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
    if (_currentIndex == index) {
      print('⚠️ Already on tab $index, skipping navigation');
      return;
    }

    print(
        '🚀 Navigating from tab $_currentIndex to tab $index (${_tabTitles[index]})');

    setState(() {
      _currentIndex = index;
    });

    print('✅ Current index updated to: $_currentIndex');
    _updateUrl();
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    _notificationService.removeNotificationListener(
        widget.businessId, _onNotificationsChanged);
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
        appBar: _buildAppBar(),
        body: Center(child: ErrorMessage(message: _errorMessage!)),
      );
    }

    if (_business == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: _buildAppBar(),
        body: const Center(
          child: EmptyState(
            icon: Icons.business_rounded,
            title: 'İşletme Bulunamadı',
            message: 'İşletme bilgileri yüklenemedi',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Ana içerik
            GestureDetector(
              onTap: _closeDrawer,
              child: Column(
                children: [
                  _buildCustomHeader(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildCurrentPage(),
                    ),
                  ),
                ],
              ),
            ),

            // Yan menü
            _buildSideDrawer(),

            // Overlay (arka plan karartma) - sadece drawer'ın sağ tarafında
            if (_isDrawerOpen)
              AnimatedBuilder(
                animation: _drawerAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: 280 * _drawerAnimation.value,
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: AppColors.black
                          .withOpacity(0.3 * _drawerAnimation.value),
                      child: GestureDetector(
                        onTap: _closeDrawer,
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

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drawer açma butonu
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleDrawer,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isDrawerOpen ? Icons.close_rounded : Icons.menu_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),

          if (_business?.logoUrl != null)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
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
                child: WebSafeImage(
                  imageUrl: _business!.logoUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, error, stackTrace) => Container(
                    color: AppColors.primary.withOpacity(0.1),
                    child: Icon(Icons.business_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _business?.businessName ?? 'İşletme',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _tabTitles[_currentIndex],
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderAction(
            icon: Icons.refresh_rounded,
            onTap: _loadBusinessData,
            color: AppColors.info,
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              _buildHeaderAction(
                icon: Icons.notifications_rounded,
                onTap: _showNotificationsDialog,
                color: AppColors.primary,
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
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
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            position: PopupMenuPosition.under,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            offset: const Offset(0, 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.more_vert_rounded,
                  color: AppColors.textSecondary, size: 24),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                height: 48,
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      toolbarHeight: 0,
    );
  }

  Widget _buildSideDrawer() {
    return AnimatedBuilder(
      animation: _drawerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-280 + (280 * _drawerAnimation.value), 0),
          child: Container(
            width: 280,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(5, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_business?.logoUrl != null)
                          Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border:
                                  Border.all(color: AppColors.white, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: WebSafeImage(
                                imageUrl: _business!.logoUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (context, error, stackTrace) =>
                                    Container(
                                  color: AppColors.white.withOpacity(0.2),
                                  child: Icon(Icons.business_rounded,
                                      color: AppColors.white, size: 30),
                                ),
                              ),
                            ),
                          ),
                        Text(
                          _business?.businessName ?? 'İşletme',
                          style: AppTypography.h6.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'İşletme Yönetimi',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Menü Listesi
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _tabTitles.length,
                    itemBuilder: (context, index) =>
                        _buildDrawerMenuItem(index),
                  ),
                ),

                // Alt Kısım - Çıkış
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.greyLight, width: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDrawerActionItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Yardım',
                        onTap: () {
                          // Yardım sayfası
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDrawerActionItem(
                        icon: Icons.logout_rounded,
                        title: 'Çıkış Yap',
                        color: AppColors.error,
                        onTap: () {
                          _closeDrawer();
                          _handleLogout();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerMenuItem(int index) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            print('🖱️ Drawer item tapped: $index (${_tabTitles[index]})');
            _navigateToTab(index);

            // Drawer'ı kapat ve biraz bekle
            _closeDrawer();

            // Sayfa değişimi için ekstra setState
            await Future.delayed(const Duration(milliseconds: 50));
            if (mounted) {
              setState(() {});
            }
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primary.withOpacity(0.2),
          highlightColor: AppColors.primary.withOpacity(0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.5)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _tabIcons[index],
                    color: isSelected ? AppColors.white : AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _tabTitles[index],
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (index == 1 && _pendingOrders > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: itemColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: itemColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    print(
        '📱 Building current page for index: $_currentIndex (${_tabTitles[_currentIndex]})');

    switch (_currentIndex) {
      case 0:
        print('🏠 Loading Overview Page');
        return Container(
          key: const ValueKey('overview'),
          child: _buildOverviewPage(),
        );
      case 1:
        print('📋 Loading Orders Page');
        return Container(
          key: const ValueKey('orders'),
          child: OrderManagementPage(businessId: widget.businessId),
        );
      case 2:
        print('🍽️ Loading Menu Management Page');
        return Container(
          key: const ValueKey('menu'),
          child: MenuManagementPage(businessId: widget.businessId),
        );
      case 3:
        print('🎯 Loading Discounts Page');
        return Container(
          key: const ValueKey('discounts'),
          child: DiscountManagementPage(businessId: widget.businessId),
        );
      case 4:
        print('📱 Loading QR Page');
        return Container(
          key: const ValueKey('qr'),
          child: QRManagementPage(businessId: widget.businessId),
        );
      case 5:
        print('🍽️ Loading Table Management Page');
        return Container(
          key: const ValueKey('table-management'),
          child: TableManagementPage(businessId: widget.businessId),
        );
      case 6:
        print('👥 Loading Staff Management Page');
        return Container(
          key: const ValueKey('staff-management'),
          child: StaffManagementPage(businessId: widget.businessId),
        );
      case 7:
        print('🚀 Loading Future Features Page');
        return Container(
          key: const ValueKey('future-features'),
          child: ComingSoonFeaturesPage(businessId: widget.businessId),
        );
      case 8:
        print('⚙️ Loading Profile Page');
        return Container(
          key: const ValueKey('profile'),
          child: BusinessProfilePage(businessId: widget.businessId),
        );
      default:
        print('🏠 Loading Default Overview Page');
        return Container(
          key: const ValueKey('overview'),
          child: _buildOverviewPage(),
        );
    }
  }

  Widget _buildOverviewPage() {
    return RefreshIndicator(
      onRefresh: _loadBusinessData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildWaiterCallsSection(),
            const SizedBox(height: 24),
            _buildQuickActionsSection(),
            const SizedBox(height: 24),
            _buildRecentOrdersSection(),
            const SizedBox(height: 24),
            _buildPopularProductsSection(),
            const SizedBox(height: 80), // Bottom padding for floating nav
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    Color greetingColor;

    if (hour < 12) {
      greeting = 'Günaydın';
      greetingIcon = Icons.wb_sunny_rounded;
      greetingColor = const Color(0xFFFFA502);
    } else if (hour < 18) {
      greeting = 'İyi günler';
      greetingIcon = Icons.wb_sunny_rounded;
      greetingColor = const Color(0xFF4E9FF7);
    } else {
      greeting = 'İyi akşamlar';
      greetingIcon = Icons.nights_stay_rounded;
      greetingColor = const Color(0xFF6C63FF);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [greetingColor, greetingColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: greetingColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(greetingIcon, color: AppColors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTypography.h5.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'İşletmeniz bugün $_todayOrders sipariş aldı',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Özet İstatistikler',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Bugün',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                title: 'Bugünkü',
                value: _todayOrders.toString(),
                subtitle: 'Sipariş',
                icon: Icons.today_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileStatCard(
                title: 'Bekleyen',
                value: _pendingOrders.toString(),
                subtitle: 'Sipariş',
                icon: Icons.pending_actions_rounded,
                gradient: LinearGradient(
                  colors: _pendingOrders > 0
                      ? [const Color(0xFFFF6B6B), const Color(0xFFFF8787)]
                      : [const Color(0xFF4ECDC4), const Color(0xFF6FE6DD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                icon: Icons.restaurant_menu_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4E9FF7), Color(0xFF6DB3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileStatCard(
                title: 'Gelir',
                value: _totalRevenue > 1000
                    ? '₺${(_totalRevenue / 1000).toStringAsFixed(1)}K'
                    : '₺${_totalRevenue.toStringAsFixed(0)}',
                subtitle: 'Toplam',
                icon: Icons.payments_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1DD1A1), Color(0xFF3DDBB7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: AppColors.white, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
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
            fontWeight: FontWeight.w700,
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
          childAspectRatio: 3.2,
          children: [
            _buildQuickActionCard(
              title: 'Ürün Ekle',
              icon: Icons.add_circle_rounded,
              color: const Color(0xFF1DD1A1),
              onTap: () => _navigateToTab(2), // Menu Management
            ),
            _buildQuickActionCard(
              title: 'Masa Yönetimi',
              icon: Icons.table_restaurant_rounded,
              color: const Color(0xFF6C63FF),
              onTap: () => _navigateToTab(5), // Table Management
            ),
            _buildQuickActionCard(
              title: 'İndirim',
              icon: Icons.local_offer_rounded,
              color: const Color(0xFFFFA502),
              onTap: () => _navigateToTab(3),
            ),
            _buildQuickActionCard(
              title: 'QR Kod',
              icon: Icons.qr_code_rounded,
              color: const Color(0xFF4E9FF7),
              onTap: () => _navigateToTab(4),
            ),
            _buildQuickActionCard(
              title: 'Personel',
              icon: Icons.group_rounded,
              color: const Color(0xFF607D8B),
              onTap: () => _navigateToTab(6),
            ),
            _buildQuickActionCard(
              title: 'Ayarlar',
              icon: Icons.settings_rounded,
              color: const Color(0xFF795548),
              onTap: () => _navigateToTab(8),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: color.withOpacity(0.5), size: 14),
              ],
            ),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Son Siparişler',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _navigateToTab(1),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Row(
                children: const [
                  Text('Tümü', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
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
          ...List.generate(
            _recentOrders.take(3).length,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index < 2 ? 12.0 : 0),
              child: _buildMobileOrderCard(_recentOrders[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileOrderCard(app_order.Order order) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToTab(1),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(order.status).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getStatusText(order.status),
                              style: TextStyle(
                                color: _getStatusColor(order.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${order.items.length} ürün',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
              ],
            ),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.star_rounded,
                      color: AppColors.success, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Popüler Ürünler',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _navigateToTab(2), // Menu Management
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Row(
                children: const [
                  Text('Tümü', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_popularProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
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
          ...List.generate(
            _popularProducts.take(4).length,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index < 3 ? 12.0 : 0),
              child: _buildMobileProductCard(_popularProducts[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToTab(2), // Menu Management
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: WebSafeImage(
                            imageUrl: product.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorWidget: (context, error, stackTrace) => Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.textSecondary,
                              size: 28,
                            ),
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
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
                      Row(
                        children: [
                          Text(
                            '₺${product.price.toStringAsFixed(2)}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (product.hasDiscount)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-%${product.discountPercentage.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      color: product.isAvailable
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _activeWaiterCalls.isNotEmpty
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.room_service_rounded,
                    color: _activeWaiterCalls.isNotEmpty
                        ? AppColors.error
                        : AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                            ? '${_activeWaiterCalls.length} aktif çağrı'
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
                  iconSize: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // Content
          if (_activeWaiterCalls.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bekleyen Çağrılar',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._activeWaiterCalls
                      .take(2)
                      .map((call) => _buildMobileWaiterCallCard(call)),
                  if (_activeWaiterCalls.length > 2)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.greyLighter,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '+${_activeWaiterCalls.length - 2} çağrı daha',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 40,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Harika! Tüm çağrılar halledildi',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Şu anda bekleyen garson çağrısı yok.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          // Statistics
          if (_recentWaiterCalls.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMobileCallStat(
                      'Bugün',
                      '${_recentWaiterCalls.where((c) => _isToday(c.createdAt)).length}',
                      Icons.today_rounded,
                      AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildMobileCallStat(
                      'Ort. Yanıt',
                      '${_calculateAverageResponseTime()} dk',
                      Icons.access_time_rounded,
                      AppColors.info,
                    ),
                  ),
                  Expanded(
                    child: _buildMobileCallStat(
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

  Widget _buildMobileCallStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyLarge.copyWith(
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

  Widget _buildMobileWaiterCallCard(WaiterCall call) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greyLighter,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: call.isOverdue ? AppColors.error : AppColors.greyLight,
          width: call.isOverdue ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _handleMobileWaiterCall(call),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(
                        int.parse('0xFF${call.priorityColorCode.substring(1)}'))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getCallTypeIcon(call.requestType),
                color: Color(
                    int.parse('0xFF${call.priorityColorCode.substring(1)}')),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Masa ${call.tableNumber}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(int.parse(
                                  '0xFF${call.statusColorCode.substring(1)}'))
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          call.status.displayName,
                          style: AppTypography.caption.copyWith(
                            color: Color(int.parse(
                                '0xFF${call.statusColorCode.substring(1)}')),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        call.requestType.displayName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${call.waitingTimeMinutes} dk',
                        style: AppTypography.caption.copyWith(
                          color: call.isOverdue
                              ? AppColors.error
                              : AppColors.textSecondary,
                          fontWeight: call.isOverdue
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (call.isOverdue) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.warning_rounded,
                          size: 12,
                          color: AppColors.error,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.textSecondary,
            ),
          ],
        ),
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
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  int _calculateAverageResponseTime() {
    final completedCalls = _recentWaiterCalls
        .where((c) =>
            c.status == WaiterCallStatus.completed &&
            c.responseTimeMinutes != null)
        .toList();

    if (completedCalls.isEmpty) return 0;

    final totalTime = completedCalls
        .map((c) => c.responseTimeMinutes!)
        .reduce((a, b) => a + b);

    return (totalTime / completedCalls.length).round();
  }

  void _handleMobileWaiterCall(WaiterCall call) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                            '0xFF${call.priorityColorCode.substring(1)}'))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCallTypeIcon(call.requestType),
                    color: Color(int.parse(
                        '0xFF${call.priorityColorCode.substring(1)}')),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Masa ${call.tableNumber}',
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        call.requestType.displayName,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                            '0xFF${call.statusColorCode.substring(1)}'))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    call.status.displayName,
                    style: AppTypography.caption.copyWith(
                      color: Color(int.parse(
                          '0xFF${call.statusColorCode.substring(1)}')),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Details
            _buildMobileInfoRow('Öncelik', call.priority.displayName),
            if (call.message != null && call.message!.isNotEmpty)
              _buildMobileInfoRow('Mesaj', call.message!),
            _buildMobileInfoRow(
                'Çağrı Zamanı', _formatDateTime(call.createdAt)),
            _buildMobileInfoRow(
                'Bekleme Süresi', '${call.waitingTimeMinutes} dakika'),
            if (call.waiterName != null)
              _buildMobileInfoRow('Atanan Garson', call.waiterName!),

            if (call.isOverdue) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Bu çağrı gecikmiş!',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.greyLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Kapat'),
                  ),
                ),
                const SizedBox(width: 12),
                if (call.status == WaiterCallStatus.pending)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _acknowledgeCall(call);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Onayla'),
                    ),
                  ),
                if (call.status == WaiterCallStatus.acknowledged ||
                    call.status == WaiterCallStatus.inProgress)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _completeCall(call);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Tamamla'),
                    ),
                  ),
              ],
            ),

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileInfoRow(String label, String value) {
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
            content: const Text('Çağrı onaylandı'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çağrı onaylanırken hata: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
            content: const Text('Çağrı tamamlandı'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çağrı tamamlanırken hata: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
