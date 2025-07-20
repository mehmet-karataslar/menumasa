import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/url_service.dart';
import '../../../core/mixins/url_mixin.dart';
import '../../../data/models/user.dart' as app_user;
import '../../../data/models/business.dart';
import '../../../data/models/order.dart' as app_order;
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import '../../widgets/shared/empty_state.dart';
import 'menu_page.dart';

class CustomerDashboardPage extends StatefulWidget {
  final String userId;

  const CustomerDashboardPage({super.key, required this.userId});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage>
    with TickerProviderStateMixin, UrlMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final UrlService _urlService = UrlService();

  app_user.User? _user;
  app_user.CustomerData? _customerData;
  List<app_order.Order> _orders = [];
  List<Business> _nearbyBusinesses = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTabIndex = 0;

  late TabController _tabController;

  // Tab route mappings
  final List<String> _tabRoutes = ['dashboard', 'orders', 'favorites', 'profile'];
  final List<String> _tabTitles = ['Ana Sayfa', 'Siparişlerim', 'Favorilerim', 'Profil'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUserData();
    
    // Update URL on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCustomerUrl();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
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

      // Kullanıcının siparişlerini yükle
      final orders = await _firestoreService.getOrdersByCustomer(widget.userId);
      
      // Yakındaki işletmeleri yükle (demo data)
      final businesses = await _firestoreService.getBusinesses();

      setState(() {
        _orders = orders;
        _nearbyBusinesses = businesses.take(5).toList();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Müşteri Paneli'),
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
        ),
        body: Center(child: ErrorMessage(message: _errorMessage!)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.success,
      foregroundColor: AppColors.white,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.white.withOpacity(0.2),
            child: Icon(
              Icons.person,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.name ?? 'Müşteri',
                  style: AppTypography.h6.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _tabTitles[_selectedTabIndex],
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            _urlService.updateUrl('/search', customTitle: 'İşletme Ara | MasaMenu');
            Navigator.pushNamed(context, '/search');
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
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
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Ayarlar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: AppColors.error),
                title: Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.success,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.success,
        indicatorWeight: 3,
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            icon: Icon(Icons.dashboard),
            text: 'Ana Sayfa',
          ),
          Tab(
            icon: Icon(Icons.receipt_long),
            text: 'Siparişlerim',
          ),
          Tab(
            icon: Icon(Icons.favorite),
            text: 'Favorilerim',
          ),
          Tab(
            icon: Icon(Icons.person),
            text: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoş geldin kartı
            _buildWelcomeCard(),
            
            const SizedBox(height: 24),
            
            // Yakındaki işletmeler
            _buildNearbyBusinesses(),
            
            const SizedBox(height: 24),
            
            // Son siparişler
            _buildRecentOrders(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: _orders.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long,
              title: 'Henüz siparişiniz yok',
              message: 'İlk siparişinizi vermek için bir işletme seçin',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return _buildOrderCard(order);
              },
            ),
    );
  }

  Widget _buildFavoritesTab() {
    return const EmptyState(
      icon: Icons.favorite,
      title: 'Henüz favori işletmeniz yok',
      message: 'Beğendiğiniz işletmeleri favorilerinize ekleyin',
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profil bilgileri
          _buildProfileCard(),
          
          const SizedBox(height: 24),
          
          // Ayarlar
          _buildSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.success,
                  child: Icon(
                    Icons.person,
                    color: AppColors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş geldin, ${_user?.name ?? 'Müşteri'}!',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bugün hangi lezzeti keşfetmek istiyorsun?',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyBusinesses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yakındaki İşletmeler',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_nearbyBusinesses.isEmpty)
          const EmptyState(
            icon: Icons.business,
            title: 'Yakında işletme bulunamadı',
            message: 'Daha sonra tekrar kontrol edin',
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyBusinesses.length,
              itemBuilder: (context, index) {
                final business = _nearbyBusinesses[index];
                return _buildBusinessCard(business);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBusinessCard(Business business) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          _urlService.updateMenuUrl(
            business.id,
            businessName: business.businessName,
          );
          Navigator.pushNamed(
            context,
            '/menu',
            arguments: {'businessId': business.id},
          );
        },
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.business,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                business.businessName,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                business.businessType,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
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
              ),
            ),
            if (_orders.isNotEmpty)
              TextButton(
                onPressed: () {
                  _tabController.animateTo(1); // Switch to orders tab
                },
                child: const Text('Tümünü Gör'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_orders.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long,
            title: 'Henüz siparişiniz yok',
            message: 'İlk siparişinizi vermek için bir işletme seçin',
          )
        else
          Column(
            children: _orders
                .take(3)
                .map((order) => _buildOrderCard(order))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildOrderCard(app_order.Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
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
            Text(
              'Toplam: ${order.totalAmount.toStringAsFixed(2)} TL',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatOrderDate(order.createdAt),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.success,
              child: Icon(
                Icons.person,
                color: AppColors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user?.name ?? 'Müşteri',
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _user?.email ?? '',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Edit profile
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Profili Düzenle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Bildirimler'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to notifications settings
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Güvenlik'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to security settings
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Yardım'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to help
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Color _getOrderStatusColor(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return AppColors.warning;
      case app_order.OrderStatus.inProgress:
        return AppColors.info;
      case app_order.OrderStatus.completed:
        return AppColors.success;
      case app_order.OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getOrderStatusText(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return 'Bekliyor';
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