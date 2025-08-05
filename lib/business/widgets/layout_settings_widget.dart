import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';

/// Layout ayarları widget'ı
///
/// Bu widget menü düzeni ile ilgili ayarları yönetir:
/// - Layout tipi (Grid, Liste, Masonry, Carousel)
/// - Kolon sayısı
/// - Görüntüleme seçenekleri
/// - Layout önizleme
class LayoutSettingsWidget extends StatelessWidget {
  final MenuSettings currentSettings;
  final Function(MenuSettings) onSettingsChanged;

  const LayoutSettingsWidget({
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
            'Layout Ayarları',
            'Menünüzün düzenini özelleştirin',
            Icons.dashboard_rounded,
          ),
          const SizedBox(height: 24),

          // Layout Tip Seçimi
          _buildLayoutTypeSelection(),
          const SizedBox(height: 24),

          // Kolon Ayarları (Grid için)
          if (_isGridLayout()) ...[
            _buildColumnSettings(),
            const SizedBox(height: 24),
          ],

          // Kart Boyutu Ayarları
          _buildCardSizeSettings(),
          const SizedBox(height: 24),

          // Görüntüleme Seçenekleri
          _buildDisplayOptions(),
          const SizedBox(height: 24),

          // Layout Önizlemesi
          _buildLayoutPreview(),
        ],
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

  Widget _buildLayoutTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layout Tipi',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Menü öğelerinin nasıl gösterileceğini seçin',
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: _getLayoutTypes()
              .map(
                (layout) => _buildLayoutTypeCard(layout),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLayoutTypeCard(Map<String, dynamic> layout) {
    final isSelected =
        currentSettings.layoutStyle.layoutType.toString().split('.').last ==
            layout['type'];

    return GestureDetector(
      onTap: () => _selectLayoutType(layout['type'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // Layout İkonu
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.greyLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                layout['icon'] as IconData,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),

            const SizedBox(height: 12),

            // Layout Adı
            Text(
              layout['name'] as String,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // Layout Açıklaması
            Text(
              layout['description'] as String,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kolon Sayısı',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Grid görünümünde kaç kolon gösterileceğini ayarlayın',
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Text(
              'Kolon Sayısı: ${currentSettings.layoutStyle.columnsCount}',
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              '1',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            Expanded(
              flex: 3,
              child: Slider(
                value: currentSettings.layoutStyle.columnsCount.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                onChanged: (value) {
                  final newSettings = currentSettings.copyWith(
                    layoutStyle: currentSettings.layoutStyle.copyWith(
                      columnsCount: value.toInt(),
                    ),
                  );
                  onSettingsChanged(newSettings);
                },
              ),
            ),
            Text(
              '4',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Kolon Önizlemesi
        Container(
          height: 60,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: Row(
            children: List.generate(
              currentSettings.layoutStyle.columnsCount,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < currentSettings.layoutStyle.columnsCount - 1
                        ? 4
                        : 0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görüntüleme Seçenekleri',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Gösterme/Gizleme Seçenekleri
        _buildDisplayOption(
          'Fiyatları Göster',
          'Ürün fiyatlarını menüde göster',
          Icons.attach_money,
          currentSettings.showPrices,
          (value) {
            final newSettings = currentSettings.copyWith(showPrices: value);
            onSettingsChanged(newSettings);
          },
        ),

        const SizedBox(height: 12),

        _buildDisplayOption(
          'Açıklamaları Göster',
          'Ürün açıklamalarını göster',
          Icons.description,
          currentSettings.showDescriptions,
          (value) {
            final newSettings =
                currentSettings.copyWith(showDescriptions: value);
            onSettingsChanged(newSettings);
          },
        ),

        const SizedBox(height: 12),

        _buildDisplayOption(
          'Resimleri Göster',
          'Ürün resimlerini göster',
          Icons.image,
          currentSettings.showImages,
          (value) {
            final newSettings = currentSettings.copyWith(showImages: value);
            onSettingsChanged(newSettings);
          },
        ),

        const SizedBox(height: 12),

        _buildDisplayOption(
          'Alerjen Bilgilerini Göster',
          'Ürün alerjen uyarılarını göster',
          Icons.warning,
          currentSettings.showAllergens,
          (value) {
            final newSettings = currentSettings.copyWith(showAllergens: value);
            onSettingsChanged(newSettings);
          },
        ),
      ],
    );
  }

  Widget _buildDisplayOption(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layout Önizlemesi',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: _buildPreviewContent(),
        ),
      ],
    );
  }

  Widget _buildPreviewContent() {
    final layoutType = currentSettings.layoutStyle.layoutType;

    switch (layoutType) {
      case MenuLayoutType.grid:
        return _buildGridPreview();
      case MenuLayoutType.list:
        return _buildListPreview();
      case MenuLayoutType.masonry:
        return _buildMasonryPreview();
      case MenuLayoutType.carousel:
        return _buildCarouselPreview();
      default:
        return _buildGridPreview();
    }
  }

  Widget _buildGridPreview() {
    return GridView.count(
      crossAxisCount: currentSettings.layoutStyle.columnsCount,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: List.generate(
        6,
        (index) => Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: Column(
            children: [
              if (currentSettings.showImages)
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.fastfood,
                        color: AppColors.primary.withOpacity(0.5),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (currentSettings.showPrices)
                        Container(
                          height: 6,
                          width: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListPreview() {
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Container(
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: Row(
          children: [
            if (currentSettings.showImages)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.fastfood,
                  color: AppColors.primary.withOpacity(0.5),
                  size: 12,
                ),
              ),
            if (currentSettings.showImages) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (currentSettings.showPrices)
              Container(
                width: 30,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasonryPreview() {
    return _buildGridPreview(); // Basit bir örnek için grid preview kullan
  }

  Widget _buildCarouselPreview() {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: Column(
              children: [
                if (currentSettings.showImages)
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.fastfood,
                          color: AppColors.primary.withOpacity(0.5),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (currentSettings.showPrices)
                          Container(
                            height: 6,
                            width: 30,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
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

  List<Map<String, dynamic>> _getLayoutTypes() {
    return [
      {
        'type': 'grid',
        'name': 'Grid',
        'description': 'Düzenli ızgara görünümü',
        'icon': Icons.grid_view,
      },
      {
        'type': 'list',
        'name': 'Liste',
        'description': 'Dikey liste görünümü',
        'icon': Icons.list,
      },
      {
        'type': 'masonry',
        'name': 'Masonry',
        'description': 'Değişken yükseklik',
        'icon': Icons.view_quilt,
      },
      {
        'type': 'carousel',
        'name': 'Carousel',
        'description': 'Yatay kaydırmalı',
        'icon': Icons.view_carousel,
      },
      {
        'type': 'staggered',
        'name': 'Zigzag',
        'description': 'Zigzag düzen',
        'icon': Icons.view_comfy,
      },
      {
        'type': 'waterfall',
        'name': 'Şelale',
        'description': 'Pinterest tarzı',
        'icon': Icons.water_drop,
      },
      {
        'type': 'magazine',
        'name': 'Dergi',
        'description': 'Dergi sayfa düzeni',
        'icon': Icons.book_outlined,
      },
    ];
  }

  bool _isGridLayout() {
    return currentSettings.layoutStyle.layoutType == MenuLayoutType.grid ||
        currentSettings.layoutStyle.layoutType == MenuLayoutType.masonry;
  }

  void _selectLayoutType(String type) {
    MenuLayoutType layoutType;
    switch (type) {
      case 'grid':
        layoutType = MenuLayoutType.grid;
        break;
      case 'list':
        layoutType = MenuLayoutType.list;
        break;
      case 'masonry':
        layoutType = MenuLayoutType.masonry;
        break;
      case 'carousel':
        layoutType = MenuLayoutType.carousel;
        break;
      case 'staggered':
        layoutType = MenuLayoutType.staggered;
        break;
      case 'waterfall':
        layoutType = MenuLayoutType.waterfall;
        break;
      case 'magazine':
        layoutType = MenuLayoutType.magazine;
        break;
      default:
        layoutType = MenuLayoutType.grid;
    }

    final newSettings = currentSettings.copyWith(
      layoutStyle: currentSettings.layoutStyle.copyWith(
        layoutType: layoutType,
      ),
    );

    onSettingsChanged(newSettings);
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required Widget child,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCardSizeSettings() {
    return _buildSettingsCard(
      title: 'Kart Boyutu',
      subtitle: 'Ürün kartlarının boyutunu ayarlayın',
      child: Column(
        children: [
          // Kart boyutu seçenekleri
          ...MenuCardSize.values.map((size) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: RadioListTile<MenuCardSize>(
                title: Text(
                  size.displayName,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Ölçek: ${size.scale}x',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                value: size,
                groupValue: currentSettings.layoutStyle.cardSize,
                onChanged: (MenuCardSize? newSize) {
                  if (newSize != null) {
                    _updateCardSize(newSize);
                  }
                },
                activeColor: AppColors.primary,
                dense: true,
              ),
            );
          }).toList(),

          const SizedBox(height: 16),

          // Kart aspect ratio slider
          _buildSliderSetting(
            title: 'Kart En/Boy Oranı',
            value: currentSettings.layoutStyle.cardAspectRatio,
            min: 0.5,
            max: 1.5,
            divisions: 20,
            onChanged: (value) {
              _updateCardAspectRatio(value);
            },
            format: (value) => '${value.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  void _updateCardSize(MenuCardSize cardSize) {
    final newSettings = currentSettings.copyWith(
      layoutStyle: currentSettings.layoutStyle.copyWith(
        cardSize: cardSize,
      ),
    );
    onSettingsChanged(newSettings);
  }

  void _updateCardAspectRatio(double aspectRatio) {
    final newSettings = currentSettings.copyWith(
      layoutStyle: currentSettings.layoutStyle.copyWith(
        cardAspectRatio: aspectRatio,
      ),
    );
    onSettingsChanged(newSettings);
  }

  Widget _buildSliderSetting({
    required String title,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required Function(double) onChanged,
    required String Function(double) format,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                format(value),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) => SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.3),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
              valueIndicatorColor: AppColors.primary,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
