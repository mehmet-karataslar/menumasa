import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../presentation/widgets/shared/empty_state.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: const Center(
        child: EmptyState(
          icon: Icons.analytics,
          title: 'Analitikler',
          message: 'Bu sayfa yakında eklenecek',
        ),
      ),
    );
  }
} 