import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../business/models/product.dart';
import '../../business/models/category.dart';
import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/cart_service.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product)? onProductTap;
  final Function(Product)? onAddToCart;
  final EdgeInsets? padding;
  final int crossAxisCount;
  final double childAspectRatio;
  final bool isQRMenu;

  const ProductGrid({
    Key? key,
    required this.products,
    this.onProductTap,
    this.onAddToCart,
    this.padding,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
    this.isQRMenu = false,
  }) : super(key: key);

  double _calculateGridHeight() {
    if (products.isEmpty) return 200;
    
    final rows = (products.length / crossAxisCount).ceil();
    final itemHeight = 200 / childAspectRatio; // Ortalama item height
    final spacingHeight = (rows - 1) * 20; // mainAxisSpacing
    final paddingHeight = 40; // padding top + bottom
    
    return (rows * itemHeight) + spacingHeight + paddingHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(20),
      child: SizedBox(
        height: _calculateGridHeight(),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ModernProductCard(
              product: product,
              onTap: onProductTap != null ? () => onProductTap!(product) : null,
              onAddToCart: onAddToCart != null ? () => onAddToCart!(product) : null,
              index: index,
              isQRMenu: isQRMenu,
            );
          },
        ),
      ),
    );
  }
}

class ModernProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final int index;
  final bool isQRMenu;

  const ModernProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    required this.index,
    this.isQRMenu = false,
  }) : super(key: key);

  @override
  State<ModernProductCard> createState() => _ModernProductCardState();
}

class _ModernProductCardState extends State<ModernProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Staggered animation
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.product.hasDiscount;
    final isAvailable = widget.product.isAvailable;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onTap: widget.onTap != null ? () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              } : null,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section (60% of height)
                    Expanded(
                      flex: 6,
                      child: _buildCompactImageSection(hasDiscount, isAvailable),
                    ),
                    
                    // Info Section (40% of height)
                    Expanded(
                      flex: 4,
                      child: _buildCompactInfoSection(hasDiscount, isAvailable),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactImageSection(bool hasDiscount, bool isAvailable) {
    return Stack(
      children: [
        // Main Image
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            color: AppColors.greyLighter.withOpacity(0.5),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: widget.product.primaryImage?.url.isNotEmpty == true
                ? Image.network(
                    widget.product.primaryImage!.url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),
          ),
        ),

        // Top badges row
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status badges
              Row(
                children: _buildCompactBadges(),
              ),
              
              // Discount badge
              if (hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.product.formattedDiscountPercentage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Unavailable overlay
        if (!isAvailable)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tükendi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactInfoSection(bool hasDiscount, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product name (single line)
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Price and button row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Price section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current price
                    Text(
                      widget.product.formattedPrice,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasDiscount ? AppColors.accent : AppColors.primary,
                      ),
                    ),
                    
                    // Original price if discounted
                    if (hasDiscount)
                      Text(
                        widget.product.formattedOriginalPrice,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Add button
              if (isAvailable && widget.onAddToCart != null)
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onAddToCart!();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCompactBadges() {
    final badges = <Widget>[];

    if (widget.product.isNew) {
      badges.add(_buildCompactBadge('YENİ', AppColors.success));
    }

    if (widget.product.isPopular) {
      badges.add(_buildCompactBadge('POP', AppColors.warning));
    }

    if (widget.product.isVegetarian) {
      badges.add(_buildCompactBadge('V', AppColors.success));
    }

    if (widget.product.isSpicy) {
      badges.add(_buildCompactBadge('🌶', AppColors.error));
    }

    return badges.take(2).toList(); // Limit to 2 badges to prevent overflow
  }

  Widget _buildCompactBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.greyLighter,
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 28,
          color: AppColors.textSecondary.withOpacity(0.5),
        ),
      ),
    );
  }
}

// Modern List View version
class ModernProductList extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductTapped;
  final Function(Product)? onAddToCart;
  final EdgeInsets? padding;

  const ModernProductList({
    Key? key,
    required this.products,
    required this.onProductTapped,
    this.onAddToCart,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final product = products[index];
        return ModernProductListItem(
          product: product,
          onTap: () => onProductTapped(product),
          onAddToCart: onAddToCart != null ? () => onAddToCart!(product) : null,
          index: index,
        );
      },
    );
  }
}

class ModernProductListItem extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final int index;

  const ModernProductListItem({
    Key? key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    required this.index,
  }) : super(key: key);

  @override
  State<ModernProductListItem> createState() => _ModernProductListItemState();
}

class _ModernProductListItemState extends State<ModernProductListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Staggered animation
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.product.hasDiscount;
    final isAvailable = widget.product.isAvailable;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Product Image
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(16),
                          ),
                          color: AppColors.greyLighter.withOpacity(0.5),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(16),
                              ),
                              child: widget.product.primaryImage?.url.isNotEmpty == true
                                  ? Image.network(
                                      widget.product.primaryImage!.url,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildListImagePlaceholder(),
                                    )
                                  : _buildListImagePlaceholder(),
                            ),
                            
                            // Discount Badge
                            if (hasDiscount)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.product.formattedDiscountPercentage,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Product Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Name and badges
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  const SizedBox(height: 4),
                                  
                                  // Compact badges
                                  Row(
                                    children: _buildCompactListBadges(),
                                  ),
                                ],
                              ),

                              // Price and Add Button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.product.formattedPrice,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: hasDiscount 
                                                ? AppColors.accent 
                                                : AppColors.primary,
                                          ),
                                        ),
                                        if (hasDiscount)
                                          Text(
                                            widget.product.formattedOriginalPrice,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Add Button
                                  if (isAvailable && widget.onAddToCart != null)
                                    Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.mediumImpact();
                                          widget.onAddToCart!();
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.add_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCompactListBadges() {
    final badges = <Widget>[];

    if (widget.product.isNew) {
      badges.add(_buildListBadge('YENİ', AppColors.success));
    }

    if (widget.product.isPopular) {
      badges.add(_buildListBadge('POP', AppColors.warning));
    }

    if (widget.product.isVegetarian) {
      badges.add(_buildListBadge('V', AppColors.success));
    }

    if (widget.product.isSpicy) {
      badges.add(_buildListBadge('🌶', AppColors.error));
    }

    return badges.take(3).toList(); // Limit to 3 badges for list view
  }

  Widget _buildListBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListImagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: AppColors.greyLighter,
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 24,
          color: AppColors.textSecondary.withOpacity(0.5),
        ),
      ),
    );
  }
}