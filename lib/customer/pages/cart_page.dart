import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masamenu/customer/customer.dart';
import '../models/cart.dart';
import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/cart_service.dart';
import '../../data/models/order.dart' as app_order;
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../../core/services/core_firestore_service.dart';
import '../services/customer_firestore_service.dart';

class CartPage extends StatefulWidget {
  final String businessId;
  final String? userId;

  const CartPage({Key? key, required this.businessId, this.userId}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with TickerProviderStateMixin {
  final CartService _cartService = CartService();
  final CustomerService _customerService = CustomerService();
  final CustomerFirestoreService _customerFirestoreService = CustomerFirestoreService();
  final CoreFirestoreService _coreFirestoreService = CoreFirestoreService();

  Cart? _cart;
  Business? _business;
  bool _isLoading = true;
  bool _isPlacingOrder = false;

  // Order form controllers
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isFormExpanded = false;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic));
    
    _loadData();
    _cartService.addCartListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cartService.removeCartListener(_onCartChanged);
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _tableNumberController.dispose();
    _notesController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _onCartChanged(Cart cart) {
    if (mounted) {
      setState(() {
        _cart = cart;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _cartService.initialize();

      final cart = await _cartService.getCurrentCart(widget.businessId);
      final business = await _customerFirestoreService.getBusiness(widget.businessId);

      setState(() {
        _cart = cart;
        _business = business;
        _isLoading = false;
      });
      
      _fadeAnimationController.forward();
      _slideAnimationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sepet yüklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _updateQuantity(String productId, int quantity) async {
    try {
      await _cartService.updateCartItemQuantity(
        productId,
        widget.businessId,
        quantity,
      );
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Miktar güncellenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeItem(String productId) async {
    try {
      await _cartService.removeFromCart(productId, widget.businessId);
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                SizedBox(width: 8),
                Text('Ürün sepetten çıkarıldı'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün çıkarılırken hata oluştu: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateNotes(String productId, String? notes) async {
    try {
      await _cartService.updateCartItemNotes(
        productId,
        widget.businessId,
        notes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not güncellenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text(
              'Sepeti Temizle',
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Sepetteki tüm ürünleri silmek istediğinizden emin misiniz?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Temizle'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cartService.clearCart(widget.businessId);
        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.white),
                  SizedBox(width: 8),
                  Text('Sepet temizlendi'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sepet temizlenirken hata oluştu: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _onOrdersPressed() {
    Navigator.pushNamed(
      context,
      '/customer/orders',
      arguments: {
        'businessId': widget.businessId,
        'customerPhone': _customerPhoneController.text.trim().isNotEmpty
            ? _customerPhoneController.text.trim()
            : null,
      },
    );
  }

  Future<void> _placeOrder() async {
    if (_cart == null || _cart!.isEmpty) {
      _showErrorSnackBar('Sepetiniz boş');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Lütfen gerekli alanları doldurun');
      return;
    }

    final tableNumber = int.tryParse(_tableNumberController.text.trim());
    if (tableNumber == null || tableNumber <= 0) {
      _showErrorSnackBar('Geçerli bir masa numarası girin');
      return;
    }

    try {
      setState(() {
        _isPlacingOrder = true;
      });

      final customerName = _customerNameController.text.trim();
      final order = app_order.Order.fromCart(
        _cart!,
        customerId: widget.userId ?? customerName, // Use userId if available, fallback to customerName
        customerName: customerName,
        customerPhone: _customerPhoneController.text.trim().isNotEmpty
            ? _customerPhoneController.text.trim()
            : null,
        tableNumber: tableNumber,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final orderId = await _coreFirestoreService.createOrderWithNotification(order);
      final savedOrder = order.copyWith(orderId: orderId);

      await _cartService.clearCart(widget.businessId);

      setState(() {
        _isPlacingOrder = false;
      });

      HapticFeedback.heavyImpact();

      if (mounted) {
        await _showSuccessDialog(savedOrder);
      }
    } catch (e) {
      setState(() {
        _isPlacingOrder = false;
      });
      if (mounted) {
        _showErrorSnackBar('Sipariş verilirken hata oluştu: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showSuccessDialog(app_order.Order order) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: AppColors.white,
                size: 40,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Sipariş Alındı! 🎉',
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greyLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildOrderInfoRow('Sipariş No', '#${order.orderId.substring(0, 8)}'),
                  _buildOrderInfoRow('Masa', 'Masa ${order.tableNumber}'),
                  _buildOrderInfoRow('Toplam', '${order.totalAmount.toStringAsFixed(2)} ₺'),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Siparişiniz işletmeye iletildi. Hazırlanmaya başlanacak.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Menüye Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _onOrdersPressed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Siparişlerimi Gör'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: LoadingIndicator())
          : _cart == null || _cart!.isEmpty
          ? _buildEmptyCart()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: _buildCartContent(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sepetim',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          if (_business != null)
            Text(
              _business!.businessName,
              style: AppTypography.caption.copyWith(
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _onOrdersPressed,
          icon: Icon(Icons.receipt_long_rounded),
          tooltip: 'Siparişlerim',
        ),
        if (_cart != null && _cart!.isNotEmpty)
          IconButton(
            onPressed: _clearCart,
            icon: Icon(Icons.delete_outline_rounded),
            tooltip: 'Sepeti Temizle',
          ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return FadeTransition(
      opacity: _fadeAnimation,
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
                  color: AppColors.greyLighter,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 60,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Sepetiniz Boş',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Menüden ürün ekleyerek\nsiparişinizi oluşturun',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.restaurant_menu_rounded),
                label: Text('Menüye Dön'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Cart items
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _cart!.items.length,
                itemBuilder: (context, index) {
                  final item = _cart!.items[index];
                  return _buildModernCartItemCard(item, index);
                },
              ),
            ),
          ),
          // Sticky bottom section
          _buildStickyBottomSection(),
        ],
      ),
    );
  }

  Widget _buildModernCartItemCard(CartItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Hero(
                    tag: 'cart_item_${item.productId}',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [AppColors.greyLighter, AppColors.greyLight],
                        ),
                      ),
                      child: item.productImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.productImage!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.restaurant_rounded,
                                  color: AppColors.textSecondary,
                                  size: 32,
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.textSecondary,
                              size: 32,
                            ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.formattedUnitPrice,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Not: ${item.notes}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.info,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 12),
                        // Quantity controls and total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuantityControls(item),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item.formattedTotalPrice,
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _removeItem(item.productId),
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildQuantityControls(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _updateQuantity(item.productId, item.quantity - 1),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.remove_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              item.quantity.toString(),
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _updateQuantity(item.productId, item.quantity + 1),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order summary
          _buildOrderSummary(),
          // Order form - with constraints to prevent overflow
          if (_isFormExpanded)
            Container(
              constraints: BoxConstraints(
                maxHeight: 350, // Reduced from 400 to prevent overflow
              ),
              child: _buildOrderFormContent(),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toplam (${_cart!.totalItems} ürün)',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _cart!.formattedTotalPrice,
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isFormExpanded = !_isFormExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isFormExpanded ? 'Gizle' : 'Sipariş Ver',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    _isFormExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFormContent() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.greyLight, width: 1),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'Sipariş Bilgileri',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _customerNameController,
                      labelText: 'Adınız *',
                      icon: Icons.person_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ad alanı gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _tableNumberController,
                      labelText: 'Masa No *',
                      icon: Icons.table_restaurant_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Masa numarası gerekli';
                        }
                        final tableNum = int.tryParse(value);
                        if (tableNum == null || tableNum <= 0) {
                          return 'Geçerli masa numarası girin';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildModernTextField(
                controller: _customerPhoneController,
                labelText: 'Telefon',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              _buildModernTextField(
                controller: _notesController,
                labelText: 'Sipariş Notu',
                icon: Icons.note_rounded,
                maxLines: 2,
              ),
              SizedBox(height: 24),
              _buildModernOrderButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.greyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.greyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.greyLighter,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildModernOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPlacingOrder ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isPlacingOrder
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Sipariş Veriliyor...',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Sipariş Ver (${_cart!.formattedTotalPrice})',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
