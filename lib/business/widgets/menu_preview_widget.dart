import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/business.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../../presentation/widgets/shared/empty_state.dart';

class MenuPreviewWidget extends StatefulWidget {
  final Business business;
  final List<Category> categories;
  final List<Product> products;

  const MenuPreviewWidget({
    super.key,
    required this.business,
    required this.categories,
    required this.products,
  });

  @override
  State<MenuPreviewWidget> createState() => _MenuPreviewWidgetState();
}

class _MenuPreviewWidgetState extends State<MenuPreviewWidget> {
  String? _selectedCategoryId;
  bool _showPrices = true;
  bool _showDescriptions = true;
  String _previewMode = 'customer'; // customer, qr, print

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  List<Product> get _filteredProducts {
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      return widget.products.where((p) => p.isAvailable).toList();
    }
    return widget.products
        .where((p) => p.categoryId == _selectedCategoryId && p.isAvailable)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPreviewHeader(),
        Expanded(child: _buildPreviewContent()),
      ],
    );
  }

  Widget _buildPreviewHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menü Ön İzleme',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Menünüzün müşteri gözünden görünümü',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Görünüm ayarları
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildToggleButton(
                          'Müşteri',
                          'customer',
                          Icons.person_rounded,
                        ),
                        _buildToggleButton(
                          'QR Menü',
                          'qr',
                          Icons.qr_code_rounded,
                        ),
                        _buildToggleButton(
                          'Yazdır',
                          'print',
                          Icons.print_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Kategori filtresi ve görünüm seçenekleri
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategoryId,
                      hint: const Text('Tüm Kategoriler'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tüm Kategoriler'),
                        ),
                        ...widget.categories
                            .map((category) => DropdownMenuItem<String>(
                                  value: category.categoryId,
                                  child: Text(category.name),
                                )),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedCategoryId = value),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Görünüm seçenekleri
              Row(
                children: [
                  Tooltip(
                    message: 'Fiyatları göster/gizle',
                    child: InkWell(
                      onTap: () => setState(() => _showPrices = !_showPrices),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _showPrices
                              ? AppColors.primary.withOpacity(0.1)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.monetization_on_rounded,
                          color: _showPrices
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Açıklamaları göster/gizle',
                    child: InkWell(
                      onTap: () => setState(
                          () => _showDescriptions = !_showDescriptions),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _showDescriptions
                              ? AppColors.primary.withOpacity(0.1)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.description_rounded,
                          color: _showDescriptions
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, String mode, IconData icon) {
    final isSelected = _previewMode == mode;

    return InkWell(
      onTap: () => setState(() => _previewMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : null,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    final filteredProducts = _filteredProducts;

    if (filteredProducts.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.restaurant_menu_rounded,
          title: 'Menü boş',
          message: 'Bu kategoride henüz ürün bulunmuyor',
        ),
      );
    }

    return Container(
      color:
          _previewMode == 'print' ? AppColors.white : const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // İşletme header'ı
            _buildBusinessHeader(),

            const SizedBox(height: 32),

            // Kategoriler (eğer tümü gösteriliyorsa)
            if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty)
              ..._buildCategorySections()
            else
              _buildProductsList(filteredProducts),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _previewMode == 'print'
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Logo ve işletme adı
          if (widget.business.logoUrl != null)
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.business.logoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.restaurant_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),

          Text(
            widget.business.businessName,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          if (widget.business.businessDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.business.businessDescription,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          if (widget.business.businessAddress.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded,
                    color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.business.businessAddress,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCategorySections() {
    final sections = <Widget>[];

    for (final category in widget.categories) {
      final categoryProducts = widget.products
          .where((p) => p.categoryId == category.categoryId && p.isAvailable)
          .toList();

      if (categoryProducts.isNotEmpty) {
        sections.add(_buildCategorySection(category, categoryProducts));
        sections.add(const SizedBox(height: 32));
      }
    }

    return sections;
  }

  Widget _buildCategorySection(Category category, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategori başlığı
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            boxShadow: _previewMode == 'print'
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              if (category.imageUrl != null)
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      category.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTypography.h4.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_showDescriptions &&
                        category.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Ürünler
        _buildProductsList(products),
      ],
    );
  }

  Widget _buildProductsList(List<Product> products) {
    return Column(
      children: products
          .map((product) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _previewMode == 'print'
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ürün resmi
                    if (product.images.isNotEmpty)
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            product.images.first.url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.restaurant_menu_rounded,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Ürün bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: AppTypography.h5.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_showPrices)
                                Text(
                                  '${product.price.toStringAsFixed(0)} ₺',
                                  style: AppTypography.h5.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),

                          if (_showDescriptions &&
                              product.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              product.description,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],

                          // Allergen bilgileri
                          if (product.allergens.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: product.allergens
                                  .map((allergen) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          allergen,
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
