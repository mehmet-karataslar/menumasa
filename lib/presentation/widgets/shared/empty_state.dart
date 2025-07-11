import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppDimensions.paddingL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppDimensions.iconSizeXXL,
              color: AppColors.textLight,
            ),
            AppSizedBox.h16,
            Text(
              title,
              style: AppTypography.h4.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            AppSizedBox.h8,
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onActionPressed != null) ...[
              AppSizedBox.h24,
              ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
