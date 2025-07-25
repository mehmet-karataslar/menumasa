import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Maliyet Kontrolü ve Kârlılık Analizi Sayfası
class CostControlPage extends StatefulWidget {
  final String businessId;

  const CostControlPage({
    super.key,
    required this.businessId,
  });

  @override
  State<CostControlPage> createState() => _CostControlPageState();
}

class _CostControlPageState extends State<CostControlPage> {
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
          'Maliyet Kontrolü',
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
              Icons.trending_up_rounded,
              size: 64,
              color: AppColors.success,
            ),
            SizedBox(height: 16),
            Text(
              'Kârlılık Analizi',
              style: AppTypography.h5,
            ),
            SizedBox(height: 8),
            Text(
              'Maliyet kontrolü ve kârlılık analizi sistemi yakında kullanılabilir olacak.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 