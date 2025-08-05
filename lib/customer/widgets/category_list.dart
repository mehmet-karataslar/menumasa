import 'package:flutter/material.dart';
import '../../business/models/category.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/web_safe_image.dart';

class CategoryList extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;
  final bool showAll;

  const CategoryList({
    Key? key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.showAll = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Aktif kategorileri filtrele ve sortOrder'a göre sırala
    final activeCategories = categories.where((cat) => cat.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // "Tümü" seçeneğini ekle
    final displayCategories = showAll
        ? [_createAllCategory(), ...activeCategories]
        : activeCategories;

    return Container(
      height: 120, // Instagram story tarzı için yüksekliği artırdık
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppDimensions.paddingHorizontalM,
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          final isSelected = selectedCategoryId == category.categoryId ||
              (selectedCategoryId == null && category.categoryId == 'all');

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InstagramStoryCategoryItem(
              category: category,
              isSelected: isSelected,
              onTap: () => onCategorySelected(category.categoryId),
            ),
          );
        },
      ),
    );
  }

  Category _createAllCategory() {
    return Category(
      categoryId: 'all',
      businessId: '',
      name: 'Tümü',
      description: 'Tüm ürünler',
      sortOrder: -1,
      isActive: true,
      timeRules: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

// Instagram Story tarzı kategori widget'ı
class InstagramStoryCategoryItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const InstagramStoryCategoryItem({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fotoğraf alanı - Instagram story tarzı yuvarlak
            Container(
              width: 70,
              height: 70,
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
                child: _buildCategoryImage(),
              ),
            ),
            const SizedBox(height: 8),
            // Kategori adı - akıllı satır düzeni
            SizedBox(
              width: 76,
              child: _buildCategoryNameText(category.name, isSelected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage() {
    // "Tümü" kategorisi için özel ikon
    if (category.categoryId == 'all') {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.grid_view,
          color: AppColors.primary,
          size: 28,
        ),
      );
    }

    // Eğer kategori fotoğrafı varsa göster
    if (category.imageUrl != null && category.imageUrl!.isNotEmpty) {
      return WebSafeImage(
        imageUrl: category.imageUrl!,
        fit: BoxFit.cover,
        width: 70,
        height: 70,
        placeholder: (context, url) => _buildImagePlaceholder(),
        errorWidget: (context, url, error) => _buildImagePlaceholder(),
      );
    }

    // Varsayılan placeholder
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getCategoryIcon(category.name),
        color: AppColors.textSecondary,
        size: 28,
      ),
    );
  }

  Widget _buildCategoryNameText(String name, bool isSelected) {
    final words = name.split(' ');

    // Tek kelime ise tek satırda göster
    if (words.length == 1) {
      return Text(
        name,
        style: AppTypography.bodySmall.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // İki kelime veya daha fazla ise alt satıra geçebilsin
    return Text(
      name,
      style: AppTypography.bodySmall.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12,
        height: 1.1,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
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
}

// Eski CategoryChip widget'ını geriye uyumluluk için tutuyoruz
class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.greyLight,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category icon (if it's the "All" category)
                if (category.categoryId == 'all')
                  Icon(
                    Icons.grid_view,
                    size: 16,
                    color:
                        isSelected ? AppColors.white : AppColors.textSecondary,
                  ),

                if (category.categoryId == 'all') const SizedBox(width: 6),

                // Category name
                Text(
                  category.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

// Vertical category list for better organization
class VerticalCategoryList extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;

  const VerticalCategoryList({
    Key? key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeCategories = categories.where((cat) => cat.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeCategories.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final category = activeCategories[index];
        final isSelected = selectedCategoryId == category.categoryId;

        return ListTile(
          title: Text(
            category.name,
            style: AppTypography.bodyLarge.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          subtitle: category.description.isNotEmpty
              ? Text(
                  category.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: AppColors.primary)
              : null,
          onTap: () => onCategorySelected(category.categoryId),
          selected: isSelected,
          selectedTileColor: AppColors.primary.withOpacity(0.1),
        );
      },
    );
  }
}

// Expandable category tree for hierarchical categories
class CategoryTree extends StatefulWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;

  const CategoryTree({
    Key? key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategoryTree> createState() => _CategoryTreeState();
}

class _CategoryTreeState extends State<CategoryTree> {
  final Set<String> _expandedCategories = {};

  @override
  Widget build(BuildContext context) {
    final mainCategories = widget.categories
        .where((cat) => cat.parentCategoryId == null && cat.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mainCategories.length,
      itemBuilder: (context, index) {
        final category = mainCategories[index];
        final subCategories = widget.categories
            .where((cat) =>
                cat.parentCategoryId == category.categoryId && cat.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final hasSubCategories = subCategories.isNotEmpty;
        final isExpanded = _expandedCategories.contains(category.categoryId);
        final isSelected = widget.selectedCategoryId == category.categoryId;

        return Column(
          children: [
            ListTile(
              title: Text(
                category.name,
                style: AppTypography.bodyLarge.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: category.description.isNotEmpty
                  ? Text(
                      category.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
              leading: hasSubCategories
                  ? IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedCategories.remove(category.categoryId);
                          } else {
                            _expandedCategories.add(category.categoryId);
                          }
                        });
                      },
                    )
                  : null,
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () => widget.onCategorySelected(category.categoryId),
              selected: isSelected,
              selectedTileColor: AppColors.primary.withOpacity(0.1),
            ),

            // Sub categories
            if (hasSubCategories && isExpanded)
              ...subCategories.map((subCategory) {
                final isSubSelected =
                    widget.selectedCategoryId == subCategory.categoryId;

                return Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: ListTile(
                    title: Text(
                      subCategory.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSubSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight:
                            isSubSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    subtitle: subCategory.description.isNotEmpty
                        ? Text(
                            subCategory.description,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    trailing: isSubSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () =>
                        widget.onCategorySelected(subCategory.categoryId),
                    selected: isSubSelected,
                    selectedTileColor: AppColors.primary.withOpacity(0.1),
                  ),
                );
              }).toList(),
          ],
        );
      },
    );
  }
}
