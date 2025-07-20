import 'package:flutter/material.dart';
import '../../business/models/category.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';

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
    // Aktif kategorileri filtrele
    final activeCategories = categories
        .where((cat) => cat.isActive)
        .toList();

    // "Tümü" seçeneğini ekle
    final displayCategories = showAll
        ? [_createAllCategory(), ...activeCategories]
        : activeCategories;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppDimensions.paddingHorizontalM,
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          final isSelected =
              selectedCategoryId == category.categoryId ||
              (selectedCategoryId == null && category.categoryId == 'all');

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CategoryChip(
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
                    color: isSelected
                        ? AppColors.white
                        : AppColors.textSecondary,
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
    final activeCategories = categories
        .where((cat) => cat.isActive)
        .toList();

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
    final mainCategories =
        widget.categories
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
            .where((cat) => cat.parentCategoryId == category.categoryId && cat.isActive)
            .toList();
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
                        fontWeight: isSubSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
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
