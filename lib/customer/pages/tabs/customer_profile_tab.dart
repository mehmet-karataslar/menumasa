import 'package:flutter/material.dart';
import '../../../business/models/business.dart';
import '../../../data/models/order.dart' as app_order;
import '../../../data/models/user.dart' as app_user;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/url_service.dart';
import '../../../core/services/multilingual_service.dart';
import '../../services/customer_firestore_service.dart';
import '../../models/language_settings.dart';
import '../customer_profile_page.dart';

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
  final MultilingualService _multilingualService = MultilingualService();

  List<app_order.Order> _orders = [];
  List<Business> _favoriteBusinesses = [];
  LanguageSettings? _languageSettings;
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

      // Dil ayarlarını yükle
      final languageSettings = await _multilingualService.getLanguageSettings(widget.userId);

      setState(() {
        _orders = orders;
        _favoriteBusinesses = favorites;
        _languageSettings = languageSettings;
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
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerProfilePage(),
      ),
    ).then((_) {
      // Profil sayfasından dönüldüğünde verileri yenile
      _handleRefresh();
    });
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
        'icon': Icons.edit_rounded,
        'title': 'Profil Düzenle',
        'subtitle': 'Kişisel bilgilerini güncelle',
        'color': AppColors.primary,
        'action': () => _navigateToProfile(),
      },
      {
        'icon': Icons.language_rounded,
        'title': 'Dil Seçimi',
        'subtitle': _languageSettings != null 
            ? 'Mevcut: ${LanguageSettings.getLanguageInfo(_languageSettings!.preferredLanguage)?.name ?? "Türkçe"}'
            : 'Menü dilini değiştirin',
        'color': AppColors.secondary,
        'action': () => _showLanguageSelection(),
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Detaylı Sipariş Geçmişi',
        'subtitle': 'Tüm siparişlerinizi görüntüleyin',
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
        'icon': Icons.location_on_rounded,
        'title': 'Konum Ayarları',
        'subtitle': 'GPS, konum servisleri ve izinler',
        'color': AppColors.warning,
        'action': () => _navigateToLocationSettings(),
      },
      {
        'icon': Icons.notifications_rounded,
        'title': 'Bildirim Ayarları',
        'subtitle': 'Bildirim tercihlerinizi yönetin',
        'color': AppColors.info,
        'action': () => _navigateToNotificationSettings(),
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'Harcama Analizi',
        'subtitle': 'Detaylı harcama raporları',
        'color': AppColors.success,
        'action': () => _navigateToSpendingAnalysis(),
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Güvenlik & Gizlilik',
        'subtitle': 'Hesap güvenliği ayarları',
        'color': AppColors.secondary,
        'action': () => _navigateToSecuritySettings(),
      },
      {
        'icon': Icons.help_rounded,
        'title': 'Yardım & Destek',
        'subtitle': 'SSS ve müşteri desteği',
        'color': AppColors.accent,
        'action': () => _showHelpDialog(),
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

  // ============================================================================
  // NAVIGATION METHODS - Ayrı sayfalar için
  // ============================================================================

  void _navigateToLocationSettings() {
    // TODO: Implement location settings page
    _showTemporaryDialog(
      'Konum Ayarları',
      '• GPS Servisleri\n• Konum Takibi\n• Yakındaki İşletmeler\n• Konum Tabanlı Teklifler\n\nBu sayfa yakında kullanıma sunulacak.',
    );
  }

  void _navigateToNotificationSettings() {
    // TODO: Implement notification settings page
    _showTemporaryDialog(
      'Bildirim Ayarları',
      '• Sipariş Bildirimleri\n• Kampanya Bildirimleri\n• Sistem Mesajları\n• E-posta Bildirimleri\n• Push Bildirimleri\n\nBu sayfa yakında kullanıma sunulacak.',
    );
  }

  void _navigateToSpendingAnalysis() {
    // TODO: Implement spending analysis page
    _showTemporaryDialog(
      'Harcama Analizi',
      '• Aylık Harcama Grafikleri\n• Kategori Bazında Analiz\n• İşletme Bazında Harcamalar\n• Harcama Trendleri\n• Bütçe Takibi\n\nBu sayfa yakında kullanıma sunulacak.',
    );
  }

  void _navigateToSecuritySettings() {
    // TODO: Implement security settings page
    _showTemporaryDialog(
      'Güvenlik & Gizlilik',
      '• Şifre Değiştirme\n• İki Faktörlü Doğrulama\n• Oturum Geçmişi\n• Gizlilik Ayarları\n• Veri İndirme\n• Hesap Silme\n\nBu sayfa yakında kullanıma sunulacak.',
    );
  }

  void _showTemporaryDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.construction_rounded,
              color: AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.help_rounded,
              color: AppColors.accent,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Yardım & Destek',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Destek Konuları:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              '• Sipariş verme ve takibi',
              '• Ödeme işlemleri',
              '• Hesap yönetimi',
              '• Teknik sorunlar',
              '• Favori işletmeler',
              '• Bildirim ayarları',
            ].map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )).toList(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'support@masamenu.com',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DIL SEÇİMİ METHODS
  // ============================================================================

  void _showLanguageSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLanguageSelectionSheet(),
    );
  }

  Widget _buildLanguageSelectionSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.language_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Dil Seçimi',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          
          // Language list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: LanguageSettings.supportedLanguages.length,
              itemBuilder: (context, index) {
                final language = LanguageSettings.supportedLanguages[index];
                final isSelected = _languageSettings?.preferredLanguage == language.code;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectLanguage(language.code),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.greyLighter,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.greyLight,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              language.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    language.name,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    language.code.toUpperCase(),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 24,
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
          
          // Auto detect toggle
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.settings_rounded, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Otomatik Dil Algılama',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                      Text(
                        'Sistem dilinize göre menü dilini otomatik seç',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _languageSettings?.autoDetectLanguage ?? true,
                  onChanged: _toggleAutoDetect,
                  activeColor: AppColors.info,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectLanguage(String languageCode) async {
    try {
      await _multilingualService.updateLanguageSettings(
        widget.userId,
        preferredLanguage: languageCode,
      );
      
      // Dil ayarlarını güncelle
      final updatedSettings = await _multilingualService.getLanguageSettings(widget.userId);
      setState(() {
        _languageSettings = updatedSettings;
      });
      
      Navigator.pop(context);
      
      // Başarı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.language_rounded, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dil ${LanguageSettings.getLanguageInfo(languageCode)?.name} olarak güncellendi',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      // Sayfayı yenile
      widget.onRefresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dil ayarı güncellenirken hata: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleAutoDetect(bool value) async {
    try {
      await _multilingualService.updateLanguageSettings(
        widget.userId,
        autoDetectLanguage: value,
      );
      
      // Dil ayarlarını güncelle
      final updatedSettings = await _multilingualService.getLanguageSettings(widget.userId);
      setState(() {
        _languageSettings = updatedSettings;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ayar güncellenirken hata: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
} 