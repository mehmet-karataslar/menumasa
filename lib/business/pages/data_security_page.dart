import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Veri Güvenliği ve Altyapı Sayfası
class DataSecurityPage extends StatefulWidget {
  final String businessId;

  const DataSecurityPage({
    super.key,
    required this.businessId,
  });

  @override
  State<DataSecurityPage> createState() => _DataSecurityPageState();
}

class _DataSecurityPageState extends State<DataSecurityPage> {
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
          'Veri Güvenliği',
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
              Icons.security_rounded,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: 16),
            Text(
              'Veri Şifreleme ve Yedekleme',
              style: AppTypography.h5,
            ),
            SizedBox(height: 8),
            Text(
              'Güçlü veri güvenliği ve altyapı yönetimi yakında kullanılabilir olacak.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 