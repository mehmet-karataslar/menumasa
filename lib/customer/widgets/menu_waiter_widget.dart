import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../business/models/business.dart';
import '../../business/models/staff.dart';
import '../../core/constants/app_colors.dart';

import '../../core/widgets/web_safe_image.dart';

/// 👨‍💼 Menü Garson Widget'ı
///
/// Bu widget garson çağırma ve garson seçimi işlevlerini sağlar:
/// - Garson listesi
/// - Garson seçimi
/// - Garson çağırma butonu
/// - Garson bilgileri
class MenuWaiterWidget extends StatelessWidget {
  final MenuSettings? menuSettings;
  final List<Staff> waiters;
  final Function(Staff) onWaiterSelected;
  final bool isLoading;

  const MenuWaiterWidget({
    super.key,
    this.menuSettings,
    required this.waiters,
    required this.onWaiterSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return _buildWaiterSelectionDialog(context);
  }

  Widget _buildWaiterSelectionDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: menuSettings != null
                    ? _parseColor(menuSettings!.colorScheme.primaryColor)
                    : AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.room_service_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Garson Çağır',
                          style: GoogleFonts.getFont(
                            menuSettings?.typography.fontFamily ?? 'Poppins',
                            fontSize:
                                menuSettings?.typography.headingFontSize ?? 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Hangi garsonumuzu çağırmak istiyorsunuz?',
                          style: GoogleFonts.getFont(
                            menuSettings?.typography.fontFamily ?? 'Poppins',
                            fontSize:
                                menuSettings?.typography.captionFontSize ?? 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Waiter list
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (waiters.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_off_rounded,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Şu anda müsait garson bulunmuyor',
                      style: GoogleFonts.getFont(
                        menuSettings?.typography.fontFamily ?? 'Poppins',
                        fontSize: menuSettings?.typography.bodyFontSize ?? 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: waiters.length,
                  itemBuilder: (context, index) {
                    final waiter = waiters[index];
                    return _buildWaiterCard(context, waiter);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaiterCard(BuildContext context, Staff waiter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onWaiterSelected(waiter);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Waiter avatar
                _buildWaiterAvatar(waiter),
                const SizedBox(width: 16),

                // Waiter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${waiter.firstName} ${waiter.lastName}',
                        style: GoogleFonts.getFont(
                          menuSettings?.typography.fontFamily ?? 'Poppins',
                          fontSize: menuSettings?.typography.bodyFontSize ?? 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        waiter.role.name,
                        style: GoogleFonts.getFont(
                          menuSettings?.typography.fontFamily ?? 'Poppins',
                          fontSize:
                              menuSettings?.typography.captionFontSize ?? 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (waiter.isActive) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Müsait',
                              style: GoogleFonts.getFont(
                                menuSettings?.typography.fontFamily ??
                                    'Poppins',
                                fontSize:
                                    menuSettings?.typography.captionFontSize ??
                                        11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Call button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: menuSettings != null
                        ? _parseColor(menuSettings!.colorScheme.primaryColor)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.call_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaiterAvatar(Staff waiter) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: waiter.isActive ? AppColors.success : AppColors.borderLight,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: waiter.profileImageUrl?.isNotEmpty == true
            ? WebSafeImage(
                imageUrl: waiter.profileImageUrl!,
                fit: BoxFit.cover,
                width: 44,
                height: 44,
                errorWidget: (context, url, error) =>
                    _buildWaiterInitials(waiter),
              )
            : _buildWaiterInitials(waiter),
      ),
    );
  }

  Widget _buildWaiterInitials(Staff waiter) {
    final initials =
        '${waiter.firstName[0]}${waiter.lastName[0]}'.toUpperCase();

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: menuSettings != null
            ? _parseColor(menuSettings!.colorScheme.primaryColor)
                .withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.getFont(
            menuSettings?.typography.fontFamily ?? 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: menuSettings != null
                ? _parseColor(menuSettings!.colorScheme.primaryColor)
                : AppColors.primary,
          ),
        ),
      ),
    );
  }

  /// Waiter selection bottom sheet
  static void showWaiterSelectionSheet({
    required BuildContext context,
    required MenuSettings? menuSettings,
    required List<Staff> waiters,
    required Function(Staff) onWaiterSelected,
    bool isLoading = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MenuWaiterWidget(
        menuSettings: menuSettings,
        waiters: waiters,
        onWaiterSelected: onWaiterSelected,
        isLoading: isLoading,
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
