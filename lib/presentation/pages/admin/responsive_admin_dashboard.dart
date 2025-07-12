import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/business.dart';
import 'product_management_page.dart';
import 'category_management_page.dart';
import 'qr_code_management_page.dart';
import 'business_info_page.dart';
import 'menu_settings_page.dart';
import 'discount_management_page.dart';
import 'orders_page.dart';

class ResponsiveAdminDashboard extends StatefulWidget {
  final String businessId;
  final String? initialRoute;

  const ResponsiveAdminDashboard({
    Key? key,
    required this.businessId,
    this.initialRoute,
  }) : super(key: key);

  @override
  State<ResponsiveAdminDashboard> createState() =>
      _ResponsiveAdminDashboardState();
}

class _ResponsiveAdminDashboardState extends State<ResponsiveAdminDashboard> {
  int _selectedIndex = 0;
  Business? _business;

  final List<AdminMenuItem> _menuItems = [
    AdminMenuItem(
      title: 'Genel Bakış',
      icon: Icons.dashboard,
      color: AppColors.primary,
      route: '/admin/dashboard',
    ),
    AdminMenuItem(
      title: 'Siparişler',
      icon: Icons.receipt_long,
      color: AppColors.warning,
      route: '/admin/orders',
    ),
    AdminMenuItem(
      title: 'Ürün Yönetimi',
      icon: Icons.restaurant_menu,
      color: AppColors.primary,
      route: '/admin/products',
    ),
    AdminMenuItem(
      title: 'Kategori Yönetimi',
      icon: Icons.category,
      color: AppColors.success,
      route: '/admin/categories',
    ),
    AdminMenuItem(
      title: 'İndirim Yönetimi',
      icon: Icons.local_offer,
      color: AppColors.error,
      route: '/admin/discounts',
    ),
    AdminMenuItem(
      title: 'QR Kod Yönetimi',
      icon: Icons.qr_code,
      color: AppColors.secondary,
      route: '/admin/qr-codes',
    ),
    AdminMenuItem(
      title: 'İşletme Bilgileri',
      icon: Icons.business,
      color: AppColors.info,
      route: '/admin/business-info',
    ),
    AdminMenuItem(
      title: 'Menü Ayarları',
      icon: Icons.settings,
      color: AppColors.warning,
      route: '/admin/menu-settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setInitialIndex();
    _loadBusinessData();
  }

  void _setInitialIndex() {
    if (widget.initialRoute != null) {
      final index = _menuItems.indexWhere(
        (item) => item.route == widget.initialRoute,
      );
      if (index != -1) {
        _selectedIndex = index;
      }
    }
  }

  void _navigateToPage(int index, String route) {
    setState(() => _selectedIndex = index);
    Navigator.pushNamed(
      context,
      route,
      arguments: {'businessId': widget.businessId},
    );
  }

  Future<void> _loadBusinessData() async {
    // Load business data
    setState(() {
      _business = _createSampleBusiness();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;

    if (isDesktop || isTablet) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                _buildSidebarHeader(),
                const Divider(height: 1),
                // Menu Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedIndex == index;
                      return _buildSidebarMenuItem(item, index, isSelected);
                    },
                  ),
                ),
                // Footer
                _buildSidebarFooter(),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),
                // Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          _menuItems[_selectedIndex].title,
          style: AppTypography.h3.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      drawer: _buildMobileDrawer(),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: AppColors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _business?.businessName ?? 'Masa Menü',
            style: AppTypography.h4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Yönetim Paneli',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMenuItem(AdminMenuItem item, int index, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPage(index, item.route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? item.color.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: item.color.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? item.color : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? item.color : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.arrow_forward_ios, color: item.color, size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Masa Menü v1.0',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_menuItems[_selectedIndex].title, style: AppTypography.h4),
                Text(
                  _getPageDescription(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          IconButton(
            onPressed: () {
              // Notifications
            },
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              // Settings
            },
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.restaurant_menu,
                  color: AppColors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _business?.businessName ?? 'Masa Menü',
                  style: AppTypography.h4.copyWith(color: AppColors.white),
                ),
                Text(
                  'Yönetim Paneli',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? item.color : AppColors.textSecondary,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected ? item.color : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToPage(index, item.route);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewContent();
      case 1:
        return OrdersPage(businessId: widget.businessId);
      case 2:
        return ProductManagementPage(businessId: widget.businessId);
      case 3:
        return CategoryManagementPage(businessId: widget.businessId);
      case 4:
        return DiscountManagementPage(businessId: widget.businessId);
      case 5:
        return QRCodeManagementPage(businessId: widget.businessId);
      case 6:
        return BusinessInfoPage(businessId: widget.businessId);
      case 7:
        return MenuSettingsPage(businessId: widget.businessId);
      default:
        return _buildOverviewContent();
    }
  }

  Widget _buildOverviewContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş Geldiniz!',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'İşletmenizi yönetmek için sol menüden istediğiniz bölümü seçebilirsiniz.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.dashboard, color: AppColors.white, size: 48),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Toplam Ürün',
                  value: '24',
                  icon: Icons.restaurant_menu,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Kategoriler',
                  value: '6',
                  icon: Icons.category,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Aktif İndirimler',
                  value: '3',
                  icon: Icons.local_offer,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'QR Tarama',
                  value: '127',
                  icon: Icons.qr_code_scanner,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text('Hızlı İşlemler', style: AppTypography.h4),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildQuickActionCard(
                title: 'Yeni Ürün Ekle',
                icon: Icons.add_box,
                color: AppColors.primary,
                onTap: () => _navigateToPage(1, '/admin/products'),
              ),
              _buildQuickActionCard(
                title: 'İndirim Oluştur',
                icon: Icons.local_offer,
                color: AppColors.error,
                onTap: () => _navigateToPage(3, '/admin/discounts'),
              ),
              _buildQuickActionCard(
                title: 'QR Kod Paylaş',
                icon: Icons.share,
                color: AppColors.success,
                onTap: () => _navigateToPage(4, '/admin/qr-codes'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.h3.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getPageDescription() {
    switch (_selectedIndex) {
      case 0:
        return 'İşletmenizin genel durumu';
      case 1:
        return 'Ürünlerinizi yönetin';
      case 2:
        return 'Kategorilerinizi düzenleyin';
      case 3:
        return 'İndirimleri yönetin';
      case 4:
        return 'QR kodlarınızı oluşturun';
      case 5:
        return 'İşletme bilgilerinizi güncelleyin';
      case 6:
        return 'Menü görünümünü özelleştirin';
      default:
        return '';
    }
  }

  Business _createSampleBusiness() {
    return Business(
      businessId: widget.businessId,
      ownerId: 'sample-owner',
      businessName: 'Lezzet Durağı',
      businessDescription: 'Geleneksel Türk mutfağının en lezzetli örnekleri',
      logoUrl: 'https://picsum.photos/200/200?random=logo',
      address: Address(
        street: 'Atatürk Caddesi No:123',
        city: 'İstanbul',
        district: 'Beyoğlu',
        postalCode: '34000',
      ),
      contactInfo: ContactInfo(
        phone: '+90 212 123 45 67',
        email: 'info@lezzetduragi.com',
        website: 'www.lezzetduragi.com',
      ),
      menuSettings: MenuSettings(
        theme: 'default',
        primaryColor: '#2C1810',
        fontFamily: 'Poppins',
        fontSize: 16.0,
        showPrices: true,
        showImages: true,
        imageSize: 'medium',
        language: 'tr',
      ),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class AdminMenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  AdminMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}
