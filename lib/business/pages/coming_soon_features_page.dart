import 'dart:ui' show ImageFilter;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isWeb),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 40 : (isTablet ? 32 : 20),
                vertical: 20,
              ),
              child: Column(
                children: [
                  _buildHeroSection(isWeb, isTablet),
                  SizedBox(height: isWeb ? 60 : 40),
                  _buildFeaturesSection(context, isWeb, isTablet),
                  SizedBox(height: isWeb ? 80 : 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isWeb) {
    return SliverAppBar(
      expandedHeight: isWeb ? 200 : 120,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withBlue(200),
                AppColors.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Yakında Gelecek Özellikler',
          style: AppTypography.h5.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon:
                Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isWeb, bool isTablet) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
      padding: EdgeInsets.all(isWeb ? 40 : (isTablet ? 32 : 24)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF8FAFC),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: isWeb
          ? Row(
        children: [
          Expanded(flex: 3, child: _buildHeroContent(isWeb)),
          const SizedBox(width: 40),
          Expanded(flex: 2, child: _buildHeroAnimation()),
        ],
      )
          : Column(
        children: [
          _buildHeroContent(isWeb),
          const SizedBox(height: 24),
          _buildHeroAnimation(),
        ],
      ),
    );
  }

  Widget _buildHeroContent(bool isWeb) {
    return Column(
      crossAxisAlignment: isWeb ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'YENİ ÖZELLİKLER',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Güçlü Özellikler\nGeliyor!',
          style: AppTypography.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.5,
          ),
          textAlign: isWeb ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'İşletmenizi daha da güçlendirecek özellikleri en kısa sürede kullanımınıza sunacağız. Modern teknoloji ile işinizi kolaylaştıracak çözümler geliştiriyoruz.',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
            letterSpacing: 0.2,
          ),
          textAlign: isWeb ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '14 Güçlü Özellik Yakında',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroAnimation() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.trending_up_rounded,
                color: AppColors.primary,
                size: 35,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withBlue(180)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isWeb, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    if (isWeb) {
      crossAxisCount = screenWidth > 1400 ? 4 : 3;
    } else if (isTablet) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    final features = [
      {
        'title': 'Mutfak Entegrasyonu',
        'description': 'Mutfak ekranı ve sipariş yönetim sistemi',
        'icon': Icons.kitchen_rounded,
        'gradient': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      },
      {
        'title': 'Teslimat Yönetimi',
        'description': 'Paket servis ve kurye takip sistemi',
        'icon': Icons.delivery_dining_rounded,
        'gradient': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      },
      {
        'title': 'Ödeme Yönetimi',
        'description': 'Çoklu ödeme seçenekleri ve entegrasyonlar',
        'icon': Icons.payment_rounded,
        'gradient': [const Color(0xFFFFB75E), const Color(0xFFED8F03)],
      },
      {
        'title': 'CRM Yönetimi',
        'description': 'Müşteri ilişkileri ve sadakat programları',
        'icon': Icons.people_rounded,
        'gradient': [const Color(0xFFFF758C), const Color(0xFFFF7EB3)],
      },
      {
        'title': 'Donanım Entegrasyonu',
        'description': 'POS cihazları ve yazıcı entegrasyonları',
        'icon': Icons.devices_rounded,
        'gradient': [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      },
      {
        'title': 'Şube Yönetimi',
        'description': 'Çoklu şube operasyonları ve merkezi yönetim',
        'icon': Icons.store_mall_directory_rounded,
        'gradient': [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      },
      {
        'title': 'Uzaktan Erişim',
        'description': 'Bulut tabanlı uzaktan yönetim paneli',
        'icon': Icons.cloud_rounded,
        'gradient': [const Color(0xFF6A82FB), const Color(0xFFFC5C7D)],
      },
      {
        'title': 'Yasal Uyumluluk',
        'description': 'Vergi dairesi entegrasyonu ve raporlama',
        'icon': Icons.gavel_rounded,
        'gradient': [const Color(0xFFA8EDEA), const Color(0xFFFED6E3)],
      },
      {
        'title': 'Maliyet Kontrolü',
        'description': 'Gelir-gider analizi ve karlılık raporları',
        'icon': Icons.trending_up_rounded,
        'gradient': [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
      },
      {
        'title': 'AI Tahminleme',
        'description': 'Yapay zeka destekli satış ve stok tahminleri',
        'icon': Icons.psychology_rounded,
        'gradient': [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      },
      {
        'title': 'Dijital Pazarlama',
        'description': 'Sosyal medya entegrasyonu ve kampanya yönetimi',
        'icon': Icons.campaign_rounded,
        'gradient': [const Color(0xFFE100FF), const Color(0xFF7F00FF)],
      },
      {
        'title': 'Veri Güvenliği',
        'description': 'Gelişmiş güvenlik ve yedekleme sistemi',
        'icon': Icons.security_rounded,
        'gradient': [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
      },
      {
        'title': 'Analitikler',
        'description': 'Detaylı raporlama ve iş zekası araçları',
        'icon': Icons.analytics_rounded,
        'gradient': [const Color(0xFF0F4C75), const Color(0xFF3282B8)],
      },
      {
        'title': 'Stok Yönetimi',
        'description': 'Envanter takibi ve tedarikçi yönetimi',
        'icon': Icons.inventory_rounded,
        'gradient': [const Color(0xFF00D2FF), const Color(0xFF3A7BD5)],
      },
    ];

    return Container(
      constraints: BoxConstraints(maxWidth: isWeb ? 1400 : double.infinity),
      child: Column(
        children: [
          Text(
            'Planlanan Özellikler',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'İşletmenizi geleceğe taşıyacak özellikler',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isWeb ? 24 : 16,
              mainAxisSpacing: isWeb ? 24 : 16,
              childAspectRatio: isWeb ? 1.1 : 0.75,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return _buildFeatureCard(
                title: feature['title'] as String,
                description: feature['description'] as String,
                icon: feature['icon'] as IconData,
                gradient: feature['gradient'] as List<Color>,
                isWeb: isWeb,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradient,
    required bool isWeb,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(isWeb ? 28 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isWeb ? 75 : 65,
                  height: isWeb ? 75 : 65,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isWeb ? 36 : 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                    fontSize: isWeb ? 18 : 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      letterSpacing: 0.1,
                      fontSize: isWeb ? 15 : 14,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradient[0].withOpacity(0.1),
                        gradient[1].withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: gradient[0].withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: gradient[0],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Yakında',
                        style: TextStyle(
                          color: gradient[0],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
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