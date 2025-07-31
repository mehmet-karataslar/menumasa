import '../../business/models/product.dart';

class Cart {
  final String cartId;
  final String businessId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.cartId,
    required this.businessId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> data, {String? id}) {
    return Cart(
      cartId: id ?? data['cartId'] ?? '',
      businessId: data['businessId'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => CartItem.fromJson(item))
          .toList(),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartId': cartId,
      'businessId': businessId,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Cart copyWith({
    String? cartId,
    String? businessId,
    List<CartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      cartId: cartId ?? this.cartId,
      businessId: businessId ?? this.businessId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  String get formattedTotalPrice => '${totalPrice.toStringAsFixed(2)} TL';

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  // Cart operations
  Cart addItem(Product product, {int quantity = 1, String? notes}) {
    final existingItemIndex = items.indexWhere(
      (item) => item.productId == product.productId,
    );

    List<CartItem> newItems = List.from(items);

    if (existingItemIndex >= 0) {
      // Update existing item
      final existingItem = items[existingItemIndex];
      newItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
        updatedAt: DateTime.now(),
      );
    } else {
      // Add new item
      final newCartItem = CartItem(
        cartItemId: 'cart_item_${DateTime.now().millisecondsSinceEpoch}',
        productId: product.productId,
        productName: product.name,
        productPrice: product.price,
        productImage: product.primaryImage?.url,
        quantity: quantity,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      newItems.add(newCartItem);
    }

    return copyWith(items: newItems, updatedAt: DateTime.now());
  }

  Cart removeItem(String productId) {
    final newItems =
        items.where((item) => item.productId != productId).toList();
    return copyWith(items: newItems, updatedAt: DateTime.now());
  }

  Cart updateItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      return removeItem(productId);
    }

    final newItems = items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity, updatedAt: DateTime.now());
      }
      return item;
    }).toList();

    return copyWith(items: newItems, updatedAt: DateTime.now());
  }

  Cart updateItemNotes(String productId, String? notes) {
    final newItems = items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(notes: notes, updatedAt: DateTime.now());
      }
      return item;
    }).toList();

    return copyWith(items: newItems, updatedAt: DateTime.now());
  }

  Cart clearCart() {
    return copyWith(items: [], updatedAt: DateTime.now());
  }

  @override
  String toString() {
    return 'Cart(cartId: $cartId, businessId: $businessId, totalItems: $totalItems, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cart && other.cartId == cartId;
  }

  @override
  int get hashCode => cartId.hashCode;
}

class CartItem {
  final String cartItemId;
  final String productId;
  final String productName;
  final double productPrice;
  final String? productImage;
  final int quantity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartItem({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.productImage,
    required this.quantity,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> data) {
    return CartItem(
      cartItemId: data['cartItemId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productPrice: _parsePrice(data['productPrice']),
      productImage: data['productImage'],
      quantity: data['quantity'] ?? 1,
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      } else {
        print(
            'Warning: Could not parse price value "$value" as double, using 0.0');
        return 0.0;
      }
    }

    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'cartItemId': cartItemId,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'quantity': quantity,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    String? cartItemId,
    String? productId,
    String? productName,
    double? productPrice,
    String? productImage,
    int? quantity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      cartItemId: cartItemId ?? this.cartItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  double get totalPrice => productPrice * quantity;
  String get formattedTotalPrice => '${totalPrice.toStringAsFixed(2)} TL';
  String get formattedUnitPrice => '${productPrice.toStringAsFixed(2)} TL';

  @override
  String toString() {
    return 'CartItem(productId: $productId, productName: $productName, quantity: $quantity, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.cartItemId == cartItemId;
  }

  @override
  int get hashCode => cartItemId.hashCode;
}

// Default instances and helper methods
class CartDefaults {
  static Cart createEmpty({required String businessId}) {
    return Cart(
      cartId: 'cart_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
