import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../business/models/business.dart';
import '../../data/models/order.dart' as app_order;
import '../../data/models/user.dart' as app_user;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/auth_service.dart';
import '../services/customer_firestore_service.dart';
import '../../core/services/url_service.dart';
import '../../core/mixins/url_mixin.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../widgets/business_header.dart';
import 'menu_page.dart';
import 'cart_page.dart';
import 'customer_orders_page.dart';
import 'business_detail_page.dart'; // Added import for BusinessDetailPage

class CustomerDashboardPage extends StatefulWidget {
  final String userId;

  const CustomerDashboardPage({super.key, required this.userId});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage>
    with TickerProviderStateMixin, UrlMixin {
  final AuthService _authService = AuthService();
  final CustomerFirestoreService _customerFirestoreService = CustomerFirestoreService();
  final UrlService _urlService = UrlService();

  app_user.User? _user;
  app_user.CustomerData? _customerData;
  List<app_order.Order> _orders = [];
  List<Business> _nearbyBusinesses = [];
  List<Business> _favoriteBusinesses = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTabIndex = 0;

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Tab route mappings
  final List<String> _tabRoutes = ['dashboard', 'orders', 'favorites', 'profile'];
  final List<String> _tabTitles = ['Ana Sayfa', 'Siparişlerim', 'Favorilerim', 'Profil'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadUserData();
    
    // Update URL on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCustomerUrl();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      _updateCustomerUrl();
    }
  }

  void _updateCustomerUrl() {
    final route = _tabRoutes[_selectedTabIndex];
    final title = '${_tabTitles[_selectedTabIndex]} | MasaMenu';
    _urlService.updateCustomerUrl(widget.userId, route, customTitle: title);
  }

  @override
  void onUrlChanged(String newPath) {
    // Handle browser back/forward buttons
    final segments = newPath.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[0] == 'customer') {
      final page = segments[1];
      final tabIndex = _tabRoutes.indexOf(page);
      if (tabIndex != -1 && tabIndex != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = tabIndex;
          _tabController.index = tabIndex;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Kullanıcı bilgilerini yükle
      final user = await _authService.getCurrentUserData();
      if (user != null) {
        setState(() {
          _user = user;
        });
      }

      // Müşteri verilerini yükle
      final customerData = await _customerFirestoreService.getCustomerData(widget.userId);

      // Kullanıcının siparişlerini yükle
      final orders = await _customerFirestoreService.getOrdersByCustomer(widget.userId);
      
      // Yakındaki işletmeleri yükle
      final businesses = await _customerFirestoreService.getBusinesses();
      
      // Favori işletmeleri yükle
      final favoriteIds = customerData?.favorites.map((f) => f.businessId).toList() ?? [];
      final favorites = businesses.where((b) => favoriteIds.contains(b.id)).toList();

      setState(() {
        _customerData = customerData;
        _orders = orders;
        _nearbyBusinesses = businesses.where((b) => b.isActive).take(6).toList();
        _favoriteBusinesses = favorites;
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

  Future<void> _handleLogout() async {
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
            content: Text('Çıkış yapılırken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Navigation methods with dynamic URL updates
  void _navigateToSearch() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/customer/${widget.userId}/search?t=$timestamp';
    _urlService.updateUrl(dynamicRoute, customTitle: 'İşletme Ara | MasaMenu');
    
    Navigator.pushNamed(
      context, 
      '/search',
      arguments: {
        'userId': widget.userId,
        'timestamp': timestamp,
        'businesses': _nearbyBusinesses,
        'categories': [], // Will be loaded in search page
      },
    );
  }

  void _navigateToBusinessDetail(Business business) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/customer/${widget.userId}/business/${business.id}?t=$timestamp';
    _urlService.updateUrl(dynamicRoute, customTitle: '${business.businessName} | MasaMenu');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessDetailPage(
          business: business,
          customerData: _customerData,
        ),
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'business': business,
            'customerData': _customerData,
            'userId': widget.userId,
            'timestamp': timestamp,
          },
        ),
      ),
    );
  }

  void _navigateToMenu(Business business) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/customer/${widget.userId}/menu/${business.id}?t=$timestamp';
    _urlService.updateMenuUrl(business.id, businessName: business.businessName);
    

    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuPage(businessId: business.id),
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'businessId': business.id,
            'business': business,
            'userId': widget.userId,
            'timestamp': timestamp,
          },
        ),
      ),
    );
  }

  void _navigateToCart(String businessId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/customer/${widget.userId}/cart/$businessId?t=$timestamp';
    _urlService.updateUrl(dynamicRoute, customTitle: 'Sepetim | MasaMenu');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(businessId: businessId),
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'businessId': businessId,
            'userId': widget.userId,
            'timestamp': timestamp,
          },
        ),
      ),
    );
  }

  void _navigateToOrders({String? businessId}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = businessId != null 
        ? '/customer/${widget.userId}/orders/$businessId?t=$timestamp'
        : '/customer/${widget.userId}/orders?t=$timestamp';
    _urlService.updateCustomerUrl(widget.userId, 'orders', customTitle: 'Siparişlerim | MasaMenu');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerOrdersPage(
          businessId: businessId,
          customerId: widget.userId,
        ),
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'businessId': businessId,
            'customerId': widget.userId,
            'userId': widget.userId,
            'timestamp': timestamp,
          },
        ),
      ),
    );
  }

  void _navigateToProfile() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/customer/${widget.userId}/profile?t=$timestamp';
    _urlService.updateCustomerUrl(widget.userId, 'profile', customTitle: 'Profilim | MasaMenu');
    
    Navigator.pushNamed(
      context,
      '/customer/profile',
      arguments: {
        'customerData': _customerData,
        'userId': widget.userId,
        'timestamp': timestamp,
      },
    );
  }

  // Update existing navigation calls to use new methods
  void _updateNavigationCalls() {
    // This method contains all the existing navigation updates
    // Replace all direct Navigator.pushNamed calls with our dynamic methods
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Müşteri Paneli'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: Center(child: ErrorMessage(message: _errorMessage!)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(),
          ],
      body: Column(
        children: [
              _buildModernTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildOrdersTab(),
                _buildFavoritesTab(),
                _buildProfileTab(),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.primaryGradient,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
        children: [
                  Hero(
                    tag: 'customer_avatar',
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                        gradient: LinearGradient(
                          colors: [AppColors.secondary, AppColors.secondaryLight],
                        ),
                      ),
            child: Icon(
              Icons.person,
              color: AppColors.white,
                        size: 30,
            ),
          ),
                  ),
                  const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                          'Merhaba, ${_user?.name ?? 'Müşteri'}! 👋',
                          style: AppTypography.h5.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                        const SizedBox(height: 4),
                Text(
                          'Bugün hangi lezzeti keşfetmek istiyorsun?',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search_rounded, size: 28),
          onPressed: () {
            _navigateToSearch();
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, size: 28),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            switch (value) {
              case 'logout':
                _handleLogout();
                break;
              case 'settings':
                // Navigate to settings
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings_rounded, color: AppColors.primary),
                title: Text('Ayarlar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
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
      ],
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
      color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.bodyMedium,
        tabs: [
          Tab(
            icon: Icon(Icons.dashboard_rounded, size: 20),
            text: 'Ana Sayfa',
            height: 60,
          ),
          Tab(
            icon: Icon(Icons.receipt_long_rounded, size: 20),
            text: 'Siparişler',
            height: 60,
          ),
          Tab(
            icon: Icon(Icons.favorite_rounded, size: 20),
            text: 'Favoriler',
            height: 60,
          ),
          Tab(
            icon: Icon(Icons.person_rounded, size: 20),
            text: 'Profil',
            height: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_selectedTabIndex != 0) return SizedBox.shrink();
    
    return FloatingActionButton.extended(
      onPressed: () {
        _navigateToSearch();
      },
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.white,
      icon: Icon(Icons.qr_code_scanner_rounded),
      label: Text('QR Tara'),
      elevation: 8,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hızlı İstatistikler
            _buildQuickStatsCards(),
            
            const SizedBox(height: 24),
            
            // Hızlı Eylemler
            _buildQuickActions(),
            
            const SizedBox(height: 24),
            
            // Yakındaki İşletmeler
            _buildNearbyBusinesses(),
            
            const SizedBox(height: 24),
            
            // Son Siparişler
            _buildRecentOrders(),
            
            const SizedBox(height: 100), // FAB için boşluk
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCards() {
    final stats = _customerData?.stats ?? app_user.CustomerStats(
      totalOrders: 0,
      totalSpent: 0.0,
      favoriteBusinessCount: 0,
      totalVisits: 0,
      categoryPreferences: {},
      businessSpending: {},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Özet Bilgiler',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Toplam Sipariş',
                value: '${_orders.length}',
                icon: Icons.shopping_bag_rounded,
                color: AppColors.primary,
                gradient: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Harcama',
                value: '${stats.totalSpent.toStringAsFixed(0)}₺',
                icon: Icons.payments_rounded,
                color: AppColors.success,
                gradient: [AppColors.success, Color(0xFF2ECC71)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Favoriler',
                value: '${_favoriteBusinesses.length}',
                icon: Icons.favorite_rounded,
                color: AppColors.accent,
                gradient: [AppColors.accent, AppColors.accentLight],
              ),
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
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(
          'Hızlı Erişim',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
            Row(
              children: [
            Expanded(
              child: _buildActionCard(
                title: 'QR Tara',
                subtitle: 'Menüye hızlı erişim',
                icon: Icons.qr_code_scanner_rounded,
                color: AppColors.primary,
                onTap: () {
                  // QR tarama sayfası
                },
              ),
            ),
            const SizedBox(width: 12),
                Expanded(
              child: _buildActionCard(
                title: 'İşletme Ara',
                subtitle: 'Yakınında keşfet',
                icon: Icons.search_rounded,
                color: AppColors.info,
                onTap: () {
                  _navigateToSearch();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Siparişlerim',
                subtitle: 'Geçmiş siparişler',
                icon: Icons.history_rounded,
                color: AppColors.warning,
                onTap: () {
                  _navigateToOrders();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Favorilerim',
                subtitle: 'Beğendiğin yerler',
                icon: Icons.favorite_rounded,
                color: AppColors.accent,
                onTap: () {
                  _tabController.animateTo(2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
                  child: Column(
                    children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
                      Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildNearbyBusinesses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Yakındaki İşletmeler',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _navigateToSearch();
              },
              icon: Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text('Tümünü Gör'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_nearbyBusinesses.isEmpty)
          _buildEmptyStateCard(
            icon: Icons.business_rounded,
            title: 'Yakında işletme bulunamadı',
            subtitle: 'Daha sonra tekrar kontrol edin',
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyBusinesses.length,
              itemBuilder: (context, index) {
                final business = _nearbyBusinesses[index];
                return _buildBusinessCard(business, index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBusinessCard(Business business, int index) {
    return Container(
      width: 180,
      margin: EdgeInsets.only(
        right: 16,
        left: index == 0 ? 0 : 0,
      ),
      child: Material(
        color: Colors.transparent,
      child: InkWell(
        onTap: () {
            _navigateToMenu(business);
          },
          borderRadius: BorderRadius.circular(16),
        child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // İşletme resmi
              Container(
                  height: 100,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primaryLight.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (business.logoUrl != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            business.logoUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildBusinessIcon(),
                          ),
                        )
                      else
                        _buildBusinessIcon(),
                      
                      // Durum göstergesi
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: business.isOpen ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                          child: Text(
                            business.isOpen ? 'Açık' : 'Kapalı',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                  ),
                ),
              ),
                      ),
                    ],
                  ),
                ),
                
                // İşletme bilgileri
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              Text(
                business.businessName,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                ),
                          maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                business.businessType,
                style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                  color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                business.businessAddress,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
                        ),
                      ],
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

  Widget _buildBusinessIcon() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primaryLight.withOpacity(0.6),
          ],
        ),
      ),
      child: Icon(
        Icons.business_rounded,
        size: 40,
        color: AppColors.white.withOpacity(0.8),
      ),
    );
  }

  Widget _buildRecentOrders() {
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
            if (_orders.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  _navigateToOrders();
                },
                icon: Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('Tümünü Gör'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_orders.isEmpty)
          _buildEmptyStateCard(
            icon: Icons.receipt_long_rounded,
            title: 'Henüz siparişiniz yok',
            subtitle: 'İlk siparişinizi vermek için bir işletme seçin',
          )
        else
          Column(
            children: _orders
                .take(3)
                .map((order) => _buildModernOrderCard(order))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildModernOrderCard(app_order.Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Sipariş ikonu
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getOrderStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getOrderStatusIcon(order.status),
                color: _getOrderStatusColor(order.status),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Sipariş bilgileri
            Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sipariş #${order.orderId.substring(0, 8)}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(order.status),
                          borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getOrderStatusText(order.status),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
            Text(
                        _formatOrderDate(order.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${order.totalAmount.toStringAsFixed(2)} ₺',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.greyLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
            Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            textAlign: TextAlign.center,
            ),
          ],
        ),
    );
  }

  Widget _buildOrdersTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: AppColors.primary,
      child: _orders.isEmpty
          ? Center(
              child: _buildEmptyStateCard(
                icon: Icons.receipt_long_rounded,
                title: 'Henüz siparişiniz yok',
                subtitle: 'İlk siparişinizi vermek için bir işletme seçin',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return _buildModernOrderCard(order);
              },
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: AppColors.primary,
      child: _favoriteBusinesses.isEmpty
          ? Center(
              child: _buildEmptyStateCard(
                icon: Icons.favorite_rounded,
                title: 'Henüz favori işletmeniz yok',
                subtitle: 'Beğendiğiniz işletmeleri favorilerinize ekleyin',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favoriteBusinesses.length,
              itemBuilder: (context, index) {
                final business = _favoriteBusinesses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildFavoriteBusinessCard(business),
                );
              },
            ),
    );
  }

  Widget _buildFavoriteBusinessCard(Business business) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _navigateToMenu(business);
          },
          borderRadius: BorderRadius.circular(16),
      child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // İşletme resmi
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                  ),
                  child: business.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            business.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.business_rounded,
                              color: AppColors.white,
                              size: 32,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.business_rounded,
                          color: AppColors.white,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                // İşletme bilgileri
                Expanded(
        child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      Text(
                        business.businessName,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          business.businessType,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              business.businessAddress,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            business.isOpen ? 'Açık' : 'Kapalı',
                            style: AppTypography.caption.copyWith(
                              color: business.isOpen ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Favori butonu
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profil kartı
            _buildModernProfileCard(),
            
            const SizedBox(height: 24),
            
            // İstatistikler
            _buildDetailedStats(),
            
            const SizedBox(height: 24),
            
            // Menü seçenekleri
            _buildProfileMenuOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Hero(
              tag: 'customer_avatar_large',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 4),
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.secondaryLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              child: Icon(
                Icons.person,
                color: AppColors.white,
                  size: 50,
              ),
            ),
            ),
            const SizedBox(height: 20),
            Text(
              _user?.name ?? 'Müşteri',
              style: AppTypography.h4.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _user?.email ?? '',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
              onPressed: () {
                  _navigateToProfile();
              },
                icon: Icon(Icons.edit_rounded),
                label: Text('Profili Düzenle'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats() {
    final stats = _customerData?.stats ?? app_user.CustomerStats(
      totalOrders: 0,
      totalSpent: 0.0,
      favoriteBusinessCount: 0,
      totalVisits: 0,
      categoryPreferences: {},
      businessSpending: {},
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              'İstatistiklerim',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSimpleStatCard(
                    title: 'Toplam Sipariş',
                    value: '${_orders.length}',
                    icon: Icons.shopping_bag_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSimpleStatCard(
                    title: 'Toplam Harcama',
                    value: '${stats.totalSpent.toStringAsFixed(0)}₺',
                    icon: Icons.payments_rounded,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSimpleStatCard(
                    title: 'Favori İşletme',
                    value: '${_favoriteBusinesses.length}',
                    icon: Icons.favorite_rounded,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSimpleStatCard(
                    title: 'Ziyaret Sayısı',
                    value: '${stats.totalVisits}',
                    icon: Icons.visibility_rounded,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildProfileMenuOptions() {
    final menuItems = [
      {
        'icon': Icons.dashboard_rounded,
        'title': 'Detaylı Dashboard',
        'subtitle': 'Tüm aktivitelerinizi görüntüleyin',
        'color': AppColors.primary,
        'action': () {
          _tabController.animateTo(0);
        },
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Sipariş Geçmişi',
        'subtitle': 'Geçmiş siparişlerinizi inceleyin',
        'color': AppColors.info,
        'action': () {
          _navigateToOrders();
        },
      },
      {
        'icon': Icons.notifications_rounded,
        'title': 'Bildirimler',
        'subtitle': 'Bildirim ayarlarını düzenleyin',
        'color': AppColors.warning,
        'action': () {
          // Bildirim ayarları
        },
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Güvenlik',
        'subtitle': 'Hesap güvenliği ayarları',
        'color': AppColors.success,
        'action': () {
          // Güvenlik ayarları
        },
      },
      {
        'icon': Icons.help_rounded,
        'title': 'Yardım & Destek',
        'subtitle': 'Sık sorulan sorular ve destek',
        'color': AppColors.accent,
        'action': () {
          // Yardım sayfası
        },
      },
      {
        'icon': Icons.logout_rounded,
        'title': 'Çıkış Yap',
        'subtitle': 'Hesabınızdan güvenli çıkış yapın',
        'color': AppColors.error,
        'action': _handleLogout,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item['action'] as VoidCallback,
                  borderRadius: BorderRadius.circular(index == 0 ? 16 : 0),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['subtitle'] as String,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (index < menuItems.length - 1)
                Divider(
                  height: 1,
                  indent: 80,
                  color: AppColors.greyLight,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getOrderStatusColor(app_order.OrderStatus status) {
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

  IconData _getOrderStatusIcon(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return Icons.schedule_rounded;
      case app_order.OrderStatus.confirmed:
        return Icons.check_rounded;
      case app_order.OrderStatus.preparing:
        return Icons.restaurant_rounded;
      case app_order.OrderStatus.ready:
        return Icons.done_all_rounded;
      case app_order.OrderStatus.delivered:
        return Icons.delivery_dining_rounded;
      case app_order.OrderStatus.inProgress:
        return Icons.restaurant_rounded;
      case app_order.OrderStatus.completed:
        return Icons.check_circle_rounded;
      case app_order.OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String _getOrderStatusText(app_order.OrderStatus status) {
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

  String _formatOrderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Bugün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 