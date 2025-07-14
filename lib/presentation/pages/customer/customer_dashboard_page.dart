import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
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
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  app_user.User? _user;
  app_user.CustomerData? _customerData;
  List<app_order.Order> _orders = [];
  List<Business> _nearbyBusinesses = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTabIndex = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      await _loadCustomerData();

      // Siparişleri yükle
      await _loadOrders();

      // Yakındaki işletmeleri yükle
      await _loadNearbyBusinesses();

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

  Future<void> _loadCustomerData() async {
    try {
      final customerData = await _firestoreService.getCustomerData(widget.userId);
      setState(() {
        _customerData = customerData;
      });
    } catch (e) {
      print('Müşteri verileri yüklenirken hata: $e');
    }
  }

  Future<void> _loadOrders() async {
    try {
      // Kullanıcının siparişlerini getir
      final orders = await _firestoreService.getOrdersByCustomer(widget.userId);
      setState(() {
        _orders = orders;
      });
    } catch (e) {
      print('Siparişler yüklenirken hata: $e');
    }
  }

  Future<void> _loadNearbyBusinesses() async {
    try {
      // Tüm aktif işletmeleri getir (şimdilik)
      final businesses = await _firestoreService.getBusinesses();
      setState(() {
        _nearbyBusinesses = businesses.where((b) => b.isActive).toList();
      });
    } catch (e) {
      print('İşletmeler yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Müşteri Paneli'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: Center(
          child: ErrorMessage(message: _errorMessage ?? 'Kullanıcı bulunamadı'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildOrdersTab(),
                _buildBusinessesTab(),
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
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: Text(
        'Hoş geldin, ${_user!.name}',
        style: AppTypography.h4.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Bildirimler
          },
          icon: const Icon(Icons.notifications_outlined),
        ),
        IconButton(
          onPressed: () async {
            await _authService.signOut();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            }
          },
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textLight,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Genel Bakış'),
          Tab(icon: Icon(Icons.receipt_long), text: 'Siparişlerim'),
          Tab(icon: Icon(Icons.store), text: 'İşletmeler'),
          Tab(icon: Icon(Icons.person), text: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İstatistik kartları
          _buildStatsCards(),
          
          const SizedBox(height: 24),
          
          // Son siparişler
          _buildRecentOrders(),
          
          const SizedBox(height: 24),
          
          // Yakındaki işletmeler
          _buildNearbyBusinesses(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    // Müşteri verilerinden istatistikleri al
    final stats = _customerData?.stats ?? app_user.CustomerStats(
      totalOrders: 0,
      totalSpent: 0.0,
      favoriteBusinessCount: 0,
      totalVisits: 0,
      categoryPreferences: {},
      businessSpending: {},
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Toplam Sipariş',
            value: stats.totalOrders.toString(),
            icon: Icons.shopping_bag,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Toplam Harcama',
            value: '${stats.totalSpent.toStringAsFixed(2)} ₺',
            icon: Icons.payment,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Favori İşletmeler',
            value: stats.favoriteBusinessCount.toString(),
            icon: Icons.favorite,
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    final recentOrders = _customerData?.orderHistory.take(3).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Son Siparişler',
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                _tabController.animateTo(1);
              },
              child: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentOrders.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long,
            title: 'Henüz siparişiniz yok',
            message: 'İlk siparişinizi vermek için işletmeleri keşfedin',
          )
        else
          ...recentOrders.map((order) => _buildCustomerOrderCard(order)),
      ],
    );
  }

  Widget _buildCustomerOrderCard(app_user.CustomerOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(
            Icons.receipt,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          '${order.businessName}',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${order.items.length} ürün • ${order.totalAmount.toStringAsFixed(2)} ₺ • ${_formatDate(order.orderDate)}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textLight,
          ),
        ),
        trailing: _buildCustomerOrderStatusChip(order.status),
        onTap: () {
          // Sipariş detayı
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildCustomerOrderStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = 'Bekliyor';
        break;
      case 'confirmed':
        color = AppColors.info;
        text = 'Onaylandı';
        break;
      case 'preparing':
        color = AppColors.primary;
        text = 'Hazırlanıyor';
        break;
      case 'ready':
        color = AppColors.success;
        text = 'Hazır';
        break;
      case 'completed':
        color = AppColors.success;
        text = 'Tamamlandı';
        break;
      case 'cancelled':
        color = AppColors.error;
        text = 'İptal';
        break;
      default:
        color = AppColors.success;
        text = 'Tamamlandı';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrderStatusChip(app_order.OrderStatus status) {
    Color color;
    String text;

    switch (status) {
      case app_order.OrderStatus.pending:
        color = AppColors.warning;
        text = 'Bekliyor';
        break;
      case app_order.OrderStatus.inProgress:
        color = AppColors.primary;
        text = 'Hazırlanıyor';
        break;
      case app_order.OrderStatus.completed:
        color = AppColors.success;
        text = 'Tamamlandı';
        break;
      case app_order.OrderStatus.cancelled:
        color = AppColors.error;
        text = 'İptal';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNearbyBusinesses() {
    final favorites = _customerData?.favorites ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Favori İşletmeler',
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                _tabController.animateTo(2);
              },
              child: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (favorites.isEmpty)
          const EmptyState(
            icon: Icons.favorite_border,
            title: 'Henüz favori işletmeniz yok',
            message: 'Favori işletmelerinizi ekleyerek hızlı erişim sağlayın',
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: favorites.take(5).length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                return _buildFavoriteBusinessCard(favorite);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteBusinessCard(app_user.CustomerFavorite favorite) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MenuPage(businessId: favorite.businessId),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (favorite.businessLogo != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    favorite.businessLogo!,
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 80,
                        color: AppColors.greyLighter,
                        child: const Icon(
                          Icons.store,
                          color: AppColors.greyLight,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.greyLighter,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppColors.greyLight,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.businessName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${favorite.visitCount} ziyaret • ${favorite.totalSpent.toStringAsFixed(2)} ₺',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessCard(Business business) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MenuPage(businessId: business.businessId),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (business.logoUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    business.logoUrl!,
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 80,
                        color: AppColors.greyLighter,
                        child: const Icon(
                          Icons.store,
                          color: AppColors.greyLight,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.greyLighter,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppColors.greyLight,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.businessName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      business.businessDescription,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    final orders = _customerData?.orderHistory ?? [];
    
    return orders.isEmpty
        ? const EmptyState(
            icon: Icons.receipt_long,
            title: 'Henüz siparişiniz yok',
            message: 'İlk siparişinizi vermek için işletmeleri keşfedin',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildCustomerOrderCard(orders[index]);
            },
          );
  }

  Widget _buildBusinessesTab() {
    final favorites = _customerData?.favorites ?? [];
    
    return favorites.isEmpty
        ? const EmptyState(
            icon: Icons.favorite_border,
            title: 'Henüz favori işletmeniz yok',
            message: 'Favori işletmelerinizi ekleyerek hızlı erişim sağlayın',
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return _buildFavoriteBusinessGridCard(favorites[index]);
            },
          );
  }

  Widget _buildFavoriteBusinessGridCard(app_user.CustomerFavorite favorite) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuPage(businessId: favorite.businessId),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favorite.businessLogo != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    favorite.businessLogo!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.greyLighter,
                        child: const Icon(
                          Icons.store,
                          color: AppColors.greyLight,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.greyLighter,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppColors.greyLight,
                    size: 40,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.businessName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${favorite.visitCount} ziyaret • ${favorite.totalSpent.toStringAsFixed(2)} ₺',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessGridCard(Business business) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuPage(businessId: business.businessId),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (business.logoUrl != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    business.logoUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.greyLighter,
                        child: const Icon(
                          Icons.store,
                          color: AppColors.greyLight,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.greyLighter,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppColors.greyLight,
                    size: 40,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.businessName,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business.businessDescription,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profil kartı
          _buildProfileCard(),
          
          const SizedBox(height: 24),
          
          // Ayarlar
          _buildSettingsSection(),
          
          const SizedBox(height: 24),
          
          // Hesap işlemleri
          _buildAccountSection(),
        ],
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
              backgroundColor: AppColors.primary,
              child: Text(
                _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : 'U',
                style: AppTypography.h3.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user!.name,
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _user!.email,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
            if (_user!.phone != null) ...[
              const SizedBox(height: 4),
              Text(
                _user!.phone!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.primary),
            title: const Text('Profili Düzenle'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Profil düzenleme
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.warning),
            title: const Text('Şifre Değiştir'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Şifre değiştirme
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: AppColors.info),
            title: const Text('Bildirim Ayarları'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Bildirim ayarları
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help, color: AppColors.info),
            title: const Text('Yardım & Destek'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Yardım
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppColors.warning),
            title: const Text('Gizlilik Politikası'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Gizlilik politikası
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: AppColors.error),
            title: const Text('Hesabı Sil'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showDeleteAccountDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authService.deleteUserAccount();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Hesabı Sil'),
          ),
        ],
      ),
    );
  }
} 