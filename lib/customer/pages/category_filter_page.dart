import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/category.dart';
import '../../../data/models/business.dart';

import '../../presentation/widgets/shared/empty_state.dart';
import 'business_detail_page.dart';

class CategoryFilterPage extends StatefulWidget {
  final List<Category> categories;
  final List<Business> businesses;

  const CategoryFilterPage({
    super.key,
    required this.categories,
    required this.businesses,
  });

  @override
  State<CategoryFilterPage> createState() => _CategoryFilterPageState();
}

class _CategoryFilterPageState extends State<CategoryFilterPage> {
  String _selectedCategory = 'Tümü';
  List<Business> _filteredBusinesses = [];

  @override
  void initState() {
    super.initState();
    _filteredBusinesses = widget.businesses;
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'Tümü') {
        _filteredBusinesses = widget.businesses;
      } else {
        _filteredBusinesses = widget.businesses
            .where((business) => business.businessType == category)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Kategori Filtrele'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Kategori seçimi
          _buildCategorySelector(),
          
          // İşletme listesi
          Expanded(
            child: _buildBusinessList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final allCategories = ['Tümü', ...widget.categories.map((c) => c.name)];

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Seçin',
            style: AppTypography.h5.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allCategories.map((category) {
              final isSelected = category == _selectedCategory;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _filterByCategory(category);
                  }
                },
                backgroundColor: AppColors.greyLighter,
                selectedColor: AppColors.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessList() {
    if (_filteredBusinesses.isEmpty) {
      return const EmptyState(
        icon: Icons.store,
        title: 'İşletme bulunamadı',
        message: 'Seçilen kategoride işletme bulunmuyor',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBusinesses.length,
      itemBuilder: (context, index) {
        return _buildBusinessCard(_filteredBusinesses[index]);
      },
    );
  }

  Widget _buildBusinessCard(Business business) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessDetailPage(
                business: business,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // İşletme resmi
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: business.logoUrl != null
                    ? Image.network(
                        business.logoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: AppColors.greyLighter,
                            child: const Icon(
                              Icons.store,
                              color: AppColors.greyLight,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.greyLighter,
                        child: const Icon(
                          Icons.store,
                          color: AppColors.greyLight,
                        ),
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // İşletme bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.businessName,
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business.businessType,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      business.businessDescription,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            business.businessAddress,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Durum
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: business.isOpen
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      business.isOpen ? 'Açık' : 'Kapalı',
                      style: AppTypography.caption.copyWith(
                        color: business.isOpen
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 