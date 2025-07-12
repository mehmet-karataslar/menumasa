import 'package:flutter/material.dart';
import '../../../data/models/business.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
// CachedNetworkImage removed for Windows compatibility

class BusinessHeader extends StatelessWidget {
  final Business business;
  final VoidCallback? onSharePressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onLocationPressed;

  const BusinessHeader({
    Key? key,
    required this.business,
    this.onSharePressed,
    this.onCallPressed,
    this.onLocationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220, // Fixed height to match SliverAppBar expandedHeight
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Content
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Business logo - smaller size
                    _buildCompactBusinessLogo(),

                    const SizedBox(height: 8),

                    // Business name - smaller font
                    Text(
                      business.businessName,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Business description - smaller font
                    if (business.businessDescription.isNotEmpty)
                      Text(
                        business.businessDescription,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 12),

                    // Action buttons - compact version
                    _buildCompactActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessLogo() {
    return Container(
      width: AppDimensions.businessLogoSize,
      height: AppDimensions.businessLogoSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppDimensions.businessLogoBorderRadius,
        ),
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppDimensions.businessLogoBorderRadius,
        ),
        child: business.logoUrl != null
            ? Image.network(
                business.logoUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLogoPlaceholder();
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildLogoPlaceholder(),
              )
            : _buildLogoPlaceholder(),
      ),
    );
  }

  Widget _buildCompactBusinessLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: business.logoUrl != null
            ? Image.network(
                business.logoUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildCompactLogoPlaceholder();
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildCompactLogoPlaceholder(),
              )
            : _buildCompactLogoPlaceholder(),
      ),
    );
  }

  Widget _buildCompactLogoPlaceholder() {
    return Container(
      color: AppColors.white,
      child: const Icon(Icons.restaurant, size: 30, color: AppColors.primary),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      color: AppColors.white,
      child: Icon(
        Icons.restaurant,
        size: AppDimensions.businessLogoSize * 0.5,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Share button
        if (onSharePressed != null)
          _buildActionButton(
            icon: Icons.share,
            label: 'Paylaş',
            onPressed: onSharePressed!,
          ),

        // Call button
        if (business.contactInfo.phone.isNotEmpty)
          _buildActionButton(
            icon: Icons.phone,
            label: 'Ara',
            onPressed: onCallPressed ?? () => _defaultCallAction(),
          ),

        // Location button
        if (business.address.street.isNotEmpty)
          _buildActionButton(
            icon: Icons.location_on,
            label: 'Konum',
            onPressed: onLocationPressed ?? () => _defaultLocationAction(),
          ),
      ],
    );
  }

  Widget _buildCompactActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Share button
        if (onSharePressed != null)
          _buildCompactActionButton(
            icon: Icons.share,
            onPressed: onSharePressed!,
          ),

        // Call button
        if (business.contactInfo.phone.isNotEmpty)
          _buildCompactActionButton(
            icon: Icons.phone,
            onPressed: onCallPressed ?? () => _defaultCallAction(),
          ),

        // Location button
        if (business.address.street.isNotEmpty)
          _buildCompactActionButton(
            icon: Icons.location_on,
            onPressed: onLocationPressed ?? () => _defaultLocationAction(),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing12,
          vertical: AppDimensions.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.white, size: AppDimensions.iconSizeM),
            AppSizedBox.h4,
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
    );
  }

  void _defaultCallAction() {
    // URL launcher ile telefon araması yapılacak
    // await launch('tel:${business.contactInfo.phone}');
    print('Calling: ${business.contactInfo.phone}');
  }

  void _defaultLocationAction() {
    // Harita uygulamasında konum açılacak
    // await launch('https://maps.google.com/?q=${business.address.toString()}');
    print('Location: ${business.address.toString()}');
  }
}

// Animated version with slide-in effects
class AnimatedBusinessHeader extends StatefulWidget {
  final Business business;
  final VoidCallback? onSharePressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onLocationPressed;

  const AnimatedBusinessHeader({
    Key? key,
    required this.business,
    this.onSharePressed,
    this.onCallPressed,
    this.onLocationPressed,
  }) : super(key: key);

  @override
  State<AnimatedBusinessHeader> createState() => _AnimatedBusinessHeaderState();
}

class _AnimatedBusinessHeaderState extends State<AnimatedBusinessHeader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: BusinessHeader(
              business: widget.business,
              onSharePressed: widget.onSharePressed,
              onCallPressed: widget.onCallPressed,
              onLocationPressed: widget.onLocationPressed,
            ),
          ),
        );
      },
    );
  }
}

// Compact version for smaller screens
class CompactBusinessHeader extends StatelessWidget {
  final Business business;
  final VoidCallback? onSharePressed;

  const CompactBusinessHeader({
    Key? key,
    required this.business,
    this.onSharePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppDimensions.paddingM,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: business.logoUrl != null
                  ? Image.network(
                      business.logoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildCompactLogoPlaceholder();
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          _buildCompactLogoPlaceholder(),
                    )
                  : _buildCompactLogoPlaceholder(),
            ),
          ),

          AppSizedBox.w16,

          // Business info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  business.businessName,
                  style: AppTypography.h5.copyWith(color: AppColors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (business.businessDescription.isNotEmpty) ...[
                  AppSizedBox.h4,
                  Text(
                    business.businessDescription,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Share button
          if (onSharePressed != null)
            IconButton(
              onPressed: onSharePressed,
              icon: const Icon(Icons.share, color: AppColors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactLogoPlaceholder() {
    return Container(
      color: AppColors.white,
      child: const Icon(Icons.restaurant, size: 24, color: AppColors.primary),
    );
  }
}
