import 'package:flutter/material.dart';
import '../../data/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
// CachedNetworkImage removed for Windows compatibility

class BusinessHeader extends StatelessWidget {
  final Business business;
  final VoidCallback? onSharePressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onLocationPressed;
  final VoidCallback? onCartPressed;
  final int cartItemCount;

  const BusinessHeader({
    Key? key,
    required this.business,
    this.onSharePressed,
    this.onCallPressed,
    this.onLocationPressed,
    this.onCartPressed,
    this.cartItemCount = 0,
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

          // Cart button - positioned at top right
          if (onCartPressed != null)
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(child: _buildCartButton()),
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
                  return _buildLogoPlaceholder();
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildLogoPlaceholder(),
              )
            : _buildLogoPlaceholder(),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.store,
        color: AppColors.greyLight,
        size: 30,
      ),
    );
  }

  Widget _buildBusinessInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Business name
        Text(
          business.businessName,
          style: AppTypography.h2.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Business type and rating
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                business.businessType,
                style: AppTypography.caption.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildRatingBadge(),
          ],
        ),

        const SizedBox(height: 8),

        // Business description
        if (business.businessDescription.isNotEmpty)
          Text(
            business.businessDescription,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white.withOpacity(0.9),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

        const SizedBox(height: 8),

        // Status and location
        Row(
          children: [
            _buildStatusBadge(),
            const SizedBox(width: 12),
            Icon(
              Icons.location_on,
              color: AppColors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                business.businessAddress,
                style: AppTypography.caption.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: AppColors.warning,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            '4.5',
            style: AppTypography.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: business.isOpen ? AppColors.success : AppColors.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            business.isOpen ? 'Açık' : 'Kapalı',
            style: AppTypography.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (onSharePressed != null)
          _buildCompactActionButton(
            icon: Icons.share,
            label: 'Paylaş',
            onPressed: onSharePressed!,
          ),
        if (onCallPressed != null)
          _buildCompactActionButton(
            icon: Icons.phone,
            label: 'Ara',
            onPressed: onCallPressed!,
          ),
        if (onLocationPressed != null)
          _buildCompactActionButton(
            icon: Icons.location_on,
            label: 'Konum',
            onPressed: onLocationPressed!,
          ),
      ],
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.white,
                size: 16,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: AppDimensions.paddingHorizontalM,
      child: Row(
        children: [
          if (onSharePressed != null)
            Expanded(
              child: _buildActionButton(
                icon: Icons.share,
                label: 'Paylaş',
                onPressed: onSharePressed!,
              ),
            ),
          if (onSharePressed != null && onCallPressed != null)
            const SizedBox(width: 12),
          if (onCallPressed != null)
            Expanded(
              child: _buildActionButton(
                icon: Icons.phone,
                label: 'Ara',
                onPressed: onCallPressed!,
              ),
            ),
          if ((onSharePressed != null || onCallPressed != null) && 
              onLocationPressed != null)
            const SizedBox(width: 12),
          if (onLocationPressed != null)
            Expanded(
              child: _buildActionButton(
                icon: Icons.location_on,
                label: 'Konum',
                onPressed: onLocationPressed!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: AppColors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.white,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    return Material(
      color: AppColors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onCartPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.shopping_cart,
                color: AppColors.white,
                size: 24,
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      cartItemCount > 99 ? '99+' : cartItemCount.toString(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 