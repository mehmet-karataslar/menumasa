import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/url_service.dart';
import '../../core/services/cart_service.dart';
import '../../core/mixins/url_mixin.dart';
import '../../data/models/user.dart' as app_user;
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../services/customer_firestore_service.dart';
import 'dart:convert'; // Added import for jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // Added import for SharedPreferences

// Tab sayfaları
import 'tabs/customer_home_tab.dart';
import 'tabs/customer_orders_tab.dart';
import 'tabs/customer_favorites_tab.dart';
import 'tabs/customer_profile_tab.dart';
import 'cart_page.dart'; // Added import for CartPage
import 'multi_business_cart_page.dart'; // Added import for MultiBusinessCartPage

/// Müşteri ana dashboard sayfası - modern tab navigation
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
  final CartService _cartService = CartService();

  app_user.User? _user;
  app_user.CustomerData? _customerData;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTabIndex = 0;
  int _cartItemCount = 0;
  bool _hasNewOrders = false;

  // Tab management
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fabScaleAnimation;

  // Tab route mappings
  final List<String> _tabRoutes = ['dashboard', 'orders', 'favorites', 'profile'];
  final List<String> _tabTitles = ['Ana Sayfa', 'Siparişlerim', 'Favorilerim', 'Profil'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initCartTracking();
    _initAnimations();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCustomerUrl();
      _animationController.forward();
    });
  }

  void _initCartTracking() async {
    await _cartService.initialize();
    // Mevcut sepet sayısını al
    _updateCartCount();
    
    // Cart değişikliklerini dinle
    _cartService.addCartListener((cart) {
      if (mounted) {
        // Cart listener'dan gelen cart tek bir business için olabilir
        // Bu yüzden tüm business'ları tekrar kontrol edelim
        _updateCartCount();
      }
    });
  }

  Future<void> _updateCartCount() async {
    try {
      // Sadece current cart'ı kontrol et (en güvenilir yöntem)
      final prefs = await SharedPreferences.getInstance();
      final currentCartJson = prefs.getString('current_cart');
      
      if (currentCartJson != null) {
        try {
          final cartData = jsonDecode(currentCartJson);
          final businessId = cartData['businessId'] as String?;
          
          if (businessId != null && businessId.isNotEmpty) {
            final cartCount = await _cartService.getCartItemCount(businessId);
            setState(() {
              _cartItemCount = cartCount;
            });
            print('📊 Cart count for $businessId: $cartCount');
          } else {
            setState(() {
              _cartItemCount = 0;
            });
          }
        } catch (e) {
          print('❌ Error parsing current cart for count: $e');
          setState(() {
            _cartItemCount = 0;
          });
        }
      } else {
        setState(() {
          _cartItemCount = 0;
        });
        print('📊 No current cart found, count = 0');
      }
    } catch (e) {
      setState(() {
        _cartItemCount = 0;
      });
      print('❌ Error updating cart count: $e');
    }
  }

  void _initAnimations() {
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    _cartService.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      _updateCustomerUrl();

      // FAB animasyonu
      if (_selectedTabIndex == 0) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    }
  }

  void _updateCustomerUrl() {
    final route = _tabRoutes[_selectedTabIndex];
    final title = '${_tabTitles[_selectedTabIndex]} | MasaMenu';
    _urlService.updateCustomerUrl(widget.userId, route, customTitle: title);
  }



  @override
  void onUrlChanged(String newPath) {
    final segments = newPath.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[0] == 'customer') {
      final userId = segments[1];
      if (userId != widget.userId) return;
      if (segments.length >= 3) {
        final page = segments[2];
        final tabIndex = _tabRoutes.indexOf(page);
        if (tabIndex != -1 && tabIndex != _selectedTabIndex) {
          setState(() {
            _selectedTabIndex = tabIndex;
            _tabController.index = tabIndex;
          });
        }
      } else {
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
      final user = await _authService.getCurrentUserData();
      if (user != null) {
        setState(() {
          _user = user;
        });
      }
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
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Başarıyla çıkış yapıldı'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: AppColors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Çıkış yapılırken hata: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _navigateToSearch() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/customer/${widget.userId}/search?t=$timestamp';
    _urlService.updateUrl(dynamicRoute, customTitle: 'Arama | MasaMenu');
    Navigator.pushNamed(
      context,
      '/search',
      arguments: {
        'userId': widget.userId,
        'timestamp': timestamp,
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Filtre Seçenekleri',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Filtre seçenekleri yakında eklenecek...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tamam'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCart() async {
    try {
      // Her zaman multi-business cart sayfasına git
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dynamicRoute = '/customer/${widget.userId}/carts?t=$timestamp';
      _urlService.updateUrl(dynamicRoute, customTitle: 'Sepetlerim | MasaMenu');
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultiBusinessCartPage(
            userId: widget.userId,
          ),
          settings: RouteSettings(name: dynamicRoute),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: AppColors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Sepet yüklenirken hata: $e')),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateToTab(int index) {
    if (_selectedTabIndex != index) {
      _tabController.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.background,
              ],
            ),
          ),
          child: const Center(child: LoadingIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.error.withOpacity(0.1),
                AppColors.background,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ErrorMessage(message: _errorMessage!),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildModernSliverAppBar(screenWidth, screenHeight),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildEnhancedTabBar(screenWidth),
                        Container(
                          height: screenHeight * 0.75,
                          child: TabBarView(
                            controller: _tabController,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              CustomerHomeTab(
                                userId: widget.userId,
                                user: _user,
                                customerData: _customerData,
                                onRefresh: _loadUserData,
                                onNavigateToTab: (int tabIndex) {
                                  setState(() {
                                    _selectedTabIndex = tabIndex;
                                  });
                                  _tabController.animateTo(tabIndex);
                                },
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
                                onNavigateToTab: (int tabIndex) {
                                  setState(() {
                                    _selectedTabIndex = tabIndex;
                                  });
                                  _tabController.animateTo(tabIndex);
                                },
                              ),
                              CustomerProfileTab(
                                userId: widget.userId,
                                user: _user,
                                customerData: _customerData,
                                onRefresh: _loadUserData,
                                onLogout: _handleLogout,
                                onNavigateToTab: (int tabIndex) {
                                  setState(() {
                                    _selectedTabIndex = tabIndex;
                                    _tabController.animateTo(tabIndex);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernSliverAppBar(double screenWidth, double screenHeight) {
    final isCompact = screenWidth < 360;
    final appBarHeight = isCompact ? 140.0 : 160.0;
    final avatarSize = isCompact ? 56.0 : 72.0;

    return SliverAppBar(
      expandedHeight: appBarHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
              AppColors.secondary.withOpacity(0.8),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: FlexibleSpaceBar(
          background: Stack(
            children: [
              // Arka plan pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: _BackgroundPatternPainter(),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          // Avatar bölümü
                          Hero(
                            tag: 'customer_avatar_${widget.userId}',
                            child: Container(
                              width: avatarSize,
                              height: avatarSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.white,
                                    AppColors.white.withOpacity(0.9),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.secondary,
                                      AppColors.secondaryLight,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: AppColors.white,
                                  size: avatarSize * 0.45,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Hoşgeldin mesajı
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hoşgeldin!👋',
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _user?.name ?? 'Değerli Müşteri',
                                  style: AppTypography.h4.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isCompact ? 20 : 24,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Bugün hangi lezzeti tercih edersin?',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.white.withOpacity(0.85),
                                    fontSize: isCompact ? 13 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
      actions: [
        // Arama butonu
        _buildAppBarActionButton(
          icon: Icons.search_rounded,
          onTap: _navigateToSearch,
        ),
        
        // Siparişlerim butonu
        _buildAppBarActionButton(
          icon: Icons.receipt_long_rounded,
          onTap: () => _navigateToTab(1),
          badge: _hasNewOrders,
        ),
        
        // Sepet butonu
        _buildAppBarActionButton(
          icon: Icons.shopping_cart_rounded,
          onTap: _navigateToCart,
          badgeCount: _cartItemCount,
        ),
        
        // Çıkış Yap butonu
        _buildAppBarActionButton(
          icon: Icons.logout_rounded,
          onTap: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildEnhancedTabBar(double screenWidth) {
    final isCompact = screenWidth < 360;
    final tabHeight = isCompact ? 45.0 : 64.0;
    final horizontalPadding = isCompact ? 12.0 : 20.0;
    final tabItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Ana Sayfa', 'activeColor': AppColors.primary},
      {'icon': Icons.receipt_long_rounded, 'label': 'Siparişler', 'activeColor': AppColors.secondary},
      {'icon': Icons.favorite_rounded, 'label': 'Favoriler', 'activeColor': AppColors.accent},
      {'icon': Icons.person_rounded, 'label': 'Profil', 'activeColor': AppColors.primaryLight},
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Row(
        children: List.generate(4, (index) {
          final item = tabItems[index];
          final isSelected = _selectedTabIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTabIndex != index) {
                  _tabController.animateTo(index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                height: tabHeight,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      item['activeColor'] as Color,
                      (item['activeColor'] as Color).withOpacity(0.8),
                    ],
                  )
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: (item['activeColor'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textSecondary,
                        size: isCompact ? 20 : 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: isCompact ? 11 : 12,
                      ),
                      child: Text(item['label'] as String),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEnhancedFloatingActionButton() {
    if (_selectedTabIndex != 0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _fabScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.white,
                  AppColors.white.withOpacity(0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Arama Butonu
                Expanded(
                  child: _buildFloatingActionButton(
                    icon: Icons.search_rounded,
                    label: 'Ara',
                    color: AppColors.primary,
                    onTap: _navigateToSearch,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Filtre Butonu
                Expanded(
                  child: _buildFloatingActionButton(
                    icon: Icons.tune_rounded,
                    label: 'Filtre',
                    color: AppColors.secondary,
                    onTap: _showFilterOptions,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Siparişler Butonu
                Expanded(
                  child: _buildFloatingActionButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'Siparişler',
                    color: AppColors.info,
                    onTap: () => _navigateToTab(1),
                    badge: _hasNewOrders ? '!' : null,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Sepet Butonu
                Expanded(
                  child: _buildFloatingActionButton(
                    icon: Icons.shopping_cart_rounded,
                    label: 'Sepet',
                    color: AppColors.accent,
                    onTap: _navigateToCart,
                    badge: _cartItemCount > 0 ? _cartItemCount.toString() : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              
              // Badge
              if (badge != null)
                Positioned(
                  top: -2,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
    int? badgeCount,
  }) {
    final showBadge = badge || (badgeCount != null && badgeCount > 0);
    final badgeText = badgeCount != null && badgeCount > 0 
        ? badgeCount.toString() 
        : '!';

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Icon(
                  icon,
                  color: AppColors.white,
                  size: 24,
                ),
                if (showBadge)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
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
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
}

// Arka plan pattern painter sınıfı
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const double spacing = 30.0;
    const double dotSize = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }

    // Diagonal çizgiler
    final linePaint = Paint()
      ..color = AppColors.white.withOpacity(0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double i = -size.height; i < size.width; i += 60) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}