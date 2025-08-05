import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';

/// 🔍 Menü Arama Widget'ı
///
/// Bu widget menü sayfasının arama bölümünü oluşturur:
/// - Arama çubuğu
/// - Filtre butonları
/// - Arama sonuç sayısı
class MenuSearchWidget extends StatelessWidget {
  final MenuSettings? menuSettings;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback? onFilterPressed;
  final bool hasActiveFilters;
  final int resultCount;
  final bool isVisible;

  const MenuSearchWidget({
    super.key,
    this.menuSettings,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onFilterPressed,
    this.hasActiveFilters = false,
    this.resultCount = 0,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return _buildSearchSection();
  }

  Widget _buildSearchSection() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(menuSettings?.layoutStyle.padding ?? 20, 16,
          menuSettings?.layoutStyle.padding ?? 20, 12),
      child: Column(
        children: [
          // Arama çubuğu ve filtre butonu
          Row(
            children: [
              Expanded(
                child: _buildSearchField(),
              ),
              const SizedBox(width: 12),
              _buildFilterButton(),
            ],
          ),

          // Arama sonuç sayısı
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSearchResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: searchQuery.isNotEmpty
              ? _parseColor(menuSettings?.colorScheme.primaryColor ?? '#FF6B35')
              : AppColors.borderLight,
          width: searchQuery.isNotEmpty ? 2 : 1,
        ),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        style: GoogleFonts.getFont(
          menuSettings?.typography.fontFamily ?? 'Poppins',
          fontSize: menuSettings?.typography.bodyFontSize ?? 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Ürün, kategori ara...',
          hintStyle: GoogleFonts.getFont(
            menuSettings?.typography.fontFamily ?? 'Poppins',
            fontSize: menuSettings?.typography.bodyFontSize ?? 14,
            color: AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: searchQuery.isNotEmpty
                ? _parseColor(
                    menuSettings?.colorScheme.primaryColor ?? '#FF6B35')
                : AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () => onSearchChanged(''),
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  splashRadius: 20,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onFilterPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hasActiveFilters
                ? _parseColor(
                    menuSettings?.colorScheme.primaryColor ?? '#FF6B35')
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasActiveFilters
                  ? _parseColor(
                      menuSettings?.colorScheme.primaryColor ?? '#FF6B35')
                  : AppColors.borderLight,
              width: hasActiveFilters ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.tune_rounded,
                  color:
                      hasActiveFilters ? Colors.white : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _parseColor(menuSettings?.colorScheme.primaryColor ?? '#FF6B35')
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              _parseColor(menuSettings?.colorScheme.primaryColor ?? '#FF6B35')
                  .withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: _parseColor(
                menuSettings?.colorScheme.primaryColor ?? '#FF6B35'),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$searchQuery" için $resultCount sonuç',
              style: GoogleFonts.getFont(
                menuSettings?.typography.fontFamily ?? 'Poppins',
                fontSize: menuSettings?.typography.captionFontSize ?? 12,
                color: _parseColor(
                    menuSettings?.colorScheme.primaryColor ?? '#FF6B35'),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Filtreli',
                style: GoogleFonts.getFont(
                  menuSettings?.typography.fontFamily ?? 'Poppins',
                  fontSize: 10,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
      return AppColors.primary;
    }
  }
}
