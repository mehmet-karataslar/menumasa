import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class ComingSoonFeaturesPage extends StatelessWidget {
  final String businessId;

  const ComingSoonFeaturesPage({
    super.key,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Yakında Gelecek Özellikler'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 32),
            _buildFeaturesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withBlue(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              color: AppColors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Güçlü Özellikler Geliyor!',
                  style: AppTypography.h5.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'İşletmenizi daha da güçlendirecek özellikleri en kısa sürede kullanımınıza sunacağız.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      {
        'title': 'Mutfak Entegrasyonu',
        'description': 'Mutfak ekranı ve sipariş yönetim sistemi',
        'icon': Icons.kitchen_rounded,
        'color': const Color(0xFF4E9FF7),
      },
      {
        'title': 'Teslimat Yönetimi',
        'description': 'Paket servis ve kurye takip sistemi',
        'icon': Icons.delivery_dining_rounded,
        'color': const Color(0xFF1DD1A1),
      },
      {
        'title': 'Ödeme Yönetimi',
        'description': 'Çoklu ödeme seçenekleri ve entegrasyonlar',
        'icon': Icons.payment_rounded,
        'color': const Color(0xFFFFA502),
      },
      {
        'title': 'CRM Yönetimi',
        'description': 'Müşteri ilişkileri ve sadakat programları',
        'icon': Icons.people_rounded,
        'color': const Color(0xFFFF6B6B),
      },
      {
        'title': 'Donanım Entegrasyonu',
        'description': 'POS cihazları ve yazıcı entegrasyonları',
        'icon': Icons.devices_rounded,
        'color': const Color(0xFF4ECDC4),
      },
      {
        'title': 'Şube Yönetimi',
        'description': 'Çoklu şube operasyonları ve merkezi yönetim',
        'icon': Icons.store_mall_directory_rounded,
        'color': const Color(0xFF95E1D3),
      },
      {
        'title': 'Uzaktan Erişim',
        'description': 'Bulut tabanlı uzaktan yönetim paneli',
        'icon': Icons.cloud_rounded,
        'color': const Color(0xFF74B9FF),
      },
      {
        'title': 'Yasal Uyumluluk',
        'description': 'Vergi dairesi entegrasyonu ve raporlama',
        'icon': Icons.gavel_rounded,
        'color': const Color(0xFFA29BFE),
      },
      {
        'title': 'Maliyet Kontrolü',
        'description': 'Gelir-gider analizi ve karlılık raporları',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF00B894),
      },
      {
        'title': 'AI Tahminleme',
        'description': 'Yapay zeka destekli satış ve stok tahminleri',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFFE17055),
      },
      {
        'title': 'Dijital Pazarlama',
        'description': 'Sosyal medya entegrasyonu ve kampanya yönetimi',
        'icon': Icons.campaign_rounded,
        'color': const Color(0xFFE84393),
      },
      {
        'title': 'Veri Güvenliği',
        'description': 'Gelişmiş güvenlik ve yedekleme sistemi',
        'icon': Icons.security_rounded,
        'color': const Color(0xFF2D3436),
      },
      {
        'title': 'Analitikler',
        'description': 'Detaylı raporlama ve iş zekası araçları',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFF0984E3),
      },
      {
        'title': 'Stok Yönetimi',
        'description': 'Envanter takibi ve tedarikçi yönetimi',
        'icon': Icons.inventory_rounded,
        'color': const Color(0xFF00CEC9),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(
          title: feature['title'] as String,
          description: feature['description'] as String,
          icon: feature['icon'] as IconData,
          color: feature['color'] as Color,
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Özellik hakkında daha fazla bilgi göster
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                  child: Icon(icon, color: AppColors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Yakında',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
