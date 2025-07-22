import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../business/models/business.dart';
import '../../business/models/category.dart';
import '../../business/models/product.dart';
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

  const QRMenuPage({
    super.key,
    required this.businessId,
    this.userId,
    this.qrCode,
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
  
  // Data variables
  Business? _business;
  List<Category> _categories = [];
  List<Product> _products = [];
  String? _selectedCategoryId;
  
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
      final products = await _firestoreService.getProductsByBusiness(widget.businessId);

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
        _selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;
        _isLoading = false;
      });

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
    if (_selectedCategoryId == null) return _products;
    return _products.where((product) => 
      product.categoryId == _selectedCategoryId && product.isAvailable
    ).toList();
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
            // Business Header
            SliverToBoxAdapter(
              child: BusinessHeader(
                business: _business!,
                isCompact: false,
                cartItemCount: 0, // QR menüde sepet yok
                onSharePressed: _handleShare,
                onCallPressed: () => _handleCall(_business!.phone ?? ''),
                onLocationPressed: () => _handleLocation(_business!.businessAddress),
              ),
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
        ProductGrid(
          products: _filteredProducts,
          onProductTap: _handleProductTap,
          isQRMenu: true, // QR menü modu
        ),
      ],
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
                        'Garson Çağırın',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'İhtiyacınızı seçin, garson gelsin',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
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
                      onTap: () => _makeWaiterCall(callType),
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

  Future<void> _makeWaiterCall(WaiterCallType callType) async {
    Navigator.pop(context);
    
    // Masa numarası al
    final tableNumber = await _getTableNumber();
    if (tableNumber == null) return;
    
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
        tableNumber: tableNumber,
        requestType: callType,
        message: 'QR menü üzerinden çağrı',
        metadata: {
          'source': 'qr_menu',
          'qr_code': widget.qrCode,
        },
      );
      
      Navigator.pop(context); // Loading kapat
      
      // Başarı mesajı
      _showSuccessDialog(callType, tableNumber);
      
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

  void _showSuccessDialog(WaiterCallType callType, int tableNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            Text(
              '${callType.displayName} talebiniz için garson çağrıldı.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Masa: $tableNumber',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
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