import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/business.dart';
import '../../../data/models/order.dart';
import '../../../data/models/product.dart';
import '../../../data/models/category.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import '../../widgets/shared/empty_state.dart';
import '../admin/responsive_admin_dashboard.dart';
import '../admin/business_info_page.dart';
import '../admin/category_management_page.dart';
import '../admin/product_management_page.dart';
import '../admin/orders_page.dart';
import '../admin/menu_settings_page.dart';
import '../admin/discount_management_page.dart';
import '../admin/qr_code_management_page.dart';

class BusinessHomePage extends StatefulWidget {
  final String businessId;

  const BusinessHomePage({Key? key, required this.businessId}) : super(key: key);

  @override
  State<BusinessHomePage> createState() => _BusinessHomePageState();
}

class _BusinessHomePageState extends State<BusinessHomePage>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  Business? _business;
  List<Order> _recentOrders = [];
  List<Product> _popularProducts = [];
  List<Category> _categories = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  
  // İstatistikler
  int _totalOrders = 0;
  int _totalProducts = 0;
  int _totalCategories = 0;
  double _totalRevenue = 0.0;
  int _todayOrders = 0;
  double _todayRevenue = 0.0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      // İşletme bilgilerini yükle
      final business = await _firestoreService.getBusiness(widget.businessId);
      if (business == null) {
        throw Exception('İşletme bulunamadı');
      }

      // Son siparişleri yükle
      final orders = await _firestoreService.getBusinessOrders(
        widget.businessId,
        limit: 5,
      );

      // Kategorileri yükle
      final categories = await _firestoreService.getBusinessCategories(
        widget.businessId,
      );

      // Ürünleri yükle
      final products = await _firestoreService.getBusinessProducts(
        widget.businessId,
        limit: 10,
      );

      // İstatistikleri hesapla
      final stats = await _calculateStats();

      setState(() {
        _business = business;
        _recentOrders = orders;
        _categories = categories;
        _popularProducts = products;
        _totalOrders = stats['totalOrders'] ?? 0;
        _totalProducts = stats['totalProducts'] ?? 0;
        _totalCategories = stats['totalCategories'] ?? 0;
        _totalRevenue = stats['totalRevenue'] ?? 0.0;
        _todayOrders = stats['todayOrders'] ?? 0;
        _todayRevenue = stats['todayRevenue'] ?? 0.0;
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

  Future<Map<String, dynamic>> _calculateStats() async {
    try {
      // Toplam sipariş sayısı
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('businessId', isEqualTo: widget.businessId)
          .get();

      final totalOrders = ordersQuery.docs.length;
      double totalRevenue = 0.0;

      // Toplam gelir hesapla
      for (var doc in ordersQuery.docs) {
        final orderData = doc.data();
        if (orderData['status'] == 'completed') {
          totalRevenue += (orderData['totalAmount'] ?? 0.0).toDouble();
        }
      }

      // Bugünkü siparişler
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todayOrdersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('businessId', isEqualTo: widget.businessId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('createdAt', isLessThan: endOfDay.toIso8601String())
          .get();

      final todayOrders = todayOrdersQuery.docs.length;
      double todayRevenue = 0.0;

      for (var doc in todayOrdersQuery.docs) {
        final orderData = doc.data();
        if (orderData['status'] == 'completed') {
          todayRevenue += (orderData['totalAmount'] ?? 0.0).toDouble();
        }
      }

      // Toplam ürün sayısı
      final productsQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('businessId', isEqualTo: widget.businessId)
          .get();

      // Toplam kategori sayısı
      final categoriesQuery = await FirebaseFirestore.instance
          .collection('categories')
          .where('businessId', isEqualTo: widget.businessId)
          .get();

      return {
        'totalOrders': totalOrders,
        'totalProducts': productsQuery.docs.length,
        'totalCategories': categoriesQuery.docs.length,
        'totalRevenue': totalRevenue,
        'todayOrders': todayOrders,
        'todayRevenue': todayRevenue,
      };
    } catch (e) {
      print('İstatistik hesaplama hatası: $e');
      return {};
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
          title: const Text('İşletme Ana Sayfa'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: Center(child: ErrorMessage(message: _errorMessage!)),
      );
    }

    if (_business == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('İşletme Ana Sayfa'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: const Center(
          child: EmptyState(
            icon: Icons.business,
            title: 'İşletme Bulunamadı',
            message: 'İşletme bilgileri yüklenemedi',
          ),
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
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: Row(
        children: [
          if (_business?.logoUrl != null)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _business!.logoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.restaurant,
                      color: AppColors.primary,
                      size: 24,
                    );
                  },
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _business?.businessName ?? 'İşletme Adı',
                style: AppTypography.h5.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Hoş geldiniz!',
                style: AppTypography.caption.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            // Bildirimler
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/admin/menu-settings',
              arguments: {'businessId': widget.businessId},
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Navigator.pushNamed(
                  context,
                  '/admin/business-info',
                  arguments: {'businessId': widget.businessId},
                );
                break;
              case 'qr':
                Navigator.pushNamed(
                  context,
                  '/admin/qr-codes',
                  arguments: {'businessId': widget.businessId},
                );
                break;
              case 'logout':
                Navigator.pushReplacementNamed(context, '/');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.business, size: 20),
                  SizedBox(width: 8),
                  Text('İşletme Profili'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'qr',
              child: Row(
                children: [
                  Icon(Icons.qr_code, size: 20),
                  SizedBox(width: 8),
                  Text('QR Kodlar'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
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
          // İşletme bilgileri
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.greyLight,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                if (_business?.logoUrl != null)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _business!.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  _business?.businessName ?? 'İşletme Adı',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _business?.businessType ?? 'Restoran',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _business?.isOpen == true 
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _business?.isOpen == true 
                            ? Icons.check_circle 
                            : Icons.cancel,
                        size: 16,
                        color: _business?.isOpen == true 
                            ? AppColors.success 
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _business?.isOpen == true ? 'Açık' : 'Kapalı',
                        style: AppTypography.caption.copyWith(
                          color: _business?.isOpen == true 
                              ? AppColors.success 
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                  isSelected: _tabController.index == 0,
                  onTap: () => _setSelectedIndex(0),
                ),
                _buildMenuItem(
                  icon: Icons.receipt_long,
                  title: 'Siparişler',
                  isSelected: _tabController.index == 1,
                  onTap: () => _setSelectedIndex(1),
                  badge: _todayOrders > 0 ? _todayOrders.toString() : null,
                ),
                _buildMenuItem(
                  icon: Icons.restaurant_menu,
                  title: 'Menü Yönetimi',
                  isSelected: _tabController.index == 2,
                  onTap: () => _setSelectedIndex(2),
                ),
                _buildMenuItem(
                  icon: Icons.analytics,
                  title: 'Analitikler',
                  isSelected: _tabController.index == 3,
                  onTap: () => _setSelectedIndex(3),
                ),
                const Divider(height: 32),
                _buildMenuItem(
                  icon: Icons.category,
                  title: 'Kategoriler',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/admin/categories',
                    arguments: {'businessId': widget.businessId},
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.local_offer,
                  title: 'İndirimler',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/admin/discounts',
                    arguments: {'businessId': widget.businessId},
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.qr_code,
                  title: 'QR Kodlar',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/admin/qr-codes',
                    arguments: {'businessId': widget.businessId},
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Ayarlar',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/admin/menu-settings',
                    arguments: {'businessId': widget.businessId},
                  ),
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
    required VoidCallback onTap,
    bool isSelected = false,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 20,
            ),
            if (badge != null)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badge,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        selected: isSelected,
      ),
    );
  }

  Widget _buildMainContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildOrdersTab(),
        _buildMenuTab(),
        _buildAnalyticsTab(),
      ],
    );
  }

  void _setSelectedIndex(int index) {
    setState(() {
      _tabController.animateTo(index);
    });
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text(
            'İşletme Genel Bakış',
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // İstatistik kartları
          _buildStatsGrid(),

          const SizedBox(height: 32),

          // Son siparişler ve popüler ürünler
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Son siparişler
              Expanded(
                child: _buildRecentOrders(),
              ),
              const SizedBox(width: 24),
              // Popüler ürünler
              Expanded(
                child: _buildPopularProducts(),
              ),
            ],
          ),

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
          title: 'Toplam Sipariş',
          value: _totalOrders.toString(),
          icon: Icons.receipt_long,
          color: AppColors.primary,
          trend: '+${_todayOrders} bugün',
        ),
        _buildStatCard(
          title: 'Toplam Gelir',
          value: '₺${_totalRevenue.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: AppColors.success,
          trend: '+₺${_todayRevenue.toStringAsFixed(2)} bugün',
        ),
        _buildStatCard(
          title: 'Toplam Ürün',
          value: _totalProducts.toString(),
          icon: Icons.restaurant_menu,
          color: AppColors.warning,
          trend: '${_categories.length} kategori',
        ),
        _buildStatCard(
          title: 'Aktif Kategori',
          value: _totalCategories.toString(),
          icon: Icons.category,
          color: AppColors.info,
          trend: 'Aktif',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: AppTypography.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
    );
  }

  Widget _buildRecentOrders() {
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
                  'Son Siparişler',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => _setSelectedIndex(1),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentOrders.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long,
                title: 'Henüz sipariş yok',
                message: 'İlk siparişinizi bekliyoruz',
              )
            else
              Column(
                children: _recentOrders.map((order) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getOrderStatusColor(order.status).withOpacity(0.1),
                      child: Icon(
                        _getOrderStatusIcon(order.status),
                        color: _getOrderStatusColor(order.status),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Sipariş #${order.orderId.substring(0, 8)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '₺${order.totalAmount.toStringAsFixed(2)} • ${_getOrderStatusText(order.status)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    trailing: Text(
                      _formatTime(order.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularProducts() {
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
                  'Popüler Ürünler',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => _setSelectedIndex(2),
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_popularProducts.isEmpty)
              const EmptyState(
                icon: Icons.restaurant_menu,
                title: 'Henüz ürün yok',
                message: 'İlk ürününüzü ekleyin',
              )
            else
              Column(
                children: _popularProducts.take(5).map((product) {
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.greyLight,
                      ),
                      child: product.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.restaurant,
                                    color: AppColors.textLight,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.restaurant,
                              color: AppColors.textLight,
                            ),
                    ),
                    title: Text(
                      product.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '₺${product.price.toStringAsFixed(2)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: product.isAvailable 
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.isAvailable ? 'Aktif' : 'Pasif',
                        style: AppTypography.caption.copyWith(
                          color: product.isAvailable 
                              ? AppColors.success 
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                _buildQuickActionButton(
                  title: 'Yeni Ürün Ekle',
                  icon: Icons.add,
                  color: AppColors.success,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/admin/products',
                    arguments: {'businessId': widget.businessId},
                  ),
                ),
                _buildQuickActionButton(
                  title: 'Kategori Ekle',
                  icon: Icons.category,
                  color: AppColors.primary,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/admin/categories',
                    arguments: {'businessId': widget.businessId},
                  ),
                ),
                _buildQuickActionButton(
                  title: 'QR Kod Oluştur',
                  icon: Icons.qr_code,
                  color: AppColors.info,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/admin/qr-codes',
                    arguments: {'businessId': widget.businessId},
                  ),
                ),
                _buildQuickActionButton(
                  title: 'İndirim Ekle',
                  icon: Icons.local_offer,
                  color: AppColors.warning,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/admin/discounts',
                    arguments: {'businessId': widget.businessId},
                  ),
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

  Widget _buildOrdersTab() {
    return const Center(
      child: EmptyState(
        icon: Icons.receipt_long,
        title: 'Sipariş Yönetimi',
        message: 'Bu sayfa yakında eklenecek',
      ),
    );
  }

  Widget _buildMenuTab() {
    return const Center(
      child: EmptyState(
        icon: Icons.restaurant_menu,
        title: 'Menü Yönetimi',
        message: 'Bu sayfa yakında eklenecek',
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: EmptyState(
        icon: Icons.analytics,
        title: 'Analitikler',
        message: 'Bu sayfa yakında eklenecek',
      ),
    );
  }

  // Helper methods
  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'preparing':
        return AppColors.primary;
      case 'ready':
        return AppColors.success;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.done;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  String _getOrderStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'confirmed':
        return 'Onaylandı';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'ready':
        return 'Hazır';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Bilinmiyor';
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${date.day}/${date.month}';
    }
  }
} 