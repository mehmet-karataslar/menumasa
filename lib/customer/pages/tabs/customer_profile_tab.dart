import 'package:flutter/material.dart';
import '../../../business/models/business.dart';
import '../../../data/models/order.dart' as app_order;
import '../../../data/models/user.dart' as app_user;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/url_service.dart';
import '../../services/customer_firestore_service.dart';

/// Müşteri profil tab'ı
class CustomerProfileTab extends StatefulWidget {
  final String userId;
  final app_user.User? user;
  final app_user.CustomerData? customerData;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final Function(int)? onNavigateToTab;

  const CustomerProfileTab({
    super.key,
    required this.userId,
    required this.user,
    required this.customerData,
    required this.onRefresh,
    required this.onLogout,
    this.onNavigateToTab,
  });

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab> {
  final CustomerFirestoreService _customerFirestoreService = CustomerFirestoreService();
  final UrlService _urlService = UrlService();

  List<app_order.Order> _orders = [];
  List<Business> _favoriteBusinesses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Kullanıcının siparişlerini yükle
      final orders = await _customerFirestoreService.getOrdersByCustomer(widget.userId);
      
      // Favori işletmeleri yükle
      final businesses = await _customerFirestoreService.getBusinesses();
      final favoriteIds = widget.customerData?.favorites.map((f) => f.businessId).toList() ?? [];
      final favorites = businesses.where((b) => favoriteIds.contains(b.id)).toList();

      setState(() {
        _orders = orders;
        _favoriteBusinesses = favorites;
      });
    } catch (e) {
      print('Profil veri yükleme hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadProfileData();
    widget.onRefresh();
  }

  void _navigateToProfile() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/customer/${widget.userId}/profile?t=$timestamp';
    _urlService.updateCustomerUrl(widget.userId, 'profile', customTitle: 'Profilim | MasaMenu');
    
    Navigator.pushNamed(
      context,
      '/customer/profile',
      arguments: {
        'customerData': widget.customerData,
        'userId': widget.userId,
        'timestamp': timestamp,
      },
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
          children: [
            // Profil kartı
            _buildModernProfileCard(),
            
            const SizedBox(height: 24),
            
            // İstatistikler
            _buildDetailedStats(),
            
            const SizedBox(height: 24),
            
            // Menü seçenekleri
            _buildProfileMenuOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Hero(
              tag: 'customer_avatar_large',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 4),
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.secondaryLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.user?.name ?? 'Müşteri',
              style: AppTypography.h4.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.user?.email ?? '',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _navigateToProfile();
                },
                icon: Icon(Icons.edit_rounded),
                label: Text('Profili Düzenle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats() {
    final stats = widget.customerData?.stats ?? app_user.CustomerStats(
      totalOrders: 0,
      totalSpent: 0.0,
      favoriteBusinessCount: 0,
      totalVisits: 0,
      categoryPreferences: {},
      businessSpending: {},
    );

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İstatistiklerim',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSimpleStatCard(
                    title: 'Toplam Sipariş',
                    value: '${_orders.length}',
                    icon: Icons.shopping_bag_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSimpleStatCard(
                    title: 'Toplam Harcama',
                    value: '${stats.totalSpent.toStringAsFixed(0)}₺',
                    icon: Icons.payments_rounded,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSimpleStatCard(
                    title: 'Favori İşletme',
                    value: '${_favoriteBusinesses.length}',
                    icon: Icons.favorite_rounded,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSimpleStatCard(
                    title: 'Ziyaret Sayısı',
                    value: '${stats.totalVisits}',
                    icon: Icons.visibility_rounded,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuOptions() {
    final menuItems = [
      {
        'icon': Icons.dashboard_rounded,
        'title': 'Detaylı Dashboard',
        'subtitle': 'Tüm aktivitelerinizi görüntüleyin',
        'color': AppColors.primary,
        'action': () {
          // Navigate to dashboard with URL update
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _urlService.updateCustomerUrl(widget.userId, 'dashboard', customTitle: 'Ana Sayfa | MasaMenu');
          widget.onNavigateToTab?.call(0);
        },
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Sipariş Geçmişi',
        'subtitle': 'Geçmiş siparişlerinizi inceleyin',
        'color': AppColors.info,
        'action': () {
          // Navigate to orders with URL update
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _urlService.updateCustomerUrl(widget.userId, 'orders', customTitle: 'Siparişlerim | MasaMenu');
          widget.onNavigateToTab?.call(1);
        },
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Favori İşletmeler',
        'subtitle': 'Beğendiğiniz işletmeleri görün',
        'color': AppColors.accent,
        'action': () {
          // Navigate to favorites with URL update
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _urlService.updateCustomerUrl(widget.userId, 'favorites', customTitle: 'Favorilerim | MasaMenu');
          widget.onNavigateToTab?.call(2);
        },
      },
      {
        'icon': Icons.notifications_rounded,
        'title': 'Bildirimler',
        'subtitle': 'Bildirim ayarlarını düzenleyin',
        'color': AppColors.warning,
        'action': () {
          // Bildirim ayarları
          _showNotificationSettings();
        },
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Güvenlik',
        'subtitle': 'Hesap güvenliği ayarları',
        'color': AppColors.success,
        'action': () {
          // Güvenlik ayarları
          _showSecuritySettings();
        },
      },
      {
        'icon': Icons.help_rounded,
        'title': 'Yardım & Destek',
        'subtitle': 'Sık sorulan sorular ve destek',
        'color': AppColors.secondary,
        'action': () {
          // Yardım sayfası
          _showHelpDialog();
        },
      },
      {
        'icon': Icons.logout_rounded,
        'title': 'Çıkış Yap',
        'subtitle': 'Hesabınızdan güvenli çıkış yapın',
        'color': AppColors.error,
        'action': widget.onLogout,
      },
    ];

    return Container(
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
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item['action'] as VoidCallback,
                  borderRadius: BorderRadius.circular(index == 0 ? 16 : 0),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['subtitle'] as String,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (index < menuItems.length - 1)
                Divider(
                  height: 1,
                  indent: 80,
                  color: AppColors.greyLight,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bildirim Ayarları'),
        content: Text('Bildirim ayarları yakında kullanıma sunulacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Güvenlik Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Güvenlik ayarları:'),
            const SizedBox(height: 8),
            Text('• Şifre değiştirme'),
            Text('• İki faktörlü doğrulama'),
            Text('• Oturum geçmişi'),
            const SizedBox(height: 8),
            Text('Bu özellikler yakında kullanıma sunulacak.'),
          ],
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Yardım & Destek'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destek konuları:'),
            const SizedBox(height: 8),
            Text('• Sipariş verme'),
            Text('• Ödeme işlemleri'),
            Text('• Hesap yönetimi'),
            Text('• Teknik sorunlar'),
            const SizedBox(height: 16),
            Text('İletişim: support@masamenu.com'),
          ],
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