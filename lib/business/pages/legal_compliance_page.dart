import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Yasal Uyumluluk ve Dijital Dönüşüm Sayfası
class LegalCompliancePage extends StatefulWidget {
  final String businessId;

  const LegalCompliancePage({
    super.key,
    required this.businessId,
  });

  @override
  State<LegalCompliancePage> createState() => _LegalCompliancePageState();
}

class _LegalCompliancePageState extends State<LegalCompliancePage> {
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
          'Yasal Uyumluluk',
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
              Icons.gavel_rounded,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: 16),
            Text(
              'E-Fatura ve Yasal Entegrasyonlar',
              style: AppTypography.h5,
            ),
            SizedBox(height: 8),
            Text(
              'E-fatura, ÖKC ve muhasebe entegrasyonları yakında kullanılabilir olacak.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 