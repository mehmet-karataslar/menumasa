import '../../customer/models/cart.dart';

class Order {
  final String orderId;
  final String businessId;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final int tableNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  Order({
    required this.orderId,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.tableNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  // Getters for compatibility
  String get id => orderId;
  double get total => totalAmount;

  factory Order.fromJson(Map<String, dynamic> data, {String? id}) {
    return Order(
      orderId: id ?? data['orderId'] ?? '',
      businessId: data['businessId'] ?? '',
      customerId: data['customerId'] ?? data['customerName'] ?? '', // Fallback for old data
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'],
      tableNumber: data['tableNumber'] ?? 0,
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: _parsePrice(data['totalAmount']),
      status: OrderStatus.fromString(data['status'] ?? 'pending'),
      notes: data['notes'],
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      completedAt: data['completedAt'] != null 
          ? _parseDateTime(data['completedAt'])
          : null,
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
        print('Warning: Could not parse price value "$value" as double, using 0.0');
        return 0.0;
      }
    }
    
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    // Handle Firestore Timestamp
    if (value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate();
    }
    
    // Handle String
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    // Handle DateTime (already parsed)
    if (value is DateTime) {
      return value;
    }
    
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'tableNumber': tableNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status.value,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  Order copyWith({
    String? orderId,
    String? businessId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    int? tableNumber,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      tableNumber: tableNumber ?? this.tableNumber,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Helper methods
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get formattedTotalAmount => '${totalAmount.toStringAsFixed(2)} TL';

  String get formattedTableNumber => 'Masa $tableNumber';

  String get statusDisplayName => status.displayName;

  String get orderTimeDisplay {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dk önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    } else {
      return '${diff.inDays} gün önce';
    }
  }

  Duration get orderDuration {
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(createdAt);
  }

  String get formattedOrderDuration {
    final duration = orderDuration;
    if (duration.inHours > 0) {
      return '${duration.inHours}s ${duration.inMinutes % 60}dk';
    } else {
      return '${duration.inMinutes}dk';
    }
  }

  bool get isCompleted => status == OrderStatus.completed;
  bool get isPending => status == OrderStatus.pending;
  bool get isInProgress => status == OrderStatus.inProgress;
  bool get isCancelled => status == OrderStatus.cancelled;

  // Order status transitions
  Order markAsInProgress() {
    return copyWith(status: OrderStatus.inProgress, updatedAt: DateTime.now());
  }

  Order markAsCompleted() {
    return copyWith(
      status: OrderStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Order markAsCancelled() {
    return copyWith(status: OrderStatus.cancelled, updatedAt: DateTime.now());
  }

  // Create order from cart
  static Order fromCart(
    Cart cart, {
    required String customerId,
    required String customerName,
    String? customerPhone,
    required int tableNumber,
    String? notes,
  }) {
    final orderItems = cart.items
        .map(
          (cartItem) => OrderItem(
            orderItemId:
                'order_item_${DateTime.now().millisecondsSinceEpoch}_${cartItem.productId}',
            productId: cartItem.productId,
            productName: cartItem.productName,
            productPrice: cartItem.productPrice,
            productImage: cartItem.productImage,
            quantity: cartItem.quantity,
            notes: cartItem.notes,
          ),
        )
        .toList();

    return Order(
      orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
      businessId: cart.businessId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      tableNumber: tableNumber,
      items: orderItems,
      totalAmount: cart.totalPrice,
      status: OrderStatus.pending,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Order(orderId: $orderId, tableNumber: $tableNumber, status: ${status.displayName}, totalAmount: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.orderId == orderId;
  }

  @override
  int get hashCode => orderId.hashCode;
}

class OrderItem {
  final String orderItemId;
  final String productId;
  final String productName;
  final double productPrice;
  final String? productImage;
  final int quantity;
  final String? notes;

  OrderItem({
    required this.orderItemId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.productImage,
    required this.quantity,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> data) {
    return OrderItem(
      orderItemId: data['orderItemId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productPrice: _parsePriceStatic(data['productPrice']),
      productImage: data['productImage'],
      quantity: data['quantity'] ?? 1,
      notes: data['notes'],
    );
  }

  static double _parsePriceStatic(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      } else {
        print('Warning: Could not parse price value "$value" as double, using 0.0');
        return 0.0;
      }
    }
    
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'orderItemId': orderItemId,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'quantity': quantity,
      'notes': notes,
    };
  }

  OrderItem copyWith({
    String? orderItemId,
    String? productId,
    String? productName,
    double? productPrice,
    String? productImage,
    int? quantity,
    String? notes,
  }) {
    return OrderItem(
      orderItemId: orderItemId ?? this.orderItemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  double get totalPrice => productPrice * quantity;
  String get formattedTotalPrice => '${totalPrice.toStringAsFixed(2)} TL';
  String get formattedUnitPrice => '${productPrice.toStringAsFixed(2)} TL';

  // Getter for compatibility
  double get price => productPrice;

  @override
  String toString() {
    return 'OrderItem(productId: $productId, productName: $productName, quantity: $quantity, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem && other.orderItemId == orderItemId;
  }

  @override
  int get hashCode => orderItemId.hashCode;
}

enum OrderStatus {
  pending('pending', 'Bekliyor', 'Yeni sipariş alındı'),
  confirmed('confirmed', 'Onaylandı', 'Sipariş onaylandı'),
  preparing('preparing', 'Hazırlanıyor', 'Sipariş hazırlanıyor'),
  ready('ready', 'Hazır', 'Sipariş hazır'),
  delivered('delivered', 'Teslim Edildi', 'Sipariş teslim edildi'),
  inProgress('in_progress', 'Hazırlanıyor', 'Sipariş hazırlanıyor'),
  completed('completed', 'Tamamlandı', 'Sipariş tamamlandı'),
  cancelled('cancelled', 'İptal Edildi', 'Sipariş iptal edildi');

  const OrderStatus(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

// Default instances and helper methods
class OrderDefaults {
  static Order createDefault({
    required String businessId,
    String? customerId,
    required String customerName,
    String? customerPhone,
    required int tableNumber,
    required List<OrderItem> items,
    required double totalAmount,
    String? notes,
  }) {
    return Order(
      orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      customerId: customerId ?? customerName, // Use customerName as fallback
      customerName: customerName,
      customerPhone: customerPhone,
      tableNumber: tableNumber,
      items: items,
      totalAmount: totalAmount,
      status: OrderStatus.pending,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

// Extension methods for better usability
extension OrderExtensions on Order {
  /// Siparişin belirli bir durumda olup olmadığını kontrol eder
  bool hasStatus(OrderStatus status) => this.status == status;

  /// Siparişin aktif olup olmadığını kontrol eder (tamamlanmamış veya iptal edilmemiş)
  bool get isActive => !isCompleted && !isCancelled;

  /// Siparişin gecikmeli olup olmadığını kontrol eder (30 dakikadan fazla)
  bool get isDelayed => !isCompleted && orderDuration.inMinutes > 30;

  /// Siparişin acil olup olmadığını kontrol eder (45 dakikadan fazla)
  bool get isUrgent => !isCompleted && orderDuration.inMinutes > 45;

  /// Sipariş öncelik seviyesini döndürür
  int get priorityLevel {
    if (isUrgent) return 3;
    if (isDelayed) return 2;
    return 1;
  }

  /// Sipariş rengini döndürür (UI için)
  String get statusColor {
    switch (status) {
      case OrderStatus.pending:
        return '#FFA726'; // Orange
      case OrderStatus.confirmed:
        return '#42A5F5'; // Blue
      case OrderStatus.preparing:
        return '#FFA726'; // Orange
      case OrderStatus.ready:
        return '#66BB6A'; // Green
      case OrderStatus.delivered:
        return '#66BB6A'; // Green
      case OrderStatus.inProgress:
        return '#42A5F5'; // Blue
      case OrderStatus.completed:
        return '#66BB6A'; // Green
      case OrderStatus.cancelled:
        return '#EF5350'; // Red
    }
  }

  /// Masa numarasına göre gruplama için key
  String get tableGroupKey => 'table_$tableNumber';

  /// Ürün sayısını kategorize eder
  String get itemCountCategory {
    if (totalItems <= 3) return 'Küçük';
    if (totalItems <= 6) return 'Orta';
    return 'Büyük';
  }

  /// Sipariş özetini döndürür
  String get orderSummary {
    final itemNames = items
        .take(3)
        .map((item) => '${item.quantity}x ${item.productName}')
        .join(', ');
    final remaining = items.length > 3 ? ' +${items.length - 3} daha' : '';
    return '$itemNames$remaining';
  }
}
