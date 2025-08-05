import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';

import '../../presentation/widgets/shared/loading_indicator.dart';

/// 🔄 Menü State Widget'ları
///
/// Bu widget menü sayfasının farklı durumlarını gösterir:
/// - Loading state (Yükleniyor)
/// - Error state (Hata)
/// - Empty state (Boş)
/// - Shimmer loading efektleri
class MenuStateWidgets {
  /// Loading state widget'ı
  static Widget buildLoadingState(MenuSettings? menuSettings) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingIndicator(
            color: menuSettings != null
                ? _parseColor(menuSettings.colorScheme.primaryColor)
                : AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Menü yükleniyor...',
            style: GoogleFonts.getFont(
              menuSettings?.typography.fontFamily ?? 'Poppins',
              fontSize: menuSettings?.typography.bodyFontSize ?? 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildShimmerContent(menuSettings),
        ],
      ),
    );
  }

  /// Error state widget'ı
  static Widget buildErrorState(
    MenuSettings? menuSettings,
    String errorMessage,
    VoidCallback? onRetry,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bir hata oluştu',
            style: GoogleFonts.getFont(
              menuSettings?.typography.fontFamily ?? 'Poppins',
              fontSize: menuSettings?.typography.headingFontSize ?? 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: GoogleFonts.getFont(
              menuSettings?.typography.fontFamily ?? 'Poppins',
              fontSize: menuSettings?.typography.bodyFontSize ?? 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: menuSettings != null
                    ? _parseColor(menuSettings.colorScheme.primaryColor)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
        ],
      ),
    );
  }

  /// Empty state widget'ı
  static Widget buildEmptyState(
    MenuSettings? menuSettings,
    String title,
    String message, {
    IconData? icon,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.getFont(
              menuSettings?.typography.fontFamily ?? 'Poppins',
              fontSize: menuSettings?.typography.headingFontSize ?? 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.getFont(
              menuSettings?.typography.fontFamily ?? 'Poppins',
              fontSize: menuSettings?.typography.bodyFontSize ?? 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 32),
            action,
          ],
        ],
      ),
    );
  }

  /// Shimmer loading content
  static Widget _buildShimmerContent(MenuSettings? menuSettings) {
    return Column(
      children: [
        // Kategori shimmer
        _buildCategoryShimmer(),
        const SizedBox(height: 24),
        // Ürün grid shimmer
        _buildProductGridShimmer(),
      ],
    );
  }

  /// Kategori shimmer
  static Widget _buildCategoryShimmer() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Shimmer.fromColors(
                  baseColor: AppColors.backgroundLight,
                  highlightColor: Colors.white,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: AppColors.backgroundLight,
                  highlightColor: Colors.white,
                  child: Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Ürün grid shimmer
  static Widget _buildProductGridShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.backgroundLight,
          highlightColor: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Görsel shimmer
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                // Text shimmer
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// No search results state
  static Widget buildNoSearchResultsState(
    MenuSettings? menuSettings,
    String searchQuery,
    VoidCallback? onClearSearch,
  ) {
    return buildEmptyState(
      menuSettings,
      'Arama sonucu bulunamadı',
      '"$searchQuery" için hiçbir ürün bulunamadı.\nFarklı anahtar kelimeler deneyin.',
      icon: Icons.search_off_rounded,
      action: onClearSearch != null
          ? ElevatedButton.icon(
              onPressed: onClearSearch,
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Aramayı Temizle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: menuSettings != null
                    ? _parseColor(menuSettings.colorScheme.primaryColor)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            )
          : null,
    );
  }

  /// No products in category state
  static Widget buildNoCategoryProductsState(
    MenuSettings? menuSettings,
    String categoryName,
    VoidCallback? onShowAllProducts,
  ) {
    return buildEmptyState(
      menuSettings,
      'Bu kategoride ürün yok',
      '$categoryName kategorisinde henüz ürün bulunmuyor.',
      icon: Icons.category_outlined,
      action: onShowAllProducts != null
          ? TextButton.icon(
              onPressed: onShowAllProducts,
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Tüm Ürünleri Göster'),
              style: TextButton.styleFrom(
                foregroundColor: menuSettings != null
                    ? _parseColor(menuSettings.colorScheme.primaryColor)
                    : AppColors.primary,
              ),
            )
          : null,
    );
  }

  /// Network error state
  static Widget buildNetworkErrorState(
    MenuSettings? menuSettings,
    VoidCallback? onRetry,
  ) {
    return buildErrorState(
      menuSettings,
      'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
      onRetry,
    );
  }

  /// Hex string'i Color'a çevir
  static Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }
}
