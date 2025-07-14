import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../services/business_service.dart';
import '../models/business_user.dart';
import '../../../presentation/widgets/shared/loading_indicator.dart';
import '../../../presentation/widgets/shared/error_message.dart';
import '../../../presentation/widgets/shared/empty_state.dart';
import 'business_management_page.dart';
import 'customer_management_page.dart';
import 'system_settings_page.dart';
import 'analytics_page.dart';
import 'activity_logs_page.dart';

class BusinessDashboardPage extends StatefulWidget {
  const BusinessDashboardPage({super.key});

  @override
  State<BusinessDashboardPage> createState() => _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends State<BusinessDashboardPage>
    with TickerProviderStateMixin {
  final BusinessService _businessService = BusinessService();

  BusinessUser? _currentBusiness;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadBusinessData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final business = _businessService.currentBusiness;
      if (business == null) {
        // Business girişi yapılmamış, login sayfasına yönlendir
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/business/login');
        }
        return;
      }

      setState(() {
        _currentBusiness = business;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Business verileri yüklenirken hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _businessService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/business/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış sırasında hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_currentBusiness == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sistem Yönetimi'),
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.white,
        ),
        body: Center(
          child: ErrorMessage(message: _errorMessage ?? 'Business bulunamadı'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.error,
      foregroundColor: AppColors.white,
      title: Row(
        children: [
          const Icon(Icons.admin_panel_settings),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sistem Yönetimi',
                style: AppTypography.h5.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Hoş geldin, ${_currentBusiness!.displayName}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Admin bilgileri
        PopupMenuButton<String>(
          icon: CircleAvatar(
            backgroundColor: AppColors.white.withOpacity(0.2),
            child: Text(
              _currentBusiness!.initials,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                // Profil sayfası
                break;
              case 'settings':
                // Ayarlar sayfası
                break;
              case 'logout':
                _handleLogout();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person, size: 20),
                  const SizedBox(width: 8),
                  Text('Profil'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings, size: 20),
                  const SizedBox(width: 8),
                  Text('Ayarlar'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 20, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: AppColors.white,
      child: Column(
        children: [
          // Admin bilgileri
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.greyLight,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.error,
                  child: Text(
                    _currentBusiness!.initials,
                    style: AppTypography.h4.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentBusiness!.displayName,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentBusiness!.role.displayName,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Navigation menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Genel Bakış',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _setSelectedIndex(0),
                ),
                                  _buildMenuItem(
                    icon: Icons.business,
                    title: 'İşletme Yönetimi',
                    isSelected: _selectedIndex == 1,
                    onTap: () => _setSelectedIndex(1),
                    hasPermission: _currentBusiness!.hasPermission(BusinessPermission.viewBusinessInfo),
                  ),
                                  _buildMenuItem(
                    icon: Icons.people,
                    title: 'Müşteri Yönetimi',
                    isSelected: _selectedIndex == 2,
                    onTap: () => _setSelectedIndex(2),
                    hasPermission: _currentBusiness!.hasPermission(BusinessPermission.viewOrders),
                  ),
                                  _buildMenuItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Yönetimi',
                    isSelected: _selectedIndex == 3,
                    onTap: () => _setSelectedIndex(3),
                    hasPermission: _currentBusiness!.hasPermission(BusinessPermission.manageStaff),
                  ),
                  _buildMenuItem(
                    icon: Icons.analytics,
                    title: 'Analitikler',
                    isSelected: _selectedIndex == 4,
                    onTap: () => _setSelectedIndex(4),
                    hasPermission: _currentBusiness!.hasPermission(BusinessPermission.viewAnalytics),
                  ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: 'Sistem Ayarları',
                    isSelected: _selectedIndex == 5,
                    onTap: () => _setSelectedIndex(5),
                    hasPermission: _currentBusiness!.hasPermission(BusinessPermission.manageSettings),
                  ),
                  const Divider(height: 32),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Aktivite Logları',
                    isSelected: _selectedIndex == 6,
                    onTap: () => _setSelectedIndex(6),
                    hasPermission: _currentBusiness!.hasPermission(BusinessPermission.viewReports),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasPermission = true,
  }) {
    if (!hasPermission) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.error : AppColors.textLight,
          size: 20,
        ),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected ? AppColors.error : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: isSelected ? AppColors.error.withOpacity(0.1) : null,
        selected: isSelected,
      ),
    );
  }

  Widget _buildMainContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        const BusinessManagementPage(),
        const CustomerManagementPage(),
        const BusinessManagementPage(),
        const AnalyticsPage(),
        const SystemSettingsPage(),
        const ActivityLogsPage(),
      ],
    );
  }

  void _setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _tabController.animateTo(index);
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text(
            'Sistem Genel Bakış',
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // İstatistik kartları
          _buildStatsGrid(),

          const SizedBox(height: 32),

          // Son aktiviteler
          _buildRecentActivities(),

          const SizedBox(height: 32),

          // Hızlı işlemler
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Toplam İşletme',
          value: '0',
          icon: Icons.business,
          color: AppColors.primary,
          onTap: () => _setSelectedIndex(1),
        ),
        _buildStatCard(
          title: 'Toplam Müşteri',
          value: '0',
          icon: Icons.people,
          color: AppColors.success,
          onTap: () => _setSelectedIndex(2),
        ),
        _buildStatCard(
          title: 'Aktif Admin',
          value: '1',
          icon: Icons.admin_panel_settings,
          color: AppColors.error,
          onTap: () => _setSelectedIndex(3),
        ),
        _buildStatCard(
          title: 'Bugünkü Giriş',
          value: '0',
          icon: Icons.login,
          color: AppColors.warning,
          onTap: () => _setSelectedIndex(6),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textLight,
                    size: 16,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: AppTypography.h2.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son Aktiviteler',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => _setSelectedIndex(6),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const EmptyState(
              icon: Icons.history,
              title: 'Henüz aktivite yok',
              message: 'Sistem aktiviteleri burada görüntülenecek',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hızlı İşlemler',
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_currentBusiness!.hasPermission(BusinessPermission.manageStaff))
                  _buildQuickActionButton(
                    title: 'Yeni Admin Ekle',
                    icon: Icons.person_add,
                    color: AppColors.primary,
                    onTap: () => _setSelectedIndex(3),
                  ),
                if (_currentBusiness!.hasPermission(BusinessPermission.viewBusinessInfo))
                  _buildQuickActionButton(
                    title: 'İşletme Onayla',
                    icon: Icons.check_circle,
                    color: AppColors.success,
                    onTap: () => _setSelectedIndex(1),
                  ),
                if (_currentBusiness!.hasPermission(BusinessPermission.viewAnalytics))
                  _buildQuickActionButton(
                    title: 'Rapor Oluştur',
                    icon: Icons.assessment,
                    color: AppColors.secondary,
                    onTap: () => _setSelectedIndex(4),
                  ),
                if (_currentBusiness!.hasPermission(BusinessPermission.manageSettings))
                  _buildQuickActionButton(
                    title: 'Sistem Ayarları',
                    icon: Icons.settings,
                    color: AppColors.warning,
                    onTap: () => _setSelectedIndex(5),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
