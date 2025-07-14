import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../presentation/widgets/shared/empty_state.dart';

class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: const Center(
        child: EmptyState(
          icon: Icons.settings,
          title: 'Sistem Ayarları',
          message: 'Bu sayfa yakında eklenecek',
        ),
      ),
    );
  }
} 