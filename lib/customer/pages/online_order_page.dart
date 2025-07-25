import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Online Sipariş / Paket Servis Sayfası
class OnlineOrderPage extends StatefulWidget {
  final String? businessId;

  const OnlineOrderPage({
    super.key,
    this.businessId,
  });

  @override
  State<OnlineOrderPage> createState() => _OnlineOrderPageState();
}

class _OnlineOrderPageState extends State<OnlineOrderPage> {
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
          'Online Sipariş',
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
              Icons.delivery_dining_rounded,
              size: 64,
              color: AppColors.info,
            ),
            SizedBox(height: 16),
            Text(
              'Paket Servis',
              style: AppTypography.h5,
            ),
            SizedBox(height: 8),
            Text(
              'Online sipariş ve teslimat özellikleri yakında kullanılabilir olacak.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 