import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/url_service.dart';
import '../../core/mixins/url_mixin.dart';
import '../../data/models/user.dart' as app_user;
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../services/customer_firestore_service.dart';

// Tab sayfaları
import 'tabs/customer_home_tab.dart';
import 'tabs/customer_orders_tab.dart';
import 'tabs/customer_favorites_tab.dart';
import 'tabs/customer_profile_tab.dart';

/// Müşteri ana dashboard sayfası - tab navigation
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
    // Handle browser back/forward buttons and direct URL access
    final segments = newPath.split('/').where((s) => s.isNotEmpty).toList();
    
    if (segments.length >= 2 && segments[0] == 'customer') {
      final userId = segments[1];
      
      // Verify user ID matches
      if (userId != widget.userId) return;
      
      // Check for tab route
      if (segments.length >= 3) {
        final page = segments[2];
        final tabIndex = _tabRoutes.indexOf(page);
        
        if (tabIndex != -1 && tabIndex != _selectedTabIndex) {
          setState(() {
            _selectedTabIndex = tabIndex;
            _tabController.index = tabIndex;
          });
          
          // Update title based on route
          final title = '${_tabTitles[tabIndex]} | MasaMenu';
          // Don't call updateCustomerUrl here to avoid infinite loop
        }
      } else {
        // Default to dashboard if no specific tab
        if (_selectedTabIndex != 0) {
          setState(() {
            _selectedTabIndex = 0;
            _tabController.index = 0;
          });
        }
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

      setState(() {
        _customerData = customerData;
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
      },
    );
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
                    CustomerHomeTab(
                      userId: widget.userId,
                      user: _user,
                      customerData: _customerData,
                      onRefresh: _loadUserData,
                    ),
                    CustomerOrdersTab(
                      userId: widget.userId,
                      customerData: _customerData,
                      onRefresh: _loadUserData,
                    ),
                    CustomerFavoritesTab(
                      userId: widget.userId,
                      customerData: _customerData,
                      onRefresh: _loadUserData,
                    ),
                    CustomerProfileTab(
                      userId: widget.userId,
                      user: _user,
                      customerData: _customerData,
                      onRefresh: _loadUserData,
                      onLogout: _handleLogout,
                    ),
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
} 