import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/url_service.dart';
import '../../core/services/qr_service.dart';
import '../../core/services/qr_validation_service.dart';
import '../../core/services/multilingual_service.dart';
import '../../core/utils/time_rule_utils.dart';
import '../../business/services/business_firestore_service.dart';
import '../../business/models/business.dart';
import '../../business/models/product.dart';
import '../../business/models/category.dart';
import '../../business/models/discount.dart';
import '../../customer/widgets/category_list.dart';
import '../../customer/widgets/product_grid.dart';
import '../../customer/widgets/business_header.dart';
import '../../customer/widgets/search_bar.dart' as custom_search;
import '../../customer/widgets/filter_bottom_sheet.dart';
import '../../customer/pages/customer_waiter_call_page.dart';
import '../../customer/pages/product_detail_page.dart';
import '../../customer/pages/cart_page.dart';
import '../../customer/services/customer_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Evrensel QR Menü Sayfası - MenuPage ile Aynı Tasarım (Misafir Modu Destekli)
class UniversalQRMenuPage extends StatefulWidget {
  const UniversalQRMenuPage({super.key});

  @override
  State<UniversalQRMenuPage> createState() => _UniversalQRMenuPageState();
}

class _UniversalQRMenuPageState extends State<UniversalQRMenuPage>
    with TickerProviderStateMixin {
  // Controllers - MenuPage ile aynı
  TabController? _tabController;
  late ScrollController _scrollController;
  late ScrollController _categoryScrollController;

  // Services - MenuPage ile aynı
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final UrlService _urlService = UrlService();
  final QRService _qrService = QRService();
  final BusinessFirestoreService _businessService = BusinessFirestoreService();
  final MultilingualService _multilingualService = MultilingualService();
  final CustomerService _customerService = CustomerService();

  // Animation Controllers - MenuPage ile aynı
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Data - MenuPage ile aynı
  Business? _business;
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Product> _filteredProducts = [];
  List<Discount> _discounts = [];
  List<String> _favoriteProductIds = [];

  // URL Parameters
  String? _businessId;
  int? _tableNumber;

  // State - MenuPage ile aynı
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};
  bool _showSearchBar = false;
  int _cartItemCount = 0;
  double _headerOpacity = 1.0;
  String _currentLanguage = 'tr';

  // Guest Mode State
  bool _isGuestMode = false;
  String? _guestUserId;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initAnimations();
    _initializeGuestMode();
    _initializeServices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // URL parsing'i burada yap çünkü context artık kullanılabilir
    if (_businessId == null) {
      _parseUrlAndLoadData();
    }
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

  void _initializeGuestMode() {
    // Kullanıcı giriş yapmış mı kontrol et
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      // Kullanıcı giriş yapmamış, misafir modu başlat
      setState(() {
        _isGuestMode = true;
        _guestUserId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      });
    } else {
      // Kullanıcı giriş yapmış
      setState(() {
        _isGuestMode = false;
        _guestUserId = null;
      });
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
        print(
            '🔐 UniversalQRMenuPage: Initializing CustomerService with user: ${currentUser.uid}');
        await _customerService.createOrGetCustomer(
          email: currentUser.email,
          name: currentUser.displayName,
          phone: currentUser.phoneNumber,
          isAnonymous: false,
        );
        print(
            '✅ UniversalQRMenuPage: CustomerService initialized successfully');
      } else {
        print(
            '⚠️ UniversalQRMenuPage: No authenticated user found, using guest mode');
        // Anonim kullanıcı olarak devam et
        await _customerService.createOrGetCustomer(
          isAnonymous: true,
        );
      }
    } catch (e) {
      print('❌ UniversalQRMenuPage: CustomerService initialization failed: $e');
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
    if (_businessId != null) {
      final count = await _cartService.getCartItemCount(_businessId!);
      if (mounted) {
        setState(() {
          _cartItemCount = count;
        });
      }
    }
  }

  Future<List<dynamic>> _loadFavoritesFromFirebase() async {
    try {
      // Firebase Auth'dan current user'ı al
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print(
            '🔒 UniversalQRMenuPage: No authenticated user, returning empty favorites');
        return [];
      }

      print(
          '💖 UniversalQRMenuPage: Loading favorite products from Firebase...');

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
          '💖 UniversalQRMenuPage: Favorite products loaded from Firebase: ${favorites.length} items - ${favorites.map((f) => f['productId']).toList()}');

      return favorites;
    } catch (e) {
      print('❌ UniversalQRMenuPage: Error loading favorites from Firebase: $e');
      return [];
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

  Future<void> _parseUrlAndLoadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // User feedback - POST FRAME
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('🔍 QR kod doğrulanıyor...'),
                ],
              ),
              duration: Duration(seconds: 2),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      });

      // Enhanced parameter extraction with multiple fallback methods
      final parseResult = _extractBusinessParametersEnhanced();
      _businessId = parseResult['businessId'];
      _tableNumber = parseResult['tableNumber'];

      // Validate that we have a business ID
      if (_businessId == null || _businessId!.isEmpty) {
        throw QRValidationException(
          'QR kod geçersiz: İşletme bilgisi bulunamadı',
          errorCode: 'MISSING_BUSINESS_ID',
        );
      }

      // Enhanced QR validation using QR Service
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
        _businessId = validationResult.businessId;
      }
      if (validationResult.tableNumber != null) {
        _tableNumber = validationResult.tableNumber;
      }

      // Use business from validation if available
      if (validationResult.business != null) {
        setState(() {
          _business = validationResult.business;
        });
      }

      // QR kod başarıyla çözümlendi, menü verilerini yükle
      print('✅ QR kod doğrulandı, menü verileri yükleniyor...');
      await _loadMenuData();

      // Start animations
      _slideAnimationController.forward();
      _fadeAnimationController.forward();
    } catch (e) {
      String userFriendlyMessage;
      String? errorCode;

      if (e is QRValidationException) {
        userFriendlyMessage = e.message;
        errorCode = e.errorCode;
      } else {
        userFriendlyMessage = _getUserFriendlyErrorMessage(e.toString());
        errorCode = 'GENERAL_ERROR';
      }

      setState(() {
        _hasError = true;
        _errorMessage = userFriendlyMessage;
      });

      // Log error for analytics
      final currentUrl = _buildValidationUrl();
      final validationService = QRValidationService();
      await validationService.logQRCodeError(
        currentUrl,
        userFriendlyMessage,
        errorCode,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Enhanced business parameter extraction with multiple fallback methods
  Map<String, dynamic> _extractBusinessParametersEnhanced() {
    // Method 1: Route arguments (highest priority - most reliable)
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

    // Method 2: URL Service (web-compatible)
    try {
      final urlParams = _urlService.getCurrentParams();
      final businessId = urlParams['business'] ?? urlParams['businessId'];
      final tableString = urlParams['table'] ?? urlParams['tableNumber'];
      if (businessId != null && businessId.isNotEmpty) {
        final tableNumber = int.tryParse(tableString ?? '');
        return {'businessId': businessId, 'tableNumber': tableNumber};
      }
    } catch (e) {
      // print('⚠️ URL Service method failed: $e'); // Removed print
    }

    // Method 3: Direct route name parsing
    try {
      if (routeSettings?.name != null) {
        final uri = Uri.tryParse(routeSettings!.name!);
        if (uri != null) {
          final businessId = uri.queryParameters['business'] ??
              uri.queryParameters['businessId'];
          final tableString = uri.queryParameters['table'] ??
              uri.queryParameters['tableNumber'];
          if (businessId != null && businessId.isNotEmpty) {
            final tableNumber = int.tryParse(tableString ?? '');
            return {'businessId': businessId, 'tableNumber': tableNumber};
          }
        }
      }
    } catch (e) {
      // print('⚠️ Route parsing method failed: $e'); // Removed print
    }

    // Method 4: Web-specific QR route info (from enhanced web routing)
    try {
      // This would be populated by the enhanced web routing system
      final webQRInfo = _getWebQRRouteInfo();
      if (webQRInfo != null) {
        final businessId = webQRInfo['businessId'];
        final tableString = webQRInfo['tableNumber']?.toString();
        if (businessId != null && businessId.isNotEmpty) {
          final tableNumber = int.tryParse(tableString ?? '');
          return {'businessId': businessId, 'tableNumber': tableNumber};
        }
      }
    } catch (e) {
      // print('⚠️ Web QR info method failed: $e'); // Removed print
    }

    return {'businessId': null, 'tableNumber': null};
  }

  /// Get QR route info from web platform (if available)
  Map<String, dynamic>? _getWebQRRouteInfo() {
    // This would interface with the JavaScript QR route info
    try {
      // Web platformunda JavaScript'ten QR bilgilerini al
      // Bu method web'de çalıştığında JavaScript'teki window.qrRouteInfo'yu okuyacak

      // Flutter web'de JavaScript interop kullanarak
      if (kIsWeb) {
        // JavaScript window.getQRRouteInfo() function'ını çağır
        // Bu implementation JavaScript ile Flutter arasında bridge gerektirir
        // Şimdilik URL parsing ile fallback yapıyoruz

        final currentUrl = Uri.base;
        final businessId = currentUrl.queryParameters['business'] ??
            currentUrl.queryParameters['businessId'];
        final tableNumber = currentUrl.queryParameters['table'] ??
            currentUrl.queryParameters['tableNumber'];

        if (businessId != null && businessId.isNotEmpty) {
          return {
            'businessId': businessId,
            'tableNumber':
                tableNumber != null ? int.tryParse(tableNumber) : null,
            'source': 'flutter_web_fallback'
          };
        }
      }

      return null;
    } catch (e) {
      print('⚠️ Web QR info extraction failed: $e');
      return null;
    }
  }

  /// Build validation URL for QR service
  String _buildValidationUrl() {
    if (_businessId != null) {
      final baseUrl = _qrService.baseUrl;
      if (_tableNumber != null) {
        return '$baseUrl/qr?business=$_businessId&table=$_tableNumber';
      } else {
        return '$baseUrl/qr?business=$_businessId';
      }
    }

    // Fallback: try to construct from route
    final routeSettings = ModalRoute.of(context)?.settings;
    if (routeSettings?.name != null) {
      return '${_qrService.baseUrl}${routeSettings!.name!}';
    }

    // Last resort: empty URL (will cause validation to fail appropriately)
    return '';
  }

  /// Mevcut URL'yi validation için hazırlar
  String _getCurrentUrlForValidation() {
    return _buildValidationUrl();
  }

  /// Basitleştirilmiş parametre çıkarma metodu (legacy fallback)
  Map<String, String?> _extractBusinessParameters() {
    // Use the enhanced method and convert to legacy format
    final enhanced = _extractBusinessParametersEnhanced();
    return {
      'businessId': enhanced['businessId']?.toString(),
      'tableNumber': enhanced['tableNumber']?.toString(),
    };
  }

  Future<void> _loadMenuData() async {
    try {
      print(
          '🔄 UniversalQRMenuPage: Loading menu data for business: $_businessId');
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // Load business, categories, products, and discounts
      print('📊 UniversalQRMenuPage: Loading business data...');
      final businessData = await _businessService.getBusiness(_businessId!);
      print(
          '📊 UniversalQRMenuPage: Business data loaded: ${businessData?.businessName ?? 'null'}');

      print('📂 UniversalQRMenuPage: Loading categories...');
      final categoriesData =
          await _businessService.getBusinessCategories(_businessId!);
      print(
          '📂 UniversalQRMenuPage: Categories loaded: ${categoriesData.length} items');

      print('🍽️ UniversalQRMenuPage: Loading products...');
      final productsData =
          await _businessService.getBusinessProducts(_businessId!);
      print(
          '🍽️ UniversalQRMenuPage: Raw products loaded: ${productsData.length} items');

      // Sadece aktif ve müsait ürünleri filtrele
      final activeProducts =
          productsData.where((p) => p.isActive && p.isAvailable).toList();
      print(
          '🍽️ UniversalQRMenuPage: Active products after filtering: ${activeProducts.length} items');

      // Debug için kullanıcıya da göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'UniversalQRMenuPage: ${productsData.length} ürün bulundu, ${activeProducts.length} tanesi aktif'),
            duration: Duration(seconds: 2),
            backgroundColor:
                activeProducts.isEmpty ? AppColors.error : AppColors.success,
          ),
        );
      }

      print('🎯 UniversalQRMenuPage: Loading discounts...');
      final discountsData =
          await _businessService.getDiscountsByBusinessId(_businessId!);
      print(
          '🎯 UniversalQRMenuPage: Discounts loaded: ${discountsData.length} items');

      // Load favorite products from Firebase (sadece kayıtlı kullanıcılar için)
      List<String> favoriteProductIds = [];
      if (!_isGuestMode) {
        try {
          print(
              '💖 UniversalQRMenuPage: Loading favorite products from Firebase...');
          final favoriteProducts = await _loadFavoritesFromFirebase();
          favoriteProductIds =
              favoriteProducts.map((f) => f['productId'] as String).toList();
          print(
              '💖 UniversalQRMenuPage: Favorite products loaded from Firebase: ${favoriteProductIds.length} items - $favoriteProductIds');
        } catch (e) {
          print(
              '❌ UniversalQRMenuPage: Error loading favorite products from Firebase: $e');
          favoriteProductIds = [];
        }
      }

      if (businessData != null) {
        print('✅ UniversalQRMenuPage: Business data is valid, processing...');

        print('🔄 UniversalQRMenuPage: Setting state with loaded data...');
        setState(() {
          _business = businessData;
          _categories = categoriesData.where((c) => c.isActive).toList();
          _products = activeProducts;
          _discounts = discountsData;
          _favoriteProductIds = favoriteProductIds;
          _filterProducts();
          _isLoading = false;
        });
        print('✅ UniversalQRMenuPage: State updated successfully');

        // Initialize tab controller after categories are loaded
        if (_categories.isNotEmpty && _tabController == null) {
          _tabController =
              TabController(length: _categories.length, vsync: this);
          _tabController?.addListener(_onTabChanged);
        }

        // Start animations after data is loaded
        print('🎬 UniversalQRMenuPage: Starting animations...');
        _fadeAnimationController.forward();
        _slideAnimationController.forward();

        // URL'i güncelle
        _updateUrl();
      } else {
        print('❌ UniversalQRMenuPage: Business data is null');
        setState(() {
          _hasError = true;
          _errorMessage = 'İşletme bilgileri yüklenirken bir hata oluştu.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ UniversalQRMenuPage: Exception occurred: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Veriler yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _updateUrl() {
    if (_business != null) {
      final title = _tableNumber != null
          ? '${_business!.businessName} - Masa $_tableNumber | MasaMenu'
          : '${_business!.businessName} - Menü | MasaMenu';

      _urlService.updateUrl('/qr', customTitle: title, params: {
        'business': _businessId!,
        if (_tableNumber != null) 'table': _tableNumber.toString(),
      });
    }
  }

  Future<void> _addToCart(Product product, {int quantity = 1}) async {
    if (_businessId == null) return;

    try {
      // Misafir modu için guest user ID kullan
      final userId =
          _isGuestMode ? _guestUserId : _authService.currentUser?.uid;

      await _cartService.addToCart(product, _businessId!, quantity: quantity);

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
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${product.name} sepete eklendi'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: _isGuestMode ? 'Sepete Git' : 'Sepete Git',
              textColor: AppColors.white,
              onPressed: () {
                _handleCartAction();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sepete eklenirken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilters: {'categoryId': _selectedCategoryId},
        onFiltersChanged: (filters) {
          final categoryId = filters['categoryId'] as String? ?? 'all';
          _onCategorySelected(categoryId);
        },
      ),
    );
  }

  void _handleCartAction() {
    if (_isGuestMode) {
      // Misafir modunda sepet erişimi için kayıt teşviki göster
      _showGuestCartDialog();
    } else {
      // Kayıtlı kullanıcı - direkt sepete git
      final currentUser = _authService.currentUser;
      Navigator.pushNamed(
        context,
        '/customer/cart',
        arguments: {
          'businessId': _businessId,
          'userId': currentUser?.uid,
        },
      );
    }
  }

  void _handleWaiterCall() {
    if (_isGuestMode) {
      // Misafir modunda garson çağırma için kayıt teşviki göster
      _showGuestWaiterDialog();
    } else {
      // Kayıtlı kullanıcı - direkt garson çağırma
      _showWaiterCallDialog();
    }
  }

  void _showAuthDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.login_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Giriş Gerekli'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Kayıt Ol',
                style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _showWaiterCallDialog() {
    if (_business == null || _businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşletme bilgileri yüklenemedi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Müşteri bilgilerini al
    final currentUser = _authService.currentUser;
    String customerId;
    String customerName;

    if (_isGuestMode) {
      customerId =
          _guestUserId ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      customerName = 'Misafir Kullanıcı';
    } else if (currentUser != null) {
      customerId = currentUser.uid;
      customerName = currentUser.displayName ?? 'Müşteri';
    } else {
      _showAuthDialog('Garson çağırmak için giriş yapmanız gerekmektedir.');
      return;
    }

    // Garson çağırma sayfasına git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerWaiterCallPage(
          businessId: _businessId!,
          customerId: customerId,
          customerName: customerName,
          tableNumber: _tableNumber?.toString(),
          floorNumber: null, // QR'dan kat bilgisi gelmiyorsa null
        ),
      ),
    );
  }

  void _showGuestCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.shopping_cart_rounded, color: AppColors.secondary),
            const SizedBox(width: 8),
            const Text('Sepete Gitmek İçin Giriş Yapın'),
          ],
        ),
        content: Text(
            'Misafir modunda sepete erişim için giriş yapmanız gerekmektedir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Kayıt Ol',
                style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _showGuestWaiterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.room_service_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Garson Çağırma'),
          ],
        ),
        content: Text(
            'Misafir modunda da garson çağırabilirsiniz. Daha iyi hizmet için giriş yapmanızı öneririz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showWaiterCallDialog(); // Direkt garson çağırma sayfasına git
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Garson Çağır',
                style: TextStyle(color: AppColors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Giriş Yap',
                style: TextStyle(color: AppColors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Kayıt Ol',
                style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  /// Destek dialog'unu gösterir
  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.support_agent_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Müşteri Desteği'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QR kod problemi mi yaşıyorsunuz? Size nasıl yardımcı olabiliriz?',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Hata detayları göster
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hata Detayı:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Destek seçenekleri
            _buildSupportOption(
              Icons.phone_rounded,
              'Telefonla Destek',
              'İşletmeyi arayın',
              () {
                Navigator.pop(context);
                _contactBusinessSupport();
              },
            ),

            _buildSupportOption(
              Icons.qr_code_scanner_rounded,
              'QR Kod Tarayıcı',
              'Manuel QR tarama',
              () {
                Navigator.pop(context);
                _showQRScannerHelp();
              },
            ),

            _buildSupportOption(
              Icons.refresh_rounded,
              'Sayfa Yenile',
              'Tekrar deneyin',
              () {
                Navigator.pop(context);
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _parseUrlAndLoadData();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// QR Scanner yardım dialog'unu gösterir
  void _showQRScannerHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.info),
            const SizedBox(width: 12),
            const Text('QR Kod Tarayıcı'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QR kodunuzu manuel olarak tarayabilirsiniz:',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_2_rounded,
                      size: 48, color: AppColors.info),
                  const SizedBox(height: 12),
                  Text(
                    'QR kod tarayıcıya yönlendirileceksiniz. QR kodunuzu kameranızla taratın.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/qr-scanner');
            },
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: Text('QR Tarayıcı Aç'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// İşletme desteği ile iletişime geçme
  void _contactBusinessSupport() {
    // Eğer business bilgisi varsa, işletmeye özel destek göster
    if (_business != null) {
      _showBusinessContactDialog();
    } else {
      _showGeneralSupportDialog();
    }
  }

  /// İşletme iletişim dialog'u
  void _showBusinessContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.store_rounded, color: AppColors.secondary),
            const SizedBox(width: 12),
            Text('${_business!.businessName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İşletme ile iletişime geçin:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_business!.phone != null && _business!.phone!.isNotEmpty) ...[
              _buildContactOption(
                Icons.phone_rounded,
                'Telefon',
                _business!.phone!,
                () => _makePhoneCall(_business!.phone!),
              ),
              const SizedBox(height: 8),
            ],
            if (_business!.email != null && _business!.email!.isNotEmpty) ...[
              _buildContactOption(
                Icons.email_rounded,
                'E-posta',
                _business!.email!,
                () => _sendEmail(_business!.email!),
              ),
              const SizedBox(height: 8),
            ],
            _buildContactOption(
              Icons.location_on_rounded,
              'Adres',
              '${_business!.address.street}, ${_business!.address.city}',
              () => _showAddressDialog(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Genel destek dialog'u
  void _showGeneralSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_center_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Genel Destek'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QR kod problemi için aşağıdaki adımları deneyin:',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildHelpStep(
                '1', 'QR kodun net ve hasarsız olduğundan emin olun'),
            _buildHelpStep('2', 'İnternet bağlantınızı kontrol edin'),
            _buildHelpStep('3', 'Uygulamayı yeniden başlatın'),
            _buildHelpStep('4', 'İşletmeden yeni bir QR kod isteyin'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // YARDIMCI WIDGET'LAR ve METODLAR
  // =============================================================================

  /// Destek seçeneği widget'ı
  Widget _buildSupportOption(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  /// İletişim seçeneği widget'ı
  Widget _buildContactOption(
      IconData icon, String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Yardım adımı widget'ı
  Widget _buildHelpStep(String number, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Telefon arama
  void _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Telefon uygulaması açılamadı';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Telefon açılamadı: $phoneNumber'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// E-posta gönderme
  void _sendEmail(String email) async {
    try {
      final Uri emailUri = Uri.parse('mailto:$email?subject=QR Menü Desteği');
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'E-posta uygulaması açılamadı';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E-posta açılamadı: $email'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Adres detay dialog'u
  void _showAddressDialog() {
    if (_business == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_on_rounded, color: AppColors.secondary),
            const SizedBox(width: 12),
            const Text('Adres Bilgisi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _business!.businessName,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_business!.address.street}\n${_business!.address.district}\n${_business!.address.city} ${_business!.address.postalCode}',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openMaps();
            },
            icon: Icon(Icons.map_rounded),
            label: Text('Haritada Aç'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Harita uygulamasını açma
  void _openMaps() async {
    if (_business == null) return;

    try {
      final address =
          '${_business!.address.street}, ${_business!.address.district}, ${_business!.address.city}';
      final Uri mapsUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');

      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri);
      } else {
        throw 'Harita uygulaması açılamadı';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harita açılamadı'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
                  onPressed: () => _parseUrlAndLoadData(),
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

            // Decorative pattern - Kaldırıldı, çünkü HeaderPatternPainter sınıfı eksik

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
                          tag: 'business_avatar_$_businessId',
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
                                      errorBuilder:
                                          (context, error, stackTrace) =>
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
          onTap: _isGuestMode ? _showGuestCartDialog : _onCartPressed,
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
                      final isSelected = _selectedCategoryId == 'all' ||
                          _selectedCategoryId == null;
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: ElevatedButton.icon(
                          onPressed: () => _onCategorySelected('all'),
                          icon: Icon(Icons.apps_rounded),
                          label: Text('Tümü'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.white,
                            foregroundColor: isSelected
                                ? AppColors.white
                                : AppColors.primary,
                          ),
                        ),
                      );
                    }

                    final category = _categories[index - 1];
                    final isSelected =
                        _selectedCategoryId == category.categoryId;
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: ElevatedButton(
                        onPressed: () =>
                            _onCategorySelected(category.categoryId),
                        child: Text(category.name),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelected ? AppColors.primary : AppColors.white,
                          foregroundColor:
                              isSelected ? AppColors.white : AppColors.primary,
                        ),
                      ),
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

  Widget _buildProductSection() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: AppColors.background,
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Text(
                    'Henüz ürün bulunmuyor',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _parseUrlAndLoadData,
                  color: AppColors.primary,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.greyLighter,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                ),
                                child: product.imageUrl != null
                                    ? Image.network(
                                        product.imageUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(Icons.restaurant),
                                      )
                                    : Icon(Icons.restaurant),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${product.price.toStringAsFixed(0)} ₺',
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (!_isGuestMode)
                                        ElevatedButton(
                                          onPressed: () => _addToCart(product),
                                          child: Icon(Icons.add, size: 16),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: AppColors.white,
                                            minimumSize: Size(32, 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
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

  void _onCartPressed() {
    if (_isGuestMode) {
      _showGuestCartDialog();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartPage(
            businessId: _businessId!,
            userId: _authService.currentUser?.uid,
          ),
        ),
      );
    }
  }

  // =============================================================================
  // YARDIMCI WIDGET'LAR ve METODLAR
  // =============================================================================

  Widget _buildSolutionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  String _getUserFriendlyErrorMessage(String originalError) {
    if (originalError.contains('İşletme ID\'si bulunamadı')) {
      return 'Bu QR kod geçerli değil veya hasarlı. Lütfen işletmeden yeni bir QR kod isteyin.';
    } else if (originalError.contains('İşletme bulunamadı')) {
      return 'Bu işletme sistemde bulunamıyor. İşletme hesabı kapatılmış olabilir.';
    } else if (originalError.contains('İşletme aktif değil')) {
      return 'Bu işletme şu anda hizmet vermiyor. Lütfen daha sonra tekrar deneyin.';
    } else if (originalError.contains('Veriler yüklenirken hata')) {
      return 'Menü bilgileri yüklenemiyor. İnternet bağlantınızı kontrol edin.';
    } else if (originalError.contains('businesses collection')) {
      return 'Sistemde bir teknik sorun var. Lütfen daha sonra tekrar deneyin.';
    } else {
      return 'QR kod okunamadı. Lütfen tekrar deneyin veya işletmeden yardım isteyin.';
    }
  }
}

/// QR doğrulama hata sınıfı
class QRValidationException implements Exception {
  final String message;
  final String? errorCode;

  QRValidationException(this.message, {this.errorCode});

  @override
  String toString() =>
      'QRValidationException: $message${errorCode != null ? ' (Code: $errorCode)' : ''}';
}
