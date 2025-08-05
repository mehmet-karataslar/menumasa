import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';

/// Tema ayarları widget'ı
///
/// Bu widget menü teması ile ilgili ayarları yönetir:
/// - Tema seçimi (Modern, Klasik, Minimal, Elegant)
/// - Tema önizleme
/// - Hızlı tema değiştirme
class ThemeSettingsWidget extends StatefulWidget {
  final MenuSettings currentSettings;
  final Function(MenuSettings) onSettingsChanged;

  const ThemeSettingsWidget({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<ThemeSettingsWidget> createState() => _ThemeSettingsWidgetState();
}

class _ThemeSettingsWidgetState extends State<ThemeSettingsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Tema Seçimi',
              'Menünüzün genel görünümünü belirleyin',
              Icons.palette_rounded,
            ),
            const SizedBox(height: 24),

            // Tema Grid'i
            _buildThemeGrid(),
            const SizedBox(height: 32),

            // Seçilen Tema Detayları
            _buildSelectedThemeDetails(),
            const SizedBox(height: 24),

            // Hızlı Özelleştirme
            _buildQuickCustomization(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.backgroundLight
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGrid() {
    final themes = _getAvailableThemes();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isSelected = _isThemeSelected(theme);

        return _buildThemeCard(theme, isSelected);
      },
    );
  }

  Widget _buildThemeCard(Map<String, dynamic> theme, bool isSelected) {
    return GestureDetector(
      onTap: () => _applyTheme(theme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tema İkonu ve Adı
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (theme['primaryColor'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    theme['icon'] as IconData,
                    color: theme['primaryColor'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    theme['name'] as String,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Tema Açıklaması
            Text(
              theme['description'] as String,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Renk Paleti Önizleme
            Row(
              children: [
                _buildColorPreview(theme['primaryColor'] as Color),
                const SizedBox(width: 4),
                _buildColorPreview(theme['secondaryColor'] as Color),
                const SizedBox(width: 4),
                _buildColorPreview(theme['accentColor'] as Color),
                const Spacer(),
                Text(
                  theme['type'] as String,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPreview(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.greyLight.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildSelectedThemeDetails() {
    final selectedTheme = _getCurrentTheme();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selectedTheme['icon'] as IconData,
                color: selectedTheme['primaryColor'] as Color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Seçili Tema: ${selectedTheme['name']}',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            selectedTheme['longDescription'] as String,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Tema Özellikleri
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (selectedTheme['features'] as List<String>)
                .map(
                  (feature) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.greyLight),
                    ),
                    child: Text(
                      feature,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCustomization() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Özelleştirme',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickOption(
                'Koyu Tema',
                'Gece görünümü için',
                Icons.dark_mode,
                widget.currentSettings.designTheme.themeType ==
                    MenuThemeType.dark,
                (value) {
                  final newSettings = widget.currentSettings.copyWith(
                    designTheme: value
                        ? MenuDesignTheme.dark()
                        : MenuDesignTheme.modern(),
                  );
                  widget.onSettingsChanged(newSettings);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickOption(
                'Animasyonlar',
                'Geçiş efektleri',
                Icons.animation,
                widget.currentSettings.visualStyle.enableAnimations,
                (value) {
                  final newSettings = widget.currentSettings.copyWith(
                    visualStyle: widget.currentSettings.visualStyle.copyWith(
                      enableAnimations: value,
                    ),
                  );
                  widget.onSettingsChanged(newSettings);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAvailableThemes() {
    return [
      {
        'name': 'Modern',
        'description': 'Temiz ve minimalist tasarım',
        'longDescription':
            'Modern tema, temiz çizgiler ve minimal tasarım anlayışı ile çağdaş bir görünüm sağlar. Mobil dostu ve kullanıcı deneyimi odaklıdır.',
        'type': 'Popüler',
        'icon': Icons.auto_awesome,
        'primaryColor': const Color(0xFF6366F1),
        'secondaryColor': const Color(0xFF8B5CF6),
        'accentColor': const Color(0xFF06B6D4),
        'features': [
          'Minimal tasarım',
          'Hızlı yükleme',
          'Mobil uyumlu',
          'Okunabilir'
        ],
      },
      {
        'name': 'Klasik',
        'description': 'Geleneksel ve zarif görünüm',
        'longDescription':
            'Klasik tema, zamansız tasarım öğeleri ile restoranınıza sofistike bir hava katar. Özellikle fine dining işletmeleri için uygundur.',
        'type': 'Zarif',
        'icon': Icons.auto_fix_high,
        'primaryColor': const Color(0xFF7C2D12),
        'secondaryColor': const Color(0xFFA16207),
        'accentColor': const Color(0xFFDC2626),
        'features': [
          'Zarif tipografi',
          'Klasik renkler',
          'Profesyonel',
          'Güvenilir'
        ],
      },
      {
        'name': 'Minimal',
        'description': 'Sade ve odaklanmış tasarım',
        'longDescription':
            'Minimal tema, gereksiz öğeleri elimine ederek içeriğe odaklanmayı sağlar. Hızlı ve performans odaklıdır.',
        'type': 'Sade',
        'icon': Icons.remove_circle_outline,
        'primaryColor': const Color(0xFF1F2937),
        'secondaryColor': const Color(0xFF6B7280),
        'accentColor': const Color(0xFF10B981),
        'features': ['Sade tasarım', 'Hızlı yükleme', 'Az renk', 'Odaklanmış'],
      },
      {
        'name': 'Elegant',
        'description': 'Lüks ve gösterişli stil',
        'longDescription':
            'Elegant tema, lüks ve prestijli bir atmosfer yaratır. Premium işletmeler ve özel etkinlikler için idealdir.',
        'type': 'Premium',
        'icon': Icons.diamond,
        'primaryColor': const Color(0xFF7E22CE),
        'secondaryColor': const Color(0xFFBE185D),
        'accentColor': const Color(0xFFEAB308),
        'features': [
          'Lüks görünüm',
          'Altın detaylar',
          'Premium his',
          'Prestijli'
        ],
      },
      {
        'name': 'Koyu',
        'description': 'Karanlık tema ve koyu renkler',
        'longDescription':
            'Koyu tema, gözleri yormuyan karanlık renk paleti ile modern bir deneyim sunar. Gece kullanımı ve şık görünüm için idealdir.',
        'type': 'Modern',
        'icon': Icons.dark_mode,
        'primaryColor': const Color(0xFF64748B),
        'secondaryColor': const Color(0xFF94A3B8),
        'accentColor': const Color(0xFFF59E0B),
        'features': [
          'Koyu renkler',
          'Göz dostu',
          'Modern tasarım',
          'Şık görünüm'
        ],
      },
    ];
  }

  Map<String, dynamic> _getCurrentTheme() {
    final themes = _getAvailableThemes();
    // Şu anki tema ayarlarına göre en yakın temayı bul
    // Bu sadece bir örnek implementasyon, gerçek mantığı currentSettings'e göre yapılmalı
    return themes.first;
  }

  bool _isThemeSelected(Map<String, dynamic> theme) {
    // Şu anki ayarlarla tema eşleşmesini kontrol et
    return widget.currentSettings.designTheme.name == theme['name'];
  }

  void _applyTheme(Map<String, dynamic> theme) async {
    // Animasyonlu geçiş başlat
    await _animationController.reverse();

    final themeName = theme['name'] as String;
    final isThemeDark =
        themeName.toLowerCase() == 'koyu' || themeName.toLowerCase() == 'dark';

    // Dark theme için özel renk şeması
    final colorScheme = isThemeDark
        ? MenuColorScheme.dark().copyWith(
            primaryColor:
                '#${(theme['primaryColor'] as Color).value.toRadixString(16).substring(2)}',
            secondaryColor:
                '#${(theme['secondaryColor'] as Color).value.toRadixString(16).substring(2)}',
            accentColor:
                '#${(theme['accentColor'] as Color).value.toRadixString(16).substring(2)}',
          )
        : widget.currentSettings.colorScheme.copyWith(
            primaryColor:
                '#${(theme['primaryColor'] as Color).value.toRadixString(16).substring(2)}',
            secondaryColor:
                '#${(theme['secondaryColor'] as Color).value.toRadixString(16).substring(2)}',
            accentColor:
                '#${(theme['accentColor'] as Color).value.toRadixString(16).substring(2)}',
          );

    final newSettings = widget.currentSettings.copyWith(
      colorScheme: colorScheme,
      designTheme: _getThemeForName(themeName),
    );

    widget.onSettingsChanged(newSettings);

    // Animasyonu tekrar başlat
    await _animationController.forward();
  }

  MenuDesignTheme _getThemeForName(String name) {
    switch (name.toLowerCase()) {
      case 'modern':
        return MenuDesignTheme.modern();
      case 'klasik':
      case 'classic':
        return MenuDesignTheme.classic();
      case 'minimal':
        return MenuDesignTheme.minimal();
      case 'elegant':
        return MenuDesignTheme.elegant();
      case 'izgara':
      case 'grid':
        return MenuDesignTheme.grid();
      case 'dergi':
      case 'magazine':
        return MenuDesignTheme.magazine();
      case 'koyu':
      case 'dark':
        return MenuDesignTheme.dark();
      default:
        return MenuDesignTheme.modern();
    }
  }
}
