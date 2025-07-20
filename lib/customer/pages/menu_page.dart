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
import '../../core/services/data_service.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/url_service.dart';
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

class MenuPage extends StatefulWidget {
  final String businessId;

  const MenuPage({Key? key, required this.businessId}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  TabController? _tabController;
  late ScrollController _scrollController;

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
  final _dataService = DataService();
  final _cartService = CartService();
  final _urlService = UrlService();

  // UI State
  String _searchQuery = '';
  String? _selectedCategoryId;
  Map<String, dynamic> _filters = {};
  bool _showSearchBar = false;
  int _cartItemCount = 0;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic));
    
    _loadMenuData();
    _initializeCart();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
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
    }
  }

  Future<void> _loadMenuData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      _business = await _dataService.getBusiness(widget.businessId);
      if (_business == null) {
        throw Exception('İşletme bulunamadı');
      }

      _categories = await _dataService.getCategories(
        businessId: widget.businessId,
      );
      _products = await _dataService.getProducts(businessId: widget.businessId);
      _discounts = await _dataService.getDiscountsByBusinessId(
        widget.businessId,
      );

      _filterProducts();

      if (_categories.isNotEmpty) {
        _tabController?.dispose();
        
        _tabController = TabController(length: _categories.length, vsync: this);

        _tabController!.addListener(() {
          if (_tabController!.indexIsChanging) {
            _onCategorySelected(_categories[_tabController!.index].categoryId);
          }
        });
        
        if (_selectedCategoryId == null && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.categoryId;
        }
      } else {
        _tabController?.dispose();
        _tabController = null;
      }

      setState(() {
        _isLoading = false;
      });

      _fadeAnimationController.forward();
      _slideAnimationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Menü yüklenirken bir hata oluştu: $e';
      });
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filterProducts();
    });
    HapticFeedback.lightImpact();
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
      if (_selectedCategoryId != null &&
          _selectedCategoryId != 'all' &&
          product.categoryId != _selectedCategoryId) {
        return false;
      }

      if (_searchQuery.isNotEmpty &&
          !product.matchesSearchQuery(_searchQuery)) {
        return false;
      }

      if (!TimeRuleUtils.isProductVisible(product)) {
        return false;
      }

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

    _filteredProducts = _filteredProducts.map((product) {
      final finalPrice = product.calculateFinalPrice(_discounts);
      return product.copyWith(currentPrice: finalPrice);
    }).toList();

    _categories = _categories.where((category) {
      return TimeRuleUtils.isCategoryVisible(category);
    }).toList();
  }

  void _showFilterBottomSheet() {
    HapticFeedback.lightImpact();
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
    
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(businessId: widget.businessId),
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'businessId': widget.businessId,
            'timestamp': timestamp,
          },
        ),
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
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'businessId': widget.businessId,
            'timestamp': timestamp,
          },
        ),
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
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'product': product,
            'business': _business,
            'businessId': widget.businessId,
            'timestamp': timestamp,
          },
        ),
      ),
    );
  }

  Future<void> _addToCart(Product product, {int quantity = 1}) async {
    try {
      await _cartService.addToCart(
        product,
        widget.businessId,
        quantity: quantity,
      );
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                SizedBox(width: 8),
                Expanded(child: Text('${product.name} sepete eklendi')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
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
                Icon(Icons.error_outline, color: AppColors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Hata: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
            ? _buildErrorState()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: _buildMenuContent(),
              ),
      ),
      floatingActionButton: _cartItemCount > 0 ? _buildCartFAB() : null,
    );
  }

  Widget _buildCartFAB() {
    return Hero(
      tag: 'cart_fab',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _onCartPressed,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 12,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.shopping_cart_rounded, size: 24),
              if (_cartItemCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
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
                      style: TextStyle(
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
          label: Text(
            'Sepet (${_cartItemCount})',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Loading header
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingIndicator(color: AppColors.white),
                SizedBox(height: 16),
                Text(
                  'Menü yükleniyor...',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Loading content
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Loading category tabs
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) => Container(
                      width: 100,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      child: Shimmer.fromColors(
                        baseColor: AppColors.greyLight,
                        highlightColor: AppColors.white,
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

                SizedBox(height: 24),

                // Loading products
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => Shimmer.fromColors(
                      baseColor: AppColors.greyLight,
                      highlightColor: AppColors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
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
                Icons.error_outline_rounded,
                size: 60,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Menü Yüklenemedi',
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Bir hata oluştu',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadMenuData,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuContent() {
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // Modern Business Header
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildModernBusinessHeader(),
            ),
            actions: [
              _buildHeaderAction(
                icon: _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
                onPressed: _toggleSearchBar,
                tooltip: _showSearchBar ? 'Aramayı Kapat' : 'Ara',
              ),
              _buildHeaderAction(
                icon: Icons.tune_rounded,
                onPressed: _showFilterBottomSheet,
                tooltip: 'Filtrele',
              ),
              _buildHeaderAction(
                icon: Icons.receipt_long_rounded,
                onPressed: _onOrdersPressed,
                tooltip: 'Siparişlerim',
              ),
              _buildCartHeaderButton(),
              SizedBox(width: 8),
            ],
          ),

          // Search Bar
          if (_showSearchBar)
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildModernSearchBar(),
              ),
            ),

          // Category Tabs
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildModernCategoryTabs(),
            ),
          ),
        ];
      },
      body: _buildProductContent(),
    );
  }

  Widget _buildModernBusinessHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/patterns/restaurant_pattern.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => SizedBox(),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // Business logo/avatar
                      Hero(
                        tag: 'business_logo_${widget.businessId}',
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _business?.logoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.network(
                                    _business!.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildBusinessIcon(),
                                  ),
                                )
                              : _buildBusinessIcon(),
                        ),
                      ),
                      SizedBox(width: 16),
                      // Business info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _business?.businessName ?? 'İşletme',
                              style: AppTypography.h4.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _business?.businessType ?? 'Restoran',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: AppColors.white.withOpacity(0.9),
                                ),
                                SizedBox(width: 4),
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
    );
  }

  Widget _buildBusinessIcon() {
    return Icon(
      Icons.restaurant_rounded,
      size: 40,
      color: AppColors.primary,
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartHeaderButton() {
    return Container(
      margin: EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onCartPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 1),
                      ),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        _cartItemCount > 99 ? '99+' : _cartItemCount.toString(),
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
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

  Widget _buildModernSearchBar() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.greyLighter,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: TextField(
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Ürün ara...',
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                    onPressed: () => _onSearchChanged(''),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildModernCategoryTabs() {
    if (_categories.isEmpty) return SizedBox.shrink();

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
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
          SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1, // +1 for "Tümü" option
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryChip(
                    categoryId: 'all',
                    name: 'Tümü',
                    isSelected: _selectedCategoryId == 'all' || _selectedCategoryId == null,
                  );
                }
                
                final category = _categories[index - 1];
                return _buildCategoryChip(
                  categoryId: category.categoryId,
                  name: category.name,
                  isSelected: _selectedCategoryId == category.categoryId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String categoryId,
    required String name,
    required bool isSelected,
  }) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onCategorySelected(categoryId),
          borderRadius: BorderRadius.circular(25),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.greyLight,
                width: isSelected ? 0 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.08),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              name,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductContent() {
    if (_filteredProducts.isEmpty) {
      return SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: AppColors.background,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: _buildEmptyState(),
            ),
          ),
        ),
      );
    }

    return SlideTransition(
      position: _slideAnimation,
      child: RefreshIndicator(
        onRefresh: _loadMenuData,
        color: AppColors.primary,
        child: Container(
          color: AppColors.background,
          child: _buildModernProductGrid(),
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
      subtitle = 'Aradığınız "${_searchQuery}" için sonuç bulunamadı.\nFarklı bir arama terimi deneyin.';
      icon = Icons.search_off_rounded;
    } else if (_selectedCategoryId != null && _selectedCategoryId != 'all') {
      title = 'Bu kategoride ürün yok';
      subtitle = 'Seçilen kategoride henüz ürün bulunmamaktadır.';
      icon = Icons.category_rounded;
    } else {
      title = 'Henüz ürün yok';
      subtitle = 'Bu işletmede henüz ürün bulunmamaktadır.';
      icon = Icons.restaurant_menu_rounded;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.greyLighter,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 60,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 24),
        Text(
          title,
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          subtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        if (_searchQuery.isNotEmpty) ...[
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              _onSearchChanged('');
              if (_showSearchBar) _toggleSearchBar();
            },
            icon: Icon(Icons.clear_rounded),
            label: Text('Aramayı Temizle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModernProductGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildModernProductCard(product, index);
      },
    );
  }

  Widget _buildModernProductCard(Product product, int index) {
    final hasDiscount = product.currentPrice != null && product.currentPrice! < product.price;
    
    return Hero(
      tag: 'product_${product.productId}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onProductTapped(product),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          gradient: LinearGradient(
                            colors: [AppColors.greyLighter, AppColors.greyLight],
                          ),
                        ),
                        child: product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildProductIcon(),
                                ),
                              )
                            : _buildProductIcon(),
                      ),
                      
                      // Discount badge
                      if (hasDiscount)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '%${((1 - (product.currentPrice! / product.price)) * 100).round()}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      
                      // Availability status
                      if (!product.isAvailable)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Center(
                              child: Text(
                                'Tükendi',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Product info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        if (product.description.isNotEmpty)
                          Text(
                            product.description,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasDiscount)
                                  Text(
                                    '${product.price.toStringAsFixed(2)} ₺',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  '${(product.currentPrice ?? product.price).toStringAsFixed(2)} ₺',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: hasDiscount ? AppColors.accent : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (product.isAvailable)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _addToCart(product),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: AppColors.white,
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
    );
  }

  Widget _buildProductIcon() {
    return Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: 40,
        color: AppColors.textSecondary,
      ),
    );
  }

  void _onProductTapped(Product product) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          product: product,
          business: _business!,
        ),
      ),
    );
  }

  void _onSharePressed() {
    final menuUrl = 'https://masamenu.com/menu/${widget.businessId}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.share_rounded, color: AppColors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Menü linki kopyalandı')),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onCallPressed() {
    final phone = _business?.contactInfo.phone ?? '';
    if (phone.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.phone_rounded, color: AppColors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Aranıyor: $phone')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _onLocationPressed() {
    final address = _business?.address.toString() ?? '';
    if (address.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppColors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Konum: $address')),
            ],
          ),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
} 
