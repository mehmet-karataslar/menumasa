import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;
  final String? message;
  final bool showMessage;

  const LoadingIndicator({
    Key? key,
    this.size = AppDimensions.loadingIndicatorSize,
    this.color = AppColors.primary,
    this.message,
    this.showMessage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpinKitFadingCircle(color: color, size: size),
        if (showMessage && message != null) ...[
          const SizedBox(height: AppDimensions.spacing16),
          Text(
            message!,
            style: TextStyle(color: color, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class PulseLoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const PulseLoadingIndicator({
    Key? key,
    this.size = AppDimensions.loadingIndicatorSize,
    this.color = AppColors.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpinKitPulse(color: color, size: size);
  }
}

class DotsLoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const DotsLoadingIndicator({
    Key? key,
    this.size = AppDimensions.loadingIndicatorSize,
    this.color = AppColors.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpinKitThreeBounce(color: color, size: size);
  }
}
