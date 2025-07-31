import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../core/widgets/web_safe_image.dart';
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
import 'product_detail_page.dart';
import '../services/customer_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../business/models/staff.dart';
import '../../business/models/waiter_call.dart';
import '../../business/services/staff_service.dart';
import '../../business/services/waiter_call_service.dart';
import '../../core/services/dynamic_theme_service.dart';
import '../../shared/qr_menu/widgets/dynamic_menu_widgets.dart';

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

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initAnimations();
    _extractTableInformation();
    _determineUserLanguage();
    _initializeServices();
  }

  void _extractTableInformation() {
    try {
      // Extract table number from current URL
      final params = _urlService.getCurrentParams();
      final tableParam = params['table'] ?? params['tableNumber'];

      if (tableParam != null) {
        _tableNumber = int.tryParse(tableParam.toString());
        if (_tableNumber != null) {
          _tableInfo = 'Masa $_tableNumber';
          print('📍 MenuPage: Table information extracted: $_tableInfo');
        }
      }

      // Alternative: Extract from current URL path
      if (_tableNumber == null) {
        final currentUrl = Uri.base.toString();
        final tableMatch = RegExp(r'[?&]table=(\d+)').firstMatch(currentUrl);
        if (tableMatch != null) {
          _tableNumber = int.tryParse(tableMatch.group(1) ?? '');
          if (_tableNumber != null) {
            _tableInfo = 'Masa $_tableNumber';
            print(
                '📍 MenuPage: Table information extracted from URL: $_tableInfo');
          }
        }
      }

      // Log result
      if (_tableNumber != null) {
        print('✅ MenuPage: Table $_tableNumber detected');
      } else {
        print('⚠️ MenuPage: No table number found in URL');
      }
    } catch (e) {
      print('❌ MenuPage: Error extracting table information: $e');
    }
  }

  Future<void> _initializeServices() async {
    await _initializeCustomerService();
    await _initializeCart();
    await _loadMenuData();
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideAnimationController, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _cartService.removeCartListener(_onCartChanged);
    super.dispose();
  }

  Future<void> _initializeCustomerService() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print(
            '🔐 MenuPage: Initializing CustomerService with user: ${currentUser.uid}');
        await _customerService.createOrGetCustomer(
          email: currentUser.email,
          name: currentUser.displayName,
          phone: currentUser.phoneNumber,
          isAnonymous: false,
        );
        print('✅ MenuPage: CustomerService initialized successfully');
      } else {
        print('⚠️ MenuPage: No authenticated user found');
        // Anonim kullanıcı olarak devam et
        await _customerService.createOrGetCustomer(
          isAnonymous: true,
        );
      }
    } catch (e) {
      print('❌ MenuPage: CustomerService initialization failed: $e');
    }
  }

  Future<void> _waitForCustomerServiceInitialization() async {
    // CustomerService'in initialize olmasını bekle
    int attempts = 0;
    const maxAttempts = 10;
    const delay = Duration(milliseconds: 500);

    while (_customerService.currentCustomer == null && attempts < maxAttempts) {
      print(
          '⏳ MenuPage: Waiting for CustomerService initialization... Attempt ${attempts + 1}');
      await Future.delayed(delay);
      attempts++;
    }

    if (_customerService.currentCustomer == null) {
      print(
          '⚠️ MenuPage: CustomerService not initialized after $maxAttempts attempts');
    } else {
      print('✅ MenuPage: CustomerService is ready');
    }
  }

  Future<List<dynamic>> _loadFavoritesFromFirebase() async {
    try {
      // Firebase Auth'dan current user'ı al
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('🔒 MenuPage: No authenticated user, returning empty favorites');
        return [];
      }

      print('💖 MenuPage: Loading favorite products from Firebase...');

      // Firebase'den direkt olarak favorileri yükle - Firebase Auth UID ile
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('product_favorites')
          .where('customerId', isEqualTo: user.uid) // Firebase Auth UID kullan
          .orderBy('createdAt', descending: true)
          .get();

      final favorites = favoritesSnapshot.docs.map((doc) {
        return doc.data();
      }).toList();

      print(
          '💖 MenuPage: Favorite products loaded from Firebase: ${favorites.length} items - ${favorites.map((f) => f['productId']).toList()}');

      return favorites;
    } catch (e) {
      print('❌ MenuPage: Error loading favorites from Firebase: $e');
      return [];
    }
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
      print(
          '🔄 MenuPage: Loading menu data for business: ${widget.businessId}');
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // Load business, categories, products, and discounts
      print('📊 MenuPage: Loading business data...');
      final businessData =
          await _businessFirestoreService.getBusiness(widget.businessId);
      print(
          '📊 MenuPage: Business data loaded: ${businessData?.businessName ?? 'null'}');

      print('📂 MenuPage: Loading categories...');
      final categoriesData = await _businessFirestoreService
          .getBusinessCategories(widget.businessId);
      print('📂 MenuPage: Categories loaded: ${categoriesData.length} items');

      print('🍽️ MenuPage: Loading products...');
      final productsData = await _businessFirestoreService
          .getBusinessProducts(widget.businessId);
      print('🍽️ MenuPage: Raw products loaded: ${productsData.length} items');

      // Sadece aktif ve müsait ürünleri filtrele
      final activeProducts =
          productsData.where((p) => p.isActive && p.isAvailable).toList();
      print(
          '🍽️ MenuPage: Active products after filtering: ${activeProducts.length} items');

      // Debug için kullanıcıya da göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'MenuPage: ${productsData.length} ürün bulundu, ${activeProducts.length} tanesi aktif'),
            duration: Duration(seconds: 2),
            backgroundColor:
                activeProducts.isEmpty ? AppColors.error : AppColors.success,
          ),
        );
      }

      print('🎯 MenuPage: Loading discounts...');
      final discountsData = await _businessFirestoreService
          .getDiscountsByBusinessId(widget.businessId);
      print('🎯 MenuPage: Discounts loaded: ${discountsData.length} items');

      // CustomerService is already initialized in initState

      // Load favorite products from Firebase
      List<String> favoriteProductIds = [];
      try {
        print('💖 MenuPage: Loading favorite products from Firebase...');
        final favoriteProducts = await _loadFavoritesFromFirebase();
        favoriteProductIds =
            favoriteProducts.map((f) => f['productId'] as String).toList();
        print(
            '💖 MenuPage: Favorite products loaded from Firebase: ${favoriteProductIds.length} items - $favoriteProductIds');
      } catch (e) {
        print('❌ MenuPage: Error loading favorite products from Firebase: $e');
        favoriteProductIds = [];
      }

      if (businessData != null) {
        print('✅ MenuPage: Business data is valid, processing...');
        // Apply multilingual translations
        final translatedCategories = categoriesData; // .map((category) =>
        // _multilingualService.translateCategory(category, _currentLanguage)).toList();
        final translatedProducts = activeProducts; // .map((product) =>
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
          _tabController =
              TabController(length: _categories.length, vsync: this);
          _tabController?.addListener(_onTabChanged);
        }

        // Start animations after data is loaded
        print('🎬 MenuPage: Starting animations...');
        _fadeAnimationController.forward();
        _slideAnimationController.forward();

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
      _tabController =
          TabController(length: _categories.length + 1, vsync: this);
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

  void _onWaiterCallPressed() {
    // Tüm kullanıcılar için garson seçimi göster
    _showWaiterSelectionDialog();
  }

  void _showGuestWaiterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.room_service_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Garson Çağır'),
          ],
        ),
        content: const Text(
          'Garson çağırmak için sisteme giriş yapmanız gerekmektedir. Kayıtlı kullanıcılar garson seçebilir ve öncelikli hizmet alır.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showWaiterSelectionDialog(); // Misafir kullanıcı da garson seçebilsin
            },
            child: const Text('Misafir Olarak Devam Et'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Giriş Yap',
                style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showWaiterSelectionDialog() async {
    try {
      // Load available waiters for this business
      final staffService = StaffService();
      final availableWaiters =
          await staffService.getAvailableWaiters(widget.businessId);

      if (!mounted) return;

      if (availableWaiters.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        Text('Garsonlar yükleniyor, lütfen biraz bekleyin...')),
              ],
            ),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      final user = _authService.currentUser;
      final isGuest = user == null;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.room_service_rounded, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Garson Seç'),
                    if (isGuest)
                      Text(
                        'Misafir Çağrı',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_tableNumber != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_restaurant_rounded,
                            color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'MASA $_tableNumber',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (isGuest) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Misafir olarak çağrı yapıyorsunuz. Kayıtlı kullanıcılar öncelikli hizmet alır.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  _tableNumber != null
                      ? 'Masa $_tableNumber için ${isGuest ? "misafir" : ""} garson seçin'
                      : 'Müsait garsonları seçebilir ve çağırabilirsiniz',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${availableWaiters.length} Müsait Garson',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableWaiters.length,
                    itemBuilder: (context, index) {
                      final waiter = availableWaiters[index];
                      return _buildWaiterCard(waiter);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            if (isGuest)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('Giriş Yap',
                    style: TextStyle(color: AppColors.white)),
              ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Garson listesi yüklenirken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildWaiterCard(Staff waiter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _callWaiter(waiter),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.greyLight.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Waiter Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: waiter.profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: WebSafeImage(
                            imageUrl: waiter.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                _buildWaiterInitials(waiter),
                          ),
                        )
                      : _buildWaiterInitials(waiter),
                ),
                const SizedBox(width: 16),

                // Waiter Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        waiter.fullName,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              waiter.role.displayName,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(waiter.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            waiter.status.displayName,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            waiter.statistics.averageRating > 0
                                ? '${waiter.statistics.averageRating.toStringAsFixed(1)}'
                                : 'Yeni',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.timer_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            waiter.statistics.responseTime > 0
                                ? '~${waiter.statistics.responseTime.toInt()} dk'
                                : 'Hızlı',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Call Button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.phone_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaiterInitials(Staff waiter) {
    return Center(
      child: Text(
        waiter.initials,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(StaffStatus status) {
    switch (status) {
      case StaffStatus.available:
        return AppColors.success;
      case StaffStatus.busy:
        return AppColors.warning;
      case StaffStatus.break_:
        return AppColors.info;
      case StaffStatus.offline:
        return AppColors.error;
    }
  }

  Future<void> _callWaiter(Staff waiter) async {
    try {
      Navigator.pop(context); // Close dialog

      final user = _authService.currentUser;

      // Use extracted table number or fallback to URL parsing
      int tableNumber = _tableNumber ?? 0;
      if (_tableNumber == null) {
        try {
          final params = _urlService.getCurrentParams();
          final tableParam = params['table'] ?? params['tableNumber'];
          if (tableParam != null) {
            _tableNumber = int.tryParse(tableParam.toString());
            tableNumber = _tableNumber ?? 0;
          }
        } catch (e) {
          print('Fallback table number extraction failed: $e');
        }
      }

      final waiterCallService = WaiterCallService();
      final call = WaiterCall.create(
        businessId: widget.businessId,
        customerId:
            user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
        customerName: user?.displayName ?? 'Misafir Müşteri',
        waiterId: waiter.staffId,
        waiterName: waiter.fullName,
        tableNumber: tableNumber,
        message: _tableNumber != null
            ? 'Masa $_tableNumber\'dan yardım talep edildi ${user == null ? "(Misafir)" : ""}'
            : 'Masa yardımı talep edildi ${user == null ? "(Misafir)" : ""}',
      );

      await waiterCallService.createWaiterCall(call);

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _tableNumber != null
                        ? '${waiter.fullName} başarıyla çağrıldı! (Masa $_tableNumber)${user == null ? " - Misafir çağrı" : ""}'
                        : '${waiter.fullName} başarıyla çağrıldı!${user == null ? " - Misafir çağrı" : ""}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Garson çağırırken hata: $e',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _navigateToProductDetail(Product product) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute =
        '/menu/${widget.businessId}/product/${product.productId}?t=$timestamp';
    _urlService.updateUrl(dynamicRoute,
        customTitle: '${product.name} | MasaMenu');

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
      print(
          '🔄 MenuPage: Toggling favorite for product: ${product.productName} (ID: ${product.productId})');

      // Firebase Auth'dan current user'ı al
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş yapılması gerekli')),
        );
        return;
      }

      // Mevcut favori durumunu kontrol et
      final isFavorite = _favoriteProductIds.contains(product.productId);

      if (isFavorite) {
        // Favorilerden çıkar
        final query = await FirebaseFirestore.instance
            .collection('product_favorites')
            .where('customerId', isEqualTo: user.uid)
            .where('productId', isEqualTo: product.productId)
            .get();

        for (final doc in query.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          setState(() {
            _favoriteProductIds.remove(product.productId);
          });
        }
      } else {
        // Favorilere ekle
        final favoriteId =
            FirebaseFirestore.instance.collection('product_favorites').doc().id;

        await FirebaseFirestore.instance
            .collection('product_favorites')
            .doc(favoriteId)
            .set({
          'id': favoriteId,
          'productId': product.productId,
          'businessId': widget.businessId,
          'customerId': user.uid, // Firebase Auth UID kullan
          'createdAt': FieldValue.serverTimestamp(),
          'productName': product.productName,
          'productDescription': product.description,
          'productPrice': product.price,
          'productImage': product.imageUrl,
          'businessName': _business?.businessName,
          'categoryName': null,
          'addedDate': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            _favoriteProductIds.add(product.productId);
          });
        }
      }

      print('✅ MenuPage: Backend favorite toggle completed');

      // Favorileri yeniden yükle
      print('🔄 MenuPage: Refreshing favorites from Firebase...');
      final favoriteProducts = await _loadFavoritesFromFirebase();
      final favoriteProductIds =
          favoriteProducts.map((f) => f['productId'] as String).toList();

      if (mounted) {
        setState(() {
          _favoriteProductIds = favoriteProductIds;
        });
      }
      print(
          '✅ MenuPage: Fresh favorites loaded: ${_favoriteProductIds.length} items');
    } catch (e) {
      print('❌ MenuPage: Favorite toggle error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Favori işlemi hatası: $e')),
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

      await _cartService.addToCart(product, widget.businessId,
          quantity: quantity);

      // Debug: Check cart contents
      final cart = await _cartService.getCurrentCart(widget.businessId);
      print('🛒 Cart now has ${cart.items.length} unique items:');
      for (var item in cart.items) {
        print(
            '   - ${item.productName} (ID: ${item.productId}) x${item.quantity}');
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
                  child: Icon(Icons.check_rounded,
                      color: AppColors.white, size: 16),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                Icon(Icons.error_outline_rounded,
                    color: AppColors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Hata: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer business yüklenmişse dinamik tema kullan
    if (_business != null) {
      return DynamicThemeWrapper(
        businessId: _business!.id,
        fallbackSettings: _business!.menuSettings,
        builder: (menuSettings, themeData) {
          return Theme(
            data: themeData,
            child: Scaffold(
              backgroundColor:
                  _parseColor(menuSettings.colorScheme.backgroundColor),
              extendBodyBehindAppBar: true,
              body: _isLoading
                  ? _buildLoadingState(menuSettings)
                  : _hasError
                      ? _buildErrorState(menuSettings)
                      : _buildMenuContent(menuSettings),
            ),
          );
        },
      );
    }

    // Fallback tema
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: _buildBackgroundDecoration(null),
        child: _isLoading
            ? _buildLoadingState(null)
            : _hasError
                ? _buildErrorState(null)
                : _buildMenuContent(null),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration(MenuSettings? menuSettings) {
    final backgroundSettings = menuSettings?.backgroundSettings;

    print('🎨 DEBUG: backgroundSettings = $backgroundSettings');
    print('🎨 DEBUG: type = ${backgroundSettings?.type}');
    print('🎨 DEBUG: backgroundImage = ${backgroundSettings?.backgroundImage}');

    if (backgroundSettings == null) {
      print('🎨 DEBUG: backgroundSettings is null, using default');
      return BoxDecoration(color: AppColors.background);
    }

    switch (backgroundSettings.type) {
      case 'color':
        return BoxDecoration(
          color: _parseColor(backgroundSettings.primaryColor)
              .withOpacity(backgroundSettings.opacity),
        );

      case 'gradient':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _parseColor(backgroundSettings.primaryColor)
                  .withOpacity(backgroundSettings.opacity),
              _parseColor(backgroundSettings.secondaryColor)
                  .withOpacity(backgroundSettings.opacity),
            ],
          ),
        );

      case 'pattern':
        return BoxDecoration(
          color: Colors.white,
          image: _getPatternDecoration(backgroundSettings),
        );

      case 'image':
        print(
            '🎨 DEBUG: Image case - backgroundImage = ${backgroundSettings.backgroundImage}');
        print(
            '🎨 DEBUG: Image case - isEmpty = ${backgroundSettings.backgroundImage.isEmpty}');
        return BoxDecoration(
          image: backgroundSettings.backgroundImage.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(backgroundSettings.backgroundImage),
                  fit: BoxFit.cover,
                  opacity: backgroundSettings.opacity,
                )
              : null,
          color: backgroundSettings.backgroundImage.isEmpty
              ? _parseColor(backgroundSettings.primaryColor)
                  .withOpacity(backgroundSettings.opacity)
              : null,
        );

      default:
        return BoxDecoration(color: AppColors.background);
    }
  }

  DecorationImage? _getPatternDecoration(
      MenuBackgroundSettings backgroundSettings) {
    // Pattern oluşturma - CSS pattern benzeri yaklaşım
    final patternColors = [
      _parseColor(backgroundSettings.primaryColor),
      _parseColor(backgroundSettings.secondaryColor),
    ];

    // Bu örnekte basit bir pattern implementasyonu
    return null; // Gerçek implementasyon için pattern generator gerekli
  }

  Widget _buildLoadingState(MenuSettings? menuSettings) {
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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

  Widget _buildErrorState(MenuSettings? menuSettings) {
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
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

  Widget _buildMenuContent(MenuSettings? menuSettings) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernHeader(menuSettings),
              if (_showSearchBar) _buildSearchSection(menuSettings),
              _buildCategorySection(menuSettings),
              _buildProductSection(menuSettings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(MenuSettings? menuSettings) {
    final primaryColor = menuSettings != null
        ? _parseColor(menuSettings.colorScheme.primaryColor)
        : AppColors.primary;
    final secondaryColor = menuSettings != null
        ? _parseColor(menuSettings.colorScheme.secondaryColor)
        : AppColors.secondary;

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.8),
                    secondaryColor.withOpacity(0.9),
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
                                  ? WebSafeImage(
                                      imageUrl: _business!.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
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
                                              : AppColors.error)
                                          .withOpacity(0.2),
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
                                    _business?.isOpen == true
                                        ? 'Açık'
                                        : 'Kapalı',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_tableNumber != null) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.accent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.table_restaurant_rounded,
                                            size: 12,
                                            color: AppColors.white
                                                .withOpacity(0.9),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Masa $_tableNumber',
                                            style:
                                                AppTypography.caption.copyWith(
                                              color: AppColors.white
                                                  .withOpacity(0.9),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
          icon:
              _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
          onPressed: _toggleSearchBar,
        ),
        _buildHeaderButton(
          icon: Icons.tune_rounded,
          onPressed: _showFilterBottomSheet,
        ),
        _buildWaiterCallButton(),
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

  Widget _buildWaiterCallButton() {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _onWaiterCallPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.success.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.room_service_rounded,
              color: AppColors.white,
              size: 22,
            ),
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
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
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

  Widget _buildSearchSection(MenuSettings? menuSettings) {
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

  Widget _buildCategorySection(MenuSettings? menuSettings) {
    if (_categories.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

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
                        isSelected: _selectedCategoryId == 'all' ||
                            _selectedCategoryId == null,
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
                    color:
                        isSelected ? AppColors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
    if (name.contains('burger') || name.contains('hamburger'))
      return Icons.lunch_dining_rounded;
    if (name.contains('içecek') || name.contains('drink'))
      return Icons.local_drink_rounded;
    if (name.contains('tatlı') || name.contains('dessert'))
      return Icons.cake_rounded;
    if (name.contains('kahve') || name.contains('coffee'))
      return Icons.local_cafe_rounded;
    if (name.contains('salata') || name.contains('salad'))
      return Icons.eco_rounded;
    if (name.contains('et') || name.contains('meat'))
      return Icons.restaurant_rounded;
    if (name.contains('balık') || name.contains('fish'))
      return Icons.set_meal_rounded;
    return Icons.restaurant_menu_rounded;
  }

  Widget _buildProductSection(MenuSettings? menuSettings) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: menuSettings != null
              ? _parseColor(menuSettings.colorScheme.backgroundColor)
              : AppColors.background,
          child: _filteredProducts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMenuData,
                  color: menuSettings != null
                      ? _parseColor(menuSettings.colorScheme.primaryColor)
                      : AppColors.primary,
                  child: _buildProductGrid(menuSettings),
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
      subtitle =
          'Aradığınız "${_searchQuery}" için sonuç bulunamadı.\nFarklı bir arama deneyin.';
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

  Widget _buildProductGrid(MenuSettings? menuSettings) {
    // Layout tipine göre farklı grid ayarları
    final layoutType =
        menuSettings?.layoutStyle.layoutType ?? MenuLayoutType.grid;
    final columnsCount = menuSettings?.layoutStyle.columnsCount ?? 2;

    SliverGridDelegate gridDelegate;

    switch (layoutType) {
      case MenuLayoutType.list:
        gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          crossAxisSpacing: 0,
          mainAxisSpacing: 8,
          childAspectRatio: 3.5, // Geniş liste kartları
        );
        break;
      case MenuLayoutType.grid:
        gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnsCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85, // Kare benzeri kartlar
        );
        break;
      case MenuLayoutType.masonry:
        gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnsCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.7, // Daha uzun kartlar
        );
        break;
      case MenuLayoutType.carousel:
        // Carousel için farklı widget kullanılacak
        return _buildProductCarousel(menuSettings);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: gridDelegate,
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildDynamicProductCard(
            product, index, menuSettings, layoutType);
      },
    );
  }

  Widget _buildProductCarousel(MenuSettings? menuSettings) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: _buildDynamicProductCard(
                product, index, menuSettings, MenuLayoutType.carousel),
          );
        },
      ),
    );
  }

  Widget _buildDynamicProductCard(Product product, int index,
      MenuSettings? menuSettings, MenuLayoutType layoutType) {
    // Layout tipine göre farklı card tasarımları
    switch (layoutType) {
      case MenuLayoutType.list:
        return _buildListProductCard(product, index, menuSettings);
      case MenuLayoutType.carousel:
        return _buildCarouselProductCard(product, index, menuSettings);
      case MenuLayoutType.masonry:
        return _buildMasonryProductCard(product, index, menuSettings);
      case MenuLayoutType.grid:
        return _buildCompactProductCard(product, index, menuSettings);
    }
  }

  Widget _buildListProductCard(
      Product product, int index, MenuSettings? menuSettings) {
    // Tek fiyat sistemi - discount hesaplaması kaldırıldı

    // Dinamik renkler ve style
    final cardColor = menuSettings != null
        ? _parseColor(menuSettings.colorScheme.cardColor)
        : AppColors.white;
    final borderRadius = menuSettings?.visualStyle.borderRadius ?? 12.0;
    final primaryColor = menuSettings != null
        ? _parseColor(menuSettings.colorScheme.primaryColor)
        : AppColors.primary;
    final textPrimaryColor = menuSettings != null
        ? _parseColor(menuSettings.colorScheme.textPrimaryColor)
        : AppColors.textPrimary;
    final accentColor = menuSettings != null
        ? _parseColor(menuSettings.colorScheme.accentColor)
        : AppColors.accent;

    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: menuSettings?.visualStyle.showShadows ?? true
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Image Section
            Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(borderRadius)),
                color: _parseColor(
                        menuSettings?.colorScheme.surfaceColor ?? '#F8F9FA')
                    .withOpacity(0.3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(borderRadius)),
                child: product.imageUrl != null
                    ? WebSafeImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 80,
                      )
                    : Icon(
                        Icons.restaurant_menu,
                        size: 40,
                        color: primaryColor.withOpacity(0.3),
                      ),
              ),
            ),
            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: menuSettings?.typography.titleFontSize ?? 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimaryColor,
                        fontFamily:
                            menuSettings?.typography.fontFamily ?? 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.description != null &&
                        (menuSettings?.showDescriptions ?? true)) ...[
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          product.description!,
                          style: TextStyle(
                            fontSize:
                                (menuSettings?.typography.bodyFontSize ?? 12) -
                                    1,
                            color: textPrimaryColor.withOpacity(0.7),
                            fontFamily: menuSettings?.typography.fontFamily ??
                                'Poppins',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (menuSettings?.showPrices ?? true)
                          Text(
                            '${product.price.toStringAsFixed(0)} ₺',
                            style: TextStyle(
                              fontSize:
                                  menuSettings?.typography.headingFontSize ??
                                      16,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                              fontFamily: menuSettings?.typography.fontFamily ??
                                  'Poppins',
                            ),
                          ),
                        if (product.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius:
                                  BorderRadius.circular(borderRadius / 2),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
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

  Widget _buildCarouselProductCard(
      Product product, int index, MenuSettings? menuSettings) {
    return _buildCompactProductCard(product, index, menuSettings);
  }

  Widget _buildMasonryProductCard(
      Product product, int index, MenuSettings? menuSettings) {
    return _buildCompactProductCard(product, index, menuSettings);
  }

  Widget _buildCompactProductCard(
      Product product, int index, MenuSettings? menuSettings) {
    // Tek fiyat sistemi - discount hesaplaması kaldırıldı

    // Dinamik renkler ve style
    final cardColor = menuSettings != null
        ? _parseColor(menuSettings.colorScheme.cardColor)
        : AppColors.white;
    final borderRadius = menuSettings?.visualStyle.borderRadius ?? 16.0;
    final shadowColor = menuSettings != null
        ? _parseColor(menuSettings.colorScheme.shadowColor)
        : AppColors.shadow;
    final primaryColor = menuSettings != null
        ? _parseColor(menuSettings.colorScheme.primaryColor)
        : AppColors.primary;
    final textPrimaryColor = menuSettings != null
        ? _parseColor(menuSettings.colorScheme.textPrimaryColor)
        : AppColors.textPrimary;
    final accentColor = menuSettings != null
        ? _parseColor(menuSettings.colorScheme.accentColor)
        : AppColors.accent;
    final imageShape = menuSettings?.visualStyle.imageShape ?? 'rounded';

    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: menuSettings?.visualStyle.showShadows ?? true
              ? [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.1),
                    blurRadius: menuSettings?.visualStyle.cardElevation ?? 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
          border: menuSettings?.visualStyle.showBorders ?? false
              ? Border.all(
                  color: _parseColor(menuSettings!.colorScheme.borderColor),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (65% of height) - Conditional based on showImages
            if (menuSettings?.showImages ?? true)
              Expanded(
                flex: 65,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: _getImageBorderRadius(
                            imageShape, borderRadius,
                            isTopImage: true),
                        color: _parseColor(
                                menuSettings?.colorScheme.surfaceColor ??
                                    '#F8F9FA')
                            .withOpacity(0.3),
                      ),
                      child: ClipRRect(
                        borderRadius: _getImageBorderRadius(
                            imageShape, borderRadius,
                            isTopImage: true),
                        child: product.imageUrl != null
                            ? WebSafeImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorWidget: (context, url, error) =>
                                    _buildCompactIcon(),
                                placeholder: (context, url) =>
                                    _buildCompactIcon(),
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
                                  _favoriteProductIds.contains(product.id)
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color:
                                      _favoriteProductIds.contains(product.id)
                                          ? AppColors.accent
                                          : AppColors.textSecondary,
                                  size: 14,
                                ),
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

            // Info Section (35% of height, 100% if no image)
            Expanded(
              flex: (menuSettings?.showImages ?? true) ? 35 : 100,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name (single line)
                    Flexible(
                      child: Text(
                        product.name,
                        style: _buildGoogleFontTextStyle(
                          fontSize:
                              menuSettings?.typography.titleFontSize ?? 14,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: textPrimaryColor,
                          fontFamily:
                              menuSettings?.typography.fontFamily ?? 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Price and Button Row
                    Flexible(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price Section
                          if (menuSettings?.showPrices ?? true)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Product Price
                                  Text(
                                    '${product.price.toStringAsFixed(0)} ₺',
                                    style: _buildGoogleFontTextStyle(
                                      fontSize: menuSettings
                                              ?.typography.headingFontSize ??
                                          16,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                      color: accentColor,
                                      fontFamily:
                                          menuSettings?.typography.fontFamily ??
                                              'Poppins',
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
                                  color: primaryColor,
                                  borderRadius:
                                      BorderRadius.circular(borderRadius / 2),
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
        final language =
            await _multilingualService.determineUserLanguage(userId);
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

/// MenuPage extension for dynamic theme support
extension MenuPageTheme on _MenuPageState {
  /// Hex string'i Color'a çevir
  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary; // Fallback color
    }
  }

  /// Image shape'e göre border radius belirle
  BorderRadius _getImageBorderRadius(String imageShape, double borderRadius,
      {bool isTopImage = false}) {
    switch (imageShape) {
      case 'circle':
        return BorderRadius.circular(
            borderRadius * 2); // Daire için yüksek radius
      case 'rectangle':
        return BorderRadius.zero; // Dikdörtgen için radius yok
      case 'rounded':
      default:
        return isTopImage
            ? BorderRadius.vertical(top: Radius.circular(borderRadius))
            : BorderRadius.circular(borderRadius);
    }
  }

  /// Google Fonts ile TextStyle oluşturur
  TextStyle _buildGoogleFontTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required Color color,
    required String fontFamily,
  }) {
    try {
      // Google Fonts'tan font ailesi al
      switch (fontFamily.toLowerCase()) {
        case 'poppins':
          return GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            color: color,
          );
        case 'roboto':
          return GoogleFonts.roboto(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            color: color,
          );
        case 'open sans':
        case 'opensans':
          return GoogleFonts.openSans(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            color: color,
          );
        case 'lato':
          return GoogleFonts.lato(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            color: color,
          );
        case 'nunito':
          return GoogleFonts.nunito(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            color: color,
          );
        case 'montserrat':
          return GoogleFonts.montserrat(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            color: color,
          );
        case 'source sans pro':
        case 'sourcesanspro':
          return GoogleFonts.sourceSans3(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            color: color,
          );
        case 'playfair display':
        case 'playfairdisplay':
          return GoogleFonts.playfairDisplay(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            color: color,
          );
        default:
          // Fallback: Varsayılan Poppins kullan
          return GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            color: color,
          );
      }
    } catch (e) {
      // Google Fonts yüklenemezse standart TextStyle kullan
      print('🔤 Google Fonts yükleme hatası: $e');
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
        fontFamily: fontFamily,
      );
    }
  }
}
