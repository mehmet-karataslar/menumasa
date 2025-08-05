import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../presentation/widgets/shared/empty_state.dart';

class ActivityLogsPage extends StatelessWidget {
  const ActivityLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: const Center(
        child: EmptyState(
          icon: Icons.history,
          title: 'Aktivite Logları',
          message: 'Bu sayfa yakında eklenecek',
        ),
      ),
    );
  }
} 