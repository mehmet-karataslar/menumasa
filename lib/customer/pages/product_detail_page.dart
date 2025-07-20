import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../business/models/product.dart';
import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/auth_service.dart';
import 'cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final Business business;

  const ProductDetailPage({
    Key? key,
    required this.product,
    required this.business,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = false;
  bool _isFavorite = false;
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleAnimationController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _scaleAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildModernSliverAppBar(),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildProductDetails(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideAnimationController,
          curve: Curves.easeOutCubic,
        )),
        child: _buildModernBottomBar(),
      ),
    );
  }

  Widget _buildModernSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: AppColors.white),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.white),
            onPressed: _onSharePressed,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
          decoration: BoxDecoration(
            color: AppColors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? AppColors.accent : AppColors.white,
            ),
            onPressed: _onFavoritePressed,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            _buildEnhancedImageCarousel(),
            // Gradient overlay for better readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.black.withOpacity(0.8),
                      AppColors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedImageCarousel() {
    final images = widget.product.images;

    if (images.isEmpty) {
      return _buildModernPlaceholderImage();
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
            HapticFeedback.lightImpact();
          },
          itemBuilder: (context, index) {
            return Hero(
              tag: 'product_image_${widget.product.productId}',
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(images[index].url),
                    fit: BoxFit.cover,
                    onError: (error, stackTrace) {},
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Enhanced image indicators
        if (images.length > 1)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                final isActive = _currentImageIndex == entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.white : AppColors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),
          ),

        // Availability overlay
        if (!widget.product.isAvailable)
          Positioned.fill(
            child: Container(
              color: AppColors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: AppColors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Geçici Olarak\nTükendi',
                      style: AppTypography.h5.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModernPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.greyLighter, AppColors.greyLight],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Ürün Görseli\nYükleniyor...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product header with modern design
        _buildModernProductHeader(),

        // Product description
        _buildModernProductDescription(),

        // Nutrition & Allergens with better design
        _buildModernNutritionAndAllergens(),

        // Product features with icons
        _buildModernProductFeatures(),

        // Similar products with enhanced cards
        _buildModernSimilarProducts(),

        // Extra space for bottom bar
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildModernProductHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name and badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.product.name,
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildModernProductBadges(),
              ],
            ),

            const SizedBox(height: 12),

            // Category with icon
            Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ana Yemekler', // This would come from category
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Enhanced price section
            _buildModernPriceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProductBadges() {
    return Column(
      children: [
        if (widget.product.tags.contains('new'))
          _buildModernBadge('YENİ', AppColors.success, Icons.fiber_new_rounded),
        const SizedBox(height: 8),
        if (widget.product.tags.contains('popular'))
          _buildModernBadge('POPÜLER', AppColors.warning, Icons.trending_up_rounded),
        const SizedBox(height: 8),
        if (widget.product.tags.contains('vegetarian'))
          _buildModernBadge('VEJETARYeN', AppColors.info, Icons.eco_rounded),
        const SizedBox(height: 8),
        if (widget.product.tags.contains('spicy'))
          _buildModernBadge('ACILI', AppColors.accent, Icons.local_fire_department_rounded),
      ],
    );
  }

  Widget _buildModernBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPriceSection() {
    final hasDiscount = widget.product.discountPercentage > 0;
    final discountedPrice = hasDiscount
        ? widget.product.price * (1 - widget.product.discountPercentage / 100)
        : widget.product.price;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.primaryLight.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fiyat',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Current price
                    Text(
                      '${discountedPrice.toStringAsFixed(2)} ₺',
                      style: AppTypography.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // Original price (if discounted)
                    if (hasDiscount) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${widget.product.price.toStringAsFixed(2)} ₺',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Discount badge
          if (hasDiscount)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '%${widget.product.discountPercentage.toInt()} İNDİRİM',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernProductDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Açıklama',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.product.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNutritionAndAllergens() {
    final hasNutrition = widget.product.nutritionInfo != null;
    final hasAllergens = widget.product.allergens.isNotEmpty;
    
    if (!hasNutrition && !hasAllergens) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Nutrition Facts
          if (hasNutrition) ...[
            _buildModernNutritionCard(),
            const SizedBox(height: 16),
          ],

          // Allergens
          if (hasAllergens) _buildModernAllergensCard(),
        ],
      ),
    );
  }

  Widget _buildModernNutritionCard() {
    final nutrition = widget.product.nutritionInfo!;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Besin Değerleri (100g)',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                if (nutrition.calories != null)
                  _buildModernNutritionRow(
                    'Kalori',
                    '${nutrition.calories} kcal',
                    Icons.local_fire_department_rounded,
                    AppColors.accent,
                  ),
                if (nutrition.protein != null)
                  _buildModernNutritionRow(
                    'Protein',
                    '${nutrition.protein}g',
                    Icons.fitness_center_rounded,
                    AppColors.primary,
                  ),
                if (nutrition.carbs != null)
                  _buildModernNutritionRow(
                    'Karbonhidrat',
                    '${nutrition.carbs}g',
                    Icons.grain_rounded,
                    AppColors.warning,
                  ),
                if (nutrition.fat != null)
                  _buildModernNutritionRow(
                    'Yağ',
                    '${nutrition.fat}g',
                    Icons.opacity_rounded,
                    AppColors.info,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNutritionRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAllergensCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Alerjen Uyarısı',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu ürün aşağıdaki alerjenleri içerebilir:',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: widget.product.allergens.map((allergen) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            allergen,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProductFeatures() {
    final features = <Map<String, dynamic>>[];

    if (widget.product.tags.contains('vegetarian')) {
      features.add({'name': 'Vejetaryen', 'icon': Icons.eco_rounded, 'color': AppColors.success});
    }
    if (widget.product.tags.contains('vegan')) {
      features.add({'name': 'Vegan', 'icon': Icons.nature_rounded, 'color': AppColors.success});
    }
    if (widget.product.tags.contains('spicy')) {
      features.add({'name': 'Acılı', 'icon': Icons.local_fire_department_rounded, 'color': AppColors.accent});
    }
    if (widget.product.tags.contains('gluten-free')) {
      features.add({'name': 'Glütensiz', 'icon': Icons.no_meals_rounded, 'color': AppColors.info});
    }
    if (widget.product.tags.contains('organic')) {
      features.add({'name': 'Organik', 'icon': Icons.spa_rounded, 'color': AppColors.primary});
    }

    if (features.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: AppColors.warning,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Özellikler',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: features.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: (feature['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (feature['color'] as Color).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      feature['icon'] as IconData,
                      size: 18,
                      color: feature['color'] as Color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature['name'] as String,
                      style: AppTypography.bodyMedium.copyWith(
                        color: feature['color'] as Color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSimilarProducts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
                 boxShadow: [
           BoxShadow(
             color: AppColors.shadow.withOpacity(0.08),
             blurRadius: 12,
             offset: const Offset(0, 4),
           ),
         ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.recommend_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Benzer Ürünler',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3, // Placeholder
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildModernSimilarProductCard(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSimilarProductCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLighter,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.1), AppColors.primaryLight.withOpacity(0.05)],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Benzer Ürün ${index + 1}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '25.00 ₺',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Modern quantity selector
            _buildModernQuantitySelector(),

            const SizedBox(width: 20),

            // Enhanced add to cart button
            Expanded(
              child: _buildModernAddToCartButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLighter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove_rounded,
            onPressed: _quantity > 1 ? _decreaseQuantity : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              '$_quantity',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add_rounded,
            onPressed: _increaseQuantity,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: onPressed != null ? AppColors.primary.withOpacity(0.1) : AppColors.greyLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: onPressed != null ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildModernAddToCartButton() {
    final isAvailable = widget.product.isAvailable;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        onPressed: isAvailable && !_isLoading ? _addToCart : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isAvailable ? AppColors.primary : AppColors.greyLight,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isAvailable ? 8 : 0,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isAvailable) ...[
                    Icon(Icons.shopping_cart_rounded, size: 20),
                    const SizedBox(width: 8), // Reduced spacing
                    Flexible(
                      child: Text(
                        'Sepete Ekle - ${_getTotalPrice().toStringAsFixed(2)} ₺',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.inventory_2_outlined, size: 20),
                    const SizedBox(width: 8), // Reduced spacing
                    Flexible(
                      child: Text(
                        'Geçici Olarak Tükendi',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  double _getTotalPrice() {
    final hasDiscount = widget.product.discountPercentage > 0;
    final unitPrice = hasDiscount
        ? widget.product.price * (1 - widget.product.discountPercentage / 100)
        : widget.product.price;
    return unitPrice * _quantity;
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
    HapticFeedback.lightImpact();
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _addToCart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _cartService.addToCart(
        widget.product,
        widget.business.id,
        quantity: _quantity,
      );

      setState(() {
        _isLoading = false;
      });

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${widget.product.name} sepete eklendi!'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Sepete Git',
              textColor: AppColors.white,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(
                      businessId: widget.business.id,
                      userId: _authService.currentUser?.uid,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Hata: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _onSharePressed() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.share_rounded, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Ürün paylaşıldı!')),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onFavoritePressed() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: AppColors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_isFavorite ? 'Favorilere eklendi!' : 'Favorilerden çıkarıldı!'),
            ),
          ],
        ),
        backgroundColor: _isFavorite ? AppColors.accent : AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

