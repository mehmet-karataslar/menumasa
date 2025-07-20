import 'package:flutter/material.dart';
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
import '../widgets/business_header.dart';
import '../widgets/category_list.dart';
import '../widgets/product_grid.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import 'cart_page.dart';
// CachedNetworkImage removed for Windows compatibility
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

  // UI State
  String _searchQuery = '';
  String? _selectedCategoryId;
  Map<String, dynamic> _filters = {};
  bool _showSearchBar = false;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadMenuData();
    _initializeCart();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.dispose();
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

      // Gerçek veri yükleme
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

      // Zaman kurallarına göre filtrele
      _filterProducts();

      // TabController'ı kategorilere göre ayarla
      if (_categories.isNotEmpty) {
        // Önceki TabController'ı dispose et
        _tabController?.dispose();
        
        _tabController = TabController(length: _categories.length, vsync: this);

        _tabController!.addListener(() {
          if (_tabController!.indexIsChanging) {
            _onCategorySelected(_categories[_tabController!.index].categoryId);
          }
        });
        
        // İlk kategoriyi seçili yap
        if (_selectedCategoryId == null && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.categoryId;
        }
      } else {
        // Kategoriler boşsa TabController'ı null yap
        _tabController?.dispose();
        _tabController = null;
      }

      setState(() {
        _isLoading = false;
      });
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
      // Kategori filtresi - 'all' kategorisi seçildiğinde tüm ürünleri göster
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

      // Zaman kuralları kontrolü - TimeRuleUtils kullanarak
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

    // İndirimli fiyatları hesapla
    _filteredProducts = _filteredProducts.map((product) {
      final finalPrice = product.calculateFinalPrice(_discounts);
      return product.copyWith(currentPrice: finalPrice);
    }).toList();

    // Kategorileri de zaman kurallarına göre filtrele
    _categories = _categories.where((category) {
      return TimeRuleUtils.isCategoryVisible(category);
    }).toList();
  }

  void _showFilterBottomSheet() {
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
  }

  void _onCartPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(businessId: widget.businessId),
      ),
    );
  }

  void _onOrdersPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerOrdersPage(
          businessId: widget.businessId,
          customerPhone: null, // Could be set from user preferences
          userId: null,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} sepete eklendi'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Sepete Git',
              textColor: Colors.white,
              onPressed: _onCartPressed,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün sepete eklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
            ? _buildErrorState()
            : _buildMenuContent(),
      ),
      floatingActionButton: _cartItemCount > 0 ? _buildCartFAB() : null,
    );
  }

  Widget _buildCartFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton.extended(
        onPressed: _onCartPressed,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 8,
        heroTag: "cart_fab",
        icon: Stack(
          children: [
            const Icon(Icons.shopping_cart, size: 24),
            if (_cartItemCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    _cartItemCount > 99 ? '99+' : _cartItemCount.toString(),
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
        label: Text(
          'Sepet (${_cartItemCount})',
          style: const TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: 16,
          ),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Loading header
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: LoadingIndicator(
              size: AppDimensions.loadingIndicatorSizeL,
              color: AppColors.white,
            ),
          ),
        ),

        // Loading content
        Expanded(
          child: Padding(
            padding: AppDimensions.paddingM,
            child: Column(
              children: [
                // Loading category tabs
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) => Shimmer.fromColors(
                      baseColor: AppColors.greyLight,
                      highlightColor: AppColors.white,
                      child: Container(
                        width: 100,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: AppDimensions.borderRadiusM,
                        ),
                      ),
                    ),
                  ),
                ),

                AppSizedBox.h24,

                // Loading products
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                          borderRadius: AppDimensions.borderRadiusM,
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
    return ErrorMessage(
      message: _errorMessage ?? 'Bir hata oluştu',
      onRetry: _loadMenuData,
    );
  }

  Widget _buildMenuContent() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // Business Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: BusinessHeader(
                business: _business!,
                onSharePressed: _onSharePressed,
                onCallPressed: _onCallPressed,
                onLocationPressed: _onLocationPressed,
                cartItemCount: 0, // Cart moved to AppBar actions
              ),
            ),
            actions: [
              // Search button
              IconButton(
                icon: Icon(
                  _showSearchBar ? Icons.search_off : Icons.search,
                  color: AppColors.white,
                  size: 24,
                ),
                onPressed: _toggleSearchBar,
                tooltip: _showSearchBar ? 'Aramayı Kapat' : 'Ara',
              ),
              // Filter button
              IconButton(
                icon: const Icon(
                  Icons.tune,
                  color: AppColors.white,
                  size: 24,
                ),
                onPressed: _showFilterBottomSheet,
                tooltip: 'Filtrele',
              ),
              // Orders button
              IconButton(
                icon: const Icon(
                  Icons.receipt_long,
                  color: AppColors.white,
                  size: 24,
                ),
                onPressed: _onOrdersPressed,
                tooltip: 'Siparişlerim',
              ),
              // Cart button
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      color: AppColors.white,
                      size: 24,
                    ),
                    if (_cartItemCount > 0)
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
                onPressed: _onCartPressed,
                tooltip: 'Sepet',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Search Bar (if visible)
          if (_showSearchBar)
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(16),
                child: CustomSearchBar(
                  onSearchChanged: _onSearchChanged,
                  hintText: 'Ürün ara...',
                ),
              ),
            ),

          // Category Tabs
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CategoryList(
                categories: _categories,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: _onCategorySelected,
                showAll: true,
              ),
            ),
          ),
        ];
      },
      body: _buildProductContent(),
    );
  }

  Widget _buildProductContent() {
    if (_filteredProducts.isEmpty) {
      return Container(
        color: AppColors.menuBackground,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: EmptyState(
              icon: Icons.restaurant_menu,
              title: _searchQuery.isNotEmpty 
                  ? 'Ürün Bulunamadı' 
                  : 'Henüz Ürün Yok',
              message: _searchQuery.isNotEmpty
                  ? 'Aradığınız "${_searchQuery}" için sonuç bulunamadı.\nFarklı bir arama terimi deneyin.'
                  : _selectedCategoryId != null && _selectedCategoryId != 'all'
                      ? 'Bu kategoride henüz ürün bulunmamaktadır.'
                      : 'Bu işletmede henüz ürün bulunmamaktadır.',
              actionText: _searchQuery.isNotEmpty ? 'Aramayı Temizle' : null,
              onActionPressed: _searchQuery.isNotEmpty
                  ? () {
                      _onSearchChanged('');
                      if (_showSearchBar) _toggleSearchBar();
                    }
                  : null,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMenuData,
      color: AppColors.primary,
      child: Container(
        color: AppColors.menuBackground,
        child: ProductGrid(
          products: _filteredProducts,
          onProductTapped: _onProductTapped,
          onAddToCart: (product) => _addToCart(product),
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          childAspectRatio: 0.8,
        ),
      ),
    );
  }

  void _onProductTapped(Product product) {
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
    // QR kod veya menü linkini paylaş
    final menuUrl = 'https://masamenu.com/menu/${widget.businessId}';
    // Share.share(menuUrl);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menü linki kopyalandı: $menuUrl'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _onCallPressed() {
    // Telefon araması yap
    final phone = _business?.contactInfo.phone ?? '';
    if (phone.isNotEmpty) {
      // await launch('tel:$phone');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aranıyor: $phone'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _onLocationPressed() {
    // Konum bilgisini göster
    final address = _business?.address.toString() ?? '';
    if (address.isNotEmpty) {
      // await launch('https://maps.google.com/?q=$address');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum: $address'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }
} 
