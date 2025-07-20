import 'package:flutter/material.dart';
import '../../data/models/category.dart';
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
        .where((cat) => cat.isActiveNow)
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
                    Icons.apps,
                    size: 16,
                    color: isSelected ? AppColors.white : AppColors.primary,
                  ),
                
                if (category.categoryId == 'all')
                  const SizedBox(width: 4),

                // Category name
                Text(
                  category.name,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.primary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),

                // Active indicator (for time-based categories)
                if (category.hasTimeRules && category.isActiveNow)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.white : AppColors.success,
                      shape: BoxShape.circle,
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

/// Utility extension for Category
extension CategoryListUtils on Category {
  bool get isActiveNow {
    if (!isActive) return false;
    
    if (timeRules.isEmpty) return true;
    
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final currentDay = now.weekday;
    
    return timeRules.any((rule) {
      // Check day
      if (rule.dayOfWeek != null && rule.dayOfWeek != currentDay) {
        return false;
      }
      
      // Check time range
      if (rule.startTime != null && rule.endTime != null) {
        final startTime = _parseTimeString(rule.startTime!);
        final endTime = _parseTimeString(rule.endTime!);
        final startMinutes = startTime.hour * 60 + startTime.minute;
        final endMinutes = endTime.hour * 60 + endTime.minute;
        final currentMinutes = currentTime.hour * 60 + currentTime.minute;
        
        if (startMinutes <= endMinutes) {
          // Same day time range
          return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
        } else {
          // Overnight time range
          return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
        }
      }
      
      return true;
    });
  }

  bool get hasTimeRules => timeRules.isNotEmpty;

  DateTime _parseTimeString(String timeString) {
    // Parse time string like "14:30" to DateTime
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}

/// Category filter utility
class CategoryFilter {
  static List<Category> filterActiveCategories(List<Category> categories) {
    return categories.where((category) => category.isActiveNow).toList();
  }

  static List<Category> sortCategories(List<Category> categories) {
    final sortedList = List<Category>.from(categories);
    sortedList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sortedList;
  }

  static List<Category> filterAndSort(List<Category> categories) {
    return sortCategories(filterActiveCategories(categories));
  }
}

/// Category grid widget for larger displays
class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;
  final int crossAxisCount;

  const CategoryGrid({
    Key? key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.crossAxisCount = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeCategories = CategoryFilter.filterAndSort(categories);
    final displayCategories = [_createAllCategory(), ...activeCategories];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: AppDimensions.paddingM,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: displayCategories.length,
      itemBuilder: (context, index) {
        final category = displayCategories[index];
        final isSelected = selectedCategoryId == category.categoryId ||
            (selectedCategoryId == null && category.categoryId == 'all');

        return CategoryChip(
          category: category,
          isSelected: isSelected,
          onTap: () => onCategorySelected(category.categoryId),
        );
      },
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

/// Animated category selector
class AnimatedCategorySelector extends StatefulWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;

  const AnimatedCategorySelector({
    Key? key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<AnimatedCategorySelector> createState() => _AnimatedCategorySelectorState();
}

class _AnimatedCategorySelectorState extends State<AnimatedCategorySelector>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
      child: CategoryList(
        categories: widget.categories,
        selectedCategoryId: widget.selectedCategoryId,
        onCategorySelected: widget.onCategorySelected,
      ),
    );
  }
} 