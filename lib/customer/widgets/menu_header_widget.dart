import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';

import '../../business/models/staff.dart';

/// 🏪 Menü Header Widget'ı
///
/// Bu widget menü sayfasının üst kısmını oluşturur:
/// - İşletme logosu ve bilgileri
/// - Sepet butonu
/// - Garson çağırma butonu
/// - Header butonları
class MenuHeaderWidget extends StatelessWidget {
  final Business? business;
  final MenuSettings? menuSettings;
  final int cartItemCount;
  final VoidCallback? onCartPressed;
  final VoidCallback? onWaiterCallPressed;
  final VoidCallback? onLanguagePressed;
  final List<Staff> waiters;
  final bool isWaiterCallLoading;

  const MenuHeaderWidget({
    super.key,
    this.business,
    this.menuSettings,
    required this.cartItemCount,
    this.onCartPressed,
    this.onWaiterCallPressed,
    this.onLanguagePressed,
    this.waiters = const [],
    this.isWaiterCallLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return _buildModernHeader();
  }

  Widget _buildModernHeader() {
    final primaryColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.primaryColor)
        : AppColors.primary;
    final secondaryColor = menuSettings != null
        ? _parseColor(menuSettings!.colorScheme.secondaryColor)
        : AppColors.secondary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
            secondaryColor.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(menuSettings?.layoutStyle.padding ?? 20,
              20, menuSettings?.layoutStyle.padding ?? 20, 20),
          child: Column(
            children: [
              // Üst bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // İşletme logosu ve bilgileri
                  Expanded(
                    child: Row(
                      children: [
                        _buildBusinessIcon(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                business?.businessName ?? 'Menü',
                                style: GoogleFonts.getFont(
                                  menuSettings?.typography.fontFamily ??
                                      'Poppins',
                                  fontSize:
                                      menuSettings?.typography.titleFontSize ??
                                          20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (business?.businessAddress.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  business!.businessAddress,
                                  style: GoogleFonts.getFont(
                                    menuSettings?.typography.fontFamily ??
                                        'Poppins',
                                    fontSize: menuSettings
                                            ?.typography.captionFontSize ??
                                        12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Header butonları
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildWaiterCallButton(),
                      const SizedBox(width: 12),
                      _buildCartHeaderButton(),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        icon: Icons.language_rounded,
                        onPressed: onLanguagePressed,
                        badgeCount: null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: business?.logoUrl?.isNotEmpty == true
          ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                business!.logoUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultBusinessIcon();
                },
              ),
            )
          : _buildDefaultBusinessIcon(),
    );
  }

  Widget _buildDefaultBusinessIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    VoidCallback? onPressed,
    int? badgeCount,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  color: iconColor ?? Colors.white,
                  size: 20,
                ),
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaiterCallButton() {
    return _buildHeaderButton(
      icon: isWaiterCallLoading
          ? Icons.hourglass_empty_rounded
          : Icons.room_service_rounded,
      onPressed: isWaiterCallLoading ? null : onWaiterCallPressed,
      backgroundColor: isWaiterCallLoading
          ? Colors.white.withOpacity(0.1)
          : Colors.white.withOpacity(0.2),
      iconColor:
          isWaiterCallLoading ? Colors.white.withOpacity(0.5) : Colors.white,
    );
  }

  Widget _buildCartHeaderButton() {
    return _buildHeaderButton(
      icon: Icons.shopping_cart_rounded,
      onPressed: onCartPressed,
      badgeCount: cartItemCount > 0 ? cartItemCount : null,
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
