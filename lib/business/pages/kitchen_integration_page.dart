import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Mutfak Entegrasyonu (KDS) Sayfası
class KitchenIntegrationPage extends StatefulWidget {
  final String businessId;

  const KitchenIntegrationPage({
    super.key,
    required this.businessId,
  });

  @override
  State<KitchenIntegrationPage> createState() => _KitchenIntegrationPageState();
}

class _KitchenIntegrationPageState extends State<KitchenIntegrationPage> {
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
          'Mutfak Entegrasyonu',
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
              Icons.kitchen_rounded,
              size: 64,
              color: AppColors.warning,
            ),
            SizedBox(height: 16),
            Text(
              'Kitchen Display System',
              style: AppTypography.h5,
            ),
            SizedBox(height: 8),
            Text(
              'Dijital mutfak ekranı ve sipariş takip sistemi yakında kullanılabilir olacak.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 