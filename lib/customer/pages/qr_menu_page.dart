import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../business/models/business.dart';
import '../../business/models/category.dart';
import '../../business/models/product.dart';
import '../../business/models/waiter.dart';
import '../../business/services/waiter_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/url_service.dart';
import '../../core/services/waiter_call_service.dart';
import '../services/customer_firestore_service.dart';
import '../services/customer_service.dart';
import '../models/waiter_call.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../widgets/business_header.dart';
import '../widgets/category_list.dart';
import '../widgets/product_grid.dart';

/// Ortak QR Menü Sayfası - Tüm işletmeler için
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

class _QRMenuPageState extends State<QRMenuPage>
    with TickerProviderStateMixin {
  final CustomerFirestoreService _firestoreService = CustomerFirestoreService();
  final CustomerService _customerService = CustomerService();
  final UrlService _urlService = UrlService();
  final WaiterCallService _waiterCallService = WaiterCallService();
  final WaiterService _waiterService = WaiterService();
  
  // Data variables
  Business? _business;
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Waiter> _waiters = [];
  String? _selectedCategoryId;
  int? _currentTableNumber;
  
  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  
  // Animation controllers
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _extractTableNumberFromQR() {
    if (widget.tableNumber != null) {
      _currentTableNumber = widget.tableNumber;
      return;
    }

    if (widget.qrCode != null) {
      try {
        final qrCode = widget.qrCode!;
        
        // QR kod formatları:
        // 1. "masamenu_{businessId}_table_{tableNumber}"
        // 2. URL formatı: "https://menumebak.web.app/menu/{businessId}?table={tableNumber}"
        
        if (qrCode.contains('table_')) {
          final parts = qrCode.split('_');
          final tableIndex = parts.indexOf('table');
          if (tableIndex >= 0 && tableIndex + 1 < parts.length) {
            _currentTableNumber = int.tryParse(parts[tableIndex + 1]);
          }
        } else if (qrCode.contains('table=')) {
          final uri = Uri.tryParse(qrCode);
          if (uri != null && uri.queryParameters.containsKey('table')) {
            _currentTableNumber = int.tryParse(uri.queryParameters['table']!);
          }
        }
      } catch (e) {
        print('QR kodundan masa numarası çıkarılırken hata: $e');
      }
    }
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

      // QR kodundan masa numarasını çıkar
      _extractTableNumberFromQR();

      // İşletme bilgilerini yükle
      final business = await _firestoreService.getBusinessById(widget.businessId);
      if (business == null) {
        throw Exception('İşletme bulunamadı');
      }

      // İşletmenin aktif olup olmadığını kontrol et
      if (!business.isActive) {
        throw Exception('İşletme şu anda hizmet vermiyor');
      }

      // Kategorileri yükle
      final categories = await _firestoreService.getCategoriesByBusiness(widget.businessId);
      
      // Ürünleri yükle
      print('🔄 Ürünler yükleniyor: ${widget.businessId}');
      final products = await _firestoreService.getProductsByBusiness(widget.businessId);
      print('✅ Ürün yükleme tamamlandı: ${products.length} ürün');

      // Garsonları yükle
      final waiters = await _waiterService.getWaitersByBusiness(widget.businessId);

      // URL'yi güncelle
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dynamicRoute = '/qr-menu/${widget.businessId}?t=$timestamp&qr=${widget.qrCode ?? ''}';
      _urlService.updateUrl(
        dynamicRoute,
        customTitle: '${business.businessName} - QR Menü | MasaMenu',
      );

      setState(() {
        _business = business;
        _categories = categories;
        _products = products;
        _waiters = waiters;
        // Mevcut ürünlere sahip ilk kategoriyi seç
        _selectedCategoryId = _findFirstCategoryWithProducts(categories, products);
        _isLoading = false;
      });

      // Debug bilgileri
      print('🍽️ İşletme yüklendi: ${business.businessName}');
      print('📂 Kategori sayısı: ${categories.length}');
      print('🥘 Toplam ürün sayısı: ${products.length}');
      print('🥘 Mevcut ürün sayısı: ${products.where((p) => p.isAvailable).length}');
      print('🎯 Seçili kategori ID: $_selectedCategoryId');
      print('🔍 Filtrelenmiş ürün sayısı: ${_filteredProducts.length}');
      if (categories.isNotEmpty) {
        print('📂 Kategoriler: ${categories.map((c) => '${c.name} (${c.id})').join(', ')}');
      }
      if (products.isNotEmpty) {
        print('🥘 İlk 3 ürün: ${products.take(3).map((p) => '${p.name} - Kategori: ${p.categoryId} - Mevcut: ${p.isAvailable}').join(' | ')}');
      }

      // Animasyonları başlat
      _fadeController.forward();
      _slideController.forward();

      // QR tarama aktivitesini logla
      await _logQRScanActivity();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _logQRScanActivity() async {
    if (widget.userId != null && _business != null) {
      try {
        // QR tarama aktivitesini logla
        await _customerService.logActivity(
          action: 'qr_scan',
          details: 'QR kod tarandi: ${_business!.businessName}',
          metadata: {
            'business_id': widget.businessId,
            'business_name': _business!.businessName,
            'qr_code': widget.qrCode ?? '',
            'scan_timestamp': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        print('QR scan activity log hatası: $e');
      }
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    
    // Hafif titreşim
    HapticFeedback.selectionClick();
  }

  List<Product> get _filteredProducts {
    if (_selectedCategoryId == null) return _products.where((p) => p.isAvailable).toList();
    return _products.where((product) => 
      product.categoryId == _selectedCategoryId && product.isAvailable
    ).toList();
  }

  String? _findFirstCategoryWithProducts(List<Category> categories, List<Product> products) {
    if (categories.isEmpty) return null;
    
    // Her kategori için mevcut ürün sayısını kontrol et
    for (final category in categories) {
      final hasProducts = products.any((product) => 
        product.categoryId == category.id && product.isAvailable
      );
      if (hasProducts) {
        print('🎯 Mevcut ürünlere sahip kategori bulundu: ${category.name} (${category.id})');
        return category.id;
      }
    }
    
    // Hiçbir kategoride mevcut ürün yoksa ilk kategoriyi döndür
    print('⚠️ Hiçbir kategoride mevcut ürün yok, ilk kategori seçildi');
    return categories.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildMenuContent(),
      floatingActionButton: _buildWaiterCallButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
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
              _errorMessage!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Geri Dön'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.greyLight),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadBusinessData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          slivers: [
            // Business Header (sadece işletme bilgileri)
            SliverToBoxAdapter(
              child: BusinessHeader(
                business: _business!,
                isCompact: false,
                cartItemCount: 0,
                showActions: false, // QR menüde action butonları gizle
              ),
            ),
            
            // QR Menu özel action bar
            SliverToBoxAdapter(
              child: _buildQRMenuActionBar(),
            ),
            
            // Kategori Listesi
            if (_categories.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: CategoryList(
                    categories: _categories,
                    selectedCategoryId: _selectedCategoryId,
                    onCategorySelected: _onCategorySelected,
                  ),
                ),
              ),
            ],
            
            // Ürün Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildProductSection(),
              ),
            ),
            
            // Alt boşluk
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    if (_filteredProducts.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Bu kategoride ürün bulunmuyor',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diğer kategorilere göz atın',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              _selectedCategoryId != null
                  ? _categories.firstWhere((c) => c.id == _selectedCategoryId).name
                  : 'Tüm Ürünler',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_filteredProducts.length} ürün',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
                  ],
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ProductGrid(
          products: _filteredProducts,
          onProductTap: _handleProductTap,
          isQRMenu: true, // QR menü modu
        ),
      ),
    ],
  );
  }

  Widget _buildQRMenuActionBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.qr_code_rounded, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Menü',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                      Text(
                        _currentTableNumber != null 
                            ? 'Masa ${_currentTableNumber!} - Sipariş için garson çağırın'
                            : 'Sipariş için garson çağırın veya mobil uygulamayı indirin',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleShare(),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Paylaş'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleCall(_business!.contactInfo.phone ?? ''),
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: const Text('Ara'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleLocation(_business!.businessAddress),
                  icon: const Icon(Icons.location_on_rounded, size: 18),
                  label: const Text('Konum'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Event handlers
  void _handleProductTap(Product product) {
    // QR menüde ürün detaylarını göster (sepet yok)
    _showProductDetails(product);
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
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Product image
          if (product.imageUrl != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(product.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Product info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.price.toStringAsFixed(2)} ₺',
                    style: AppTypography.h6.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Açıklama',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // QR menü info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.info.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sipariş vermek için garson çağırın veya mobil uygulamayı indirin',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleShare() {
    // QR menü paylaşma
    HapticFeedback.mediumImpact();
    // Share implementation
  }

  void _handleCall(String phone) {
    // İşletmeyi arama
    HapticFeedback.mediumImpact();
    // Call implementation
  }

  void _handleLocation(String address) {
    // Harita açma
    HapticFeedback.mediumImpact();
    // Location implementation
  }

  // ============================================================================
  // WAITER CALL METHODS
  // ============================================================================

  Widget _buildWaiterCallButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showWaiterCallDialog,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Icon(
              Icons.room_service_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  void _showWaiterCallDialog() {
    if (_currentTableNumber == null) {
      _showTableNumberDialog();
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWaiterListSheet(),
    );
  }

  void _showTableNumberDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.table_restaurant_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Masa Numarası'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QR kodunuzda masa numarası bulunamadı. Lütfen masa numaranızı manuel olarak girin.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Masa Numarası',
                hintText: 'Örn: 15',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.table_restaurant_rounded),
              ),
              autofocus: true,
              onChanged: (value) {
                _currentTableNumber = int.tryParse(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentTableNumber != null) {
                Navigator.pop(context);
                _showWaiterCallDialog();
              }
            },
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  Widget _buildWaiterListSheet() {
    final availableWaiters = _waiters.where((w) => w.isAvailable && w.isActive).toList();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.room_service_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Garson Seçin',
                            style: AppTypography.h5.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Masa ${_currentTableNumber ?? "?"}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                
                // Quick action buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _callDefaultWaiter(),
                        icon: const Icon(Icons.flash_on_rounded),
                        label: const Text('Hızlı Çağır'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCallTypeDialog(),
                        icon: const Icon(Icons.more_horiz_rounded),
                        label: const Text('Özel Talep'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Waiters list
          Expanded(
            child: availableWaiters.isEmpty 
                ? _buildNoWaitersAvailable()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: availableWaiters.length,
                    itemBuilder: (context, index) {
                      final waiter = availableWaiters[index];
                      return _buildWaiterCard(waiter);
                    },
                  ),
          ),
          
          // All waiters section
          if (_waiters.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.greyLight),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tüm Garsonlar',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _waiters.length,
                      itemBuilder: (context, index) {
                        final waiter = _waiters[index];
                        return _buildWaiterAvatar(waiter);
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaiterCard(Waiter waiter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _callSpecificWaiter(waiter),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.greyLighter,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: Row(
              children: [
                // Waiter avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    image: waiter.profileImageUrl != null 
                        ? DecorationImage(
                            image: NetworkImage(waiter.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: waiter.profileImageUrl == null
                      ? Center(
                          child: Text(
                            waiter.initials,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                
                const SizedBox(width: 16),
                
                // Waiter info
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(int.parse('0xFF${waiter.rankColor.substring(1)}')).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              waiter.rank.displayName,
                              style: AppTypography.caption.copyWith(
                                color: Color(int.parse('0xFF${waiter.rankColor.substring(1)}')),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: waiter.isAvailable ? AppColors.success : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            waiter.isAvailable ? 'Müsait' : 'Meşgul',
                            style: AppTypography.caption.copyWith(
                              color: waiter.isAvailable ? AppColors.success : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Call button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: waiter.isAvailable ? AppColors.primary : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.call_rounded,
                    color: waiter.isAvailable ? AppColors.white : AppColors.textSecondary,
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

  Widget _buildWaiterAvatar(Waiter waiter) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _callSpecificWaiter(waiter),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: waiter.isAvailable ? AppColors.success : AppColors.greyLight,
                  width: 2,
                ),
                image: waiter.profileImageUrl != null 
                    ? DecorationImage(
                        image: NetworkImage(waiter.profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: waiter.profileImageUrl == null
                  ? Center(
                      child: Text(
                        waiter.initials,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              waiter.firstName,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWaitersAvailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 64,
              color: AppColors.greyLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Şu Anda Müsait Garson Yok',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tüm garsonlar meşgul. Hızlı çağır butonunu kullanarak ilk müsait olan garsonu çağırabilirsiniz.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _callDefaultWaiter(),
              icon: const Icon(Icons.flash_on_rounded),
              label: const Text('Hızlı Çağır'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _callDefaultWaiter() {
    Navigator.pop(context);
    _makeWaiterCall(WaiterCallType.service, null);
  }

  void _callSpecificWaiter(Waiter waiter) {
    if (!waiter.isAvailable) {
      _showWaiterNotAvailableDialog(waiter);
      return;
    }
    
    Navigator.pop(context);
    _makeWaiterCall(WaiterCallType.service, waiter);
  }

  void _showWaiterNotAvailableDialog(Waiter waiter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.schedule_rounded,
          color: AppColors.warning,
          size: 48,
        ),
        title: const Text('Garson Müsait Değil'),
        content: Text(
          '${waiter.fullName} şu anda meşgul. Başka bir garson seçebilir veya hızlı çağır ile ilk müsait olan garsonu çağırabilirsiniz.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _callDefaultWaiter();
            },
            child: const Text('Hızlı Çağır'),
          ),
        ],
      ),
    );
  }

  void _showCallTypeDialog() {
    Navigator.pop(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWaiterCallSheet(),
    );
  }

  Widget _buildWaiterCallSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.room_service_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Özel Talep Seçin',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Masa ${_currentTableNumber ?? "?"}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          
          // Call types
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: WaiterCallType.values.length,
              itemBuilder: (context, index) {
                final callType = WaiterCallType.values[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => {
                        Navigator.pop(context),
                        _makeWaiterCall(callType, null)
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.greyLighter,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.greyLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getCallTypeColor(callType).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getCallTypeIcon(callType),
                                color: _getCallTypeColor(callType),
                                size: 20,
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
                                  Text(
                                    callType.description,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Note
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'QR menüde sepet yok. Sipariş vermek için garson çağırın veya mobil uygulamayı indirin.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makeWaiterCall(WaiterCallType callType, Waiter? selectedWaiter) async {
    if (_currentTableNumber == null) return;
    
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LoadingIndicator(),
      );
      
      final callId = await _waiterCallService.callWaiter(
        businessId: widget.businessId,
        customerId: widget.userId ?? 'qr_customer_${DateTime.now().millisecondsSinceEpoch}',
        customerName: 'QR Müşterisi',
        tableNumber: _currentTableNumber!,
        requestType: callType,
        message: selectedWaiter != null 
            ? '${selectedWaiter.fullName} için özel çağrı - QR menü üzerinden'
            : 'QR menü üzerinden çağrı',
        metadata: {
          'source': 'qr_menu',
          'qr_code': widget.qrCode,
          'selected_waiter_id': selectedWaiter?.waiterId,
          'selected_waiter_name': selectedWaiter?.fullName,
          'table_number_from_qr': _currentTableNumber,
        },
      );
      
      Navigator.pop(context); // Loading kapat
      
      // Başarı mesajı
      _showSuccessDialog(callType, _currentTableNumber!, selectedWaiter);
      
    } catch (e) {
      Navigator.pop(context); // Loading kapat
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Garson çağırırken hata: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<int?> _getTableNumber() async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.table_restaurant_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Masa Numarası'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Masa Numarası',
            hintText: 'Örn: 15',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final tableNumber = int.tryParse(controller.text);
              if (tableNumber != null && tableNumber > 0) {
                Navigator.pop(context, tableNumber);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen geçerli bir masa numarası girin'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Devam'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(WaiterCallType callType, int tableNumber, Waiter? selectedWaiter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 32,
          ),
        ),
        title: const Text('Garson Çağrıldı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedWaiter != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      image: selectedWaiter.profileImageUrl != null 
                          ? DecorationImage(
                              image: NetworkImage(selectedWaiter.profileImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: selectedWaiter.profileImageUrl == null
                        ? Center(
                            child: Text(
                              selectedWaiter.initials,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedWaiter.fullName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'size yardım için geliyor.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Talep: ${callType.displayName}',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ] else ...[
              Text(
                '${callType.displayName} talebiniz için garson çağrıldı.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'İlk müsait olan garson size yardım edecek.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Masa: $tableNumber',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Color _getCallTypeColor(WaiterCallType callType) {
    switch (callType) {
      case WaiterCallType.service:
        return AppColors.primary;
      case WaiterCallType.order:
        return AppColors.secondary;
      case WaiterCallType.payment:
        return AppColors.success;
      case WaiterCallType.complaint:
        return AppColors.error;
      case WaiterCallType.assistance:
        return AppColors.info;
      case WaiterCallType.bill:
        return AppColors.success;
      case WaiterCallType.help:
        return AppColors.info;
      case WaiterCallType.cleaning:
        return AppColors.warning;
      case WaiterCallType.emergency:
        return AppColors.error;
    }
  }

  IconData _getCallTypeIcon(WaiterCallType callType) {
    switch (callType) {
      case WaiterCallType.service:
        return Icons.room_service_rounded;
      case WaiterCallType.order:
        return Icons.restaurant_menu_rounded;
      case WaiterCallType.payment:
        return Icons.receipt_rounded;
      case WaiterCallType.complaint:
        return Icons.report_problem_rounded;
      case WaiterCallType.assistance:
        return Icons.help_rounded;
      case WaiterCallType.bill:
        return Icons.receipt_rounded;
      case WaiterCallType.help:
        return Icons.help_rounded;
      case WaiterCallType.cleaning:
        return Icons.cleaning_services_rounded;
      case WaiterCallType.emergency:
        return Icons.emergency_rounded;
    }
  }
} 