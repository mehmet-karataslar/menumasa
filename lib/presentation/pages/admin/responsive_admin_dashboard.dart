import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/business.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import 'admin_dashboard_page.dart';
import 'business_info_page.dart';
import 'product_management_page.dart';
import 'category_management_page.dart';
import 'orders_page.dart';
import 'qr_code_management_page.dart';
import 'menu_settings_page.dart';
import 'discount_management_page.dart';

class ResponsiveAdminDashboard extends StatefulWidget {
  final String businessId;

  const ResponsiveAdminDashboard({super.key, required this.businessId});

  @override
  State<ResponsiveAdminDashboard> createState() => _ResponsiveAdminDashboardState();
}

class _ResponsiveAdminDashboardState extends State<ResponsiveAdminDashboard> {
  Business? _business;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final FirestoreService _firestoreService = FirestoreService();

  // Sidebar menü öğeleri
  final List<SidebarItem> _sidebarItems = [
    SidebarItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    SidebarItem(
      icon: Icons.business,
      label: 'İşletme Bilgileri',
      route: '/business-info',
    ),
    SidebarItem(
      icon: Icons.restaurant_menu,
      label: 'Ürün Yönetimi',
      route: '/products',
    ),
    SidebarItem(
      icon: Icons.category,
      label: 'Kategori Yönetimi',
      route: '/categories',
    ),
    SidebarItem(
      icon: Icons.receipt_long,
      label: 'Siparişler',
      route: '/orders',
    ),
    SidebarItem(
      icon: Icons.qr_code,
      label: 'QR Kod Yönetimi',
      route: '/qr-codes',
    ),
    SidebarItem(
      icon: Icons.settings,
      label: 'Menü Ayarları',
      route: '/menu-settings',
    ),
    SidebarItem(
      icon: Icons.local_offer,
      label: 'İndirim Yönetimi',
      route: '/discounts',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final business = await _firestoreService.getBusiness(widget.businessId);
      if (business != null) {
        setState(() {
          _business = business;
        });
      } else {
        setState(() {
          _errorMessage = 'İşletme bulunamadı';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'İşletme bilgileri yüklenirken hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPageByIndex(int index) {
    switch (index) {
      case 0:
        return AdminDashboardPage(businessId: widget.businessId);
      case 1:
        return BusinessInfoPage(businessId: widget.businessId);
      case 2:
        return ProductManagementPage(businessId: widget.businessId);
      case 3:
        return CategoryManagementPage(businessId: widget.businessId);
      case 4:
        return OrdersPage(businessId: widget.businessId);
      case 5:
        return QRCodeManagementPage(businessId: widget.businessId);
      case 6:
        return MenuSettingsPage(businessId: widget.businessId);
      case 7:
        return DiscountManagementPage(businessId: widget.businessId);
      default:
        return AdminDashboardPage(businessId: widget.businessId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mobil cihazlarda normal admin dashboard kullan
    if (!kIsWeb || MediaQuery.of(context).size.width < 768) {
      return AdminDashboardPage(businessId: widget.businessId);
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_business == null) {
      return Scaffold(
        body: Center(child: ErrorMessage(message: _errorMessage ?? 'İşletme bulunamadı')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          
          // Main content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: _isSidebarCollapsed ? 70 : 280,
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
          
          // Menu items
          Expanded(
            child: _buildSidebarMenu(),
          ),
          
          // Footer
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Logo ve işletme adı
          Row(
            children: [
              if (_business?.logoUrl != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _business!.logoUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.restaurant,
                          size: 20,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.white,
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _business?.businessName ?? 'İşletme',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Yönetim Paneli',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Collapse button
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSidebarCollapsed = !_isSidebarCollapsed;
                  });
                },
                icon: Icon(
                  _isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
                  color: AppColors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMenu() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _sidebarItems.length,
      itemBuilder: (context, index) {
        final item = _sidebarItems[index];
        final isSelected = _selectedIndex == index;
        
        return _buildSidebarItem(
          item: item,
          index: index,
          isSelected: isSelected,
        );
      },
    );
  }

  Widget _buildSidebarItem({
    required SidebarItem item,
    required int index,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyLighter,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          if (!_isSidebarCollapsed) ...[
            // İstatistikler
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.visibility,
                    label: 'Görüntülenme',
                    value: '1.2K',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.shopping_cart,
                    label: 'Sipariş',
                    value: '24',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Çıkış butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, size: 18),
              label: _isSidebarCollapsed 
                  ? const SizedBox.shrink()
                  : const Text('Çıkış Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
      ),
      child: Column(
        children: [
          // Top bar
          _buildTopBar(),
          
          // Page content
          Expanded(
            child: _getPageByIndex(_selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Page title
          Text(
            _sidebarItems[_selectedIndex].label,
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const Spacer(),
          
          // Notifications
          IconButton(
            onPressed: () {
              // Notifications
            },
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textSecondary,
          ),
          
          // Profile
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              child: Text(
                'A',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String label;
  final String route;

  SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
 