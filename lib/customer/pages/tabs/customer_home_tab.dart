import 'package:flutter/material.dart';
import '../../../business/models/business.dart';
import '../../../business/models/category.dart';
import '../../../data/models/order.dart' as app_order;
import '../../../data/models/user.dart' as app_user;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/url_service.dart';
import '../../services/customer_firestore_service.dart';
import '../../services/customer_service.dart';
import '../../../presentation/widgets/shared/empty_state.dart';
import '../menu_page.dart';
import '../business_detail_page.dart';
import '../search_page.dart';
import '../qr_scanner_page.dart';
import '../../../core/services/waiter_call_service.dart';
import '../../models/waiter_call.dart';
import '../../../core/utils/date_utils.dart' as date_utils;

/// Müşteri ana sayfa tab'ı
class CustomerHomeTab extends StatefulWidget {
  final String userId;
  final app_user.User? user;
  final app_user.CustomerData? customerData;
  final VoidCallback onRefresh;
  final Function(int)? onNavigateToTab;

  const CustomerHomeTab({
    super.key,
    required this.userId,
    required this.user,
    required this.customerData,
    required this.onRefresh,
    this.onNavigateToTab,
  });

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  final CustomerFirestoreService _customerFirestoreService =
      CustomerFirestoreService();
  final CustomerService _customerService = CustomerService();
  final UrlService _urlService = UrlService();
  final WaiterCallService _waiterCallService = WaiterCallService();

  List<app_order.Order> _orders = [];
  List<Business> _nearbyBusinesses = [];
  List<Business> _favoriteBusinesses = [];
  List<Category> _categories = [];
  bool _isLoading = false;

  // Gerçek istatistikler
  int _totalOrders = 0;
  double _totalSpent = 0.0;
  int _favoriteCount = 0;
  int _totalVisits = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Kullanıcının siparişlerini yükle
      final orders =
          await _customerFirestoreService.getOrdersByCustomer(widget.userId);

      // Yakındaki işletmeleri yükle
      final businesses = await _customerFirestoreService.getBusinesses();

      // Kategorileri yükle
      final categories = await _customerFirestoreService.getCategories();

      // Favori işletmeleri yükle - hem CustomerData hem CustomerService'den
      Set<String> favoriteIds = <String>{};

      // CustomerData'dan favori ID'leri al
      if (widget.customerData?.favorites != null) {
        favoriteIds
            .addAll(widget.customerData!.favorites.map((f) => f.businessId));
      }

      // CustomerService'den de favori ID'leri al (daha güncel olabilir)
      final currentCustomer = _customerService.currentCustomer;
      if (currentCustomer?.favoriteBusinessIds != null) {
        favoriteIds.addAll(currentCustomer!.favoriteBusinessIds);
      }

      final favorites =
          businesses.where((b) => favoriteIds.contains(b.id)).toList();

      // Gerçek istatistikleri hesapla
      _calculateRealStatistics(orders, favorites);

      setState(() {
        _orders = orders;
        _nearbyBusinesses =
            businesses.where((b) => b.isActive).take(6).toList();
        _favoriteBusinesses = favorites;
        _categories = categories;
      });
    } catch (e) {
      print('Veri yükleme hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateRealStatistics(
      List<app_order.Order> orders, List<Business> favorites) {
    // Toplam sipariş sayısı
    _totalOrders = orders.length;

    // Toplam harcama - tamamlanan siparişlerin toplamı
    _totalSpent = orders
        .where((order) => order.status == app_order.OrderStatus.completed)
        .fold(0.0, (sum, order) => sum + order.totalAmount);

    // Favori işletme sayısı
    _favoriteCount = favorites.length;

    // Toplam ziyaret sayısı - benzersiz işletme sayısı
    final uniqueBusinessIds = orders.map((order) => order.businessId).toSet();
    _totalVisits = uniqueBusinessIds.length;
  }

  Future<void> _handleRefresh() async {
    await _loadData();
    widget.onRefresh();
  }

  // Navigation methods
  void _navigateToSearch() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute =
        '/customer/${widget.userId}/search?t=$timestamp&ref=home';
    _urlService.updateUrl(dynamicRoute, customTitle: 'İşletme Ara | MasaMenu');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(
          businesses: _nearbyBusinesses,
          categories: _categories,
        ),
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'userId': widget.userId,
            'timestamp': timestamp,
            'businesses': _nearbyBusinesses,
            'categories': _categories,
            'referrer': 'home',
            'source': 'dashboard',
          },
        ),
      ),
    );
  }

  void _navigateToMenu(Business business) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute =
        '/customer/${widget.userId}/menu/${business.id}?t=$timestamp&ref=home';
    _urlService.updateMenuUrl(business.id, businessName: business.businessName);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuPage(businessId: business.id),
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'businessId': business.id,
            'business': business,
            'userId': widget.userId,
            'timestamp': timestamp,
            'referrer': 'home',
            'businessName': business.businessName,
          },
        ),
      ),
    );
  }

  void _navigateToBusinessDetail(Business business) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute =
        '/customer/${widget.userId}/business/${business.id}?t=$timestamp&ref=home';
    _urlService.updateUrl(dynamicRoute,
        customTitle: '${business.businessName} | MasaMenu');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessDetailPage(
          business: business,
          customerData: widget.customerData,
        ),
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'business': business,
            'customerData': widget.customerData,
            'userId': widget.userId,
            'timestamp': timestamp,
            'referrer': 'home',
            'businessName': business.businessName,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hızlı İstatistikler
            _buildQuickStatsCards(),

            const SizedBox(height: 24),

            // Hızlı Eylemler
            _buildQuickActions(),

            const SizedBox(height: 24),

            // Yakındaki İşletmeler
            _buildNearbyBusinesses(),

            const SizedBox(height: 24),

            // Son Siparişler
            _buildRecentOrders(),

            const SizedBox(height: 100), // FAB için boşluk
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCards() {
    // Gerçek verilerden istatistikleri kullan

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Özet Bilgiler',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Toplam Sipariş',
                value: '$_totalOrders',
                icon: Icons.shopping_bag_rounded,
                color: AppColors.primary,
                gradient: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Harcama',
                value: '${_totalSpent.toStringAsFixed(0)}₺',
                icon: Icons.payments_rounded,
                color: AppColors.success,
                gradient: [AppColors.success, const Color(0xFF2ECC71)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Favoriler',
                value: '$_favoriteCount',
                icon: Icons.favorite_rounded,
                color: AppColors.accent,
                gradient: [AppColors.accent, AppColors.accentLight],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Erişim',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'QR Tara',
                subtitle: 'Menüye hızlı erişim',
                icon: Icons.qr_code_scanner_rounded,
                color: AppColors.primary,
                onTap: () {
                  // QR tarama sayfasına yönlendir
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final dynamicRoute =
                      '/customer/${widget.userId}/qr-scan?t=$timestamp';
                  _urlService.updateUrl(dynamicRoute,
                      customTitle: 'QR Tara | MasaMenu');

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          QRScannerPage(userId: widget.userId),
                      settings: RouteSettings(
                        name: dynamicRoute,
                        arguments: {
                          'userId': widget.userId,
                          'timestamp': timestamp,
                          'referrer': 'home_quick_actions',
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'İşletme Ara',
                subtitle: 'Yakınında keşfet',
                icon: Icons.search_rounded,
                color: AppColors.info,
                onTap: () {
                  _navigateToSearch();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Siparişlerim',
                subtitle: 'Geçmiş siparişler',
                icon: Icons.history_rounded,
                color: AppColors.warning,
                onTap: () {
                  // Navigate to orders tab with URL update
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  _urlService.updateCustomerUrl(widget.userId, 'orders',
                      customTitle: 'Siparişlerim | MasaMenu');
                  widget.onNavigateToTab?.call(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Favorilerim',
                subtitle: 'Beğendiğin yerler',
                icon: Icons.favorite_rounded,
                color: AppColors.accent,
                onTap: () {
                  // Navigate to favorites tab with URL update
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  _urlService.updateCustomerUrl(widget.userId, 'favorites',
                      customTitle: 'Favorilerim | MasaMenu');
                  widget.onNavigateToTab?.call(2);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Garson Çağırma Butonu
        _buildWaiterCallCard(),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyBusinesses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yakındaki İşletmeler',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _navigateToSearch();
              },
              icon: Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text('Tümünü Gör'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_nearbyBusinesses.isEmpty)
          _buildEmptyStateCard(
            icon: Icons.business_rounded,
            title: 'Yakında işletme bulunamadı',
            subtitle: 'Daha sonra tekrar kontrol edin',
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyBusinesses.length,
              itemBuilder: (context, index) {
                final business = _nearbyBusinesses[index];
                return _buildBusinessCard(business, index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBusinessCard(Business business, int index) {
    return Container(
      width: 180,
      margin: EdgeInsets.only(
        right: 16,
        left: index == 0 ? 0 : 0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _navigateToMenu(business);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İşletme resmi
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primaryLight.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (business.logoUrl != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Image.network(
                            business.logoUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildBusinessIcon(),
                          ),
                        )
                      else
                        _buildBusinessIcon(),

                      // Durum göstergesi
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: business.isOpen
                                ? AppColors.success
                                : AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            business.isOpen ? 'Açık' : 'Kapalı',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // İşletme bilgileri
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.businessName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            business.businessType,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                business.businessAddress,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildBusinessIcon() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primaryLight.withOpacity(0.6),
          ],
        ),
      ),
      child: Icon(
        Icons.business_rounded,
        size: 40,
        color: AppColors.white.withOpacity(0.8),
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
                color: AppColors.textPrimary,
              ),
            ),
            if (_orders.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  // Navigate to orders tab with URL update
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  _urlService.updateCustomerUrl(widget.userId, 'orders',
                      customTitle: 'Siparişlerim | MasaMenu');
                  // Navigation will be handled by URL change
                },
                icon: Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('Tümünü Gör'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_orders.isEmpty)
          _buildEmptyStateCard(
            icon: Icons.receipt_long_rounded,
            title: 'Henüz siparişiniz yok',
            subtitle: 'İlk siparişinizi vermek için bir işletme seçin',
          )
        else
          Column(
            children: _orders
                .take(3)
                .map((order) => _buildModernOrderCard(order))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildModernOrderCard(app_order.Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Sipariş ikonu
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getOrderStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getOrderStatusIcon(order.status),
                color: _getOrderStatusColor(order.status),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Sipariş bilgileri
            Expanded(
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getOrderStatusColor(order.status),
                          borderRadius: BorderRadius.circular(8),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date_utils.DateUtils.formatOrderListDate(
                            order.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${order.totalAmount.toStringAsFixed(2)} ₺',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.greyLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getOrderStatusColor(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return AppColors.warning;
      case app_order.OrderStatus.confirmed:
        return AppColors.info;
      case app_order.OrderStatus.preparing:
        return AppColors.warning;
      case app_order.OrderStatus.ready:
        return AppColors.success;
      case app_order.OrderStatus.delivered:
        return AppColors.success;
      case app_order.OrderStatus.inProgress:
        return AppColors.info;
      case app_order.OrderStatus.completed:
        return AppColors.success;
      case app_order.OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getOrderStatusIcon(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return Icons.schedule_rounded;
      case app_order.OrderStatus.confirmed:
        return Icons.check_rounded;
      case app_order.OrderStatus.preparing:
        return Icons.restaurant_rounded;
      case app_order.OrderStatus.ready:
        return Icons.done_all_rounded;
      case app_order.OrderStatus.delivered:
        return Icons.delivery_dining_rounded;
      case app_order.OrderStatus.inProgress:
        return Icons.restaurant_rounded;
      case app_order.OrderStatus.completed:
        return Icons.check_circle_rounded;
      case app_order.OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String _getOrderStatusText(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return 'Bekliyor';
      case app_order.OrderStatus.confirmed:
        return 'Onaylandı';
      case app_order.OrderStatus.preparing:
        return 'Hazırlanıyor';
      case app_order.OrderStatus.ready:
        return 'Hazır';
      case app_order.OrderStatus.delivered:
        return 'Teslim Edildi';
      case app_order.OrderStatus.inProgress:
        return 'Hazırlanıyor';
      case app_order.OrderStatus.completed:
        return 'Tamamlandı';
      case app_order.OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  // Garson Çağırma Widget'ı
  Widget _buildWaiterCallCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.room_service_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garson Çağır',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hızlı hizmet için garson çağırın',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _showWaiterCallDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.call_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Çağır',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWaiterCallDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWaiterCallSheet(),
    );
  }

  Widget _buildWaiterCallSheet() {
    WaiterCallType selectedType = WaiterCallType.service;
    String message = '';
    int tableNumber = 1;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.room_service_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Garson Çağır',
                          style: AppTypography.h6.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Hizmet talebinizi belirtin',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Masa Numarası
              Text(
                'Masa Numarası',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.greyExtraLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.greyLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: tableNumber,
                    isExpanded: true,
                    items: List.generate(20, (index) => index + 1)
                        .map((number) => DropdownMenuItem(
                              value: number,
                              child: Text('Masa $number'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tableNumber = value ?? 1;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Talep Türü
              Text(
                'Talep Türü',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WaiterCallType.values.map((type) {
                  final isSelected = selectedType == type;
                  return FilterChip(
                    label: Text(_getCallTypeText(type)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        selectedType = type;
                      });
                    },
                    backgroundColor: AppColors.greyExtraLight,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Mesaj
              Text(
                'Mesaj (Opsiyonel)',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Özel talebinizi yazın...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.greyLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.greyLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  message = value;
                },
              ),
              const SizedBox(height: 24),

              // Gönder Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _makeWaiterCall(selectedType, tableNumber, message);
                  },
                  icon: Icon(Icons.send_rounded),
                  label: Text('Garson Çağır'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCallTypeText(WaiterCallType type) {
    switch (type) {
      case WaiterCallType.service:
        return 'Genel Hizmet';
      case WaiterCallType.order:
        return 'Sipariş';
      case WaiterCallType.payment:
        return 'Hesap';
      case WaiterCallType.complaint:
        return 'Şikayet';
      case WaiterCallType.assistance:
        return 'Yardım';
      case WaiterCallType.bill:
        return 'Hesap';
      case WaiterCallType.help:
        return 'Yardım';
      case WaiterCallType.cleaning:
        return 'Temizlik';
      case WaiterCallType.emergency:
        return 'Acil Durum';
    }
  }

  Future<void> _makeWaiterCall(
      WaiterCallType type, int tableNumber, String message) async {
    try {
      // Yakındaki işletmelerden birini varsayılan olarak al (demo için)
      String? businessId;
      if (_nearbyBusinesses.isNotEmpty) {
        businessId = _nearbyBusinesses.first.id;
      }

      if (businessId == null) {
        _showErrorDialog(
            'Çağrı yapılacak işletme bulunamadı. Lütfen önce bir işletme seçin.');
        return;
      }

      await _waiterCallService.callWaiter(
        businessId: businessId,
        customerId: widget.userId,
        customerName: widget.user?.name ?? 'Müşteri',
        customerPhone: widget.user?.phone,
        tableNumber: tableNumber,
        requestType: type,
        message: message.isNotEmpty ? message : null,
        priority: WaiterCallPriority.normal,
        metadata: {
          'source': 'customer_home',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      _showSuccessDialog(
          'Garson çağrınız gönderildi! En kısa sürede yanınızda olacaktır.');
    } catch (e) {
      _showErrorDialog('Garson çağırma işlemi başarısız oldu: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 48,
        ),
        title: Text(
          'Başarılı',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline_rounded,
          color: AppColors.error,
          size: 48,
        ),
        title: Text(
          'Hata',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
