import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../business/models/business.dart';
import '../../business/models/category.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/web_safe_image.dart';

/// 📂 Menü Kategori Widget'ı
///
/// Bu widget menü sayfasının kategori bölümünü oluşturur:
/// - Instagram story tarzı kategori listeleri
/// - Kategori fotoğrafları ve isimleri
/// - Kategori seçimi ve filtresi
class MenuCategoryWidget extends StatelessWidget {
  final MenuSettings? menuSettings;
  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;
  final ScrollController? scrollController;

  const MenuCategoryWidget({
    super.key,
    this.menuSettings,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCategorySection();
  }

  Widget _buildCategorySection() {
    return Container(
          color: AppColors.white,
          padding: EdgeInsets.fromLTRB(menuSettings?.layoutStyle.padding ?? 20,
              8, menuSettings?.layoutStyle.padding ?? 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategoriler',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: menuSettings?.layoutStyle.sectionSpacing ?? 16),
              SizedBox(
                height: _getCategoryImageSize() +
                    50, // Dinamik yükseklik: resim + text + padding
                child: ListView.builder(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length + 1, // +1 "Tümü" için
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "Tümü" kategorisi
                      return _buildInstagramStoryCategoryItem(
                        categoryId: 'all',
                        name: 'Tümü',
                        isSelected: selectedCategoryId == null ||
                            selectedCategoryId == 'all',
                        icon: Icons.grid_view,
                        imageUrl: null,
                      );
                    }

                    final category = categories[index - 1];
                    return _buildInstagramStoryCategoryItem(
                      categoryId: category.categoryId,
                      name: category.name,
                      isSelected: selectedCategoryId == category.categoryId,
                      imageUrl: category.imageUrl,
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInstagramStoryCategoryItem({
    required String categoryId,
    required String name,
    required bool isSelected,
    IconData? icon,
    String? imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => onCategorySelected(categoryId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fotoğraf alanı - Instagram story tarzı yuvarlak
              Container(
                width: _getCategoryImageSize(),
                height: _getCategoryImageSize(),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.greyLight,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: ClipOval(
                  child: _buildCategoryImage(imageUrl, icon, name),
                ),
              ),
              const SizedBox(height: 8),
              // Kategori adı - akıllı satır düzeni
              SizedBox(
                width:
                    _getCategoryImageSize() + 6, // Resim boyutu + biraz padding
                child: _buildCategoryNameText(name, isSelected),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryImage(String? imageUrl, IconData? icon, String name) {
    // "Tümü" kategorisi için özel ikon
    if (icon != null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 28,
        ),
      );
    }

    // Eğer kategori fotoğrafı varsa göster
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return WebSafeImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: _getCategoryImageSize(),
        height: _getCategoryImageSize(),
        placeholder: (context, url) =>
            _buildCategoryImagePlaceholder(null, name),
        errorWidget: (context, url, error) =>
            _buildCategoryImagePlaceholder(null, name),
      );
    }

    // Varsayılan placeholder
    return _buildCategoryImagePlaceholder(_getCategoryIcon(name), name);
  }

  Widget _buildCategoryImagePlaceholder(IconData? icon, String categoryName) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? _getCategoryIcon(categoryName),
        color: AppColors.textSecondary,
        size: 28,
      ),
    );
  }

  Widget _buildCategoryNameText(String name, bool isSelected) {
    final words = name.split(' ');
    final categoryTextColor = _getCategoryTextColor(isSelected);
    final fontSize = _getCategoryFontSize();
    final fontWeight = _getCategoryFontWeight(isSelected);

    // Tek kelime ise tek satırda göster
    if (words.length == 1) {
      return Text(
        name,
        style: _buildGoogleFontTextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.2,
          color: categoryTextColor,
          fontFamily: menuSettings?.typography.fontFamily ?? 'Poppins',
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // İki kelime veya daha fazla ise alt satıra geçebilsin
    return Text(
      name,
      style: _buildGoogleFontTextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.1,
        color: categoryTextColor,
        fontFamily: menuSettings?.typography.fontFamily ?? 'Poppins',
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Kategori stil ayarları için yardımcı metodlar
  double _getCategoryImageSize() {
    return menuSettings?.typography.categoryImageSize ?? 70.0;
  }

  double _getCategoryFontSize() {
    return menuSettings?.typography.categoryFontSize ?? 12.0;
  }

  FontWeight _getCategoryFontWeight(bool isSelected) {
    final weightString = menuSettings?.typography.categoryFontWeight ?? '500';
    final baseWeight = _parseFontWeight(weightString);
    return isSelected ? FontWeight.w600 : baseWeight;
  }

  Color _getCategoryTextColor(bool isSelected) {
    if (isSelected) {
      final selectedColorString =
          menuSettings?.typography.categorySelectedTextColor ?? '#FF6B35';
      return _parseColor(selectedColorString);
    } else {
      final normalColorString =
          menuSettings?.typography.categoryTextColor ?? '#333333';
      return _parseColor(normalColorString);
    }
  }

  FontWeight _parseFontWeight(String weight) {
    switch (weight) {
      case '100':
        return FontWeight.w100;
      case '200':
        return FontWeight.w200;
      case '300':
        return FontWeight.w300;
      case '400':
        return FontWeight.w400;
      case '500':
        return FontWeight.w500;
      case '600':
        return FontWeight.w600;
      case '700':
        return FontWeight.w700;
      case '800':
        return FontWeight.w800;
      case '900':
        return FontWeight.w900;
      default:
        return FontWeight.w500;
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('çorba')) return Icons.soup_kitchen_outlined;
    if (name.contains('ana') || name.contains('yemek'))
      return Icons.restaurant_menu_outlined;
    if (name.contains('tatlı') || name.contains('desert'))
      return Icons.cake_outlined;
    if (name.contains('içecek') || name.contains('drink'))
      return Icons.local_bar_outlined;
    if (name.contains('başlangıç') || name.contains('meze'))
      return Icons.restaurant_outlined;
    if (name.contains('salata')) return Icons.eco_outlined;
    if (name.contains('pizza')) return Icons.local_pizza_outlined;
    if (name.contains('burger')) return Icons.lunch_dining_outlined;
    if (name.contains('kahve') || name.contains('coffee'))
      return Icons.local_cafe_outlined;
    return Icons.category_outlined;
  }

  TextStyle _buildGoogleFontTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required Color color,
    required String fontFamily,
  }) {
    return GoogleFonts.getFont(
      fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }

  /// Hex string'i Color'a çevir
  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }
}
