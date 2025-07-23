import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/url_service.dart';
import '../../business/services/business_firestore_service.dart';
import '../../business/models/business.dart';
import '../../business/models/product.dart';
import '../../business/models/category.dart';
import '../../customer/widgets/category_list.dart';
import '../../customer/widgets/product_grid.dart';
import '../../customer/widgets/business_header.dart';
import '../../customer/widgets/search_bar.dart' as custom_search;
import '../../customer/widgets/filter_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      print('🎭 Misafir modu aktif - Guest ID: $_guestUserId');
    } else {
      // Kullanıcı giriş yapmış
      setState(() {
        _isGuestMode = false;
        _guestUserId = null;
      });
      print('👤 Kayıtlı kullanıcı - ID: ${currentUser.uid}');
    }
  }

  Future<void> _parseUrlAndLoadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? businessId;
      int? tableNumber;
      
      print('🔍 UniversalQRMenuPage - URL parsing basliyor...');
      
      // Show debug info to user - POST FRAME
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔍 QR kod analiz ediliyor...'),
              duration: Duration(seconds: 2),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      });

      // 1. ÖNCE: Route arguments'tan kontrol et (en güvenilir)
      final routeSettings = ModalRoute.of(context)?.settings;
      final arguments = routeSettings?.arguments as Map<String, dynamic>?;
      
      if (arguments != null) {
        businessId = arguments['businessId']?.toString();
        if (arguments['tableNumber'] != null) {
          tableNumber = int.tryParse(arguments['tableNumber'].toString());
        }
        print('🔍 Arguments\'tan alindi - business: $businessId, table: $tableNumber');
        
        if (mounted && businessId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ QR kod başarıyla okundu'),
                  duration: Duration(seconds: 1),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          });
        }
      }
      
      // 2. URL Service'den dene (Mobil Browser destekli)
      if (businessId == null) {
        final urlParams = _urlService.getCurrentParams();
        businessId = urlParams['business'];
        if (urlParams['table'] != null) {
          tableNumber = int.tryParse(urlParams['table']!);
        }
        print('🔍 URL Service\'ten alindi - business: $businessId, table: $tableNumber');
      }
      
      // 3. Manuel URL parsing (Mobil Browser fallback)
      if (businessId == null) {
        try {
          final currentUrl = _urlService.getCurrentPath();
          final currentParams = _urlService.getCurrentParams();
          
          print('🔍 Manual parsing - URL: $currentUrl, Params: $currentParams');
          
          // Web browser URL'den manuel parsing
          if (currentUrl.contains('?')) {
            final parts = currentUrl.split('?');
            if (parts.length > 1) {
              final queryString = parts[1];
              final params = Uri.splitQueryString(queryString);
              businessId = params['business'];
              if (params['table'] != null) {
                tableNumber = int.tryParse(params['table']!);
              }
              print('🔍 Manuel parsing\'den alindi - business: $businessId, table: $tableNumber');
            }
          }
        } catch (e) {
          print('❌ Manuel URL parsing error: $e');
        }
      }
      
      // 4. Route name'den parsing (Eski formatlar için)
      if (businessId == null && routeSettings?.name != null) {
        try {
          final routeName = routeSettings!.name!;
          print('🔍 Route name parsing: $routeName');
          
          if (routeName.isNotEmpty && routeName != '/') {
            final uri = Uri.parse(routeName);
            final pathSegments = uri.pathSegments;
            
            // Eski format: /menu/businessId veya /qr-menu/businessId
            if (pathSegments.length >= 2 && 
                (pathSegments[0] == 'menu' || pathSegments[0] == 'qr-menu')) {
              businessId = pathSegments[1];
              print('🔍 Eski format\'tan alindi - business: $businessId');
            }
            
            // Query parametrelerini de kontrol et
            if (uri.queryParameters.isNotEmpty) {
              businessId = businessId ?? uri.queryParameters['business'];
              if (uri.queryParameters['table'] != null) {
                tableNumber = int.tryParse(uri.queryParameters['table']!);
              }
              print('🔍 Route query params\'tan alindi - business: $businessId, table: $tableNumber');
            }
          }
        } catch (e) {
          print('❌ Route name parsing error: $e');
        }
      }

      // 5. Validation
      if (businessId == null || businessId.isEmpty) {
        print('❌ Business ID validation failed - businessId: $businessId');
        print('❌ Arguments: $arguments');
        print('❌ Route name: ${routeSettings?.name}');
        print('❌ Current URL: ${_urlService.getCurrentPath()}');
        print('❌ Current params: ${_urlService.getCurrentParams()}');
        throw Exception('Isletme ID\'si bulunamadi. QR kodunuz gecerli degil.');
      }

      // Final assignment
      _businessId = businessId;
      _tableNumber = tableNumber;

      print('✅ Final - Business ID: $_businessId, Table: $_tableNumber');

      // İşletme verilerini yükle
      print('🔄 Starting _loadBusinessData...');
      await _loadBusinessData();
      print('✅ _loadBusinessData completed successfully');
      
      // Animasyonları başlat
      _slideController.forward();
      _fadeController.forward();
      
    } catch (e) {
      print('❌ Universal QR Menu Error: $e');
      print('❌ Stack trace in parseUrlAndLoadData: ${StackTrace.current}');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBusinessData() async {
    try {
      print('🔄 Loading business data for ID: $_businessId');
      
      // User feedback - POST FRAME
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 İşletme bilgileri yükleniyor...'),
              duration: Duration(seconds: 2),
              backgroundColor: AppColors.info,
            ),
          );
        }
      });
      
      // İşletme bilgilerini al - detaylı logging ile
      print('🔄 Calling BusinessFirestoreService.getBusiness($_businessId)');
      
      Business? business;
      try {
        business = await _businessService.getBusiness(_businessId!);
        print('🔄 BusinessFirestoreService.getBusiness response: ${business != null ? "SUCCESS" : "NULL"}');
        
        if (business != null) {
          print('✅ Business found - Name: ${business.businessName}, ID: ${business.id}, Active: ${business.isActive}');
        } else {
          print('❌ Business NULL - ID $_businessId not found in businesses collection');
          
          // Firebase connection test
          try {
            print('🔄 Testing Firebase connection...');
            final testQuery = await FirebaseFirestore.instance.collection('businesses').limit(1).get();
            print('✅ Firebase connection OK, businesses collection has ${testQuery.docs.length} docs');
            
            // Bu ID ile business var mı direkt kontrol et
            print('🔄 Direct Firestore check for ID: $_businessId');
            final directDoc = await FirebaseFirestore.instance.collection('businesses').doc(_businessId!).get();
            print('📄 Direct document exists: ${directDoc.exists}');
            if (directDoc.exists) {
              print('📄 Document data: ${directDoc.data()}');
            }
          } catch (e) {
            print('❌ Firebase connection error: $e');
          }
        }
        
        if (business == null) {
          // User-friendly error message - POST FRAME
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ İşletme bulunamadı (ID: $_businessId)'),
                  duration: Duration(seconds: 4),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          });
          
          throw Exception('İşletme bulunamadı - ID: $_businessId businesses collection\'ında mevcut değil');
        }
      } catch (e) {
        print('❌ BusinessFirestoreService.getBusiness error: $e');
        rethrow;
      }

      print('✅ Business found: ${business.businessName}');
      
      // Kategorileri al
      print('🔄 Loading categories...');
      final categories = await _businessService.getCategories(businessId: _businessId!);
      print('✅ Categories loaded: ${categories.length}');
      
      // Ürünleri al
      print('🔄 Loading products...');
      final products = await _businessService.getProducts(businessId: _businessId!);
      final activeProducts = products.where((p) => p.isActive).toList();
      print('✅ Products loaded: ${activeProducts.length} active out of ${products.length} total');

      setState(() {
        _business = business;
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
      
      print('✅ Business data loaded: ${business.businessName}');
      print('📊 Categories: ${categories.length}, Products: ${activeProducts.length}');
      
    } catch (e) {
      print('❌ Error in _loadBusinessData: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      throw Exception('Veriler yüklenirken hata: $e');
    }
  }

  void _updateUrl() {
    if (_business != null) {
      final title = _tableNumber != null 
          ? '${_business!.businessName} - Masa $_tableNumber | MasaMenu'
          : '${_business!.businessName} - Menü | MasaMenu';
      
      _urlService.updateUrl('/qr', 
        customTitle: title,
        params: {
          'business': _businessId!,
          if (_tableNumber != null) 'table': _tableNumber.toString(),
        }
      );
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
      filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  Future<void> _addToCart(Product product, {int quantity = 1}) async {
    if (_businessId == null) return;

    try {
      // Misafir modu için guest user ID kullan
      final userId = _isGuestMode ? _guestUserId : _authService.currentUser?.uid;
      
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
                  child: const Icon(Icons.check_rounded, color: AppColors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${product.productName} sepete eklendi'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            child: const Text('Giriş Yap', style: TextStyle(color: AppColors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Kayıt Ol', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _showWaiterCallDialog() {
    // Garson çağırma dialog implementasyonu
    // Gerektiğinde eklenebilir
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
        content: Text('Misafir modunda sepete erişim için giriş yapmanız gerekmektedir.'),
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
            child: const Text('Giriş Yap', style: TextStyle(color: AppColors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Kayıt Ol', style: TextStyle(color: AppColors.white)),
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
            const Text('Garson Çağırma İçin Giriş Yapın'),
          ],
        ),
        content: Text('Misafir modunda garson çağırma işlemi için giriş yapmanız gerekmektedir.'),
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
            child: const Text('Giriş Yap', style: TextStyle(color: AppColors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Kayıt Ol', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
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
                'Bir Hata Oluştu',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Bilinmeyen bir hata oluştu',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Debug Information Container
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Bilgileri:',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_businessId != null) ...[
                      Text(
                        '• İşletme ID: $_businessId',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '• İşletme ID: Bulunamadı ❌',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    if (_tableNumber != null) ...[
                      Text(
                        '• Masa Numarası: $_tableNumber',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    Text(
                      '• Mevcut URL: ${_urlService.getCurrentPath()}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '• URL Parametreleri: ${_urlService.getCurrentParams()}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isLoading = true;
                      });
                      _parseUrlAndLoadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Tekrar Dene'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Ana Sayfa'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                colors: [AppColors.primary.withOpacity(0.9), AppColors.secondary.withOpacity(0.9)],
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
                Icon(Icons.person_outline_rounded, color: AppColors.white, size: 16),
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
                child: const Icon(Icons.login_rounded, color: AppColors.white, size: 18),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                backgroundColor: AppColors.secondary,
                heroTag: "register",
                child: const Icon(Icons.person_add_rounded, color: AppColors.white, size: 18),
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
          child: const Icon(Icons.shopping_cart_rounded, color: AppColors.white),
        ),
      ],
    );
  }
} 