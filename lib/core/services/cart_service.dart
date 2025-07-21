import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../customer/models/cart.dart';
import '../../business/models/product.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;
  Cart? _currentCart;

  // Cart change listeners
  final List<Function(Cart)> _cartListeners = [];

  Future<void> initialize() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      await _loadCurrentCart();
    }
  }

  // Cart listeners
  void addCartListener(Function(Cart) listener) {
    _cartListeners.add(listener);
  }

  void removeCartListener(Function(Cart) listener) {
    _cartListeners.remove(listener);
  }

  void _notifyCartListeners() {
    if (_currentCart != null) {
      for (final listener in _cartListeners) {
        listener(_currentCart!);
      }
    }
  }

  // Cart operations
  Future<Cart> getCurrentCart(String businessId) async {
    await initialize();

    if (_currentCart == null || _currentCart!.businessId != businessId) {
      _currentCart = CartDefaults.createEmpty(businessId: businessId);
      await _saveCurrentCart();
    }

    return _currentCart!;
  }

  Future<void> addToCart(
    Product product,
    String businessId, {
    int quantity = 1,
    String? notes,
  }) async {
    await initialize();

    // If cart is for different business, clear it
    if (_currentCart != null && _currentCart!.businessId != businessId) {
      _currentCart = CartDefaults.createEmpty(businessId: businessId);
    } else if (_currentCart == null) {
      _currentCart = CartDefaults.createEmpty(businessId: businessId);
    }

    _currentCart = _currentCart!.addItem(
      product,
      quantity: quantity,
      notes: notes,
    );
    
    await _saveCurrentCart();
    _notifyCartListeners();
  }

  Future<void> removeFromCart(String productId, String businessId) async {
    await initialize();

    final cart = await getCurrentCart(businessId);
    _currentCart = cart.removeItem(productId);
    await _saveCurrentCart();
    _notifyCartListeners();
  }

  Future<void> updateCartItemQuantity(
    String productId,
    String businessId,
    int quantity,
  ) async {
    await initialize();

    final cart = await getCurrentCart(businessId);
    _currentCart = cart.updateItemQuantity(productId, quantity);
    await _saveCurrentCart();
    _notifyCartListeners();
  }

  Future<void> updateCartItemNotes(
    String productId,
    String businessId,
    String? notes,
  ) async {
    await initialize();

    final cart = await getCurrentCart(businessId);
    _currentCart = cart.updateItemNotes(productId, notes);
    await _saveCurrentCart();
    _notifyCartListeners();
  }

  Future<void> clearCart(String businessId) async {
    await initialize();

    _currentCart = CartDefaults.createEmpty(businessId: businessId);
    await _saveCurrentCart();
    _notifyCartListeners();
  }

  Future<int> getCartItemCount(String businessId) async {
    final cart = await getCurrentCart(businessId);
    return cart.totalItems;
  }

  Future<double> getCartTotal(String businessId) async {
    final cart = await getCurrentCart(businessId);
    return cart.totalPrice;
  }

  Future<bool> isProductInCart(String productId, String businessId) async {
    final cart = await getCurrentCart(businessId);
    return cart.items.any((item) => item.productId == productId);
  }

  Future<int> getProductQuantityInCart(
    String productId,
    String businessId,
  ) async {
    final cart = await getCurrentCart(businessId);
    final item = cart.items
        .where((item) => item.productId == productId)
        .firstOrNull;
    return item?.quantity ?? 0;
  }

  // Private methods
  Future<void> _loadCurrentCart() async {
    final cartJson = _prefs.getString('current_cart');
    if (cartJson != null) {
      try {
        _currentCart = Cart.fromJson(jsonDecode(cartJson));
      } catch (e) {
        // If cart data is corrupted, create a new empty cart
        _currentCart = null;
      }
    }
  }

  Future<void> _saveCurrentCart() async {
    if (_currentCart != null) {
      await _prefs.setString(
        'current_cart',
        jsonEncode(_currentCart!.toJson()),
      );
    } else {
      await _prefs.remove('current_cart');
    }
  }

  // Utility methods
  Future<void> dispose() async {
    _cartListeners.clear();
  }
}

// Extension for easier null checking
extension on Iterable<CartItem> {
  CartItem? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
