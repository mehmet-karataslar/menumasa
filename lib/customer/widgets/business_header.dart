import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../services/customer_service.dart';

class BusinessHeader extends StatefulWidget {
  final Business business;
  final VoidCallback? onSharePressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onLocationPressed;
  final VoidCallback? onCartPressed;
  final int cartItemCount;
  final bool isCompact;
  final bool showActions; // Action butonlarını göster/gizle

  const BusinessHeader({
    Key? key,
    required this.business,
    this.onSharePressed,
    this.onCallPressed,
    this.onLocationPressed,
    this.onCartPressed,
    this.cartItemCount = 0,
    this.isCompact = false,
    this.showActions = true,
  }) : super(key: key);

  @override
  State<BusinessHeader> createState() => _BusinessHeaderState();
}

class _BusinessHeaderState extends State<BusinessHeader>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  final CustomerService _customerService = CustomerService();
  bool _isFavorite = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
    
    // Favori durumunu kontrol et
    _checkFavoriteStatus();
  }
  
  void _checkFavoriteStatus() {
    final currentCustomer = _customerService.currentCustomer;
    if (currentCustomer != null) {
      setState(() {
        _isFavorite = currentCustomer.favoriteBusinessIds.contains(widget.business.id);
      });
    }
  }

  Widget _buildFavoriteButton() {
    return _buildFloatingActionButton(
      icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      isActive: _isFavorite,
      onPressed: _isToggling ? null : () async {
        HapticFeedback.mediumImpact();
        await _toggleFavorite();
      },
    );
  }

  Future<void> _toggleFavorite() async {
    if (_isToggling) return;

    setState(() {
      _isToggling = true;
    });

    try {
      await _customerService.toggleFavorite(widget.business.id);
      _checkFavoriteStatus();
    } catch (e) {
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Favori durumu değiştirilemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: widget.isCompact ? 140 : 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
                AppColors.secondary.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              _buildBackgroundPattern(),
              
              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: widget.isCompact
                          ? _buildCompactLayout()
                          : _buildFullLayout(),
                    ),
                  ),
                ),
              ),

              // Action buttons overlay (sadece gerektiğinde göster)
              if (widget.showActions) _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1,
        child: CustomPaint(
          painter: HexagonPatternPainter(),
        ),
      ),
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      children: [
        // Business logo
        ScaleTransition(
          scale: _scaleAnimation,
          child: _buildModernBusinessLogo(size: 60),
        ),
        
        const SizedBox(width: 16),
        
        // Business info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.business.businessName,
                style: AppTypography.h5.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              _buildStatusIndicator(),
              
              const SizedBox(height: 8),
              
              _buildQuickInfo(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header section
          SizedBox(
            height: 200, // Fixed height for header section
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Business logo with pulse animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildModernBusinessLogo(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Business name with gradient text
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [AppColors.white, AppColors.white.withOpacity(0.8)],
                  ).createShader(bounds),
                  child: Text(
                    widget.business.businessName,
                    style: AppTypography.h3.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 6),

                // Business type badge
                _buildBusinessTypeBadge(),

                const SizedBox(height: 8),

                // Status indicator
                _buildStatusIndicator(),
              ],
            ),
          ),

          // Basit bilgi bölümü
          if (widget.showActions)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: _buildQuickInfo(),
            ),
        ],
      ),
    );
  }

  Widget _buildModernBusinessLogo({double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.white.withOpacity(0.3),
            AppColors.white.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: AppColors.white.withOpacity(0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: widget.business.logoUrl != null && widget.business.logoUrl!.isNotEmpty
            ? Image.network(
                widget.business.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildLogoPlaceholder(size),
              )
            : _buildLogoPlaceholder(size),
      ),
    );
  }

  Widget _buildLogoPlaceholder(double size) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withOpacity(0.3),
            AppColors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.store_rounded,
        size: size * 0.5,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildBusinessTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        widget.business.businessType,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.business.isOpen 
            ? AppColors.success.withOpacity(0.2)
            : AppColors.error.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.business.isOpen 
              ? AppColors.success.withOpacity(0.5)
              : AppColors.error.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.business.isOpen ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.business.isOpen ? 'Açık' : 'Kapalı',
            style: AppTypography.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo() {
    return Row(
      children: [
        _buildInfoChip(
          icon: Icons.star_rounded,
          text: '4.8',
          color: AppColors.warning,
        ),
        const SizedBox(width: 8),
        _buildInfoChip(
          icon: Icons.access_time_rounded,
          text: '25 dk',
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            icon: Icons.location_on_rounded,
            title: 'Adres',
            value: widget.business.businessAddress,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: AppColors.white.withOpacity(0.3),
        ),
        Expanded(
          child: _buildInfoItem(
            icon: Icons.phone_rounded,
            title: 'Telefon',
                         value: widget.business.contactInfo.phone ?? 'Belirtilmemiş',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.white, size: 18),
        const SizedBox(height: 2),
        Text(
          title,
          style: AppTypography.caption.copyWith(
            color: AppColors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 1),
        Flexible(
          child: Text(
            value,
            style: AppTypography.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.phone_rounded,
          label: 'Ara',
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onCallPressed?.call();
          },
        ),
        _buildActionButton(
          icon: Icons.location_on_rounded,
          label: 'Konum',
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onLocationPressed?.call();
          },
        ),
        _buildActionButton(
          icon: Icons.share_rounded,
          label: 'Paylaş',
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onSharePressed?.call();
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.white, size: 14),
            const SizedBox(width: 3),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildFavoriteButton(),
              const SizedBox(width: 12),
              _buildCartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.accent.withOpacity(0.9)
            : AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
              ? AppColors.accent
              : AppColors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon, 
          color: isActive ? AppColors.white : AppColors.white,
        ),
        iconSize: 20,
      ),
    );
  }

  Widget _buildCartButton() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.onCartPressed?.call();
            },
            icon: const Icon(Icons.shopping_cart_rounded, color: AppColors.white),
            iconSize: 20,
          ),
        ),
        
        if (widget.cartItemCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                widget.cartItemCount > 99 ? '99+' : widget.cartItemCount.toString(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// Custom painter for hexagon pattern
class HexagonPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double hexRadius = 30.0;
    const double hexHeight = hexRadius * 2;
    const double hexWidth = hexRadius * 1.732;

    for (double x = 0; x < size.width + hexWidth; x += hexWidth * 0.75) {
      for (double y = 0; y < size.height + hexHeight; y += hexHeight) {
        final offsetY = (x / (hexWidth * 0.75)).round() % 2 == 1 ? hexHeight / 2 : 0;
        _drawHexagon(canvas, paint, Offset(x, y + offsetY), hexRadius);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60.0) * (3.14159 / 180.0);
      final x = center.dx + radius * (angle == 0 ? 1 : (angle == 3.14159 ? -1 : 0));
      final y = center.dy + radius * (angle == 1.5708 ? 1 : (angle == 4.7124 ? -1 : 0));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
 