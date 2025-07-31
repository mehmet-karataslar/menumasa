import 'package:flutter/material.dart';
import '../../../business/models/business.dart';
import '../../../business/models/product.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/web_safe_image.dart';

/// Dinamik menü widget'ları
/// MenuSettings'e göre UI bileşenlerini oluşturur
class DynamicMenuWidgets {
  /// Dinamik layout builder
  Widget buildDynamicLayout({
    required List<Widget> children,
    required MenuSettings menuSettings,
  }) {
    switch (menuSettings.layoutStyle.layoutType) {
      case MenuLayoutType.list:
        return _buildListLayout(children, menuSettings);
      case MenuLayoutType.grid:
        return _buildGridLayout(children, menuSettings);
      case MenuLayoutType.masonry:
        return _buildMasonryLayout(children, menuSettings);
      case MenuLayoutType.carousel:
        return _buildCarouselLayout(children, menuSettings);
    }
  }

  /// Liste layout'u
  Widget _buildListLayout(List<Widget> children, MenuSettings menuSettings) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(menuSettings.layoutStyle.itemSpacing),
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(
        height: menuSettings.layoutStyle.itemSpacing,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }

  /// Grid layout'u
  Widget _buildGridLayout(List<Widget> children, MenuSettings menuSettings) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(menuSettings.layoutStyle.itemSpacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: menuSettings.layoutStyle.columnsCount,
        crossAxisSpacing: menuSettings.layoutStyle.itemSpacing,
        mainAxisSpacing: menuSettings.layoutStyle.itemSpacing,
        childAspectRatio: menuSettings.layoutStyle.autoHeight ? 0.85 : 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  /// Masonry layout'u
  Widget _buildMasonryLayout(List<Widget> children, MenuSettings menuSettings) {
    // Basit implementasyon - gelecekte daha gelişmiş masonry yapılabilir
    return _buildGridLayout(children, menuSettings);
  }

  /// Carousel layout'u
  Widget _buildCarouselLayout(
      List<Widget> children, MenuSettings menuSettings) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: children.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: menuSettings.layoutStyle.itemSpacing / 2,
          ),
          child: children[index],
        ),
      ),
    );
  }

  /// Dinamik ürün kartı
  Widget buildProductCard({
    required Product product,
    required MenuSettings menuSettings,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final theme = menuSettings.designTheme;

    switch (theme.themeType) {
      case MenuThemeType.modern:
        return _buildModernProductCard(product, menuSettings, onTap, context);
      case MenuThemeType.classic:
        return _buildClassicProductCard(product, menuSettings, onTap, context);
      case MenuThemeType.grid:
        return _buildGridProductCard(product, menuSettings, onTap, context);
      case MenuThemeType.magazine:
        return _buildMagazineProductCard(product, menuSettings, onTap, context);
    }
  }

  /// Modern tema ürün kartı
  Widget _buildModernProductCard(
    Product product,
    MenuSettings menuSettings,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _parseColor(menuSettings.colorScheme.surfaceColor),
          borderRadius:
              BorderRadius.circular(menuSettings.visualStyle.borderRadius),
          boxShadow: menuSettings.visualStyle.showShadows
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: menuSettings.visualStyle.cardElevation,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
          border: menuSettings.visualStyle.showBorders
              ? Border.all(
                  color: _parseColor(menuSettings.colorScheme.primaryColor)
                      .withOpacity(0.2),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün resmi
            if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(menuSettings.visualStyle.borderRadius),
                  ),
                  child: Stack(
                    children: [
                      WebSafeImage(
                        imageUrl: product.imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      if (menuSettings.visualStyle.showImageOverlay)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Ürün bilgileri
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontFamily: menuSettings.typography.fontFamily,
                            fontSize: menuSettings.typography.headingFontSize,
                            fontWeight: FontWeight.w600,
                            color: _parseColor(
                                menuSettings.colorScheme.textPrimaryColor),
                            height: menuSettings.typography.lineHeight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.description != null &&
                            product.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.description!,
                            style: TextStyle(
                              fontFamily: menuSettings.typography.fontFamily,
                              fontSize: menuSettings.typography.bodyFontSize,
                              color: _parseColor(
                                  menuSettings.colorScheme.textSecondaryColor),
                              height: menuSettings.typography.lineHeight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),

                    // Fiyat
                    if (menuSettings.showPrices && product.price > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${product.price.toStringAsFixed(2)} ${menuSettings.currency}',
                        style: TextStyle(
                          fontFamily: menuSettings.typography.fontFamily,
                          fontSize: menuSettings.typography.headingFontSize,
                          fontWeight: FontWeight.w700,
                          color: _parseColor(
                              menuSettings.colorScheme.primaryColor),
                          height: menuSettings.typography.lineHeight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Klasik tema ürün kartı
  Widget _buildClassicProductCard(
    Product product,
    MenuSettings menuSettings,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _parseColor(menuSettings.colorScheme.surfaceColor),
          border: Border.all(
            color: _parseColor(menuSettings.colorScheme.primaryColor)
                .withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            // Ürün resmi
            if (product.imageUrl?.isNotEmpty ?? false)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: WebSafeImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Ürün bilgileri
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontFamily: menuSettings.typography.fontFamily,
                        fontSize: menuSettings.typography.headingFontSize,
                        fontWeight: FontWeight.w600,
                        color: _parseColor(
                            menuSettings.colorScheme.textPrimaryColor),
                      ),
                    ),
                    if (product.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontFamily: menuSettings.typography.fontFamily,
                          fontSize: menuSettings.typography.bodyFontSize,
                          color: _parseColor(
                              menuSettings.colorScheme.textSecondaryColor),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (menuSettings.showPrices && product.price > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${product.price.toStringAsFixed(2)} ${menuSettings.currency}',
                        style: TextStyle(
                          fontFamily: menuSettings.typography.fontFamily,
                          fontSize: menuSettings.typography.headingFontSize,
                          fontWeight: FontWeight.w700,
                          color: _parseColor(
                              menuSettings.colorScheme.primaryColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Grid tema ürün kartı
  Widget _buildGridProductCard(
    Product product,
    MenuSettings menuSettings,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return _buildModernProductCard(product, menuSettings, onTap, context);
  }

  /// Dergi tema ürün kartı
  Widget _buildMagazineProductCard(
    Product product,
    MenuSettings menuSettings,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _parseColor(menuSettings.colorScheme.surfaceColor),
          borderRadius:
              BorderRadius.circular(menuSettings.visualStyle.borderRadius),
          boxShadow: menuSettings.visualStyle.showShadows
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: menuSettings.visualStyle.cardElevation * 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Arka plan resmi
            if (product.imageUrl?.isNotEmpty ?? false)
              ClipRRect(
                borderRadius: BorderRadius.circular(
                    menuSettings.visualStyle.borderRadius),
                child: WebSafeImage(
                  imageUrl: product.imageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                    menuSettings.visualStyle.borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // İçerik
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontFamily: menuSettings.typography.fontFamily,
                        fontSize: menuSettings.typography.headingFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: menuSettings.typography.lineHeight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (menuSettings.showPrices && product.price > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${product.price.toStringAsFixed(2)} ${menuSettings.currency}',
                        style: TextStyle(
                          fontFamily: menuSettings.typography.fontFamily,
                          fontSize: menuSettings.typography.titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: _parseColor(
                              menuSettings.colorScheme.primaryColor),
                          height: menuSettings.typography.lineHeight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Loading indicator
  Widget buildLoadingIndicator(MenuSettings menuSettings) {
    return Center(
      child: CircularProgressIndicator(
        color: _parseColor(menuSettings.colorScheme.primaryColor),
      ),
    );
  }

  /// Error widget
  Widget buildErrorWidget({
    required String message,
    required MenuSettings menuSettings,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: _parseColor(menuSettings.colorScheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontFamily: menuSettings.typography.fontFamily,
              fontSize: menuSettings.typography.headingFontSize,
              color: _parseColor(menuSettings.colorScheme.textPrimaryColor),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _parseColor(menuSettings.colorScheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    menuSettings.visualStyle.buttonRadius),
              ),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  /// Hex string'i Color'a çevir
  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary; // Fallback color
    }
  }
}
