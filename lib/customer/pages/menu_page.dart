import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../business/models/business.dart';
import '../../business/models/category.dart';
import '../../business/models/product.dart';
import '../../business/models/discount.dart';
import '../../business/models/staff.dart';
import '../../business/models/waiter_call.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/multilingual_service.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/url_service.dart';
import '../../core/services/auth_service.dart';
import '../services/customer_firestore_service.dart';
import '../services/customer_service.dart';
import '../../business/services/business_firestore_service.dart';
import '../../business/services/staff_service.dart';
import '../../business/services/waiter_call_service.dart';
import '../widgets/menu_header_widget.dart';
import '../widgets/menu_search_widget.dart';
import '../widgets/menu_category_widget.dart';
import '../widgets/menu_product_widget.dart';
import '../widgets/menu_state_widgets.dart';
import '../widgets/menu_waiter_widget.dart';
import '../widgets/filter_bottom_sheet.dart';
// import '../../shared/qr_menu/widgets/dynamic_menu_widgets.dart';

import 'cart_page.dart';
import 'product_detail_page.dart';

/// 🍽️ Yeniden Yapılandırılmış Menü Sayfası
///
/// Bu sayfa modüler widget yapısı ile yeniden tasarlandı:
/// - MenuHeaderWidget - Header ve butonlar
/// - MenuSearchWidget - Arama ve filtre
/// - MenuCategoryWidget - Kategori listesi
/// - MenuProductWidget - Ürün grid/list
/// - MenuStateWidgets - Loading, error, empty states
/// - MenuWaiterWidget - Garson çağırma
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
  List<Staff> _waiters = [];

  // Services
  final _customerFirestoreService = CustomerFirestoreService();
  final _businessFirestoreService = BusinessFirestoreService();
  final _cartService = CartService();
  final _urlService = UrlService();
  final _authService = AuthService();
  final _multilingualService = MultilingualService();
  final _customerService = CustomerService();
  final _staffService = StaffService();
  final _waiterCallService = WaiterCallService();

  // Table information from QR code
  int? _tableNumber;
  String? _tableInfo;

  // UI State
  String _searchQuery = '';
  String? _selectedCategoryId;
  Map<String, dynamic> _filters = {};
  bool _showSearchBar = false;
  int _cartItemCount = 0;
  double _headerOpacity = 1.0;
  String _currentLanguage = 'tr';
  List<String> _favoriteProductIds = [];
  bool _isWaiterCallLoading = false;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initData();
  }

  void _initControllers() {
    _scrollController = ScrollController();
    _categoryScrollController = ScrollController();

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutBack,
    ));

    _scrollController.addListener(_onScroll);
    _cartService.addCartListener((_) => _updateCartItemCount());
  }

  void _initData() {
    _extractTableInfoFromUrl();
    _setupRealTimeListeners();
    _loadWaiters();
  }

  void _extractTableInfoFromUrl() {
    final uri = Uri.base;
    final tableParam = uri.queryParameters['table'];
    if (tableParam != null) {
      try {
        _tableNumber = int.parse(tableParam);
        _tableInfo = 'Masa $_tableNumber';
      } catch (e) {
        _tableInfo = tableParam;
      }
    }
  }

  void _setupRealTimeListeners() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    // Setup real-time listeners for business data
    _customerFirestoreService.startBusinessDataListener(
      widget.businessId,
      onBusinessUpdated: (business) {
        setState(() {
          _business = business;
          if (business == null) {
            _hasError = true;
            _errorMessage = 'İşletme bulunamadı';
          }
        });
      },
      onCategoriesUpdated: (categories) {
        setState(() {
          _categories = categories;
        });
      },
      onProductsUpdated: (products) {
        setState(() {
          _products = products;
          _applyFilters(); // Reapply current filters
          if (_isLoading) {
            _isLoading = false;
            _fadeAnimationController.forward();
            _slideAnimationController.forward();
          }
        });
      },
    );
  }

  void _applyFilters() {
    List<Product> filtered = List.from(_products);

    // Apply category filter
    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      filtered = filtered
          .where((product) => product.categoryId == _selectedCategoryId)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply other filters
    for (final entry in _filters.entries) {
      switch (entry.key) {
        case 'isVegan':
          if (entry.value == true) {
            filtered = filtered.where((product) => product.isVegan).toList();
          }
          break;
        case 'isVegetarian':
          if (entry.value == true) {
            filtered =
                filtered.where((product) => product.isVegetarian).toList();
          }
          break;
        // case 'isGlutenFree':
        //   if (entry.value == true) {
        //     filtered =
        //         filtered.where((product) => product.isGlutenFree).toList();
        //   }
        //   break;
        case 'priceRange':
          if (entry.value is Map) {
            final range = entry.value as Map<String, double>;
            final min = range['min'] ?? 0.0;
            final max = range['max'] ?? double.infinity;
            filtered = filtered
                .where(
                    (product) => product.price >= min && product.price <= max)
                .toList();
          }
          break;
      }
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  Future<void> _loadBusinessData() async {
    // This method is now replaced by _setupRealTimeListeners
    // Keep it for backwards compatibility or remove if not needed
    _setupRealTimeListeners();
  }

  Future<void> _loadWaiters() async {
    try {
      final waiters = await _staffService.getStaffByBusiness(widget.businessId);
      setState(() {
        _waiters = waiters;
      });
    } catch (e) {
      print('Garson listesi yüklenirken hata: $e');
    }
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final opacity = (1.0 - (offset / 200)).clamp(0.0, 1.0);
    if (opacity != _headerOpacity) {
      setState(() {
        _headerOpacity = opacity;
      });
    }
  }

  void _updateCartItemCount() async {
    final newCount = await _cartService.getCartItemCount(widget.businessId);
    if (newCount != _cartItemCount) {
      setState(() {
        _cartItemCount = newCount;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId == 'all' ? null : categoryId;
      _applyFilters();
    });
  }

  Future<void> _onWaiterCallPressed() async {
    if (_waiters.isEmpty) {
      await _loadWaiters();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => MenuWaiterWidget(
        menuSettings: _business?.menuSettings,
        waiters: _waiters,
        onWaiterSelected: _callWaiter,
        isLoading: _isWaiterCallLoading,
      ),
    );
  }

  Future<void> _callWaiter(Staff waiter) async {
    setState(() {
      _isWaiterCallLoading = true;
    });

    try {
      await _waiterCallService.createWaiterCall(WaiterCall(
        callId: DateTime.now().millisecondsSinceEpoch.toString(),
        businessId: widget.businessId,
        customerId: 'guest',
        customerName: 'Misafir',
        waiterId: waiter.staffId,
        waiterName: '${waiter.firstName} ${waiter.lastName}',
        tableNumber: _tableNumber ?? 0,
        message: _tableInfo ?? 'Masa $_tableNumber',
        status: WaiterCallStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${waiter.firstName} ${waiter.lastName} garsonumuz çağrıldı!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Garson çağrısı gönderilemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isWaiterCallLoading = false;
        });
      }
    }
  }

  void _onProductTap(Product product) {
    if (_business != null) {
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
  }

  void _onAddToCart(Product product) {
    _cartService.addToCart(product, widget.businessId, quantity: 1);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} sepete eklendi'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Sepeti Gör',
          textColor: Colors.white,
          onPressed: _onCartPressed,
        ),
      ),
    );
  }

  void _onFavoriteToggle(Product product) {
    setState(() {
      if (_favoriteProductIds.contains(product.productId)) {
        _favoriteProductIds.remove(product.productId);
      } else {
        _favoriteProductIds.add(product.productId);
      }
    });

    // Favorileri kaydet
    // ... save favorites logic ...
  }

  void _onCartPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          businessId: widget.businessId,
        ),
      ),
    );
  }

  void _onFilterPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilters: _filters,
        onFiltersChanged: (filters) {
          setState(() {
            _filters = filters;
            _applyFilters();
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    // Stop real-time listeners
    _customerFirestoreService.stopBusinessDataListener(widget.businessId);

    // Dispose controllers
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();

    // TODO: Remove cart listener
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuSettings = _business?.menuSettings ?? MenuSettings();

    return Scaffold(
      backgroundColor: _parseColor(menuSettings.colorScheme.backgroundColor),
      body: Container(
        decoration: _buildBackgroundDecoration(menuSettings),
        child: _isLoading
            ? MenuStateWidgets.buildLoadingState(menuSettings)
            : _hasError
                ? MenuStateWidgets.buildErrorState(menuSettings,
                    _errorMessage ?? 'Bilinmeyen hata', _loadBusinessData)
                : _buildMenuContent(menuSettings),
      ),
    );
  }

  /// Arka plan dekorasyonunu oluştur (renk veya fotoğraf)
  BoxDecoration _buildBackgroundDecoration(MenuSettings menuSettings) {
    final backgroundSettings = menuSettings.backgroundSettings;

    // Arka plan fotoğrafı varsa onu kullan
    if (backgroundSettings.backgroundImage.isNotEmpty &&
        backgroundSettings.type == 'image') {
      return BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(backgroundSettings.backgroundImage),
          fit: BoxFit.cover,
          colorFilter: backgroundSettings.opacity < 1.0
              ? ColorFilter.mode(
                  Colors.black.withOpacity(1.0 - backgroundSettings.opacity),
                  BlendMode.overlay,
                )
              : null,
        ),
      );
    }

    // Arka plan fotoğrafı yoksa sadece renk
    return BoxDecoration(
      color: _parseColor(menuSettings.colorScheme.backgroundColor),
    );
  }

  Widget _buildMenuContent(MenuSettings menuSettings) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: MenuHeaderWidget(
              business: _business,
              menuSettings: menuSettings,
              cartItemCount: _cartItemCount,
              onCartPressed: _onCartPressed,
              onWaiterCallPressed: _onWaiterCallPressed,
              onLanguagePressed: () {}, // TODO: Language switching
              waiters: _waiters,
              isWaiterCallLoading: _isWaiterCallLoading,
            ),
          ),
        ),

        // Search section
        if (_showSearchBar)
          SliverToBoxAdapter(
            child: MenuSearchWidget(
              menuSettings: menuSettings,
              searchQuery: _searchQuery,
              onSearchChanged: _onSearchChanged,
              onFilterPressed: _onFilterPressed,
              hasActiveFilters: _filters.isNotEmpty,
              resultCount: _filteredProducts.length,
            ),
          ),

        // Category section
        SliverToBoxAdapter(
          child: SlideTransition(
            position: _slideAnimation,
            child: MenuCategoryWidget(
              menuSettings: menuSettings,
              categories: _categories,
              selectedCategoryId: _selectedCategoryId,
              onCategorySelected: _onCategorySelected,
              scrollController: _categoryScrollController,
            ),
          ),
        ),

        // Product section
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: MenuProductWidget(
              menuSettings: menuSettings,
              products: _filteredProducts,
              onProductTap: _onProductTap,
              onAddToCart: _onAddToCart,
              onFavoriteToggle: _onFavoriteToggle,
              favoriteProductIds: _favoriteProductIds,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.backgroundLight;
    }
  }
}
