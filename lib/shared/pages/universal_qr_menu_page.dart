import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/url_service.dart';
import '../../core/services/qr_service.dart';
import '../../core/services/qr_validation_service.dart';
import '../../business/services/business_firestore_service.dart';
import '../../business/models/business.dart';
import '../../business/models/product.dart';
import '../../business/models/category.dart';
import '../../customer/widgets/category_list.dart';
import '../../customer/widgets/product_grid.dart';
import '../../customer/widgets/business_header.dart';
import '../../customer/widgets/search_bar.dart' as custom_search;
import '../../customer/widgets/filter_bottom_sheet.dart';
import '../../customer/pages/customer_waiter_call_page.dart';
import '../../customer/pages/menu_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

/// Evrensel QR Menü Sayfası - Tüm İşletmeler İçin Ortak (Misafir Modu Destekli)
class UniversalQRMenuPage extends StatefulWidget {
  const UniversalQRMenuPage({super.key});

  @override
  State<UniversalQRMenuPage> createState() => _UniversalQRMenuPageState();
}

class _UniversalQRMenuPageState extends State<UniversalQRMenuPage>
    with TickerProviderStateMixin {
  // Services
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final UrlService _urlService = UrlService();
  final QRService _qrService = QRService();
  final BusinessFirestoreService _businessService = BusinessFirestoreService();

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Data
  Business? _business;
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Product> _filteredProducts = [];

  // URL Parameters
  String? _businessId;
  int? _tableNumber;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  bool _isSearching = false;

  // Guest Mode State
  bool _isGuestMode = false;
  String? _guestUserId;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGuestMode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // URL parsing'i burada yap çünkü context artık kullanılabilir
    if (_businessId == null) {
      _parseUrlAndLoadData();
    }
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
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

  Future<void> _parseUrlAndLoadData() async {
    setState(() {
      _isLoading = true;
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

      // QR kod başarıyla çözümlendi, direkt MenuPage'e yönlendir
      if (mounted && _businessId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MenuPage(businessId: _businessId!),
            settings: RouteSettings(
              arguments: {
                'businessId': _businessId!,
                if (_tableNumber != null) 'tableNumber': _tableNumber,
              },
            ),
          ),
        );
        return;
      }

      // Load remaining data (fallback - normalde çalışmayacak)
      await _loadMenuData();

      // Start animations
      _slideController.forward();
      _fadeController.forward();
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
    // For now, return null as this requires platform-specific implementation
    return null;
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
                  Text('📍 Menü yükleniyor...'),
                ],
              ),
              duration: Duration(seconds: 2),
              backgroundColor: AppColors.info,
            ),
          );
        }
      });

      // Eğer business bilgisi henüz yüklenmemişse, şimdi yükle
      if (_business == null) {
        final business = await _businessService.getBusiness(_businessId!);

        if (business == null) {
          throw QRValidationException(
            'İşletme bulunamadı (ID: $_businessId)',
            errorCode: 'BUSINESS_NOT_FOUND',
          );
        }

        if (!business.isActive) {
          throw QRValidationException(
            'İşletme şu anda hizmet vermiyor',
            errorCode: 'BUSINESS_INACTIVE',
          );
        }

        setState(() {
          _business = business;
        });
      }

      // Kategorileri al
      final categories =
          await _businessService.getCategories(businessId: _businessId!);

      // Ürünleri al
      final products =
          await _businessService.getProducts(businessId: _businessId!);
      final activeProducts =
          products.where((p) => p.isActive && p.isAvailable).toList();

      print('📦 UniversalQRMenuPage: Total products found: ${products.length}');
      print('✅ UniversalQRMenuPage: Active products: ${activeProducts.length}');

      // Debug için kullanıcıya da göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Toplam ${products.length} ürün bulundu, ${activeProducts.length} tanesi aktif'),
            duration: Duration(seconds: 3),
            backgroundColor:
                activeProducts.isEmpty ? AppColors.error : AppColors.success,
          ),
        );
      }

      setState(() {
        _business = _business; // Business zaten yukarıda set edilmiş
        _categories = [
          Category(
            categoryId: 'all',
            businessId: _businessId!,
            name: 'Tümü',
            description: 'Tüm ürünler',
            isActive: true,
            sortOrder: -1,
            timeRules: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ...categories.where((c) => c.isActive).toList()
        ];
        _products = activeProducts;
        _filteredProducts = activeProducts;
      });

      // URL'i güncelle
      _updateUrl();
    } catch (e) {
      String userFriendlyMessage;
      String? errorCode;

      if (e is QRValidationException) {
        userFriendlyMessage = e.message;
        errorCode = e.errorCode;
      } else {
        userFriendlyMessage = _getUserFriendlyErrorMessage(e.toString());
        errorCode = 'MENU_LOAD_ERROR';
      }

      setState(() {
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

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _applyFilters();
    });
    HapticFeedback.lightImpact();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Product> filtered = _products;

    // Kategori filtresi
    if (_selectedCategoryId != 'all') {
      filtered =
          filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
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
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingPage();
    }

    if (_errorMessage != null) {
      return _buildErrorPage();
    }

    if (_business == null) {
      return _buildNotFoundPage();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Business Header
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: BusinessHeader(
                business: _business!,
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: custom_search.CustomSearchBar(
                  onSearchChanged: _onSearchChanged,
                ),
              ),
            ),
          ),

          // Category List
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: CategoryList(
                categories: _categories,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: _onCategorySelected,
              ),
            ),
          ),

          // Product Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: ProductGrid(
                  products: _filteredProducts,
                  onAddToCart: _addToCart,
                  isQRMenu: true,
                ),
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildLoadingPage() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loading Animation
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 6,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Menü Yükleniyor...',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Debug info for user
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'QR Kod Bilgileri:',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_businessId != null) ...[
                      Text(
                        'İşletme ID: $_businessId',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (_tableNumber != null) ...[
                      Text(
                        'Masa: $_tableNumber',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (_businessId == null && _tableNumber == null) ...[
                      Text(
                        'QR kod analiz ediliyor...',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Lütfen bekleyin, veriler yükleniyor.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPage() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 48,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'QR Kod Okuma Hatası',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _getUserFriendlyErrorMessage(
                    _errorMessage ?? 'Bilinmeyen hata'),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              // Kullanıcı dostu çözüm önerileri
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: AppColors.info, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Çözüm Önerileri:',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSolutionItem('• QR kodu tekrar tarayın'),
                    _buildSolutionItem('• İnternet bağlantınızı kontrol edin'),
                    _buildSolutionItem(
                        '• QR kodun net ve hasarsız olduğundan emin olun'),
                    _buildSolutionItem('• İşletmeden yeni bir QR kod isteyin'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Ana eylem butonları
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isLoading = true;
                          });
                          _parseUrlAndLoadData();
                        },
                        icon: Icon(Icons.refresh_rounded),
                        label: Text('Tekrar Dene'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/'),
                        icon: Icon(Icons.home_rounded),
                        label: Text('Ana Sayfa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Destek ve yardım butonları
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: _showSupportDialog,
                        icon: Icon(Icons.support_agent_rounded, size: 18),
                        label: Text('Destek Al'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _showQRScannerHelp,
                        icon: Icon(Icons.qr_code_scanner_rounded, size: 18),
                        label: Text('QR Tarayıcı'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.info,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundPage() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.store_outlined,
                  size: 64,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'İşletme Bulunamadı',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aradığınız işletme bulunamadı veya artık aktif değil.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Misafir modu için opsiyonel giriş/kayıt butonları
        if (_isGuestMode) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.9),
                  AppColors.secondary.withOpacity(0.9)
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline_rounded,
                    color: AppColors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Misafir Modu',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                backgroundColor: AppColors.primary,
                heroTag: "login",
                child: const Icon(Icons.login_rounded,
                    color: AppColors.white, size: 18),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                backgroundColor: AppColors.secondary,
                heroTag: "register",
                child: const Icon(Icons.person_add_rounded,
                    color: AppColors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Ana aksiyonlar
        // Garson Çağır
        FloatingActionButton(
          onPressed: _handleWaiterCall,
          backgroundColor: AppColors.primary,
          heroTag: "waiter",
          child: const Icon(Icons.room_service_rounded, color: AppColors.white),
        ),
        const SizedBox(height: 12),
        // Sepet
        FloatingActionButton(
          onPressed: _handleCartAction,
          backgroundColor: AppColors.secondary,
          heroTag: "cart",
          child:
              const Icon(Icons.shopping_cart_rounded, color: AppColors.white),
        ),
      ],
    );
  }

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
