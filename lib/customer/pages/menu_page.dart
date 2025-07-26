import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../business/models/business.dart';
import '../../business/models/category.dart';
import '../../business/models/product.dart';
import '../../business/models/discount.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/time_rule_utils.dart';
import '../../core/services/multilingual_service.dart';

import '../services/customer_firestore_service.dart';
import '../models/language_settings.dart';
import '../../business/services/business_firestore_service.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/url_service.dart';
import '../../core/services/auth_service.dart';
import '../widgets/business_header.dart';
import '../widgets/category_list.dart';
import '../widgets/product_grid.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import 'cart_page.dart';
import 'package:shimmer/shimmer.dart';
import 'customer_orders_page.dart';
import 'product_detail_page.dart';
import '../services/customer_service.dart';

class MenuPage extends StatefulWidget {
  final String businessId;

  const MenuPage({Key? key, required this.businessId}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  TabController? _tabController;
  late ScrollController _scrollController;
  late ScrollController _categoryScrollController;

  // State
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Data
  Business? _business;
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Discount> _discounts = [];

  // Services
  final _customerFirestoreService = CustomerFirestoreService();
  final _businessFirestoreService = BusinessFirestoreService();
  final _cartService = CartService();
  final _urlService = UrlService();
  final _authService = AuthService();
  final _multilingualService = MultilingualService();
  final _customerService = CustomerService();

  // UI State
  String _searchQuery = '';
  String? _selectedCategoryId;
  Map<String, dynamic> _filters = {};
  bool _showSearchBar = false;
  int _cartItemCount = 0;
  double _headerOpacity = 1.0;
  String _currentLanguage = 'tr';
  List<String> _favoriteProductIds = [];

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initAnimations();
    _determineUserLanguage();
    _loadMenuData();
    _initializeCart();
  }

  void _initControllers() {
    _scrollController = ScrollController();
    _categoryScrollController = ScrollController();

    _scrollController.addListener(() {
      final opacity = (100 - _scrollController.offset) / 100;
      setState(() {
        _headerOpacity = opacity.clamp(0.0, 1.0);
      });
    });
  }

  void _initAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutBack));

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _fabAnimationController.dispose();
    _cartService.removeCartListener(_onCartChanged);
    super.dispose();
  }

  Future<void> _initializeCart() async {
    await _cartService.initialize();
    _cartService.addCartListener(_onCartChanged);
    _updateCartCount();
  }

  void _onCartChanged(cart) {
    _updateCartCount();
  }

  Future<void> _updateCartCount() async {
    final count = await _cartService.getCartItemCount(widget.businessId);
    if (mounted) {
      setState(() {
        _cartItemCount = count;
      });

      // FAB animasyonu
      if (count > 0) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    }
  }

  Future<void> _loadMenuData() async {
    try {
      print('🔄 MenuPage: Loading menu data for business: ${widget.businessId}');
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

             // Load business, categories, products, and discounts
       print('📊 MenuPage: Loading business data...');
       final businessData = await _businessFirestoreService.getBusiness(widget.businessId);
       print('📊 MenuPage: Business data loaded: ${businessData?.name ?? 'null'}');
       
       print('📂 MenuPage: Loading categories...');
       final categoriesData = await _businessFirestoreService.getBusinessCategories(widget.businessId);
       print('📂 MenuPage: Categories loaded: ${categoriesData.length} items');
       
       print('🍽️ MenuPage: Loading products...');
       final productsData = await _businessFirestoreService.getBusinessProducts(widget.businessId);
       print('🍽️ MenuPage: Products loaded: ${productsData.length} items');
       
       print('🎯 MenuPage: Loading discounts...');
       final discountsData = await _businessFirestoreService.getDiscountsByBusinessId(widget.businessId);
       print('🎯 MenuPage: Discounts loaded: ${discountsData.length} items');

      // Load favorite products
      List<String> favoriteProductIds = [];
      try {
        final favoriteProducts = await _customerService.getFavoriteProducts();
        favoriteProductIds = favoriteProducts.map((f) => f.productId).toList();
      } catch (e) {
        print('Favori ürünler yüklenirken hata: $e');
        favoriteProductIds = [];
      }

      if (businessData != null) {
        print('✅ MenuPage: Business data is valid, processing...');
        // Apply multilingual translations
        final translatedCategories = categoriesData; // .map((category) =>
            // _multilingualService.translateCategory(category, _currentLanguage)).toList();
        final translatedProducts = productsData; // .map((product) =>
            // _multilingualService.translateProduct(product, _currentLanguage)).toList();

        print('🔄 MenuPage: Setting state with loaded data...');
        setState(() {
          _business = businessData;
          _categories = translatedCategories;
          _products = translatedProducts;
          _discounts = discountsData;
          _favoriteProductIds = favoriteProductIds;
          _filterProducts();
          _isLoading = false;
        });
        print('✅ MenuPage: State updated successfully');

        // Initialize tab controller after categories are loaded
        if (_categories.isNotEmpty && _tabController == null) {
          _tabController = TabController(length: _categories.length, vsync: this);
          _tabController?.addListener(_onTabChanged);
        }

        // Log business visit
        // _logBusinessVisit();
      } else {
        print('❌ MenuPage: Business data is null');
        setState(() {
          _hasError = true;
          _errorMessage = 'İşletme bilgileri yüklenirken bir hata oluştu.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ MenuPage: Exception occurred: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Veriler yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeTabs() {
    if (_categories.isNotEmpty) {
      _tabController?.dispose();
      _tabController = TabController(length: _categories.length + 1, vsync: this);
      _tabController!.addListener(_onTabChanged);

      if (_selectedCategoryId == null) {
        _selectedCategoryId = 'all';
      }
    }
  }

  void _onTabChanged() {
    if (_tabController != null && !_tabController!.indexIsChanging) return;

    final categoryId = _tabController!.index == 0
        ? 'all'
        : _categories[_tabController!.index - 1].categoryId;

    _onCategorySelected(categoryId);
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filterProducts();
    });
    HapticFeedback.selectionClick();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterProducts();
    });
  }

  void _onFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters;
      _filterProducts();
    });
  }

  void _filterProducts() {
    _filteredProducts = _products.where((product) {
      // Kategori filtresi
      if (_selectedCategoryId != null &&
          _selectedCategoryId != 'all' &&
          product.categoryId != _selectedCategoryId) {
        return false;
      }

      // Arama filtresi
      if (_searchQuery.isNotEmpty &&
          !product.matchesSearchQuery(_searchQuery)) {
        return false;
      }

      // Zaman kuralları
      if (!TimeRuleUtils.isProductVisible(product)) {
        return false;
      }

      // Diğer filtreler
      return product.matchesFilters(
        tagFilters: _filters['tags'],
        allergenFilters: _filters['allergens'],
        minPrice: _filters['minPrice'],
        maxPrice: _filters['maxPrice'],
        isVegetarian: _filters['isVegetarian'],
        isVegan: _filters['isVegan'],
        isHalal: _filters['isHalal'],
        isSpicy: _filters['isSpicy'],
      );
    }).toList();

    // İndirim hesapla
    _filteredProducts = _filteredProducts.map((product) {
      final finalPrice = product.calculateFinalPrice(_discounts);
      return product.copyWith(currentPrice: finalPrice);
    }).toList();

    // Kategorileri filtrele
    _categories = _categories.where((category) {
      return TimeRuleUtils.isCategoryVisible(category);
    }).toList();
  }

  void _showFilterBottomSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilters: _filters,
        onFiltersChanged: _onFiltersChanged,
      ),
    );
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchQuery = '';
        _filterProducts();
      }
    });
    HapticFeedback.lightImpact();
  }

  void _onCartPressed() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/menu/${widget.businessId}/cart?t=$timestamp';
    _urlService.updateUrl(dynamicRoute, customTitle: 'Sepetim | MasaMenu');

    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          businessId: widget.businessId,
          userId: _authService.currentUser?.uid,
        ),
        settings: RouteSettings(name: dynamicRoute),
      ),
    );
  }

  void _onOrdersPressed() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/menu/${widget.businessId}/orders?t=$timestamp';
    _urlService.updateUrl(dynamicRoute, customTitle: 'Siparişlerim | MasaMenu');

    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerOrdersPage(
          businessId: widget.businessId,
          customerPhone: null,
          customerId: null,
        ),
        settings: RouteSettings(name: dynamicRoute),
      ),
    );
  }

  void _navigateToProductDetail(Product product) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute = '/menu/${widget.businessId}/product/${product.productId}?t=$timestamp';
    _urlService.updateUrl(dynamicRoute, customTitle: '${product.name} | MasaMenu');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          product: product,
          business: _business!,
        ),
        settings: RouteSettings(name: dynamicRoute),
      ),
    );
  }

  Future<void> _toggleProductFavorite(Product product) async {
    try {
      await _customerService.toggleProductFavorite(product.productId, product.businessId);
      
      // Favori listesini güncelle
      final favoriteProducts = await _customerService.getFavoriteProducts();
      final favoriteProductIds = favoriteProducts.map((f) => f.productId).toList();
      
      setState(() {
        _favoriteProductIds = favoriteProductIds;
      });
      
      // Kullanıcıya bilgi ver
      final isFavorite = favoriteProductIds.contains(product.productId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isFavorite 
                      ? '${product.name} favorilere eklendi'
                      : '${product.name} favorilerden çıkarıldı',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: isFavorite ? AppColors.success : AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Favori işlemi hatası: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _addToCart(Product product, {int quantity = 1}) async {
    try {
      // Debug logging
      print('🛒 Adding to cart: ${product.name}');
      print('   Product ID: ${product.productId}'); 
      print('   Price: ${product.price}');
      print('   Current Price: ${product.currentPrice}');
      
      await _cartService.addToCart(product, widget.businessId, quantity: quantity);
      
      // Debug: Check cart contents
      final cart = await _cartService.getCurrentCart(widget.businessId);
      print('🛒 Cart now has ${cart.items.length} unique items:');
      for (var item in cart.items) {
        print('   - ${item.productName} (ID: ${item.productId}) x${item.quantity}');
      }
      
      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.check_rounded, color: AppColors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${product.name} sepete eklendi',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Sepete Git',
              textColor: AppColors.white,
              onPressed: _onCartPressed,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Hata: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
          ? _buildErrorState()
          : _buildMenuContent(),
      floatingActionButton: _buildCartFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCartFAB() {
    return AnimatedBuilder(
      animation: _fabScaleAnimation,
      builder: (context, child) {
        if (_cartItemCount == 0) return const SizedBox.shrink();

        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(25),
              color: AppColors.primary,
              child: InkWell(
                onTap: _onCartPressed,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(Icons.shopping_cart_rounded,
                              color: AppColors.white, size: 24),
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.white, width: 2),
                              ),
                              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                              child: Text(
                                _cartItemCount > 99 ? '99+' : _cartItemCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sepete Git ($_cartItemCount)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
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

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withOpacity(0.1), AppColors.background],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header skeleton
            Container(
              height: 180,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: AppColors.primaryGradient),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingIndicator(color: AppColors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Menü hazırlanıyor...',
                    style: AppTypography.h6.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),

            // Content skeleton
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Category skeleton
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) => Container(
                          width: 80,
                          height: 40,
                          margin: const EdgeInsets.only(right: 12),
                          child: Shimmer.fromColors(
                            baseColor: AppColors.greyLight.withOpacity(0.3),
                            highlightColor: AppColors.white.withOpacity(0.5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Product grid skeleton
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) => Shimmer.fromColors(
                          baseColor: AppColors.greyLight.withOpacity(0.3),
                          highlightColor: AppColors.white.withOpacity(0.5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.error.withOpacity(0.1), AppColors.background],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    size: 60,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Menü Yüklenemedi',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Bir hata oluştu, lütfen tekrar deneyin',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _loadMenuData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernHeader(),
              if (_showSearchBar) _buildSearchSection(),
              _buildCategorySection(),
              _buildProductSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                    AppColors.secondary.withOpacity(0.9),
                  ],
                ),
              ),
            ),

            // Decorative pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _HeaderPatternPainter(),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        // Business Avatar
                        Hero(
                          tag: 'business_avatar_${widget.businessId}',
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.white,
                                  AppColors.white.withOpacity(0.95),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: _business?.logoUrl != null
                                  ? Image.network(
                                _business!.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildBusinessIcon(),
                              )
                                  : _buildBusinessIcon(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Business Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _business?.businessName ?? 'Restoran',
                                style: AppTypography.h4.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _business?.businessType ?? 'Restoran',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: (_business?.isOpen == true
                                          ? AppColors.success
                                          : AppColors.error).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: _business?.isOpen == true
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _business?.isOpen == true ? 'Açık' : 'Kapalı',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      actions: [
        _buildHeaderButton(
          icon: _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
          onPressed: _toggleSearchBar,
        ),
        _buildHeaderButton(
          icon: Icons.tune_rounded,
          onPressed: _showFilterBottomSheet,
        ),
        _buildHeaderButton(
          icon: Icons.receipt_long_rounded,
          onPressed: _onOrdersPressed,
        ),
        _buildCartHeaderButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBusinessIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        size: 35,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppColors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildCartHeaderButton() {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _onCartPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                ),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        _cartItemCount > 9 ? '9+' : _cartItemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
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
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.greyLighter.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.greyLight.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ürün, kategori ara...',
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _onSearchChanged(''),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    if (_categories.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategoriler',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 45,
                child: ListView.builder(
                  controller: _categoryScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCategoryChip(
                        categoryId: 'all',
                        name: 'Tümü',
                        isSelected: _selectedCategoryId == 'all' || _selectedCategoryId == null,
                        icon: Icons.apps_rounded,
                      );
                    }

                    final category = _categories[index - 1];
                    return _buildCategoryChip(
                      categoryId: category.categoryId,
                      name: category.name,
                      isSelected: _selectedCategoryId == category.categoryId,
                      icon: _getCategoryIcon(category.name),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String categoryId,
    required String name,
    required bool isSelected,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _onCategorySelected(categoryId),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
                  : null,
              color: isSelected ? null : AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppColors.greyLight.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ]
                  : [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? AppColors.white
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.white
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('pizza')) return Icons.local_pizza_rounded;
    if (name.contains('burger') || name.contains('hamburger')) return Icons.lunch_dining_rounded;
    if (name.contains('içecek') || name.contains('drink')) return Icons.local_drink_rounded;
    if (name.contains('tatlı') || name.contains('dessert')) return Icons.cake_rounded;
    if (name.contains('kahve') || name.contains('coffee')) return Icons.local_cafe_rounded;
    if (name.contains('salata') || name.contains('salad')) return Icons.eco_rounded;
    if (name.contains('et') || name.contains('meat')) return Icons.restaurant_rounded;
    if (name.contains('balık') || name.contains('fish')) return Icons.set_meal_rounded;
    return Icons.restaurant_menu_rounded;
  }

  Widget _buildProductSection() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: AppColors.background,
          child: _filteredProducts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
            onRefresh: _loadMenuData,
            color: AppColors.primary,
            child: _buildProductGrid(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      title = 'Ürün Bulunamadı';
      subtitle = 'Aradığınız "${_searchQuery}" için sonuç bulunamadı.\nFarklı bir arama deneyin.';
      icon = Icons.search_off_rounded;
    } else if (_selectedCategoryId != null && _selectedCategoryId != 'all') {
      title = 'Bu kategoride ürün yok';
      subtitle = 'Seçilen kategoride henüz ürün bulunmuyor.';
      icon = Icons.category_outlined;
    } else {
      title = 'Henüz ürün eklenmemiş';
      subtitle = 'Bu işletmede henüz ürün bulunmuyor.';
      icon = Icons.restaurant_menu_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.greyLighter.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 50,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _onSearchChanged('');
                if (_showSearchBar) _toggleSearchBar();
              },
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Aramayı Temizle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85, // More square ratio for compact design
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildCompactProductCard(product, index);
      },
    );
  }

  Widget _buildCompactProductCard(Product product, int index) {
    final hasDiscount = product.currentPrice != null &&
        product.currentPrice! < product.price;
    final discountPercentage = hasDiscount
        ? ((1 - (product.currentPrice! / product.price)) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (65% of height)
            Expanded(
              flex: 65,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: AppColors.greyLighter.withOpacity(0.3),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildCompactIcon(),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildCompactIcon();
                              },
                            )
                          : _buildCompactIcon(),
                    ),
                  ),

                  // Top buttons row
                  Positioned(
                    top: 6,
                    left: 6,
                    right: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Favorite button
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => _toggleProductFavorite(product),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _favoriteProductIds.contains(product.productId)
                                    ? Icons.favorite_rounded 
                                    : Icons.favorite_border_rounded,
                                color: _favoriteProductIds.contains(product.productId)
                                    ? AppColors.accent 
                                    : AppColors.textSecondary,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                        
                        // Discount Badge
                        if (hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-%$discountPercentage',
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

                  // Unavailable Overlay
                  if (!product.isAvailable)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.black.withOpacity(0.7),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
              ),
            ),

            // Info Section (35% of height)
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name (single line)
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Price and Button Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Current Price
                              Text(
                                '${(product.currentPrice ?? product.price).toStringAsFixed(0)} ₺',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: hasDiscount
                                      ? AppColors.accent
                                      : AppColors.primary,
                                ),
                              ),
                              
                              // Original Price (if discounted)
                              if (hasDiscount)
                                Text(
                                  '${product.price.toStringAsFixed(0)} ₺',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Add Button
                        if (product.isAvailable)
                          GestureDetector(
                            onTap: () => _addToCart(product),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 16,
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
    );
  }

  Widget _buildCompactIcon() {
    return Container(
      width: double.infinity,
      height: double.infinity,
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

  Widget _buildProductIcon() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.greyLighter,
            AppColors.greyLight.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 40,
          color: AppColors.textSecondary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.greyLighter,
            AppColors.greyLight.withOpacity(0.3),
          ],
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.greyLight.withOpacity(0.3),
        highlightColor: AppColors.white.withOpacity(0.7),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // MULTILINGUAL METHODS
  // ============================================================================

  Future<void> _determineUserLanguage() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final language = await _multilingualService.determineUserLanguage(userId);
        setState(() {
          _currentLanguage = language;
        });
      }
    } catch (e) {
      print('Dil belirleme hatası: $e');
    }
  }

  Future<String> _getTranslatedText({
    required String entityId,
    required String entityType,
    required String fieldName,
    required String fallbackText,
  }) async {
    try {
      return await _multilingualService.getTranslation(
        entityId: entityId,
        entityType: entityType,
        fieldName: fieldName,
        languageCode: _currentLanguage,
        fallbackContent: fallbackText,
      );
    } catch (e) {
      print('Çeviri alma hatası: $e');
      return fallbackText;
    }
  }
}

// Header pattern painter
class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Diagonal pattern
    const spacing = 40.0;
    for (double i = -size.height; i < size.width; i += spacing) {
      final path = Path();
      path.moveTo(i, 0);
      path.lineTo(i + size.height, size.height);
      path.lineTo(i + size.height + 2, size.height);
      path.lineTo(i + 2, 0);
      path.close();
      canvas.drawPath(path, paint);
    }

    // Dots pattern
    final dotPaint = Paint()
      ..color = AppColors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}