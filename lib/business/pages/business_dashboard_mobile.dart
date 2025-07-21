import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
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
import 'dart:ui';

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

class _BusinessDashboardMobileState extends State<BusinessDashboardMobile>
    with TickerProviderStateMixin {
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
  double _todayRevenue = 0.0;
  int _pendingOrders = 0;

  // Notifications
  List<NotificationModel> _notifications = [];
  int _unreadNotificationCount = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    Icons.dashboard_rounded,
    Icons.receipt_long_rounded,
    Icons.category_rounded,
    Icons.restaurant_menu_rounded,
    Icons.local_offer_rounded,
    Icons.qr_code_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

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

      if (notifications.isNotEmpty) {
        final latestNotification = notifications.first;
        if (latestNotification.type == NotificationType.newOrder) {
          _notificationService.showInAppNotification(
            context,
            latestNotification,
            onTap: () {
              _navigateToTab(1);
              _notificationService.markAsRead(latestNotification.id);
            },
          );
        }
      }
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
        _todayRevenue = stats['todayRevenue'] ?? 0.0;
        _pendingOrders = stats['pendingOrders'] ?? 0;
      });

      _updateUrl();

      _fadeController.forward();
      _slideController.forward();
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
        'todayRevenue': 0.0,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
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
            SnackBar(
              content: const Text('Çıkış yapıldı'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _updateUrl();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    _notificationService.removeNotificationListener(
        widget.businessId, _onNotificationsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: _buildBackgroundDecoration(),
          child: const Center(child: LoadingIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Container(
          decoration: _buildBackgroundDecoration(),
          child: Center(child: ErrorMessage(message: _errorMessage!)),
        ),
      );
    }

    if (_business == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Container(
          decoration: _buildBackgroundDecoration(),
          child: const Center(
            child: EmptyState(
              icon: Icons.business,
              title: 'İşletme Bulunamadı',
              message: 'İşletme bilgileri yüklenemedi',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: PageView(
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
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF667eea).withOpacity(0.05),
          const Color(0xFF764ba2).withOpacity(0.05),
          AppColors.backgroundLight,
          const Color(0xFFF093FB).withOpacity(0.02),
        ],
        stops: const [0.0, 0.3, 0.8, 1.0],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
              const Color(0xFF667eea),
            ],
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      foregroundColor: AppColors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _business?.businessName ?? 'İşletme',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _tabTitles[_currentIndex],
            style: AppTypography.caption.copyWith(
              color: AppColors.white.withOpacity(0.9),
              fontSize: 11,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 1,
                  offset: const Offset(0, 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _buildGlassButton(
          icon: Icons.notifications_rounded,
          onPressed: _showNotificationsDialog,
          badge: _unreadNotificationCount > 0 ? _unreadNotificationCount : null,
        ),
        const SizedBox(width: 8),
        _buildGlassButton(
          icon: Icons.refresh_rounded,
          onPressed: _loadBusinessData,
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.white,
              size: 18,
            ),
          ),
          onSelected: (value) {
            switch (value) {
              case 'logout':
                _handleLogout();
                break;
            }
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 20,
          color: Colors.white,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: AppColors.error),
                title: Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    int? badge,
  }) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: AppColors.white, size: 18),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badge.toString(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.8),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _navigateToTab,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary.withOpacity(0.6),
              selectedLabelStyle: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
              unselectedLabelStyle: AppTypography.caption.copyWith(fontSize: 9),
              elevation: 0,
              items: List.generate(
                _tabTitles.length,
                (index) => BottomNavigationBarItem(
                  icon: _buildNavIcon(_tabIcons[index], index),
                  label: _getShortLabel(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    final badge = index == 1 ? _pendingOrders : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Icon(
            icon,
            size: isSelected ? 24 : 20,
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.6),
          ),
          if (badge != null && badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.white, width: 1),
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text(
                  badge.toString(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
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
                subtitle: '${_todayRevenue.toStringAsFixed(0)} TL',
                icon: Icons.today_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileStatCard(
                title: 'Bekleyen',
                value: _pendingOrders.toString(),
                subtitle: 'Sipariş',
                icon: Icons.pending_rounded,
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
                icon: Icons.restaurant_menu_rounded,
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
                icon: Icons.attach_money_rounded,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
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
              icon: Icons.add_business_rounded,
              color: AppColors.success,
              onTap: () => _navigateToTab(3),
            ),
            _buildQuickActionCard(
              title: 'Kategori',
              icon: Icons.category_rounded,
              color: AppColors.primary,
              onTap: () => _navigateToTab(2),
            ),
            _buildQuickActionCard(
              title: 'İndirim',
              icon: Icons.local_offer_rounded,
              color: AppColors.warning,
              onTap: () => _navigateToTab(4),
            ),
            _buildQuickActionCard(
              title: 'QR Kod',
              icon: Icons.qr_code_rounded,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
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
              child: Text(
                'Tümü',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.greyLight),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(order.status).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(order.status).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              color: _getStatusColor(order.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masa ${order.tableNumber}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.customerName,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${order.totalAmount.toStringAsFixed(2)} TL',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(order.status),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
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
              child: Text(
                'Tümü',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_popularProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.greyLight),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.restaurant_rounded, color: AppColors.textSecondary),
                    ),
                  )
                : Icon(Icons.restaurant_rounded, color: AppColors.textSecondary),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.price.toStringAsFixed(2)} TL',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: product.isAvailable ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              product.isAvailable ? 'Mevcut' : 'Tükendi',
              style: AppTypography.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 10,
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