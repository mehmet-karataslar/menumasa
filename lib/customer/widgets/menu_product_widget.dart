import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../business/models/business.dart';
import '../../business/models/product.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/web_safe_image.dart';

/// 🛍️ Menü Ürün Widget'ı
///
/// Bu widget menü sayfasının ürün bölümünü oluşturur:
/// - Farklı layout tiplerinde ürün listeleri (Grid, List, Carousel, Masonry)
/// - Ürün kartları ve detayları
/// - Fiyat ve açıklama gösterimi
/// - Dinamik ürün gösterimi
class MenuProductWidget extends StatelessWidget {
  final MenuSettings? menuSettings;
  final List<Product> products;
  final Function(Product) onProductTap;
  final Function(Product) onAddToCart;
  final Function(Product) onFavoriteToggle;
  final List<String> favoriteProductIds;

  const MenuProductWidget({
    super.key,
    this.menuSettings,
    required this.products,
    required this.onProductTap,
    required this.onAddToCart,
    required this.onFavoriteToggle,
    this.favoriteProductIds = const [],
  });

  @override
  Widget build(BuildContext context) {
    return _buildProductSection();
  }

  Widget _buildProductSection() {
    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
        color: menuSettings != null
            ? _parseColor(menuSettings!.colorScheme.backgroundColor)
            : AppColors.backgroundLight,
        child: Container(
          decoration: BoxDecoration(
            color: menuSettings != null
                ? _parseColor(menuSettings!.colorScheme.primaryColor)
                : AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: _buildProductGrid(),
        ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Bu kategoride henüz ürün bulunmuyor',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final layoutType =
        menuSettings?.layoutStyle.layoutType ?? MenuLayoutType.grid;
    final columnsCount = menuSettings?.layoutStyle.columnsCount ?? 2;

    switch (layoutType) {
      case MenuLayoutType.list:
        return _buildProductList();
      case MenuLayoutType.carousel:
        return _buildProductCarousel();
      case MenuLayoutType.masonry:
        return _buildProductMasonry();
      case MenuLayoutType.staggered:
        return _buildStaggeredLayout();
      case MenuLayoutType.waterfall:
        return _buildWaterfallLayout();
      case MenuLayoutType.magazine:
        return _buildMagazineLayout();
      case MenuLayoutType.grid:
      default:
        return _buildProductGridLayout(columnsCount);
    }
  }

  Widget _buildProductList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildListProductCard(product, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductCarousel() {
    return Container(
      height: 280,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PageView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCarouselProductCard(product, index),
          );
        },
      ),
    );
  }

  Widget _buildProductMasonry() {
    // Masonry layout - farklı yüksekliklerde kartlar
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: menuSettings?.layoutStyle.itemSpacing ?? 16,
            runSpacing: menuSettings?.layoutStyle.itemSpacing ?? 16,
            children: products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              // Rastgele yükseklik için index kullan
              final isLarge = (index % 3) == 0;
              return Container(
                width: (constraints.maxWidth - 48) / 2,
                child: _buildMasonryProductCard(product, index, isLarge),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildStaggeredLayout() {
    // Zigzag layout - dönüşümlü yerleşim
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (int i = 0; i < products.length; i += 2) ...[
            Row(
              children: [
                if (i % 4 == 0) ...[
                  // Sol büyük, sağ küçük
                  Expanded(
                    flex: 2,
                    child: _buildCompactProductCard(products[i], i),
                  ),
                  const SizedBox(width: 16),
                  if (i + 1 < products.length)
                    Expanded(
                      flex: 1,
                      child: _buildCompactProductCard(products[i + 1], i + 1),
                    ),
                ] else ...[
                  // Sol küçük, sağ büyük
                  if (i + 1 < products.length)
                    Expanded(
                      flex: 1,
                      child: _buildCompactProductCard(products[i], i),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildCompactProductCard(products[i + 1], i + 1),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildWaterfallLayout() {
    // Pinterest tarzı şelale layout
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = menuSettings?.layoutStyle.columnsCount ?? 2;
          final itemWidth =
              (constraints.maxWidth - (16 * (crossAxisCount - 1))) /
                  crossAxisCount;

          return GridView.custom(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8, // Farklı oranlar için
            ),
            childrenDelegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return _buildWaterfallProductCard(product, index);
              },
              childCount: products.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMagazineLayout() {
    // Dergi sayfa düzeni
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (int i = 0; i < products.length; i += 3) ...[
            if (i == 0 && products.isNotEmpty) ...[
              // İlk ürün büyük featured
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildFeaturedProductCard(products[i], i),
              ),
            ],
            // Diğer ürünler 2x1 grid
            if (i + 1 < products.length || i + 2 < products.length) ...[
              Row(
                children: [
                  if (i + 1 < products.length)
                    Expanded(
                      child: _buildCompactProductCard(products[i + 1], i + 1),
                    ),
                  const SizedBox(width: 16),
                  if (i + 2 < products.length)
                    Expanded(
                      child: _buildCompactProductCard(products[i + 2], i + 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildProductGridLayout(int columnsCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnsCount,
          childAspectRatio: menuSettings?.layoutStyle.cardAspectRatio ?? 0.75,
          crossAxisSpacing: menuSettings?.layoutStyle.itemSpacing ?? 16,
          mainAxisSpacing: menuSettings?.layoutStyle.itemSpacing ?? 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildCompactProductCard(product, index);
        },
      ),
    );
  }

  Widget _buildListProductCard(Product product, int index) {
    final cardColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.cardColor)
        : AppColors.white;
    final borderRadius = menuSettings?.visualStyle.borderRadius ?? 12.0;
    final primaryColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.primaryColor)
        : AppColors.primary;
    final textPrimaryColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.textPrimaryColor)
        : AppColors.textPrimary;
    final accentColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.accentColor)
        : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onProductTap(product),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: menuSettings?.visualStyle.showShadows ?? true
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Ürün görseli
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: _parseColor(
                        menuSettings?.colorScheme.surfaceColor ?? '#F8F9FA'),
                    child: product.images.isNotEmpty
                        ? WebSafeImage(
                            imageUrl: product.images.first.url,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                          )
                        : _buildProductIcon(),
                  ),
                ),
                const SizedBox(width: 12),

                // Ürün bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.getFont(
                          menuSettings?.typography.fontFamily ?? 'Poppins',
                          fontSize:
                              menuSettings?.typography.titleFontSize ?? 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.description.isNotEmpty &&
                          (menuSettings?.showDescriptions ?? true)) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: GoogleFonts.getFont(
                            menuSettings?.typography.fontFamily ?? 'Poppins',
                            fontSize:
                                (menuSettings?.typography.bodyFontSize ?? 12) -
                                    1,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (menuSettings?.showPrices ?? true)
                        Text(
                          '₺${product.price.toStringAsFixed(2)}',
                          style: GoogleFonts.getFont(
                            menuSettings?.typography.fontFamily ?? 'Poppins',
                            fontSize:
                                menuSettings?.typography.headingFontSize ?? 16,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                    ],
                  ),
                ),

                // Favorit ve sepet butonları
                Column(
                  children: [
                    _buildFavoriteButton(product),
                    const SizedBox(height: 8),
                    _buildAddToCartButton(product),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselProductCard(Product product, int index) {
    return _buildCompactProductCard(product, index);
  }

  Widget _buildCompactProductCard(Product product, int index) {
    final cardSize = menuSettings?.layoutStyle.cardSize ?? MenuCardSize.medium;
    final cardColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.cardColor)
        : AppColors.white;
    final borderRadius = menuSettings?.visualStyle.borderRadius ?? 16.0;
    final shadowColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.shadowColor)
        : AppColors.shadow;
    final primaryColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.primaryColor)
        : AppColors.primary;
    final textPrimaryColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.textPrimaryColor)
        : AppColors.textPrimary;
    final accentColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.accentColor)
        : AppColors.primary;

    final imageShape = menuSettings?.visualStyle.imageShape ?? 'rounded';

    return Transform.scale(
      scale: cardSize.scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onProductTap(product),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: menuSettings?.visualStyle.showShadows ?? true
                  ? [
                      BoxShadow(
                        color: shadowColor.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ürün görseli
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(borderRadius),
                            topRight: Radius.circular(borderRadius),
                            bottomLeft: imageShape == 'rectangle'
                                ? Radius.zero
                                : Radius.circular(borderRadius / 2),
                            bottomRight: imageShape == 'rectangle'
                                ? Radius.zero
                                : Radius.circular(borderRadius / 2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(borderRadius),
                            topRight: Radius.circular(borderRadius),
                            bottomLeft: imageShape == 'rectangle'
                                ? Radius.zero
                                : Radius.circular(borderRadius / 2),
                            bottomRight: imageShape == 'rectangle'
                                ? Radius.zero
                                : Radius.circular(borderRadius / 2),
                          ),
                          child: product.images.isNotEmpty
                              ? WebSafeImage(
                                  imageUrl: product.images.first.url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (context, url) =>
                                      _buildImagePlaceholder(),
                                  errorWidget: (context, url, error) =>
                                      _buildImagePlaceholder(),
                                )
                              : _buildImagePlaceholder(),
                        ),
                      ),

                      // Favorit butonu
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildFavoriteButton(product),
                      ),
                    ],
                  ),
                ),

                // Ürün bilgileri
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.getFont(
                            menuSettings?.typography.fontFamily ?? 'Poppins',
                            fontSize:
                                menuSettings?.typography.titleFontSize ?? 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.description.isNotEmpty &&
                            (menuSettings?.showDescriptions ?? true)) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            style: GoogleFonts.getFont(
                              menuSettings?.typography.fontFamily ?? 'Poppins',
                              fontSize:
                                  menuSettings?.typography.captionFontSize ??
                                      11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (menuSettings?.showPrices ?? true)
                              Text(
                                '₺${product.price.toStringAsFixed(2)}',
                                style: GoogleFonts.getFont(
                                  menuSettings?.typography.fontFamily ??
                                      'Poppins',
                                  fontSize: menuSettings
                                          ?.typography.headingFontSize ??
                                      14,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            _buildAddToCartButton(product),
                          ],
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

  Widget _buildFavoriteButton(Product product) {
    final isFavorite = favoriteProductIds.contains(product.productId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onFavoriteToggle(product),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? AppColors.error : AppColors.textSecondary,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(Product product) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onAddToCart(product),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _parseColor(
                menuSettings?.colorScheme.primaryColor ?? '#FF6B35'),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _parseColor(
                        menuSettings?.colorScheme.primaryColor ?? '#FF6B35')
                    .withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildProductIcon() {
    return Container(
      color: AppColors.backgroundLight,
      child: const Icon(
        Icons.fastfood_rounded,
        color: AppColors.textSecondary,
        size: 32,
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.backgroundLight,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textSecondary,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildMasonryProductCard(Product product, int index, bool isLarge) {
    final cardSize = menuSettings?.layoutStyle.cardSize ?? MenuCardSize.medium;
    final aspectRatio =
        isLarge ? 0.6 : (menuSettings?.layoutStyle.cardAspectRatio ?? 0.75);

    return Container(
      height: isLarge ? 250 * cardSize.scale : 200 * cardSize.scale,
      child: _buildCompactProductCard(product, index),
    );
  }

  Widget _buildWaterfallProductCard(Product product, int index) {
    final cardSize = menuSettings?.layoutStyle.cardSize ?? MenuCardSize.medium;
    // Farklı yükseklikler için rastgele aspect ratio
    final aspectRatios = [0.6, 0.75, 0.9, 1.1];
    final aspectRatio = aspectRatios[index % aspectRatios.length];

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Transform.scale(
        scale: cardSize.scale,
        child: _buildCompactProductCard(product, index),
      ),
    );
  }

  Widget _buildFeaturedProductCard(Product product, int index) {
    final cardSize = menuSettings?.layoutStyle.cardSize ?? MenuCardSize.medium;
    final cardColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.cardColor)
        : AppColors.white;
    final borderRadius = menuSettings?.visualStyle.borderRadius ?? 16.0;
    final textPrimaryColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.textPrimaryColor)
        : AppColors.textPrimary;
    final accentColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.accentColor)
        : AppColors.primary;

    return Transform.scale(
      scale: cardSize.scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onProductTap(product),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: menuSettings?.visualStyle.showShadows ?? true
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Ürün görseli
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      bottomLeft: Radius.circular(borderRadius),
                    ),
                    child: Container(
                      height: double.infinity,
                      child: product.images.isNotEmpty
                          ? WebSafeImage(
                              imageUrl: product.images.first.url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) =>
                                  _buildImagePlaceholder(),
                              errorWidget: (context, url, error) =>
                                  _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                    ),
                  ),
                ),

                // Ürün bilgileri
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.getFont(
                            menuSettings?.typography.fontFamily ?? 'Poppins',
                            fontSize:
                                (menuSettings?.typography.titleFontSize ?? 18) *
                                    cardSize.scale,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.description.isNotEmpty &&
                            (menuSettings?.showDescriptions ?? true)) ...[
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            style: GoogleFonts.getFont(
                              menuSettings?.typography.fontFamily ?? 'Poppins',
                              fontSize:
                                  (menuSettings?.typography.bodyFontSize ??
                                          14) *
                                      cardSize.scale,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (menuSettings?.showPrices ?? true)
                              Text(
                                '₺${product.price.toStringAsFixed(2)}',
                                style: GoogleFonts.getFont(
                                  menuSettings?.typography.fontFamily ??
                                      'Poppins',
                                  fontSize: (menuSettings
                                              ?.typography.headingFontSize ??
                                          16) *
                                      cardSize.scale,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            _buildAddToCartButton(product),
                          ],
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
