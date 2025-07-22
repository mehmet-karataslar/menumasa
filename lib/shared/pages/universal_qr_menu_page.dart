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

/// Evrensel QR Menü Sayfası - Tüm İşletmeler İçin Ortak
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _parseUrlAndLoadData();
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

  Future<void> _parseUrlAndLoadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // URL parametrelerini oku
      final params = _urlService.getCurrentParams();
      _businessId = params['business'];
      final tableParam = params['table'];
      
      if (tableParam != null) {
        _tableNumber = int.tryParse(tableParam);
      }

      print('🔍 Universal QR Menu - Business ID: $_businessId, Table: $_tableNumber');

      if (_businessId == null || _businessId!.isEmpty) {
        throw Exception('İşletme ID\'si bulunamadı');
      }

      // İşletme verilerini yükle
      await _loadBusinessData();
      
      // Animasyonları başlat
      _slideController.forward();
      _fadeController.forward();
      
    } catch (e) {
      print('❌ Universal QR Menu Error: $e');
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
      // İşletme bilgilerini al
      final business = await _businessService.getBusiness(_businessId!);
      if (business == null) {
        throw Exception('İşletme bulunamadı');
      }

      // Kategorileri al
      final categories = await _businessService.getCategories(businessId: _businessId!);
      
      // Ürünleri al
      final products = await _businessService.getProducts(businessId: _businessId!);
      final activeProducts = products.where((p) => p.isActive).toList();

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
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: _authService.currentUser != null ? 'Sepete Git' : 'Kayıt Ol',
              textColor: AppColors.white,
              onPressed: () {
                if (_authService.currentUser != null) {
                  Navigator.pushNamed(context, '/customer/cart', arguments: {
                    'businessId': _businessId,
                    'userId': _authService.currentUser?.uid,
                  });
                } else {
                  Navigator.pushNamed(context, '/register');
                }
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

  void _handleWaiterCall() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _showAuthDialog('Garson çağırmak için giriş yapmanız gerekir.');
      return;
    }
    
    // Garson çağırma işlemi
    _showWaiterCallDialog();
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
            sliver: SlideTransition(
              position: _slideAnimation,
              child: ProductGrid(
                products: _filteredProducts,
                onAddToCart: _addToCart,
                isQRMenu: true,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Menü yükleniyor...',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPage() {
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
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bir Sorun Oluştu',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Bilinmeyen hata',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _parseUrlAndLoadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tekrar Dene'),
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
    final currentUser = _authService.currentUser;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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