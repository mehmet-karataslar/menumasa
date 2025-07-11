import 'package:flutter/material.dart';
// CachedNetworkImage removed for Windows compatibility
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/product.dart';
import '../../../data/models/business.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final Business business;

  const ProductDetailPage({
    Key? key,
    required this.product,
    required this.business,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildProductDetails()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: AppColors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: AppColors.white),
          onPressed: _onSharePressed,
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border, color: AppColors.white),
          onPressed: _onFavoritePressed,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(background: _buildImageCarousel()),
    );
  }

  Widget _buildImageCarousel() {
    final images = widget.product.images;

    if (images.isEmpty) {
      return _buildPlaceholderImage();
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              images[index].url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: LoadingIndicator());
              },
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholderImage(),
            );
          },
        ),

        // Image indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? AppColors.white
                        : AppColors.white.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ),

        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.lightGrey,
      child: const Icon(
        Icons.restaurant_menu,
        size: 64,
        color: AppColors.textLight,
      ),
    );
  }

  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product header
        _buildProductHeader(),

        // Product description
        _buildProductDescription(),

        // Nutrition & Allergens
        _buildNutritionAndAllergens(),

        // Product features
        _buildProductFeatures(),

        // Similar products (placeholder)
        _buildSimilarProducts(),

        // Extra space for bottom bar
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildProductHeader() {
    return Container(
      padding: AppDimensions.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name and badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(widget.product.name, style: AppTypography.h2),
              ),
              const SizedBox(width: 8),
              _buildProductBadges(),
            ],
          ),

          const SizedBox(height: 8),

          // Category
          Text(
            'Ana Yemekler', // This would come from category
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // Price
          _buildPriceSection(),
        ],
      ),
    );
  }

  Widget _buildProductBadges() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (widget.product.tags.contains('new'))
          _buildBadge('YENİ', AppColors.success),
        if (widget.product.tags.contains('popular'))
          _buildBadge('POPÜLER', AppColors.warning),
        if (widget.product.tags.contains('vegetarian'))
          _buildBadge('VEJETARYeN', AppColors.info),
        if (widget.product.tags.contains('spicy'))
          _buildBadge('ACILI', AppColors.error),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    final hasDiscount = widget.product.discountPercentage > 0;
    final discountedPrice = hasDiscount
        ? widget.product.price * (1 - widget.product.discountPercentage / 100)
        : widget.product.price;

    return Row(
      children: [
        // Current price
        Text(
          '${discountedPrice.toStringAsFixed(2)} ₺',
          style: AppTypography.priceRegular,
        ),

        // Original price (if discounted)
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            '${widget.product.price.toStringAsFixed(2)} ₺',
            style: AppTypography.priceOriginal,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.discountColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '%${widget.product.discountPercentage.toInt()} İNDİRİM',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductDescription() {
    return Container(
      padding: AppDimensions.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Açıklama', style: AppTypography.h4),
          const SizedBox(height: 8),
          Text(
            widget.product.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionAndAllergens() {
    return Container(
      padding: AppDimensions.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nutrition Facts
          if (widget.product.nutritionInfo != null) ...[
            Text('Besin Değerleri (100g)', style: AppTypography.h4),
            const SizedBox(height: 12),
            _buildNutritionCard(),
            const SizedBox(height: 24),
          ],

          // Allergens
          if (widget.product.allergens.isNotEmpty) ...[
            Text('Alerjen Uyarısı', style: AppTypography.h4),
            const SizedBox(height: 8),
            _buildAllergensList(),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    final nutrition = widget.product.nutritionInfo!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (nutrition.calories != null)
            _buildNutritionRow('Kalori', '${nutrition.calories} kcal'),
          if (nutrition.protein != null)
            _buildNutritionRow('Protein', '${nutrition.protein}g'),
          if (nutrition.carbs != null)
            _buildNutritionRow('Karbonhidrat', '${nutrition.carbs}g'),
          if (nutrition.fat != null)
            _buildNutritionRow('Yağ', '${nutrition.fat}g'),
          if (nutrition.fiber != null && nutrition.fiber! > 0)
            _buildNutritionRow('Lif', '${nutrition.fiber}g'),
          if (nutrition.sugar != null && nutrition.sugar! > 0)
            _buildNutritionRow('Şeker', '${nutrition.sugar}g'),
          if (nutrition.sodium != null && nutrition.sodium! > 0)
            _buildNutritionRow('Sodyum', '${nutrition.sodium}mg'),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergensList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Bu ürün aşağıdaki alerjenleri içerebilir:',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.product.allergens.map((allergen) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withOpacity(0.5)),
                ),
                child: Text(
                  allergen,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductFeatures() {
    final features = <String>[];

    if (widget.product.tags.contains('vegetarian')) features.add('Vejetaryen');
    if (widget.product.tags.contains('vegan')) features.add('Vegan');
    if (widget.product.tags.contains('spicy')) features.add('Acılı');
    if (widget.product.tags.contains('gluten-free')) features.add('Glütensiz');
    if (widget.product.tags.contains('organic')) features.add('Organik');

    if (features.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: AppDimensions.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Özellikler', style: AppTypography.h4),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFeatureIcon(feature),
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      feature,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getFeatureIcon(String feature) {
    switch (feature.toLowerCase()) {
      case 'vejetaryen':
      case 'vegan':
        return Icons.eco;
      case 'acılı':
        return Icons.local_fire_department;
      case 'glütensiz':
        return Icons.no_meals;
      case 'organik':
        return Icons.nature;
      default:
        return Icons.check_circle;
    }
  }

  Widget _buildSimilarProducts() {
    return Container(
      padding: AppDimensions.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Benzer Ürünler', style: AppTypography.h4),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3, // Placeholder
              itemBuilder: (context, index) {
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildSimilarProductCard(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProductCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 32,
                color: AppColors.textLight,
              ),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Benzer Ürün ${index + 1}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '25.00 ₺',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.priceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _quantity > 1 ? _decreaseQuantity : null,
                  ),
                  Text(
                    '$_quantity',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _increaseQuantity,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Add to cart button
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Sepete Ekle - ${_getTotalPrice().toStringAsFixed(2)} ₺',
                        style: AppTypography.buttonMedium,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getTotalPrice() {
    final hasDiscount = widget.product.discountPercentage > 0;
    final unitPrice = hasDiscount
        ? widget.product.price * (1 - widget.product.discountPercentage / 100)
        : widget.product.price;
    return unitPrice * _quantity;
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} sepete eklendi!'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  void _onSharePressed() {
    // Share product functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ürün paylaşıldı!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _onFavoritePressed() {
    // Add to favorites functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorilere eklendi!'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
