import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/order.dart';
import '../../data/models/cart.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Order change listeners
  final List<Function(List<Order>)> _orderListeners = [];

  Future<void> initialize() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Order listeners
  void addOrderListener(Function(List<Order>) listener) {
    _orderListeners.add(listener);
  }

  void removeOrderListener(Function(List<Order>) listener) {
    _orderListeners.remove(listener);
  }

  void _notifyOrderListeners(String businessId) async {
    final orders = await getOrdersByBusinessId(businessId);
    for (final listener in _orderListeners) {
      listener(orders);
    }
  }

  // Order CRUD operations
  Future<List<Order>> getAllOrders() async {
    await initialize();
    final ordersJson = _prefs.getStringList('orders') ?? [];
    return ordersJson.map((json) => Order.fromJson(jsonDecode(json))).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Latest first
  }

  Future<List<Order>> getOrdersByBusinessId(String businessId) async {
    final orders = await getAllOrders();
    return orders.where((order) => order.businessId == businessId).toList();
  }

  Future<List<Order>> getOrdersByCustomerPhone(
    String customerPhone,
    String businessId,
  ) async {
    final orders = await getOrdersByBusinessId(businessId);
    return orders
        .where((order) => order.customerPhone == customerPhone)
        .toList();
  }

  Future<Order?> getOrder(String orderId) async {
    final orders = await getAllOrders();
    try {
      return orders.firstWhere((order) => order.orderId == orderId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveOrder(Order order) async {
    await initialize();
    final orders = await getAllOrders();
    final index = orders.indexWhere((o) => o.orderId == order.orderId);

    if (index >= 0) {
      orders[index] = order;
    } else {
      orders.add(order);
    }

    final ordersJson = orders.map((o) => jsonEncode(o.toJson())).toList();
    await _prefs.setStringList('orders', ordersJson);
    _notifyOrderListeners(order.businessId);
  }

  Future<void> deleteOrder(String orderId) async {
    await initialize();
    final orders = await getAllOrders();
    final orderToDelete = orders.where((o) => o.orderId == orderId).firstOrNull;
    orders.removeWhere((o) => o.orderId == orderId);

    final ordersJson = orders.map((o) => jsonEncode(o.toJson())).toList();
    await _prefs.setStringList('orders', ordersJson);

    if (orderToDelete != null) {
      _notifyOrderListeners(orderToDelete.businessId);
    }
  }

  // Order creation from cart
  Future<Order> createOrderFromCart(
    Cart cart, {
    required String customerName,
    String? customerPhone,
    required int tableNumber,
    String? notes,
  }) async {
    final order = Order.fromCart(
      cart,
      customerName: customerName,
      customerPhone: customerPhone,
      tableNumber: tableNumber,
      notes: notes,
    );

    await saveOrder(order);
    return order;
  }

  // Order status management
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final order = await getOrder(orderId);
    if (order != null) {
      Order updatedOrder;
      switch (status) {
        case OrderStatus.inProgress:
          updatedOrder = order.markAsInProgress();
          break;
        case OrderStatus.completed:
          updatedOrder = order.markAsCompleted();
          break;
        case OrderStatus.cancelled:
          updatedOrder = order.markAsCancelled();
          break;
        default:
          updatedOrder = order.copyWith(
            status: status,
            updatedAt: DateTime.now(),
          );
      }
      await saveOrder(updatedOrder);
    }
  }

  // Business order management
  Future<List<Order>> getPendingOrders(String businessId) async {
    final orders = await getOrdersByBusinessId(businessId);
    return orders
        .where((order) => order.status == OrderStatus.pending)
        .toList();
  }

  Future<List<Order>> getActiveOrders(String businessId) async {
    final orders = await getOrdersByBusinessId(businessId);
    return orders.where((order) => order.isActive).toList();
  }

  Future<List<Order>> getCompletedOrders(String businessId) async {
    final orders = await getOrdersByBusinessId(businessId);
    return orders
        .where((order) => order.status == OrderStatus.completed)
        .toList();
  }

  Future<List<Order>> getTodaysOrders(String businessId) async {
    final orders = await getOrdersByBusinessId(businessId);
    final today = DateTime.now();
    return orders.where((order) {
      final orderDate = order.createdAt;
      return orderDate.year == today.year &&
          orderDate.month == today.month &&
          orderDate.day == today.day;
    }).toList();
  }

  Future<List<Order>> getOrdersByTable(
    String businessId,
    int tableNumber,
  ) async {
    final orders = await getOrdersByBusinessId(businessId);
    return orders.where((order) => order.tableNumber == tableNumber).toList();
  }

  Future<List<Order>> getOrdersByStatus(
    String businessId,
    OrderStatus status,
  ) async {
    final orders = await getOrdersByBusinessId(businessId);
    return orders.where((order) => order.status == status).toList();
  }

  // Order statistics
  Future<Map<String, dynamic>> getOrderStatistics(String businessId) async {
    final orders = await getOrdersByBusinessId(businessId);
    final todaysOrders = await getTodaysOrders(businessId);
    final activeOrders = await getActiveOrders(businessId);
    final completedOrders = await getCompletedOrders(businessId);

    final totalRevenue = completedOrders.fold(
      0.0,
      (sum, order) => sum + order.totalAmount,
    );
    final todaysRevenue = todaysOrders
        .where((order) => order.status == OrderStatus.completed)
        .fold(0.0, (sum, order) => sum + order.totalAmount);

    final averageOrderValue = completedOrders.isNotEmpty
        ? totalRevenue / completedOrders.length
        : 0.0;

    return {
      'totalOrders': orders.length,
      'todaysOrders': todaysOrders.length,
      'activeOrders': activeOrders.length,
      'completedOrders': completedOrders.length,
      'totalRevenue': totalRevenue,
      'todaysRevenue': todaysRevenue,
      'averageOrderValue': averageOrderValue,
    };
  }

  // Order filtering and searching
  Future<List<Order>> searchOrders(String businessId, String query) async {
    final orders = await getOrdersByBusinessId(businessId);
    final lowerQuery = query.toLowerCase();

    return orders.where((order) {
      return order.customerName.toLowerCase().contains(lowerQuery) ||
          order.orderId.toLowerCase().contains(lowerQuery) ||
          order.tableNumber.toString().contains(lowerQuery) ||
          order.items.any(
            (item) => item.productName.toLowerCase().contains(lowerQuery),
          );
    }).toList();
  }

  Future<List<Order>> filterOrders(
    String businessId, {
    OrderStatus? status,
    int? tableNumber,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    final orders = await getOrdersByBusinessId(businessId);

    return orders.where((order) {
      if (status != null && order.status != status) return false;
      if (tableNumber != null && order.tableNumber != tableNumber) return false;
      if (startDate != null && order.createdAt.isBefore(startDate))
        return false;
      if (endDate != null && order.createdAt.isAfter(endDate)) return false;
      if (minAmount != null && order.totalAmount < minAmount) return false;
      if (maxAmount != null && order.totalAmount > maxAmount) return false;
      return true;
    }).toList();
  }

  // Utility methods
  Future<void> clearAllOrders() async {
    await initialize();
    await _prefs.remove('orders');
    _orderListeners.clear();
  }

  Future<void> dispose() async {
    _orderListeners.clear();
  }
}

// Extension for easier null checking
extension on Iterable<Order> {
  Order? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
