import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';

class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const FilterBottomSheet({
    Key? key,
    required this.currentFilters,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusL),
          topRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: AppDimensions.paddingM,
            child: Row(
              children: [
                Text('Filtreler', style: AppTypography.h4),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Temizle',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter content
          Flexible(
            child: SingleChildScrollView(
              padding: AppDimensions.paddingM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dietary preferences
                  _buildSectionTitle('Beslenme Tercihleri'),
                  _buildCheckboxTile('Vejetaryen', 'isVegetarian'),
                  _buildCheckboxTile('Vegan', 'isVegan'),
                  _buildCheckboxTile('Helal', 'isHalal'),
                  _buildCheckboxTile('Acılı', 'isSpicy'),

                  const SizedBox(height: 24),

                  // Price range
                  _buildSectionTitle('Fiyat Aralığı'),
                  _buildPriceRange(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: AppDimensions.paddingM,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.greyLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Uygula'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCheckboxTile(String title, String key) {
    return CheckboxListTile(
      title: Text(title),
      value: _filters[key] ?? false,
      onChanged: (value) {
        setState(() {
          _filters[key] = value;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildPriceRange() {
    final minPrice = (_filters['minPrice'] as double?) ?? 0.0;
    final maxPrice = (_filters['maxPrice'] as double?) ?? 100.0;

    return Column(
      children: [
        RangeSlider(
          values: RangeValues(minPrice, maxPrice),
          min: 0,
          max: 200,
          divisions: 20,
          labels: RangeLabels(
            '${minPrice.toStringAsFixed(0)} ₺',
            '${maxPrice.toStringAsFixed(0)} ₺',
          ),
          onChanged: (values) {
            setState(() {
              _filters['minPrice'] = values.start;
              _filters['maxPrice'] = values.end;
            });
          },
          activeColor: AppColors.primary,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${minPrice.toStringAsFixed(0)} ₺',
                style: AppTypography.bodyMedium,
              ),
              Text(
                '${maxPrice.toStringAsFixed(0)} ₺',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _filters.clear();
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.pop(context);
  }
} 