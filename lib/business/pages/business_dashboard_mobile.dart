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
              child: Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.w700)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          _urlService.updateUrl('/', customTitle: 'MasaMenu - Dijital Menü Çözümü');
          Navigator.pushReplacementNamed(context, '/');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Çıkış yapıldı'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
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
          ],
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
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
                child: Image.network(
                  _business!.logoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.primary.withOpacity(0.1),
                    child: Icon(Icons.business_rounded, color: AppColors.primary, size: 24),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            offset: const Offset(0, 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 24),
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
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
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

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _tabTitles.length,
                  (index) => _buildNavItem(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentIndex == index;
    final badge = index == 1 ? _pendingOrders : null;

    return Expanded(
      child: InkWell(
        onTap: () => _navigateToTab(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _tabIcons[index],
                      size: isSelected ? 26 : 22,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  if (badge != null && badge > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
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
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          badge.toString(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  _getShortLabel(index),
                  style: TextStyle(
                    fontSize: isSelected ? 10 : 9,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
                      color: AppColors.primary,
                      size: 14
                  ),
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
              onTap: () => _navigateToTab(3),
            ),
            _buildQuickActionCard(
              title: 'Kategori',
              icon: Icons.category_rounded,
              color: const Color(0xFF6C63FF),
              onTap: () => _navigateToTab(2),
            ),
            _buildQuickActionCard(
              title: 'İndirim',
              icon: Icons.local_offer_rounded,
              color: const Color(0xFFFFA502),
              onTap: () => _navigateToTab(4),
            ),
            _buildQuickActionCard(
              title: 'QR Kod',
              icon: Icons.qr_code_rounded,
              color: const Color(0xFF4E9FF7),
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
                Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color.withOpacity(0.5),
                    size: 14
                ),
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
                  child: Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 18
                  ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                horizontal: 8,
                                vertical: 3
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withOpacity(0.1),
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
                  child: Icon(
                      Icons.star_rounded,
                      color: AppColors.success,
                      size: 18
                  ),
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
              onPressed: () => _navigateToTab(3),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          onTap: () => _navigateToTab(3),
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
                          child: Image.network(
                            product.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.textSecondary,
                              size: 28,
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
                                  horizontal: 6,
                                  vertical: 2
                              ),
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
}