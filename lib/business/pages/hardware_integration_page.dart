import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Donanım Entegrasyonu Sayfası
class HardwareIntegrationPage extends StatefulWidget {
  final String businessId;

  const HardwareIntegrationPage({
    super.key,
    required this.businessId,
  });

  @override
  State<HardwareIntegrationPage> createState() => _HardwareIntegrationPageState();
}

class _HardwareIntegrationPageState extends State<HardwareIntegrationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'Donanım Entegrasyonu',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_rounded,
              size: 64,
              color: AppColors.info,
            ),
            SizedBox(height: 16),
            Text(
              'POS ve Donanım Entegrasyonu',
              style: AppTypography.h5,
            ),
            SizedBox(height: 8),
            Text(
              'POS, yazıcı ve diğer donanım entegrasyonları yakında kullanılabilir olacak.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 