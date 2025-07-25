import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Fatura/Fiş Talebi Sayfası
class InvoicePage extends StatefulWidget {
  final String? orderId;
  final String? businessId;

  const InvoicePage({
    super.key,
    this.orderId,
    this.businessId,
  });

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
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
          'Fatura & Fiş',
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
              Icons.receipt_rounded,
              size: 64,
              color: AppColors.info,
            ),
            SizedBox(height: 16),
            Text(
              'Dijital Fatura',
              style: AppTypography.h5,
            ),
            SizedBox(height: 8),
            Text(
              'Dijital fatura ve fiş sistemi yakında kullanılabilir olacak.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 