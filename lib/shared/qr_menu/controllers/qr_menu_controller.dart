import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'qr_menu_state.dart';
import '../services/qr_menu_service.dart';
import '../utils/qr_error_utils.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/url_service.dart';
import '../../../core/services/qr_service.dart';
import '../../../core/services/multilingual_service.dart';
import '../../../core/utils/time_rule_utils.dart';
import '../../../business/services/business_firestore_service.dart';
import '../../../business/models/product.dart';
import '../../../customer/services/customer_service.dart';

/// QR Menu Controller - Business logic and state management
class QRMenuController extends ChangeNotifier {
  final QRMenuState _state = QRMenuState();

  // Services
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final UrlService _urlService = UrlService();
  final QRService _qrService = QRService();
  final BusinessFirestoreService _businessService = BusinessFirestoreService();
  final MultilingualService _multilingualService = MultilingualService();
  final CustomerService _customerService = CustomerService();
  final QRMenuService _qrMenuService = QRMenuService();

  // Animation Controllers
  AnimationController? _fadeAnimationController;
  AnimationController? _slideAnimationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  // Getters
  QRMenuState get state => _state;
  Animation<double>? get fadeAnimation => _fadeAnimation;
  Animation<Offset>? get slideAnimation => _slideAnimation;

  /// Initialize controller with animation controllers
  void initialize(TickerProvider vsync) {
    _initAnimations(vsync);
    _initializeGuestMode();
    _initializeServices();
  }

  void _initAnimations(TickerProvider vsync) {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: vsync,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController!, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideAnimationController!, curve: Curves.easeOutBack));
  }

  void _initializeGuestMode() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _state.setGuestMode(
          true, 'guest_${DateTime.now().millisecondsSinceEpoch}');
    } else {
      _state.setGuestMode(false);
    }
  }

  Future<void> _initializeServices() async {
    await _initializeCustomerService();
    await _initializeCart();
  }

  Future<void> _initializeCustomerService() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _customerService.createOrGetCustomer(
          email: currentUser.email,
          name: currentUser.displayName,
          phone: currentUser.phoneNumber,
          isAnonymous: false,
        );
      } else {
        await _customerService.createOrGetCustomer(isAnonymous: true);
      }
    } catch (e) {
      print('CustomerService initialization failed: $e');
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
    if (_state.businessId != null) {
      final count = await _cartService.getCartItemCount(_state.businessId!);
      _state.setCartItemCount(count);
    }
  }

  /// Parse URL and load data
  Future<void> parseUrlAndLoadData(BuildContext context) async {
    _state.setLoading(true);
    _state.setError(false);

    try {
      // Enhanced parameter extraction
      final parseResult = _extractBusinessParametersEnhanced(context);
      _state.setBusinessId(parseResult['businessId']);
      _state.setTableNumber(parseResult['tableNumber']);

      // Validate business ID
      if (_state.businessId == null || _state.businessId!.isEmpty) {
        throw QRValidationException(
          'QR kod geçersiz: İşletme bilgisi bulunamadı',
          errorCode: 'MISSING_BUSINESS_ID',
        );
      }

      // Enhanced QR validation
      final currentUrl = _buildValidationUrl();
      final validationResult =
          await _qrService.validateAndParseQRUrl(currentUrl);

      if (!validationResult.isValid) {
        throw QRValidationException(
          validationResult.errorMessage ?? 'QR kod doğrulama hatası',
          errorCode: validationResult.errorCode,
        );
      }

      // Update with validated data
      if (validationResult.businessId != null) {
        _state.setBusinessId(validationResult.businessId);
      }
      if (validationResult.tableNumber != null) {
        _state.setTableNumber(validationResult.tableNumber);
      }
      if (validationResult.business != null) {
        _state.setBusiness(validationResult.business);
      }

      // Load menu data
      await _loadMenuData();

      // Start animations
      _slideAnimationController?.forward();
      _fadeAnimationController?.forward();
    } catch (e) {
      String userFriendlyMessage;
      String? errorCode;

      if (e is QRValidationException) {
        userFriendlyMessage = e.message;
        errorCode = e.errorCode;
      } else {
        userFriendlyMessage =
            QRErrorUtils.getUserFriendlyErrorMessage(e.toString());
        errorCode = 'GENERAL_ERROR';
      }

      _state.setError(true, userFriendlyMessage);
    } finally {
      _state.setLoading(false);
    }
  }

  /// Extract business parameters from various sources
  Map<String, dynamic> _extractBusinessParametersEnhanced(
      BuildContext context) {
    // Method 1: Route arguments
    final routeSettings = ModalRoute.of(context)?.settings;
    final arguments = routeSettings?.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      final businessId = arguments['businessId']?.toString();
      final tableString = arguments['tableNumber']?.toString();
      if (businessId != null && businessId.isNotEmpty) {
        final tableNumber = int.tryParse(tableString ?? '');
        return {'businessId': businessId, 'tableNumber': tableNumber};
      }
    }

    // Method 2: URL Service
    try {
      final urlParams = _urlService.getCurrentParams();
      final businessId = urlParams['business'] ?? urlParams['businessId'];
      final tableString = urlParams['table'] ?? urlParams['tableNumber'];
      if (businessId != null && businessId.isNotEmpty) {
        final tableNumber = int.tryParse(tableString ?? '');
        return {'businessId': businessId, 'tableNumber': tableNumber};
      }
    } catch (e) {
      print('URL Service method failed: $e');
    }

    return {'businessId': null, 'tableNumber': null};
  }

  String _buildValidationUrl() {
    if (_state.businessId != null) {
      final baseUrl = _qrService.baseUrl;
      if (_state.tableNumber != null) {
        return '$baseUrl/qr?business=${_state.businessId}&table=${_state.tableNumber}';
      } else {
        return '$baseUrl/qr?business=${_state.businessId}';
      }
    }
    return '';
  }

  Future<void> _loadMenuData() async {
    try {
      // Load business data
      final businessData =
          await _businessService.getBusiness(_state.businessId!);

      // Load categories
      final categoriesData =
          await _businessService.getBusinessCategories(_state.businessId!);

      // Load products
      final productsData =
          await _businessService.getBusinessProducts(_state.businessId!);
      final activeProducts =
          productsData.where((p) => p.isActive && p.isAvailable).toList();

      // Load discounts
      final discountsData =
          await _businessService.getDiscountsByBusinessId(_state.businessId!);

      // Load favorites (only for registered users)
      List<String> favoriteProductIds = [];
      if (!_state.isGuestMode) {
        try {
          final favoriteProducts = await _loadFavoritesFromFirebase();
          favoriteProductIds =
              favoriteProducts.map((f) => f['productId'] as String).toList();
        } catch (e) {
          print('Error loading favorites: $e');
        }
      }

      if (businessData != null) {
        _state.setBusiness(businessData);
        _state.setCategories(categoriesData.where((c) => c.isActive).toList());
        _state.setProducts(activeProducts);
        _state.setDiscounts(discountsData);
        _state.setFavoriteProductIds(favoriteProductIds);
        filterProducts();

        // Update URL
        _updateUrl();
      } else {
        throw Exception('İşletme bilgileri yüklenirken bir hata oluştu.');
      }
    } catch (e) {
      throw Exception('Veriler yüklenirken bir hata oluştu: $e');
    }
  }

  Future<List<dynamic>> _loadFavoritesFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('product_favorites')
          .where('customerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return favoritesSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error loading favorites from Firebase: $e');
      return [];
    }
  }

  void _updateUrl() {
    if (_state.business != null) {
      final title = _state.tableNumber != null
          ? '${_state.business!.businessName} - Masa ${_state.tableNumber} | MasaMenu'
          : '${_state.business!.businessName} - Menü | MasaMenu';

      _urlService.updateUrl('/qr', customTitle: title, params: {
        'business': _state.businessId!,
        if (_state.tableNumber != null) 'table': _state.tableNumber.toString(),
      });
    }
  }

  /// Filter products based on current filters
  void filterProducts() {
    final filtered = _state.products.where((product) {
      // Category filter
      if (_state.selectedCategoryId != null &&
          _state.selectedCategoryId != 'all' &&
          product.categoryId != _state.selectedCategoryId) {
        return false;
      }

      // Search filter
      if (_state.searchQuery.isNotEmpty &&
          !product.matchesSearchQuery(_state.searchQuery)) {
        return false;
      }

      // Time rules
      if (!TimeRuleUtils.isProductVisible(product)) {
        return false;
      }

      // Other filters
      return product.matchesFilters(
        tagFilters: _state.filters['tags'],
        allergenFilters: _state.filters['allergens'],
        minPrice: _state.filters['minPrice'],
        maxPrice: _state.filters['maxPrice'],
        isVegetarian: _state.filters['isVegetarian'],
        isVegan: _state.filters['isVegan'],
        isHalal: _state.filters['isHalal'],
        isSpicy: _state.filters['isSpicy'],
      );
    }).toList();

    // Apply discounts
    final discountedProducts = filtered.map((product) {
      final finalPrice = product.calculateFinalPrice(_state.discounts);
      return product.copyWith(currentPrice: finalPrice);
    }).toList();

    _state.setFilteredProducts(discountedProducts);
  }

  /// Event handlers
  void onCategorySelected(String categoryId) {
    _state.setSelectedCategoryId(categoryId);
    filterProducts();
    HapticFeedback.selectionClick();
  }

  void onSearchChanged(String query) {
    _state.setSearchQuery(query);
    filterProducts();
  }

  void onFiltersChanged(Map<String, dynamic> filters) {
    _state.setFilters(filters);
    filterProducts();
  }

  void toggleSearchBar() {
    _state.setShowSearchBar(!_state.showSearchBar);
    if (!_state.showSearchBar) {
      _state.setSearchQuery('');
      filterProducts();
    }
  }

  void updateHeaderOpacity(double offset) {
    final opacity = (100 - offset) / 100;
    _state.setHeaderOpacity(opacity.clamp(0.0, 1.0));
  }

  /// Add product to cart
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    if (_state.businessId == null) return;

    try {
      await _cartService.addToCart(product, _state.businessId!,
          quantity: quantity);
      HapticFeedback.heavyImpact();
    } catch (e) {
      throw Exception('Sepete eklenirken hata: $e');
    }
  }

  @override
  void dispose() {
    _fadeAnimationController?.dispose();
    _slideAnimationController?.dispose();
    _cartService.removeCartListener(_onCartChanged);
    _state.dispose();
    super.dispose();
  }
}

/// QR Validation Exception
class QRValidationException implements Exception {
  final String message;
  final String? errorCode;

  QRValidationException(this.message, {this.errorCode});

  @override
  String toString() =>
      'QRValidationException: $message${errorCode != null ? ' (Code: $errorCode)' : ''}';
}
