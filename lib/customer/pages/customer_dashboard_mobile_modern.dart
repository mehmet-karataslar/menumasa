import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/url_service.dart';
import 'tabs/customer_home_tab.dart';
import 'tabs/customer_orders_tab.dart';
import 'tabs/customer_favorites_tab.dart';
import 'tabs/customer_profile_tab.dart';
import 'tabs/customer_services_tab.dart';

/// Modern Müşteri Mobile Dashboard - Mobile Optimized Design
class ModernCustomerDashboardMobile extends StatefulWidget {
  final String userId;
  final int initialTabIndex;

  const ModernCustomerDashboardMobile({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  @override
  State<ModernCustomerDashboardMobile> createState() => _ModernCustomerDashboardMobileState();
}

class _ModernCustomerDashboardMobileState extends State<ModernCustomerDashboardMobile>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UrlService _urlService = UrlService();

  late TabController _tabController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  int _currentTabIndex = 0;

  // Modern Tab yapılandırması
  final List<CustomerMobileTabConfig> _tabs = [
    CustomerMobileTabConfig(
      id: 'home',
      title: 'Ana Sayfa',
      shortTitle: 'Ana',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      description: 'Keşfet ve sipariş ver',
      color: const Color(0xFF6C63FF),
      gradient: const LinearGradient(
        colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    CustomerMobileTabConfig(
      id: 'orders',
      title: 'Siparişler',
      shortTitle: 'Sipariş',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      description: 'Sipariş geçmişin',
      color: const Color(0xFFFF6B6B),
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8787)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    CustomerMobileTabConfig(
      id: 'favorites',
      title: 'Favoriler',
      shortTitle: 'Favori',
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      description: 'Beğendiğin yerler',
      color: const Color(0xFFE91E63),
      gradient: const LinearGradient(
        colors: [Color(0xFFE91E63), Color(0xFFF06292)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    CustomerMobileTabConfig(
      id: 'services',
      title: 'Hizmetler',
      shortTitle: 'Hizmet',
      icon: Icons.room_service_outlined,
      selectedIcon: Icons.room_service,
      description: 'Yeni özellikler',
      color: const Color(0xFF4ECDC4),
      gradient: const LinearGradient(
        colors: [Color(0xFF4ECDC4), Color(0xFF6FE6DD)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    CustomerMobileTabConfig(
      id: 'profile',
      title: 'Profil',
      shortTitle: 'Profil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      description: 'Hesap ayarların',
      color: const Color(0xFF1DD1A1),
      gradient: const LinearGradient(
        colors: [Color(0xFF1DD1A1), Color(0xFF3DDBB7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _initializeControllers();
    _updateUrl();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
    });
  }

  void _initializeControllers() {
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _currentTabIndex,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });
    _updateUrl();
    HapticFeedback.lightImpact();
  }

  void _updateUrl() {
    final tabId = _tabs[_currentTabIndex].id;
    final title = '${_tabs[_currentTabIndex].title} | MasaMenu';
    _urlService.updateModernCustomerUrl(widget.userId, tabId, customTitle: title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildMobileHeader(),
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: _buildTabViews(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildMobileBottomNavigation(),
    );
  }

  Widget _buildMobileHeader() {
    final currentTab = _tabs[_currentTabIndex];
    
    return Container(
      decoration: BoxDecoration(
        gradient: currentTab.gradient,
        boxShadow: [
          BoxShadow(
            color: currentTab.color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  currentTab.selectedIcon,
                  color: AppColors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTab.title,
                      style: AppTypography.h5.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentTab.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 75, // 85'ten 75'e düşürüldü
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding azaltıldı
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = index == _currentTabIndex;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(index);
                    _onTabChanged(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2), // 4'ten 2'ye düşürüldü
                    padding: const EdgeInsets.symmetric(vertical: 4), // 8'den 4'e düşürüldü
                    decoration: BoxDecoration(
                      gradient: isSelected ? tab.gradient : null,
                      color: isSelected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(16), // 20'den 16'ya düşürüldü
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: tab.color.withOpacity(0.3),
                          blurRadius: 8, // 12'den 8'e düşürüldü
                          offset: const Offset(0, 2), // 4'ten 2'ye düşürüldü
                        ),
                      ] : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(4), // 6'dan 4'e düşürüldü
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.white.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10), // 12'den 10'a düşürüldü
                          ),
                          child: Icon(
                            isSelected ? tab.selectedIcon : tab.icon,
                            color: isSelected ? AppColors.white : AppColors.textSecondary,
                            size: 20, // 24'ten 20'ye düşürüldü
                          ),
                        ),
                        const SizedBox(height: 2), // 4'ten 2'ye düşürüldü
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: AppTypography.caption.copyWith(
                            color: isSelected ? AppColors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 10, // 12'den 10'a düşürüldü
                          ),
                          child: Text(
                            tab.shortTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabViews() {
    return [
      CustomerHomeTab(
        userId: widget.userId,
        user: null,
        customerData: null,
        onRefresh: () {},
      ),
      CustomerOrdersTab(
        userId: widget.userId,
        customerData: null,
        onRefresh: () {},
      ),
      CustomerFavoritesTab(
        userId: widget.userId,
        customerData: null,
        onRefresh: () {},
      ),
      CustomerServicesTab(customerId: widget.userId),
      CustomerProfileTab(
        userId: widget.userId,
        user: null,
        customerData: null,
        onRefresh: () {},
        onLogout: _handleLogout,
      ),
    ];
  }

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.white,
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
            const Text('Çıkış Yap'),
          ],
        ),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8787)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Çıkış Yap'),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}

/// Customer Mobile Tab konfigürasyon sınıfı
class CustomerMobileTabConfig {
  final String id;
  final String title;
  final String shortTitle;
  final IconData icon;
  final IconData selectedIcon;
  final String description;
  final Color color;
  final Gradient gradient;

  CustomerMobileTabConfig({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.icon,
    required this.selectedIcon,
    required this.description,
    required this.color,
    required this.gradient,
  });
} 