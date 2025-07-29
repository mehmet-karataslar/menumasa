import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../business/models/business.dart';
import '../../../business/models/product.dart';
import '../../../business/models/category.dart';
import '../../../data/models/user.dart' as app_user;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/url_service.dart';
import '../../../core/services/data_service.dart';
import '../../services/customer_firestore_service.dart';
import '../../services/customer_service.dart';
import '../../../presentation/widgets/shared/empty_state.dart';
import '../menu_page.dart';
import '../business_detail_page.dart';
import '../search_page.dart';
import '../../../core/services/cart_service.dart';

/// Müşteri favoriler tab'ı - Performance Optimized
class CustomerFavoritesTab extends StatefulWidget {
  final String userId;
  final app_user.CustomerData? customerData;
  final VoidCallback onRefresh;
  final Function(int)? onNavigateToTab;

  const CustomerFavoritesTab({
    super.key,
    required this.userId,
    required this.customerData,
    required this.onRefresh,
    this.onNavigateToTab,
  });

  @override
  State<CustomerFavoritesTab> createState() => _CustomerFavoritesTabState();
}

class _CustomerFavoritesTabState extends State<CustomerFavoritesTab>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final CustomerFirestoreService _customerFirestoreService =
      CustomerFirestoreService();
  final UrlService _urlService = UrlService();
  final DataService _dataService = DataService();
  final CartService _cartService = CartService();

  late TabController _tabController;

  // Data caching
  List<Business> _favoriteBusinesses = [];
  List<Product> _favoriteProducts = [];
  List<app_user.ProductFavorite> _productFavorites = [];
  List<Business> _allBusinesses = [];
  List<Category> _allCategories = [];

  // Performance optimization
  bool _isLoading = false;
  bool _isDataCached = false;
  DateTime? _lastLoadTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _loadFavoritesOptimized();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only reload if cache is expired
      if (_shouldReloadData()) {
        _loadFavoritesOptimized();
      }
    }
  }

  bool _shouldReloadData() {
    if (_lastLoadTime == null) return true;
    return DateTime.now().difference(_lastLoadTime!) > _cacheValidDuration;
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  // Optimized parallel data loading
  Future<void> _loadFavoritesOptimized() async {
    if (_isLoading || (_isDataCached && !_shouldReloadData())) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Parallel data loading for better performance
      final results = await Future.wait([
        _loadBusinessFavoritesOptimized(user.uid),
        _loadProductFavoritesOptimized(user.uid),
        _loadAllBusinessesOptimized(),
        _loadAllCategoriesOptimized(),
      ]);

      final favoriteBusinessIds = results[0] as List<String>;
      final productFavorites = results[1] as List<app_user.ProductFavorite>;
      final allBusinesses = results[2] as List<Business>;
      final allCategories = results[3] as List<Category>;

      // Filter favorite businesses
      final favoriteBusinesses = allBusinesses
          .where((business) => favoriteBusinessIds.contains(business.id))
          .toList();

      // Extract favorite products from product favorites
      final favoriteProducts = <Product>[];
      for (final productFav in productFavorites) {
        final product = Product(
          productId: productFav.productId,
          name: productFav.productName ?? 'Unknown Product',
          price: productFav.productPrice?.toDouble() ?? 0.0,
          currentPrice: productFav.productPrice?.toDouble() ?? 0.0,
          currency: 'TL',
          images: productFav.productImage != null
              ? [
                  ProductImage(
                      url: productFav.productImage!,
                      isPrimary: true,
                      alt: 'Product Image')
                ]
              : [],
          businessId: productFav.businessId,
          categoryId: '', // Will be filled if needed
          description: '',
          detailedDescription: '',
          allergens: [],
          tags: [],
          isActive: true,
          isAvailable: true,
          sortOrder: 0,
          timeRules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        favoriteProducts.add(product);
      }

      if (mounted) {
        setState(() {
          _favoriteBusinesses = favoriteBusinesses;
          _favoriteProducts = favoriteProducts;
          _productFavorites = productFavorites;
          _allBusinesses = allBusinesses;
          _allCategories = allCategories;
          _isDataCached = true;
          _lastLoadTime = DateTime.now();
        });
      }
    } catch (e) {
      // Silent error handling for better UX
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Optimized business favorites loading
  Future<List<String>> _loadBusinessFavoritesOptimized(String userUid) async {
    try {
      // Try users collection first (most common case)
      final userDoc = await _customerFirestoreService.firestore
          .collection('users')
          .doc(userUid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final customerData = data['customerData'] as Map<String, dynamic>?;
        if (customerData != null) {
          return List<String>.from(customerData['favoriteBusinessIds'] ?? []);
        }
      }

      // Fallback to business_favorites collection
      final businessFavoritesQuery = await _customerFirestoreService.firestore
          .collection('business_favorites')
          .where('userId', isEqualTo: userUid)
          .get();

      return businessFavoritesQuery.docs
          .map((doc) => doc.data()['businessId'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Optimized product favorites loading
  Future<List<app_user.ProductFavorite>> _loadProductFavoritesOptimized(
      String userUid) async {
    try {
      final favoritesSnapshot = await _customerFirestoreService.firestore
          .collection('product_favorites')
          .where('customerId', isEqualTo: userUid)
          .orderBy('createdAt', descending: true)
          .get();

      return favoritesSnapshot.docs.map((doc) {
        final data = doc.data();
        return app_user.ProductFavorite(
          id: doc.id,
          productId: data['productId'] ?? '',
          businessId: data['businessId'] ?? '',
          customerId: userUid,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          productName: data['productName'],
          productPrice: data['productPrice']?.toDouble(),
          productImage: data['productImage'],
          businessName: data['businessName'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Optimized businesses loading with caching
  Future<List<Business>> _loadAllBusinessesOptimized() async {
    try {
      final businessesSnapshot = await _customerFirestoreService.firestore
          .collection('businesses')
          .where('isActive', isEqualTo: true)
          .get();

      return businessesSnapshot.docs.map((doc) {
        final data = doc.data();
        return Business.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Optimized categories loading with caching
  Future<List<Category>> _loadAllCategoriesOptimized() async {
    try {
      final categoriesSnapshot = await _customerFirestoreService.firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      return categoriesSnapshot.docs.map((doc) {
        final data = doc.data();
        return Category.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      return [];
    }
  }

  List<Business> get _filteredFavoriteBusinesses {
    if (_searchQuery.isEmpty) {
      return _favoriteBusinesses;
    }

    return _favoriteBusinesses.where((business) {
      final query = _searchQuery.toLowerCase();
      return business.businessName.toLowerCase().contains(query) ||
          business.businessType.toLowerCase().contains(query) ||
          business.businessAddress.toLowerCase().contains(query);
    }).toList();
  }

  List<Product> get _filteredFavoriteProducts {
    if (_searchQuery.isEmpty) {
      return _favoriteProducts;
    }

    return _favoriteProducts.where((product) {
      final query = _searchQuery.toLowerCase();
      return product.name.toLowerCase().contains(query) ||
          (product.description?.toLowerCase().contains(query) ?? false) ||
          (_getCategoryName(product.categoryId)
                  ?.toLowerCase()
                  .contains(query) ??
              false);
    }).toList();
  }

  String? _getCategoryName(String categoryId) {
    try {
      final category =
          _allCategories.firstWhere((c) => c.categoryId == categoryId);
      return category.name;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return; // Mounted kontrolü ekle

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the optimized parallel loading method
      await _loadFavoritesOptimized();
    } catch (e) {
      // Silent error handling for better UX
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadFavorites();
    widget.onRefresh();
  }

  /// External refresh tetikleyici
  void refreshFavorites() {
    if (mounted) {
      _loadFavorites();
    }
  }

  Future<void> _toggleBusinessFavorite(Business business) async {
    try {
      // Firebase Auth'dan current user'ı al
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Giriş yapılması gerekli');
      }

      // Önce mevcut favori durumunu kontrol et
      final isFavorite = _favoriteBusinesses.any((b) => b.id == business.id);

      // Önce users collection'ından kontrol et (customer kullanıcılar için)
      final userDocRef =
          _customerFirestoreService.firestore.collection('users').doc(user.uid);

      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        // users collection'ında bulundu (customer user) - mevcut sistemi kullan
        final userData = userDoc.data()!;
        final customerData =
            Map<String, dynamic>.from(userData['customerData'] ?? {});
        final currentFavorites =
            List<String>.from(customerData['favoriteBusinessIds'] ?? []);

        List<String> updatedFavorites;
        if (isFavorite) {
          updatedFavorites =
              currentFavorites.where((id) => id != business.id).toList();
        } else {
          updatedFavorites = [...currentFavorites, business.id];
        }

        customerData['favoriteBusinessIds'] = updatedFavorites;
        await userDocRef.update({
          'customerData': customerData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Business kullanıcı - business_favorites collection'ını kullan
        if (isFavorite) {
          // Favorilerden çıkar
          final existingFavoriteQuery = await _customerFirestoreService
              .firestore
              .collection('business_favorites')
              .where('userId', isEqualTo: user.uid)
              .where('businessId', isEqualTo: business.id)
              .get();

          for (final doc in existingFavoriteQuery.docs) {
            await doc.reference.delete();
          }
        } else {
          // Favorilere ekle
          await _customerFirestoreService.firestore
              .collection('business_favorites')
              .add({
            'userId': user.uid,
            'businessId': business.id,
            'businessName': business.businessName,
            'addedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Local state'i güncelle
      if (isFavorite) {
        setState(() {
          _favoriteBusinesses.removeWhere((b) => b.id == business.id);
        });
      } else {
        setState(() {
          _favoriteBusinesses.add(business);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isFavorite
                      ? Icons.favorite_border_rounded
                      : Icons.favorite_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isFavorite
                        ? '${business.businessName} favorilerden çıkarıldı'
                        : '${business.businessName} favorilere eklendi',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: isFavorite ? AppColors.warning : AppColors.success,
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
                Expanded(child: Text('Hata: $e')),
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

  Future<void> _toggleProductFavorite(Product product) async {
    try {
      // Firebase Auth'dan current user'ı al
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Giriş yapılması gerekli');
      }

      // Önce mevcut favori durumunu kontrol et
      final isFavorite =
          _favoriteProducts.any((p) => p.productId == product.productId);

      if (isFavorite) {
        // Ürünü favorilerden çıkar - product_favorites collection'ından sil
        final favoriteToRemove = _productFavorites.firstWhere(
          (f) => f.productId == product.productId,
          orElse: () => throw Exception('Favori bulunamadı'),
        );

        // Firebase'den sil
        final favoritesQuery = await _customerFirestoreService.firestore
            .collection('product_favorites')
            .where('customerId', isEqualTo: user.uid)
            .where('productId', isEqualTo: product.productId)
            .get();

        for (final doc in favoritesQuery.docs) {
          await doc.reference.delete();
        }

        // Local state'i güncelle
        setState(() {
          _favoriteProducts
              .removeWhere((p) => p.productId == product.productId);
          _productFavorites
              .removeWhere((f) => f.productId == product.productId);
        });
      } else {
        // Ürünü favorilere ekle
        final business =
            _allBusinesses.where((b) => b.id == product.businessId).firstOrNull;
        final businessName = business?.businessName ?? 'Bilinmeyen İşletme';

        final newFavorite = app_user.ProductFavorite(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: product.productId,
          businessId: product.businessId,
          customerId: user.uid, // Firebase Auth UID kullan
          createdAt: DateTime.now(),
          productName: product.name,
          productPrice: product.price,
          productImage: product.imageUrl,
          businessName: businessName,
        );

        // Firebase'e ekle
        await _customerFirestoreService.firestore
            .collection('product_favorites')
            .add(newFavorite.toJson());

        // Local state'i güncelle
        setState(() {
          _favoriteProducts.add(product);
          _productFavorites.add(newFavorite);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isFavorite
                      ? Icons.favorite_border_rounded
                      : Icons.favorite_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isFavorite
                        ? '${product.name} favorilerden çıkarıldı'
                        : '${product.name} favorilere eklendi',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: isFavorite ? AppColors.warning : AppColors.success,
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
                Expanded(child: Text('Hata: $e')),
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

  Future<void> _reorderProduct(Product product) async {
    try {
      // CartService kullanarak direkt sepete ekle
      await _cartService.initialize();
      await _cartService.addToCart(
        product,
        product.businessId,
        quantity: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${product.productName} sepete eklendi!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
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
                Expanded(child: Text('Sipariş hatası: $e')),
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

  /// Ürünü sepete ekle
  Future<void> _addToCart(Product product) async {
    try {
      // İşletme adını al (varsa)
      final business =
          _allBusinesses.where((b) => b.id == product.businessId).firstOrNull;
      final businessName = business?.businessName ?? 'Bilinmeyen İşletme';

      // CartService'i initialize et
      await _cartService.initialize();

      // CartService kullanarak sepete ekle
      await _cartService.addToCart(
        product,
        product.businessId,
        quantity: 1,
      );

      // Sepet sayısını kontrol et
      final cartCount = await _cartService.getCartItemCount(product.businessId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${product.productName} sepete eklendi!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Sepete Git',
              textColor: AppColors.white,
              onPressed: () {
                // Sepet sekmesine geç
                widget.onNavigateToTab?.call(3); // Sepet sekmesi index 3
              },
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
                const Icon(Icons.error_rounded, color: AppColors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Sepete ekleme hatası: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _navigateToMenu(Business business) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute =
        '/customer/${widget.userId}/menu/${business.id}?t=$timestamp&ref=favorites';
    _urlService.updateMenuUrl(business.id, businessName: business.businessName);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuPage(businessId: business.id),
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'businessId': business.id,
            'business': business,
            'userId': widget.userId,
            'timestamp': timestamp,
            'referrer': 'favorites',
            'businessName': business.businessName,
          },
        ),
      ),
    );
  }

  void _navigateToBusinessDetail(Business business) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dynamicRoute =
        '/customer/${widget.userId}/business/${business.id}?t=$timestamp&ref=favorites';
    _urlService.updateUrl(dynamicRoute,
        customTitle: '${business.businessName} | MasaMenu');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessDetailPage(
          business: business,
          customerData: widget.customerData,
        ),
        settings: RouteSettings(
          name: dynamicRoute,
          arguments: {
            'business': business,
            'customerData': widget.customerData,
            'userId': widget.userId,
            'timestamp': timestamp,
            'referrer': 'favorites',
            'businessName': business.businessName,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTypography.bodyMedium,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('İşletmeler'),
                    if (_favoriteBusinesses.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_favoriteBusinesses.length}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fastfood_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('Ürünler'),
                    if (_favoriteProducts.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_favoriteProducts.length}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Arama alanı
        if (_favoriteBusinesses.isNotEmpty || _favoriteProducts.isNotEmpty)
          _buildSearchSection(),

        // Tab view
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // İşletmeler tab'ı
              _buildBusinessesTab(),
              // Ürünler tab'ı
              _buildProductsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteBusinessCard(Business business) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _navigateToMenu(business);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // İşletme resmi
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                      ),
                      child: business.logoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                business.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.business_rounded,
                                  color: AppColors.white,
                                  size: 32,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.business_rounded,
                              color: AppColors.white,
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: 16),
                    // İşletme bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  business.businessName,
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              // Durum göstergesi
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: business.isOpen
                                      ? AppColors.success
                                      : AppColors.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  business.isOpen ? 'Açık' : 'Kapalı',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              business.businessType,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  business.businessAddress,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Favori butonu
                    GestureDetector(
                      onTap: () => _toggleBusinessFavorite(business),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _favoriteBusinesses.any((b) => b.id == business.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Eylem butonları
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToBusinessDetail(business),
                        icon: Icon(Icons.info_outline_rounded, size: 18),
                        label: Text('Detaylar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToMenu(business),
                        icon: Icon(Icons.restaurant_menu_rounded, size: 18),
                        label: Text('Menü'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Widget _buildFavoriteProductCard(Product product) {
    // Favori ürünün işletme bilgisini al
    final productFavorite = _productFavorites.firstWhere(
      (f) => f.productId == product.productId,
      orElse: () {
        // Firebase Auth UID'sini kullan
        final user = FirebaseAuth.instance.currentUser;
        return app_user.ProductFavorite(
          id: '',
          productId: product.productId,
          businessId: product.businessId,
          customerId: user?.uid ?? '', // Firebase Auth UID kullan
          createdAt: DateTime.now(),
          productName: null,
          productPrice: null,
          productImage: null,
          businessName: null,
        );
      },
    );

    final businessName = productFavorite.businessName ??
        _allBusinesses
            .firstWhere(
              (b) => b.id == product.businessId,
              orElse: () => Business.empty(),
            )
            .businessName;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // İşletme bilgisini product'tan al ve menüye git
            final business = _allBusinesses.firstWhere(
              (b) => b.id == product.businessId,
              orElse: () => Business.empty(),
            );
            if (business.id.isNotEmpty) {
              _navigateToMenu(business);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Ürün resmi
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                      ),
                      child: product.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.fastfood_rounded,
                                  color: AppColors.white,
                                  size: 32,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.fastfood_rounded,
                              color: AppColors.white,
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Ürün bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // İşletme adı - direkt görünür
                          if (businessName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.business_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      businessName,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _getCategoryName(product.categoryId) ??
                                'Kategori Belirtilmemiş',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${product.price} TL',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Favori butonu
                    GestureDetector(
                      onTap: () => _toggleProductFavorite(product),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Eylem butonları
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final business = _allBusinesses.firstWhere(
                            (b) => b.id == product.businessId,
                            orElse: () => Business.empty(),
                          );
                          if (business.id.isNotEmpty) {
                            _navigateToBusinessDetail(business);
                          }
                        },
                        icon: Icon(Icons.info_outline_rounded, size: 18),
                        label: Text('İşletme Detayı'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _addToCart(product),
                        icon: Icon(Icons.shopping_cart_rounded, size: 18),
                        label: Text('Sepete Ekle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => _navigateToSearch(),
                icon: const Icon(Icons.search_rounded),
                label: const Text('İşletme Ara'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _navigateToExplore(),
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Keşfet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ARAMA VE FİLTRE BÖLÜMÜ
  // ============================================================================

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık ve sayı
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                color: AppColors.accent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Favori İşletmelerim',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_favoriteBusinesses.length}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Arama çubuğu
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Favori işletmeler arasında ara...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Arama sonucu sayısı
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_filteredFavoriteBusinesses.length} sonuç bulundu',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // TAB BUILDING METHODS
  // ============================================================================

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Favoriler arasında ara...',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessesTab() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteBusinesses.isEmpty
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildEmptyStateCard(
                      icon: Icons.business_rounded,
                      title: 'Henüz favori işletmeniz yok',
                      subtitle:
                          'Beğendiğiniz işletmeleri favorilerinize ekleyin',
                    ),
                  ),
                )
              : _filteredFavoriteBusinesses.isEmpty
                  ? SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildEmptyStateCard(
                          icon: Icons.search_off_rounded,
                          title: 'Arama sonucu bulunamadı',
                          subtitle: 'Farklı kelimeler ile tekrar deneyin',
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredFavoriteBusinesses.length,
                      itemBuilder: (context, index) {
                        final business = _filteredFavoriteBusinesses[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: _buildFavoriteBusinessCard(business),
                        );
                      },
                    ),
    );
  }

  Widget _buildProductsTab() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.accent,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteProducts.isEmpty
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildEmptyStateCard(
                      icon: Icons.fastfood_rounded,
                      title: 'Henüz favori ürününüz yok',
                      subtitle: 'Beğendiğiniz ürünleri favorilerinize ekleyin',
                    ),
                  ),
                )
              : _filteredFavoriteProducts.isEmpty
                  ? SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildEmptyStateCard(
                          icon: Icons.search_off_rounded,
                          title: 'Arama sonucu bulunamadı',
                          subtitle: 'Farklı kelimeler ile tekrar deneyin',
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredFavoriteProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredFavoriteProducts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: _buildFavoriteProductCard(product),
                        );
                      },
                    ),
    );
  }

  // ============================================================================
  // NAVIGATION METODLARI
  // ============================================================================

  void _navigateToSearch() {
    // Arama sayfasına yönlendir
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _urlService.updateCustomerUrl(widget.userId, 'search',
        customTitle: 'İşletme Ara | MasaMenu');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(
          businesses: _allBusinesses,
          categories: _allCategories, // Kategorileri de yüklemek gerekecek
        ),
        settings: RouteSettings(
          name: '/customer/${widget.userId}/search?t=$timestamp',
          arguments: {
            'userId': widget.userId,
            'timestamp': timestamp,
            'referrer': 'favorites',
          },
        ),
      ),
    );
  }

  void _navigateToExplore() {
    // Ana sayfa/dashboard'a yönlendir (keşfet için)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _urlService.updateCustomerUrl(widget.userId, 'dashboard',
        customTitle: 'Ana Sayfa | MasaMenu');

    // Ana tab'a geç
    widget.onNavigateToTab?.call(0);
  }
}
