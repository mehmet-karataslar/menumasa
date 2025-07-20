import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/cart.dart';
import '../../../data/models/business.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/order.dart' as app_order;
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import '../../widgets/shared/empty_state.dart';

class CartPage extends StatefulWidget {
  final String businessId;

  const CartPage({Key? key, required this.businessId}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  final FirestoreService _firestoreService = FirestoreService();

  Cart? _cart;
  Business? _business;
  bool _isLoading = true;
  bool _isPlacingOrder = false;

  // Order form controllers
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      final business = await _firestoreService.getBusiness(widget.businessId);

      setState(() {
        _cart = cart;
        _business = business;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sepet yüklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
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
          ),
        );
      }
    }
  }

  Future<void> _removeItem(String productId) async {
    try {
      await _cartService.removeFromCart(productId, widget.businessId);
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün sepetten çıkarıldı'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün çıkarılırken hata oluştu: $e'),
            backgroundColor: AppColors.error,
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
          ),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sepeti Temizle'),
        content: const Text(
          'Sepetteki tüm ürünleri silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cartService.clearCart(widget.businessId);
        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sepet temizlendi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sepet temizlenirken hata oluştu: $e'),
              backgroundColor: AppColors.error,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sepetiniz boş'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Validate form
    if (_customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen adınızı girin'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_tableNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen masa numaranızı girin'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final tableNumber = int.tryParse(_tableNumberController.text.trim());
    if (tableNumber == null || tableNumber <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir masa numarası girin'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isPlacingOrder = true;
      });

      // Sepetten sipariş oluştur
      final order = app_order.Order.fromCart(
        _cart!,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim().isNotEmpty
            ? _customerPhoneController.text.trim()
            : null,
        tableNumber: tableNumber,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      // Siparişi Firebase'e kaydet ve bildirim gönder
      final orderId = await _firestoreService.createOrderWithNotification(order);
      final savedOrder = order.copyWith(orderId: orderId);

      // Clear cart after successful order
      await _cartService.clearCart(widget.businessId);

      setState(() {
        _isPlacingOrder = false;
      });

      HapticFeedback.heavyImpact();

      // Show success dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Sipariş Alındı!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sipariş No: ${savedOrder.orderId}'),
                Text('Masa: Masa ${savedOrder.tableNumber}'),
                Text('Toplam: ${savedOrder.totalAmount.toStringAsFixed(2)} ₺'),
                const SizedBox(height: 16),
                const Text(
                  'Siparişiniz işletmeye iletildi. Hazırlanmaya başlanacak.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close cart page
                },
                child: const Text('Menüye Dön'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacementNamed(
                    context,
                    '/customer/orders',
                    arguments: {
                      'businessId': widget.businessId,
                      'customerPhone':
                          _customerPhoneController.text.trim().isNotEmpty
                          ? _customerPhoneController.text.trim()
                          : null,
                    },
                  );
                },
                child: const Text('Siparişlerimi Gör'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isPlacingOrder = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş verilirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sepetim'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _onOrdersPressed,
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Siparişlerim',
          ),
          if (_cart != null && _cart!.isNotEmpty)
            IconButton(
              onPressed: _clearCart,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Sepeti Temizle',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _cart == null || _cart!.isEmpty
          ? _buildEmptyCart()
          : RefreshIndicator(onRefresh: _loadData, child: _buildCartContent()),
    );
  }

  Widget _buildEmptyCart() {
    return EmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Sepetiniz Boş',
      message: 'Menüden ürün ekleyerek siparişinizi oluşturun',
      actionText: 'Menüye Dön',
      onActionPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        // Cart items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            itemCount: _cart!.items.length,
            itemBuilder: (context, index) {
              final item = _cart!.items[index];
              return _buildCartItemCard(item);
            },
          ),
        ),
        // Order summary and form
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(children: [_buildOrderSummary(), _buildOrderForm()]),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing16),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(8),
                image: item.productImage != null
                    ? DecorationImage(
                        image: NetworkImage(item.productImage!),
                        fit: BoxFit.cover,
                        onError: (error, stackTrace) {},
                      )
                    : null,
              ),
              child: item.productImage == null
                  ? const Icon(Icons.restaurant, color: AppColors.grey)
                  : null,
            ),
            const SizedBox(width: AppDimensions.spacing16),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.formattedUnitPrice,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Not: ${item.notes}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Quantity controls
                  Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            _updateQuantity(item.productId, item.quantity - 1),
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.primary,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.quantity.toString(),
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _updateQuantity(item.productId, item.quantity + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.primary,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Total price and remove button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.formattedTotalPrice,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => _removeItem(item.productId),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.lightGrey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toplam (${_cart!.totalItems} ürün)',
                style: AppTypography.bodyMedium,
              ),
              Text(
                _cart!.formattedTotalPrice,
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderForm() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sipariş Bilgileri',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Adınız *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _tableNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Masa No *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customerPhoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon (Opsiyonel)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Özel İstekler (Opsiyonel)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Sipariş Ver (${_cart!.formattedTotalPrice})',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
