import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Sadakat ve CRM Yönetimi Sayfası
class CRMManagementPage extends StatefulWidget {
  final String businessId;

  const CRMManagementPage({
    super.key,
    required this.businessId,
  });

  @override
  State<CRMManagementPage> createState() => _CRMManagementPageState();
}

class _CRMManagementPageState extends State<CRMManagementPage> {
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
          'CRM Yönetimi',
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
              Icons.people_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'Müşteri İlişkileri Yönetimi',
              style: AppTypography.h5,
            ),
            SizedBox(height: 8),
            Text(
              'CRM ve sadakat programı yönetimi sistemi yakında kullanılabilir olacak.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 