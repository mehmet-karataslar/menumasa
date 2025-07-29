import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../presentation/widgets/shared/loading_indicator.dart';

/// Loading state widget for QR Menu
class QRMenuLoading extends StatelessWidget {
  const QRMenuLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withOpacity(0.1), AppColors.background],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header skeleton
            Container(
              height: 180,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: AppColors.primaryGradient),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingIndicator(color: AppColors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Menü hazırlanıyor...',
                    style: AppTypography.h6.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),

            // Content skeleton
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Category skeleton
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) => Container(
                          width: 80,
                          height: 40,
                          margin: const EdgeInsets.only(right: 12),
                          child: Shimmer.fromColors(
                            baseColor: AppColors.greyLight.withOpacity(0.3),
                            highlightColor: AppColors.white.withOpacity(0.5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Product grid skeleton
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) => Shimmer.fromColors(
                          baseColor: AppColors.greyLight.withOpacity(0.3),
                          highlightColor: AppColors.white.withOpacity(0.5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
