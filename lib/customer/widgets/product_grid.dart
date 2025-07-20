import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/models/category.dart';
import '../../data/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/cart_service.dart';
// CachedNetworkImage removed for Windows compatibility

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductTapped;
  final Function(Product)? onAddToCart;
  final EdgeInsets? padding;
  final int crossAxisCount;
  final double childAspectRatio;

  const ProductGrid({
    Key? key,
    required this.products,
    required this.onProductTapped,
    this.onAddToCart,
    this.padding,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: AppDimensions.getResponsiveGridCount(context),
          crossAxisSpacing: AppDimensions.spacing16,
          mainAxisSpacing: AppDimensions.spacing16,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () => onProductTapped(product),
            onAddToCart: onAddToCart != null
                ? () => onAddToCart!(product)
                : null,
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.radiusM),
                        topRight: Radius.circular(AppDimensions.radiusM),
                      ),
                      color: AppColors.greyExtraLight,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.radiusM),
                        topRight: Radius.circular(AppDimensions.radiusM),
                      ),
                      child: product.primaryImage?.url.isNotEmpty == true
                          ? Image.network(
                              product.primaryImage!.url,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return _buildImagePlaceholder();
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                    ),
                  ),

                  // Badges
                  Positioned(top: 8, left: 8, child: _buildBadges()),

                  // Discount badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.discountColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.formattedDiscountPercentage,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: AppTypography.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Product description
                    Text(
                      product.description,
                      style: AppTypography.productDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Price section and add to cart button
                    Row(
                      children: [
                        // Price column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Current price
                              Text(
                                product.formattedPrice,
                                style: AppTypography.priceRegular.copyWith(
                                  color: product.hasDiscount
                                      ? AppColors.discountColor
                                      : AppColors.priceColor,
                                ),
                              ),

                              // Original price (if discounted)
                              if (product.hasDiscount)
                                Text(
                                  product.formattedOriginalPrice,
                                  style: AppTypography.priceOriginal,
                                ),
                            ],
                          ),
                        ),

                        // Add to cart button
                        if (onAddToCart != null)
                          InkWell(
                            onTap: onAddToCart,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.greyExtraLight,
      child: const Center(
        child: Icon(Icons.restaurant, size: 48, color: AppColors.greyLight),
      ),
    );
  }

  Widget _buildBadges() {
    final badges = <Widget>[];

    if (product.isNew) {
      badges.add(_buildBadge('YENİ', AppColors.success));
    }

    if (product.isPopular) {
      badges.add(_buildBadge('POPÜLER', AppColors.warning));
    }

    if (product.isVegetarian) {
      badges.add(_buildBadge('V', AppColors.success));
    }

    if (product.isSpicy) {
      badges.add(_buildBadge('🌶', AppColors.error));
    }

    if (badges.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: badges
          .map(
            (badge) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: badge,
            ),
          )
          .toList(),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

// List view version for different layouts
class ProductList extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductTapped;
  final EdgeInsets? padding;

  const ProductList({
    Key? key,
    required this.products,
    required this.onProductTapped,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductListItem(
          product: product,
          onTap: () => onProductTapped(product),
        );
      },
    );
  }
}

class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductListItem({Key? key, required this.product, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  color: AppColors.greyExtraLight,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  child: product.primaryImage?.url.isNotEmpty == true
                      ? Image.network(
                          product.primaryImage!.url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildImagePlaceholder();
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
              ),

              const SizedBox(width: 16),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: AppTypography.productTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.hasDiscount)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.discountColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.formattedDiscountPercentage,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      product.description,
                      style: AppTypography.productDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Price
                    Row(
                      children: [
                        Text(
                          product.formattedPrice,
                          style: AppTypography.priceRegular.copyWith(
                            color: product.hasDiscount
                                ? AppColors.discountColor
                                : AppColors.priceColor,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            product.formattedOriginalPrice,
                            style: AppTypography.priceOriginal,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.greyExtraLight,
      child: const Center(
        child: Icon(Icons.restaurant, size: 32, color: AppColors.greyLight),
      ),
    );
  }
}
 