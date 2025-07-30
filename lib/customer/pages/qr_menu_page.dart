import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../business/models/business.dart';
import '../../business/models/category.dart';
import '../../business/models/product.dart';
import '../../business/models/staff.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/url_service.dart';
import '../../core/services/waiter_call_service.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/web_safe_image.dart';
import '../services/customer_firestore_service.dart';
import '../services/customer_service.dart';
import '../models/waiter_call.dart';
import 'customer_waiter_call_page.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';

/// Modern QR Menü Sayfası - Tamamen Yeni Tasarım
class QRMenuPage extends StatefulWidget {
  final String businessId;
  final String? userId;
  final String? qrCode;
  final int? tableNumber;

  const QRMenuPage({
    super.key,
    required this.businessId,
    this.userId,
    this.qrCode,
    this.tableNumber,
  });

  @override
  State<QRMenuPage> createState() => _QRMenuPageState();
}

class _QRMenuPageState extends State<QRMenuPage> with TickerProviderStateMixin {
  final CustomerFirestoreService _firestoreService = CustomerFirestoreService();
  final CustomerService _customerService = CustomerService();
  final UrlService _urlService = UrlService();
  final WaiterCallService _waiterCallService = WaiterCallService();

  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();

  // Data
  Business? _business;
  List<Category> _categories = [];
  List<Product> _products = [];

  int? _currentTableNumber;

  // State
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedCategoryId = 'all';
  String _searchQuery = '';
  bool _showSearch = false;

  // Animation
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBusinessData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _extractTableNumberFromQR();

      final business =
          await _firestoreService.getBusinessById(widget.businessId);
      if (business == null) {
        throw Exception('İşletme bulunamadı');
      }

      if (!business.isActive) {
        throw Exception('İşletme şu anda hizmet vermiyor');
      }

      final categories =
          await _firestoreService.getCategoriesByBusiness(widget.businessId);
      final products =
          await _firestoreService.getProductsByBusiness(widget.businessId);

      print(
          '🍽️ QRMenuPage: Loaded ${categories.length} categories and ${products.length} products');

      // Debug için kullanıcıya da göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QRMenuPage: ${products.length} ürün yüklendi'),
            duration: Duration(seconds: 2),
            backgroundColor:
                products.isEmpty ? AppColors.error : AppColors.success,
          ),
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dynamicRoute =
          '/qr-menu/${widget.businessId}?t=$timestamp&qr=${widget.qrCode ?? ''}';
      _urlService.updateUrl(dynamicRoute,
          customTitle: '${business.businessName} - QR Menü | MasaMenu');

      if (mounted) {
        setState(() {
          _business = business;
          _categories = categories;
          _products = products;

          _selectedCategoryId =
              _findFirstCategoryWithProducts(categories, products);
          _isLoading = false;
        });

        // Animasyonları başlat
        _fadeController.forward();
        await Future.delayed(const Duration(milliseconds: 300));
        _slideController.forward();

        await _logQRScanActivity();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _extractTableNumberFromQR() {
    if (widget.tableNumber != null) {
      _currentTableNumber = widget.tableNumber;
      return;
    }

    if (widget.qrCode != null) {
      try {
        final qrCode = widget.qrCode!;

        if (qrCode.contains('table_')) {
          final parts = qrCode.split('table_');
          if (parts.length > 1) {
            _currentTableNumber = int.tryParse(parts[1]);
          }
        } else if (qrCode.contains('table=')) {
          final uri = Uri.tryParse(qrCode);
          if (uri != null && uri.queryParameters.containsKey('table')) {
            _currentTableNumber = int.tryParse(uri.queryParameters['table']!);
          }
        }
      } catch (e) {
        print('Masa numarası çıkarılırken hata: $e');
      }
    }
  }

  String? _findFirstCategoryWithProducts(
      List<Category> categories, List<Product> products) {
    if (categories.isEmpty) return 'all';

    for (final category in categories) {
      final hasProducts = products.any((product) =>
          product.categoryId == category.id && product.isAvailable);
      if (hasProducts) {
        return category.id;
      }
    }

    return 'all';
  }

  Future<void> _logQRScanActivity() async {
    if (widget.userId != null && _business != null) {
      try {
        await _customerService.logActivity(
          action: 'qr_scan',
          details: 'QR kod tarandı: ${_business!.businessName}',
          metadata: {
            'business_id': widget.businessId,
            'table_number': _currentTableNumber,
            'qr_code': widget.qrCode,
          },
        );
      } catch (e) {
        print('QR tarama aktivitesi loglanamadı: $e');
      }
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    HapticFeedback.selectionClick();
  }

  List<Product> get _filteredProducts {
    List<Product> filtered;

    if (_selectedCategoryId == null || _selectedCategoryId == 'all') {
      filtered = _products.where((p) => p.isAvailable).toList();
    } else {
      filtered = _products
          .where((product) =>
              product.categoryId == _selectedCategoryId && product.isAvailable)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildMenuContent(),
      floatingActionButton: _buildFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.background,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 24),
            Text(
              'Menü Yükleniyor...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.error.withOpacity(0.05),
            AppColors.background,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_outlined,
                  size: 64,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Menü Yüklenemedi',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Bilinmeyen bir hata oluştu',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Geri'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.greyLight),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loadBusinessData,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tekrar Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget _buildMenuContent() {
    if (_business == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern Header
          _buildModernHeader(),

          // Search Bar
          if (_showSearch) _buildSearchSection(),

          // Categories
          if (_categories.isNotEmpty) _buildCategoriesSection(),

          // Products
          _buildProductsSection(),

          // Bottom Spacing
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchQuery = '';
            });
            HapticFeedback.lightImpact();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
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
          child: Stack(
            children: [
              // Pattern Background
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: WebSafeImage(
                    imageUrl:
                        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(),
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Business Logo
                      SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _business?.logoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: WebSafeImage(
                                    imageUrl: _business!.logoUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.restaurant_rounded,
                                  size: 50,
                                  color: AppColors.primary,
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Business Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _business!.businessName,
                            style: AppTypography.h2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                              shadows: [
                                Shadow(
                                  color: AppColors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _currentTableNumber != null
                                      ? 'Masa ${_currentTableNumber!}'
                                      : 'QR Menü',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
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
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Yemek veya içecek ara...',
                prefixIcon:
                    Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: Icon(Icons.clear_rounded,
                            color: AppColors.textSecondary),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: AppTypography.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 20),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryChip(
                  'Tümü',
                  'all',
                  _selectedCategoryId == 'all' || _selectedCategoryId == null,
                  Icons.restaurant_menu_rounded,
                );
              }

              final category = _categories[index - 1];
              final productCount = _products
                  .where((p) => p.categoryId == category.id && p.isAvailable)
                  .length;

              return _buildCategoryChip(
                category.name,
                category.id,
                _selectedCategoryId == category.id,
                _getCategoryIcon(category.name),
                productCount: productCount,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
      String name, String id, bool isSelected, IconData icon,
      {int? productCount}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: () => _onCategorySelected(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : AppColors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.black.withOpacity(0.05),
                blurRadius: isSelected ? 15 : 8,
                offset: Offset(0, isSelected ? 6 : 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.white : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              if (productCount != null && productCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.white.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    productCount.toString(),
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.white : AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            height: 300,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.greyLighter,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Arama sonucu bulunamadı'
                      : 'Bu kategoride ürün bulunmuyor',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Farklı kelimeler deneyin'
                      : 'Diğer kategorilere göz atın',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: AppColors.background,
          child: _buildProductGrid(),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildCompactProductCard(product, index);
      },
    );
  }

  Widget _buildCompactProductCard(Product product, int index) {
    final hasDiscount =
        product.currentPrice != null && product.currentPrice! < product.price;
    final discountPercentage = hasDiscount
        ? ((1 - (product.currentPrice! / product.price)) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (65% of height)
            Expanded(
              flex: 65,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: AppColors.greyLighter.withOpacity(0.3),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
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

                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-%$discountPercentage',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

            // Info Section (35% of height)
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name (single line)
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Price and Button Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Current Price
                              Text(
                                '${(product.currentPrice ?? product.price).toStringAsFixed(0)} ₺',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: hasDiscount
                                      ? AppColors.accent
                                      : AppColors.primary,
                                ),
                              ),

                              // Original Price (if discounted)
                              if (hasDiscount)
                                Text(
                                  '${product.price.toStringAsFixed(0)} ₺',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Add Button - Tüm kullanıcılar için
                        if (product.isAvailable)
                          GestureDetector(
                            onTap: () => _addToCart(product),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
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

  Widget _buildFloatingActionButtons() {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      // Giriş yapmamış kullanıcılar için sadece kayıt ol butonu
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/register');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Kayıt Ol'),
      );
    }

    // Giriş yapmış kullanıcılar için hem garson çağırma hem sepet butonu
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waiter Call Button
        FloatingActionButton(
          onPressed: _showWaiterCallDialog,
          backgroundColor: AppColors.primary,
          heroTag: "waiter_call",
          child: const Icon(Icons.room_service_rounded, color: AppColors.white),
        ),
        const SizedBox(height: 12),
        // Cart Button
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

  // Sepet sayfasına git - giriş yapmış kullanıcılar için
  void _handleCartAction() {
    final currentUser = _authService.currentUser;

    Navigator.pushNamed(
      context,
      '/customer/cart',
      arguments: {
        'businessId': widget.businessId,
        'userId': currentUser
            ?.uid, // null olabilir, sepet sayfasında kontrol edilecek
      },
    );
  }

  void _showWaiterCallDialog() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _showWaiterAuthDialog();
      return;
    }

    if (_business != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerWaiterCallPage(
            businessId: widget.businessId,
            customerId: currentUser.uid,
            customerName: currentUser.displayName ?? 'Müşteri',
            tableNumber: _currentTableNumber,
          ),
        ),
      );
    }
  }

  void _showWaiterAuthDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.room_service_rounded,
                  color: AppColors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Garson Çağırma',
                style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Garson çağırmak için hesabınıza giriş yapmanız gerekiyor.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bu sayede garsonu doğru masaya yönlendirebiliriz.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
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
            child: Text(
              'Vazgeç',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Giriş Yap'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/register');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Kayıt Ol'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(Product product, {int quantity = 1}) async {
    try {
      await _cartService.addToCart(product, widget.businessId,
          quantity: quantity);

      HapticFeedback.heavyImpact();

      if (mounted) {
        final currentUser = _authService.currentUser;

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
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: currentUser != null ? 'Sepete Git' : 'Kayıt Ol',
              textColor: AppColors.white,
              onPressed: () {
                if (currentUser != null) {
                  Navigator.pushNamed(context, '/customer/cart', arguments: {
                    'businessId': widget.businessId,
                    'userId': currentUser.uid,
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

  void _showProductDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductDetailSheet(product),
    );
  }

  Widget _buildProductDetailSheet(Product product) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  if (product.imageUrl != null)
                    Container(
                      height: 250,
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: WebSafeImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // Product Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: AppTypography.h4.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryLight
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${product.price.toStringAsFixed(2)} ₺',
                                style: AppTypography.h5.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Description
                        if (product.description.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.greyLighter,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Açıklama',
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  product.description,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // QR Menu Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.info.withOpacity(0.1),
                                AppColors.primary.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.info.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.qr_code_2_rounded,
                                      color: AppColors.info,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'QR Menü',
                                          style:
                                              AppTypography.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.info,
                                          ),
                                        ),
                                        Text(
                                          'Sepete eklemek veya garson çağırmak için kayıt olun',
                                          style:
                                              AppTypography.bodyMedium.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(
                                            context, '/register');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text('Kayıt Ol'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaiterCallSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.room_service_rounded,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Garson Çağır',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Masa ${_currentTableNumber ?? "?"}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Call Types
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              itemCount: WaiterCallType.values.length,
              itemBuilder: (context, index) {
                final callType = WaiterCallType.values[index];
                return _buildCallTypeCard(callType);
              },
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCallTypeCard(WaiterCallType callType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _makeWaiterCall(callType, null);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.greyLighter,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.greyLight.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCallTypeColor(callType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCallTypeIcon(callType),
                    color: _getCallTypeColor(callType),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        callType.displayName,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        callType.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DEPRECATED: Artık CustomerWaiterCallPage kullanılıyor
  Future<void> _makeWaiterCall(
      WaiterCallType callType, Staff? selectedWaiter) async {
    if (_currentTableNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masa numarası bulunamadı'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _waiterCallService.callWaiter(
        businessId: widget.businessId,
        customerId: widget.userId ??
            'qr_customer_${DateTime.now().millisecondsSinceEpoch}',
        customerName: 'QR Müşteri',
        tableNumber: _currentTableNumber!,
        requestType: callType,
        message: selectedWaiter != null
            ? '${selectedWaiter.firstName} ${selectedWaiter.lastName} için özel çağrı - QR menü üzerinden'
            : 'QR menü üzerinden çağrı',
        metadata: {
          'source': 'qr_menu',
          'qr_code': widget.qrCode,
          'selected_waiter_id': selectedWaiter?.staffId,
          'selected_waiter_name': selectedWaiter?.fullName,
          'table_number_from_qr': _currentTableNumber,
        },
      );

      Navigator.pop(context);
      _showSuccessDialog(callType, _currentTableNumber!, selectedWaiter);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Garson çağırırken hata: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog(
      WaiterCallType callType, int tableNumber, Staff? selectedWaiter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: AppColors.white,
            size: 32,
          ),
        ),
        title: Text(
          'Garson Çağrıldı!',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${callType.displayName} talebiniz için garson çağrıldı.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.table_restaurant_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Masa: $tableNumber',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('çorba') || name.contains('soup'))
      return Icons.soup_kitchen_rounded;
    if (name.contains('salata') || name.contains('salad'))
      return Icons.eco_rounded;
    if (name.contains('et') || name.contains('meat') || name.contains('kebap'))
      return Icons.outdoor_grill_rounded;
    if (name.contains('tavuk') || name.contains('chicken'))
      return Icons.restaurant_rounded;
    if (name.contains('balık') || name.contains('fish'))
      return Icons.set_meal_rounded;
    if (name.contains('pizza')) return Icons.local_pizza_rounded;
    if (name.contains('burger') || name.contains('hamburger'))
      return Icons.lunch_dining_rounded;
    if (name.contains('tatlı') || name.contains('dessert'))
      return Icons.cake_rounded;
    if (name.contains('içecek') ||
        name.contains('drink') ||
        name.contains('beverage')) return Icons.local_drink_rounded;
    if (name.contains('kahve') || name.contains('coffee'))
      return Icons.coffee_rounded;
    if (name.contains('çay') || name.contains('tea'))
      return Icons.emoji_food_beverage_rounded;
    if (name.contains('meze') || name.contains('appetizer'))
      return Icons.tapas_rounded;
    if (name.contains('makarna') || name.contains('pasta'))
      return Icons.ramen_dining_rounded;
    return Icons.restaurant_menu_rounded;
  }

  Color _getCallTypeColor(WaiterCallType callType) {
    switch (callType) {
      case WaiterCallType.service:
        return AppColors.primary;
      case WaiterCallType.order:
        return AppColors.success;
      case WaiterCallType.payment:
        return AppColors.secondary;
      case WaiterCallType.complaint:
        return AppColors.error;
      case WaiterCallType.assistance:
        return AppColors.info;
      case WaiterCallType.bill:
        return AppColors.warning;
      case WaiterCallType.help:
        return AppColors.primary;
      case WaiterCallType.cleaning:
        return AppColors.info;
      case WaiterCallType.emergency:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCallTypeIcon(WaiterCallType callType) {
    switch (callType) {
      case WaiterCallType.service:
        return Icons.room_service_rounded;
      case WaiterCallType.order:
        return Icons.restaurant_menu_rounded;
      case WaiterCallType.payment:
        return Icons.payment_rounded;
      case WaiterCallType.complaint:
        return Icons.report_problem_rounded;
      case WaiterCallType.assistance:
        return Icons.help_rounded;
      case WaiterCallType.bill:
        return Icons.receipt_long_rounded;
      case WaiterCallType.help:
        return Icons.help_rounded;
      case WaiterCallType.cleaning:
        return Icons.cleaning_services_rounded;
      case WaiterCallType.emergency:
        return Icons.emergency_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}

// Extensions
extension WaiterCallTypeExtension on WaiterCallType {
  String get displayName {
    switch (this) {
      case WaiterCallType.service:
        return 'Genel Hizmet';
      case WaiterCallType.order:
        return 'Sipariş Vermek';
      case WaiterCallType.payment:
        return 'Ödeme Yapmak';
      case WaiterCallType.complaint:
        return 'Şikayet/Sorun';
      case WaiterCallType.assistance:
        return 'Yardım İstemek';
      case WaiterCallType.bill:
        return 'Hesap İstemek';
      case WaiterCallType.help:
        return 'Genel Yardım';
      case WaiterCallType.cleaning:
        return 'Temizlik Talebi';
      case WaiterCallType.emergency:
        return 'Acil Durum';
    }
  }

  String get description {
    switch (this) {
      case WaiterCallType.service:
        return 'Genel hizmet ve yardım için';
      case WaiterCallType.order:
        return 'Yeni sipariş vermek için';
      case WaiterCallType.payment:
        return 'Hesabı ödemek için';
      case WaiterCallType.complaint:
        return 'Sorun bildirmek için';
      case WaiterCallType.assistance:
        return 'Özel yardım talebi için';
      case WaiterCallType.bill:
        return 'Hesabı getirmek için';
      case WaiterCallType.help:
        return 'Genel bilgi ve yardım için';
      case WaiterCallType.cleaning:
        return 'Masa temizliği için';
      case WaiterCallType.emergency:
        return 'Acil durum bildirimi için';
    }
  }
}
