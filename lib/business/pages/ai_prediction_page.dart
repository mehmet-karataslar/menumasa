import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Yapay Zekâ Destekli Tahminleme Sayfası
class AIPredictionPage extends StatefulWidget {
  final String businessId;

  const AIPredictionPage({
    super.key,
    required this.businessId,
  });

  @override
  State<AIPredictionPage> createState() => _AIPredictionPageState();
}

class _AIPredictionPageState extends State<AIPredictionPage> {
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
          'AI Tahminleme',
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
              Icons.psychology_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'AI Destekli Tahminleme',
              style: AppTypography.h5,
            ),
            SizedBox(height: 8),
            Text(
              'Yapay zeka destekli satış ve stok tahminlemesi yakında kullanılabilir olacak.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 