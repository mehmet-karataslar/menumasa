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
import 'customer_dashboard_mobile_modern.dart';

/// Modern Müşteri Dashboard - Responsive Design
class ModernCustomerDashboard extends StatefulWidget {
  final String userId;
  final int initialTabIndex;

  const ModernCustomerDashboard({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  @override
  State<ModernCustomerDashboard> createState() => _ModernCustomerDashboardState();
}

class _ModernCustomerDashboardState extends State<ModernCustomerDashboard>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UrlService _urlService = UrlService();

  late TabController _tabController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  int _currentTabIndex = 0;
  bool _isDesktop = false;

  // Tab yapılandırması
  final List<TabConfig> _tabs = [
    TabConfig(
      id: 'home',
      title: 'Ana Sayfa',
      icon: Icons.home_rounded,
      selectedIcon: Icons.home,
    ),
    TabConfig(
      id: 'orders',
      title: 'Siparişler',
      icon: Icons.receipt_long_rounded,
      selectedIcon: Icons.receipt_long,
    ),
    TabConfig(
      id: 'favorites',
      title: 'Favoriler',
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite,
    ),
    TabConfig(
      id: 'services',
      title: 'Hizmetler',
      icon: Icons.room_service_outlined,
      selectedIcon: Icons.room_service,
    ),
    TabConfig(
      id: 'profile',
      title: 'Profil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person,
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
    _isDesktop = MediaQuery.of(context).size.width > 768;
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Mobil için özel modern layout kullan
    if (isMobile) {
      return ModernCustomerDashboardMobile(
        userId: widget.userId,
        initialTabIndex: _currentTabIndex,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isDesktop ? _buildDesktopLayout() : _buildTabletLayout(),
      bottomNavigationBar: _isDesktop ? null : _buildBottomNavigation(),
    );
  }

  Widget _buildTabletLayout() {
    return SlideTransition(
      position: _slideAnimation,
      child: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: _buildTabViews(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildSideNavigation(),
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildTabViews(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideNavigation() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.white,
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hoş Geldiniz',
                  style: AppTypography.h6.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'MasaMenu',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final isSelected = index == _currentTabIndex;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _tabController.animateTo(index);
                        _onTabChanged(index);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppColors.primary.withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? tab.selectedIcon : tab.icon,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                tab.title,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Divider(color: AppColors.greyLight),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _handleLogout,
                      child: Text(
                        'Çıkış Yap',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? tab.selectedIcon : tab.icon,
                            key: ValueKey(isSelected),
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: AppTypography.caption.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          child: Text(
                            tab.title,
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
        user: null, // Modern dashboard için placeholder
        customerData: null, // Modern dashboard için placeholder  
        onRefresh: () {}, // Modern dashboard için placeholder
      ),
      CustomerOrdersTab(
        userId: widget.userId,
        customerData: null, // Modern dashboard için placeholder
        onRefresh: () {}, // Modern dashboard için placeholder
      ),
      CustomerFavoritesTab(
        userId: widget.userId,
        customerData: null, // Modern dashboard için placeholder
        onRefresh: () {}, // Modern dashboard için placeholder
      ),
      CustomerServicesTab(customerId: widget.userId),
      CustomerProfileTab(
        userId: widget.userId,
        user: null, // Modern dashboard için placeholder
        customerData: null, // Modern dashboard için placeholder
        onRefresh: () {}, // Modern dashboard için placeholder
        onLogout: _handleLogout, // Modern dashboard için logout callback
      ),
    ];
  }

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Çıkış Yap'),
          ],
        ),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Çıkış Yap'),
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

/// Tab konfigürasyon sınıfı
class TabConfig {
  final String id;
  final String title;
  final IconData icon;
  final IconData selectedIcon;

  TabConfig({
    required this.id,
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });
} 