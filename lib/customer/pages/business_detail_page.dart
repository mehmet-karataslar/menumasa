import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../business/models/business.dart';
import '../../business/models/category.dart';
import '../../business/models/category.dart' as category_model;
import '../../business/models/product.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/user.dart' as app_user;
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../widgets/business_header.dart';
import '../services/customer_firestore_service.dart';
import '../widgets/category_list.dart';
import '../widgets/product_grid.dart';
import 'menu_page.dart';

class BusinessDetailPage extends StatefulWidget {
  final Business business;
  final app_user.CustomerData? customerData;

  const BusinessDetailPage({
    super.key,
    required this.business,
    this.customerData,
  });

  @override
  State<BusinessDetailPage> createState() => _BusinessDetailPageState();
}

class _BusinessDetailPageState extends State<BusinessDetailPage>
    with TickerProviderStateMixin {
  final CustomerFirestoreService _customerFirestoreService = CustomerFirestoreService();
  final ScrollController _scrollController = ScrollController();

  List<Product> _products = [];
  List<category_model.Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;
  double _scrollOffset = 0.0;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _headerAnimation;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);

    // Initialize animations
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic));
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });

    // Update header animation based on scroll
    if (_scrollOffset > 100) {
      _headerAnimationController.forward();
    } else {
      _headerAnimationController.reverse();
    }
  }

  Future<void> _loadData() async {
    try {
      // Start animations
      _fadeAnimationController.forward();
      
      // Load products and categories
      final productsData = await _customerFirestoreService.getBusinessProducts(widget.business.id);
      final categoriesData = await _customerFirestoreService.getBusinessCategories(widget.business.id);

      setState(() {
        _products = productsData
            .map((data) => Product.fromJson(data, id: data['id']))
            .toList();
        _categories = categoriesData
            .map((data) => category_model.Category.fromJson(data, id: data['id']))
            .toList();
        _isLoading = false;
      });

      // Start slide animation after data is loaded
      _slideAnimationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildModernSliverAppBar(),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildBusinessContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingMenuButton(),
    );
  }

  Widget _buildModernSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Business cover image
            _buildBusinessCoverImage(),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.black.withOpacity(0.3),
                    AppColors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Business info overlay
            Positioned(
              bottom: 20,
              left: 72,
              right: 72,
              child: _buildBusinessInfoOverlay(),
            ),
          ],
        ),
      ),
      leading: _buildModernBackButton(),
      actions: [
        _buildFavoriteButton(),
        _buildShareButton(),
      ],
    );
  }

  Widget _buildBusinessCoverImage() {
    return Hero(
      tag: 'business_${widget.business.id}',
      child: Container(
        decoration: BoxDecoration(
          gradient: widget.business.logoUrl == null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                )
              : null,
        ),
        child: widget.business.logoUrl != null
            ? Image.network(
                widget.business.logoUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    Icons.store_rounded,
                    size: 120,
                    color: AppColors.white.withOpacity(0.3),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white.withOpacity(0.8)),
                    ),
                  );
                },
              )
            : Center(
                child: Icon(
                  Icons.store_rounded,
                  size: 120,
                  color: AppColors.white.withOpacity(0.3),
                ),
              ),
      ),
    );
  }

  Widget _buildBusinessInfoOverlay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business name and rating
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.business.businessName,
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildRatingWidget(),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Business type and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.business.businessType,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            '4.8',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.business.isOpen 
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
            style: AppTypography.bodyMedium.copyWith(
              color: widget.business.isOpen ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBackButton() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: _isFavorite ? AppColors.accent : AppColors.white,
        ),
        onPressed: () {
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
                  Text(_isFavorite ? 'Favorilere eklendi!' : 'Favorilerden çıkarıldı!'),
                ],
              ),
              backgroundColor: _isFavorite ? AppColors.accent : AppColors.info,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShareButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.share_rounded, color: AppColors.white),
        onPressed: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.share_rounded, color: AppColors.white),
                  const SizedBox(width: 12),
                  Text('İşletme paylaşıldı!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: LoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Container(
        margin: const EdgeInsets.all(20),
        child: ErrorMessage(
          message: _errorMessage!,
          onRetry: _loadData,
        ),
      );
    }

    return Column(
      children: [
        // Business details section
        _buildBusinessDetailsSection(),
        
        // Tab bar
        _buildModernTabBar(),
        
        // Tab content
        _buildTabContent(),
      ],
    );
  }

  Widget _buildBusinessDetailsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Hakkında',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.business.businessDescription,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Contact info
          _buildContactInfo(),
          
          const SizedBox(height: 24),
          
          // Quick stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.location_on_rounded,
          title: 'Adres',
          value: widget.business.businessAddress,
          color: AppColors.error,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.phone_rounded,
          title: 'Telefon',
                     value: widget.business.contactInfo.phone ?? 'Belirtilmemiş',
          color: AppColors.success,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.access_time_rounded,
          title: 'Çalışma Saatleri',
          value: '09:00 - 22:00',
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primaryLight.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.restaurant_menu_rounded,
              title: 'Ürün',
              value: '${_products.length}',
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.greyLight,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.category_rounded,
              title: 'Kategori',
              value: '${_categories.length}',
              color: AppColors.info,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.greyLight,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.star_rounded,
              title: 'Puan',
              value: '4.8',
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          title,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: Icon(Icons.grid_view_rounded),
            text: 'Menü',
          ),
          Tab(
            icon: Icon(Icons.photo_library_rounded),
            text: 'Galeri',
          ),
          Tab(
            icon: Icon(Icons.reviews_rounded),
            text: 'Yorumlar',
          ),
          Tab(
            icon: Icon(Icons.map_rounded),
            text: 'Konum',
          ),
        ],
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.bodyMedium,
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 500,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTab(),
          _buildGalleryTab(),
          _buildReviewsTab(),
          _buildLocationTab(),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    if (_products.isEmpty) {
      return EmptyState(
        icon: Icons.restaurant_menu_rounded,
        title: 'Menü Yok',
        message: 'Bu işletme henüz menüsünü yüklememiş.',
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _products.take(6).length,
      itemBuilder: (context, index) {
        return _buildMenuItemCard(_products[index]);
      },
    );
  }

  Widget _buildMenuItemCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
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
          // Product image
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.greyLighter,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primaryLight.withOpacity(0.05),
                  ],
                ),
              ),
              child: product.images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        product.images.first.url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildProductPlaceholder();
                        },
                      ),
                    )
                  : _buildProductPlaceholder(),
            ),
          ),
          
          // Product info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      product.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(2)} ₺',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPlaceholder() {
    return Center(
      child: Icon(
        Icons.restaurant_menu_rounded,
        size: 35,
        color: AppColors.primary.withOpacity(0.3),
      ),
    );
  }

  Widget _buildGalleryTab() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: EmptyState(
          icon: Icons.photo_library_rounded,
          title: 'Galeri Boş',
          message: 'Henüz fotoğraf eklenmemiş.',
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: EmptyState(
          icon: Icons.reviews_rounded,
          title: 'Yorum Yok',
          message: 'Henüz yorum yapılmamış.',
        ),
      ),
    );
  }

  Widget _buildLocationTab() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: EmptyState(
          icon: Icons.map_rounded,
          title: 'Harita',
          message: 'Konum bilgisi yakında eklenecek.',
        ),
      ),
    );
  }

  Widget _buildFloatingMenuButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
                     Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => MenuPage(
                 businessId: widget.business.id,
               ),
             ),
           );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.restaurant_menu_rounded, color: AppColors.white),
        label: Text(
          'Menüyü Görüntüle',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 