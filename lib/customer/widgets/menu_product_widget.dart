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
    // Fixed Masonry layout - proper spacing and no overlaps
    final cardSize = menuSettings?.layoutStyle.cardSize ?? MenuCardSize.medium;
    final spacing = menuSettings?.layoutStyle.itemSpacing ?? 12.0;

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          final availableWidth =
              constraints.maxWidth - (spacing * (crossAxisCount + 1));
          final itemWidth = availableWidth / crossAxisCount;

          return Column(
            children: _buildMasonryColumns(crossAxisCount, itemWidth, spacing),
          );
        },
      ),
    );
  }

  List<Widget> _buildMasonryColumns(
      int crossAxisCount, double itemWidth, double spacing) {
    // Split products into columns
    final columns = <List<Product>>[];
    for (int i = 0; i < crossAxisCount; i++) {
      columns.add([]);
    }

    // Distribute products to columns
    for (int i = 0; i < products.length; i++) {
      final columnIndex = i % crossAxisCount;
      columns[columnIndex].add(products[i]);
    }

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.asMap().entries.map((entry) {
          final columnProducts = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Column(
                children: columnProducts.asMap().entries.map((productEntry) {
                  final product = productEntry.value;
                  final isLarge = (productEntry.key % 3) == 0;
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing),
                    child: _buildMasonryProductCard(
                        product, productEntry.key, isLarge),
                  );
                }).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    ];
  }

  Widget _buildStaggeredLayout() {
    // Fixed Staggered layout - proper responsive zigzag
    final spacing = menuSettings?.layoutStyle.itemSpacing ?? 12.0;

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: _buildStaggeredRows(constraints.maxWidth, spacing),
          );
        },
      ),
    );
  }

  List<Widget> _buildStaggeredRows(double maxWidth, double spacing) {
    final rows = <Widget>[];

    for (int i = 0; i < products.length; i += 2) {
      final isEvenRow = (i ~/ 2) % 2 == 0;
      final product1 = products[i];
      final product2 = i + 1 < products.length ? products[i + 1] : null;

      // Calculate proper widths to prevent overflow
      final totalSpacing = spacing * 3; // left, center, right
      final availableWidth = maxWidth - totalSpacing;
      final largeWidth = availableWidth * 0.6; // 60%
      final smallWidth = availableWidth * 0.4; // 40%

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: isEvenRow
                ? [
                    // Even row: Large left, small right
                    Container(
                      width: largeWidth,
                      child: _buildCompactProductCard(product1, i),
                    ),
                    SizedBox(width: spacing),
                    if (product2 != null)
                      Container(
                        width: smallWidth,
                        child: _buildCompactProductCard(product2, i + 1),
                      ),
                  ]
                : [
                    // Odd row: Small left, large right
                    Container(
                      width: smallWidth,
                      child: _buildCompactProductCard(product1, i),
                    ),
                    SizedBox(width: spacing),
                    if (product2 != null)
                      Container(
                        width: largeWidth,
                        child: _buildCompactProductCard(product2, i + 1),
                      ),
                  ],
          ),
        ),
      );
    }

    return rows;
  }

  Widget _buildWaterfallLayout() {
    // Fixed Waterfall layout - proper responsive grid without overlap
    final spacing = menuSettings?.layoutStyle.itemSpacing ?? 12.0;
    final crossAxisCount = menuSettings?.layoutStyle.columnsCount ?? 2;
    final aspectRatio = menuSettings?.layoutStyle.cardAspectRatio ?? 0.8;

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate proper dimensions
          final totalSpacing = spacing * (crossAxisCount + 1);
          final availableWidth = constraints.maxWidth - totalSpacing;
          final itemWidth = availableWidth / crossAxisCount;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                constraints: BoxConstraints(maxWidth: itemWidth),
                child: _buildWaterfallProductCard(product, index),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMagazineLayout() {
    // Fixed Magazine layout - proper responsive magazine style
    final spacing = menuSettings?.layoutStyle.itemSpacing ?? 12.0;

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: _buildMagazineRows(constraints.maxWidth, spacing),
          );
        },
      ),
    );
  }

  List<Widget> _buildMagazineRows(double maxWidth, double spacing) {
    final rows = <Widget>[];

    for (int i = 0; i < products.length; i += 3) {
      // First product as featured (if it's the very first one)
      if (i == 0 && products.isNotEmpty) {
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: Container(
              width: maxWidth,
              height: 200,
              child: _buildFeaturedProductCard(products[i], i),
            ),
          ),
        );
      }

      // Next two products in a row (if available)
      final product2 = i + 1 < products.length ? products[i + 1] : null;
      final product3 = i + 2 < products.length ? products[i + 2] : null;

      if (product2 != null || product3 != null) {
        final availableWidth = maxWidth - spacing;
        final cardWidth = availableWidth / 2;

        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: Row(
              children: [
                if (product2 != null)
                  Container(
                    width: cardWidth,
                    child: _buildCompactProductCard(product2, i + 1),
                  ),
                if (product2 != null && product3 != null)
                  SizedBox(width: spacing),
                if (product3 != null)
                  Container(
                    width: cardWidth,
                    child: _buildCompactProductCard(product3, i + 2),
                  ),
              ],
            ),
          ),
        );
      }
    }

    return rows;
  }

  Widget _buildProductGridLayout(int columnsCount) {
    // Fixed Grid layout - proper responsive grid without overflow
    final spacing = menuSettings?.layoutStyle.itemSpacing ?? 12.0;
    final aspectRatio = menuSettings?.layoutStyle.cardAspectRatio ?? 0.75;

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Ensure proper spacing calculation
          final totalSpacing = spacing * (columnsCount + 1);
          final availableWidth = constraints.maxWidth - totalSpacing;
          final itemWidth = availableWidth / columnsCount;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnsCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                constraints: BoxConstraints(maxWidth: itemWidth),
                child: _buildCompactProductCard(product, index),
              );
            },
          );
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
