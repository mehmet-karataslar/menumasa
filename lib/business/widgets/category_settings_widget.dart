import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';

/// Kategori ayarları widget'ı
/// 
/// Bu widget kategori görünümü ile ilgili tüm ayarları yönetir:
/// - Kategori düzeni (Instagram story, yatay liste)
/// - Yazı ayarları (boyut, kalınlık)
/// - Renk ayarları (normal ve seçili yazı renkleri)
/// - Görsel ayarları (fotoğraf gösterimi ve boyutu)
/// - Önizleme
class CategorySettingsWidget extends StatelessWidget {
  final MenuSettings currentSettings;
  final Function(MenuSettings) onSettingsChanged;

  const CategorySettingsWidget({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Kategori Ayarları',
            'Kategorilerinizin görünümünü özelleştirin',
            Icons.category_rounded,
          ),
          const SizedBox(height: 24),

          // Kategori Layout Seçimi
          _buildCategoryLayoutSection(),
          const SizedBox(height: 24),

          // Kategori Yazı Ayarları
          _buildCategoryTextSettings(),
          const SizedBox(height: 24),

          // Kategori Renk Ayarları
          _buildCategoryColorSettings(),
          const SizedBox(height: 24),

          // Kategori Görsel Ayarları
          _buildCategoryVisualSettings(),
          const SizedBox(height: 32),

          // Kategori Önizleme
          _buildCategoryPreview(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.backgroundLight],
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

  Widget _buildCategoryLayoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Düzeni',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Kategorilerinizin nasıl görüneceğini seçin',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildLayoutOption(
                'story',
                'Instagram Story',
                'Yuvarlak fotoğraf + alt yazı',
                Icons.account_circle,
                currentSettings.typography.categoryLayout == 'story',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLayoutOption(
                'horizontal',
                'Yatay Liste',
                'Yan yana dikdörtgen',
                Icons.view_list,
                currentSettings.typography.categoryLayout == 'horizontal',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLayoutOption(String value, String title, String description, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        final newSettings = currentSettings.copyWith(
          typography: currentSettings.typography.copyWith(
            categoryLayout: value,
          ),
        );
        onSettingsChanged(newSettings);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTextSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yazı Ayarları',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Font Size
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yazı Boyutu: ${currentSettings.typography.categoryFontSize.toInt()}px',
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Slider(
              value: currentSettings.typography.categoryFontSize,
              min: 8.0,
              max: 20.0,
              divisions: 12,
              onChanged: (value) {
                final newSettings = currentSettings.copyWith(
                  typography: currentSettings.typography.copyWith(
                    categoryFontSize: value,
                  ),
                );
                onSettingsChanged(newSettings);
              },
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Font Weight
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yazı Kalınlığı',
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: currentSettings.typography.categoryFontWeight,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: '300', child: Text('İnce')),
                DropdownMenuItem(value: '400', child: Text('Normal')),
                DropdownMenuItem(value: '500', child: Text('Orta')),
                DropdownMenuItem(value: '600', child: Text('Kalın')),
                DropdownMenuItem(value: '700', child: Text('Çok Kalın')),
              ],
              onChanged: (value) {
                if (value != null) {
                  final newSettings = currentSettings.copyWith(
                    typography: currentSettings.typography.copyWith(
                      categoryFontWeight: value,
                    ),
                  );
                  onSettingsChanged(newSettings);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryColorSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Renk Ayarları',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Normal Text Color
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Normal Yazı Rengi',
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: _parseColor(currentSettings.typography.categoryTextColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: Center(
                child: Text(
                  currentSettings.typography.categoryTextColor,
                  style: TextStyle(
                    color: _parseColor(currentSettings.typography.categoryTextColor).computeLuminance() > 0.5 
                        ? Colors.black 
                        : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Selected Text Color
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seçili Yazı Rengi',
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: _parseColor(currentSettings.typography.categorySelectedTextColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: Center(
                child: Text(
                  currentSettings.typography.categorySelectedTextColor,
                  style: TextStyle(
                    color: _parseColor(currentSettings.typography.categorySelectedTextColor).computeLuminance() > 0.5 
                        ? Colors.black 
                        : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryVisualSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görsel Ayarları',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Show Category Images
        SwitchListTile(
          title: const Text('Kategori Fotoğrafları'),
          subtitle: const Text('Kategori fotoğraflarını göster'),
          value: currentSettings.typography.showCategoryImages,
          onChanged: (value) {
            final newSettings = currentSettings.copyWith(
              typography: currentSettings.typography.copyWith(
                showCategoryImages: value,
              ),
            );
            onSettingsChanged(newSettings);
          },
        ),
        
        if (currentSettings.typography.showCategoryImages) ...[
          const SizedBox(height: 16),
          
          // Image Size
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fotoğraf Boyutu: ${currentSettings.typography.categoryImageSize.toInt()}px',
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Slider(
                value: currentSettings.typography.categoryImageSize,
                min: 50.0,
                max: 100.0,
                divisions: 10,
                onChanged: (value) {
                  final newSettings = currentSettings.copyWith(
                    typography: currentSettings.typography.copyWith(
                      categoryImageSize: value,
                    ),
                  );
                  onSettingsChanged(newSettings);
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Önizleme',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: SizedBox(
            height: currentSettings.typography.categoryImageSize + 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildPreviewCategoryItem('Tümü', true, Icons.apps),
                _buildPreviewCategoryItem('Ana Yemekler', false, Icons.restaurant_menu),
                _buildPreviewCategoryItem('Tatlılar', false, Icons.cake),
                _buildPreviewCategoryItem('İçecekler', false, Icons.local_bar),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCategoryItem(String name, bool isSelected, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentSettings.typography.showCategoryImages)
            Container(
              width: currentSettings.typography.categoryImageSize,
              height: currentSettings.typography.categoryImageSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected 
                    ? _parseColor(currentSettings.typography.categorySelectedTextColor).withOpacity(0.1)
                    : AppColors.greyLight.withOpacity(0.3),
                border: Border.all(
                  color: isSelected 
                      ? _parseColor(currentSettings.typography.categorySelectedTextColor)
                      : AppColors.greyLight,
                  width: isSelected ? 3 : 2,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? _parseColor(currentSettings.typography.categorySelectedTextColor)
                    : AppColors.textSecondary,
                size: currentSettings.typography.categoryImageSize * 0.4,
              ),
            ),
          
          if (currentSettings.typography.showCategoryImages)
            const SizedBox(height: 8),
          
          SizedBox(
            width: currentSettings.typography.categoryImageSize + 6,
            child: Text(
              name,
              style: TextStyle(
                fontSize: currentSettings.typography.categoryFontSize,
                fontWeight: _parseFontWeightFromString(currentSettings.typography.categoryFontWeight),
                color: isSelected 
                    ? _parseColor(currentSettings.typography.categorySelectedTextColor)
                    : _parseColor(currentSettings.typography.categoryTextColor),
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Hex string'i Color'a çevir
  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary; // Fallback color
    }
  }

  FontWeight _parseFontWeightFromString(String weight) {
    switch (weight) {
      case '300': return FontWeight.w300;
      case '400': return FontWeight.w400;
      case '500': return FontWeight.w500;
      case '600': return FontWeight.w600;
      case '700': return FontWeight.w700;
      default: return FontWeight.w500;
    }
  }
}