import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';

class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryText;
  final IconData? icon;

  const ErrorMessage({
    Key? key,
    required this.message,
    this.onRetry,
    this.retryText,
    this.icon,
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
              icon ?? Icons.error_outline,
              size: AppDimensions.iconSizeXL,
              color: AppColors.error,
            ),
            AppSizedBox.h16,
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSizedBox.h24,
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                ),
                child: Text(retryText ?? 'Tekrar Dene'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
