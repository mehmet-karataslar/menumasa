import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Çoklu Şube ve Merkezi Yönetim Sayfası
class MultiBranchPage extends StatefulWidget {
  final String businessId;

  const MultiBranchPage({
    super.key,
    required this.businessId,
  });

  @override
  State<MultiBranchPage> createState() => _MultiBranchPageState();
}

class _MultiBranchPageState extends State<MultiBranchPage> {
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
          'Şube Yönetimi',
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
              Icons.store_mall_directory_rounded,
              size: 64,
              color: AppColors.warning,
            ),
            SizedBox(height: 16),
            Text(
              'Çoklu Şube Yönetimi',
              style: AppTypography.h5,
            ),
            SizedBox(height: 8),
            Text(
              'Merkezi şube yönetimi sistemi yakında kullanılabilir olacak.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 