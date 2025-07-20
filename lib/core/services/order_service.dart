import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/order.dart' as app_order;
import '../../data/models/user.dart' as app_user;
import '../../business/models/business.dart';
import '../../customer/models/cart.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;
  bool _initialized = false;

  // Collections
  final String _ordersCollection = 'orders';
  final String _businessOrdersCollection = 'business_orders';

  // Order change listeners
  final Map<String, List<Function(List<app_order.Order>)>> _orderListeners = {};
  final Map<String, StreamSubscription<QuerySnapshot>?> _orderStreams = {};

  Future<void> initialize() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Order listeners for real-time updates
  void addOrderListener(String businessId, Function(List<app_order.Order>) listener) {
    if (!_orderListeners.containsKey(businessId)) {
      _orderListeners[businessId] = [];
      _startOrderStream(businessId);
    }
    _orderListeners[businessId]!.add(listener);
  }

  void removeOrderListener(String businessId, Function(List<app_order.Order>) listener) {
    _orderListeners[businessId]?.remove(listener);
    if (_orderListeners[businessId]?.isEmpty == true) {
      _orderListeners.remove(businessId);
      _orderStreams[businessId]?.cancel();
      _orderStreams.remove(businessId);
    }
  }

  void _startOrderStream(String businessId) {
    _orderStreams[businessId] = _firestore
        .collection(_ordersCollection)
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();

      _notifyOrderListeners(businessId, orders);
    });
  }

  void _notifyOrderListeners(String businessId, List<app_order.Order> orders) {
    final listeners = _orderListeners[businessId];
    if (listeners != null) {
      for (final listener in listeners) {
        listener(orders);
      }
    }
  }

  // Order CRUD operations using Firestore
  Future<List<app_order.Order>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();
    } catch (e) {
      // Fallback to local storage if Firestore fails
      await initialize();
      final ordersJson = _prefs.getStringList('orders') ?? [];
      return ordersJson.map((json) => app_order.Order.fromJson(jsonDecode(json))).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Future<List<app_order.Order>> getOrdersByBusinessId(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();
    } catch (e) {
      // Fallback to local storage
      final orders = await getAllOrders();
      return orders.where((order) => order.businessId == businessId).toList();
    }
  }

  Future<List<app_order.Order>> getOrdersByCustomerPhone(
    String customerPhone,
    String businessId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('businessId', isEqualTo: businessId)
          .where('customerPhone', isEqualTo: customerPhone)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();
    } catch (e) {
      // Fallback to local storage
      final orders = await getOrdersByBusinessId(businessId);
      return orders
          .where((order) => order.customerPhone == customerPhone)
          .toList();
    }
  }

  Future<app_order.Order?> getOrder(String orderId) async {
    try {
      final doc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        return app_order.Order.fromJson(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      // Fallback to local storage
      final orders = await getAllOrders();
      try {
        return orders.firstWhere((order) => order.orderId == orderId);
      } catch (e) {
        return null;
      }
    }
  }

  Future<String> saveOrder(app_order.Order order) async {
    try {
      final data = order.toJson();
      String orderId;

      if (order.orderId.isEmpty || order.orderId.startsWith('order_')) {
        // New order - create in Firestore
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();
        
        final docRef = await _firestore
            .collection(_ordersCollection)
            .add(data);
        
        orderId = docRef.id;
        
        // Also save to business orders for quick lookup
        await _firestore
            .collection(_businessOrdersCollection)
            .doc('${order.businessId}_${docRef.id}')
            .set({
              'businessId': order.businessId,
              'orderId': docRef.id,
              'status': order.status.value,
              'createdAt': FieldValue.serverTimestamp(),
              'tableNumber': order.tableNumber,
              'customerName': order.customerName,
              'totalAmount': order.totalAmount,
            });
      } else {
        // Update existing order - check if document exists first
        final docSnapshot = await _firestore
            .collection(_ordersCollection)
            .doc(order.orderId)
            .get();
            
        if (docSnapshot.exists) {
          data['updatedAt'] = FieldValue.serverTimestamp();
          await _firestore
              .collection(_ordersCollection)
              .doc(order.orderId)
              .update(data);
          
          // Update business orders index
          await _firestore
              .collection(_businessOrdersCollection)
              .doc('${order.businessId}_${order.orderId}')
              .update({
                'status': order.status.value,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          
          orderId = order.orderId;
        } else {
          // Document doesn't exist, create new one
          data['createdAt'] = FieldValue.serverTimestamp();
          data['updatedAt'] = FieldValue.serverTimestamp();
          
          final docRef = await _firestore
              .collection(_ordersCollection)
              .add(data);
          
          orderId = docRef.id;
          
          // Also save to business orders for quick lookup
          await _firestore
              .collection(_businessOrdersCollection)
              .doc('${order.businessId}_${docRef.id}')
              .set({
                'businessId': order.businessId,
                'orderId': docRef.id,
                'status': order.status.value,
                'createdAt': FieldValue.serverTimestamp(),
                'tableNumber': order.tableNumber,
                'customerName': order.customerName,
                'totalAmount': order.totalAmount,
              });
        }
      }

      // Also save locally as backup
      await _saveOrderLocally(order.copyWith(orderId: orderId));
      
      return orderId;
    } catch (e) {
      // Fallback to local storage
      await initialize();
      await _saveOrderLocally(order);
      return order.orderId;
    }
  }

  Future<void> _saveOrderLocally(app_order.Order order) async {
    await initialize();
    final orders = await _getLocalOrders();
    final index = orders.indexWhere((o) => o.orderId == order.orderId);

    if (index >= 0) {
      orders[index] = order;
    } else {
      orders.add(order);
    }

    final ordersJson = orders.map((o) => jsonEncode(o.toJson())).toList();
    await _prefs.setStringList('orders', ordersJson);
  }

  Future<List<app_order.Order>> _getLocalOrders() async {
    await initialize();
    final ordersJson = _prefs.getStringList('orders') ?? [];
    return ordersJson.map((json) => app_order.Order.fromJson(jsonDecode(json))).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      // Get order details first
      final order = await getOrder(orderId);
      
      // Delete from Firestore
      await _firestore.collection(_ordersCollection).doc(orderId).delete();
      
      // Delete from business orders index
      if (order != null) {
        await _firestore
            .collection(_businessOrdersCollection)
            .doc('${order.businessId}_$orderId')
            .delete();
      }
    } catch (e) {
      // Fallback to local storage
      await initialize();
      final orders = await _getLocalOrders();
      orders.removeWhere((o) => o.orderId == orderId);
      final ordersJson = orders.map((o) => jsonEncode(o.toJson())).toList();
      await _prefs.setStringList('orders', ordersJson);
    }
  }

  // Order creation from cart
  Future<app_order.Order> createOrderFromCart(
    Cart cart, {
    required String customerName,
    String? customerPhone,
    required int tableNumber,
    String? notes,
  }) async {
    final order = app_order.Order.fromCart(
      cart,
      customerName: customerName,
      customerPhone: customerPhone,
      tableNumber: tableNumber,
      notes: notes,
    );

    final orderId = await saveOrder(order);
    return order.copyWith(orderId: orderId);
  }

  // Order status management
  Future<void> updateOrderStatus(String orderId, app_order.OrderStatus status) async {
    final order = await getOrder(orderId);
    if (order != null) {
      app_order.Order updatedOrder;
      switch (status) {
        case app_order.OrderStatus.inProgress:
          updatedOrder = order.markAsInProgress();
          break;
        case app_order.OrderStatus.completed:
          updatedOrder = order.markAsCompleted();
          break;
        case app_order.OrderStatus.cancelled:
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
  Future<List<app_order.Order>> getPendingOrders(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('businessId', isEqualTo: businessId)
          .where('status', isEqualTo: app_order.OrderStatus.pending.value)
          .orderBy('createdAt', descending: false) // Oldest first for pending
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();
    } catch (e) {
      final orders = await getOrdersByBusinessId(businessId);
      return orders
          .where((order) => order.status == app_order.OrderStatus.pending)
          .toList();
    }
  }

  Future<List<app_order.Order>> getActiveOrders(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('businessId', isEqualTo: businessId)
          .where('status', whereIn: [
            app_order.OrderStatus.pending.value,
            app_order.OrderStatus.inProgress.value,
          ])
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();
    } catch (e) {
      final orders = await getOrdersByBusinessId(businessId);
      return orders.where((order) => order.isActive).toList();
    }
  }

  Future<List<app_order.Order>> getCompletedOrders(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('businessId', isEqualTo: businessId)
          .where('status', isEqualTo: app_order.OrderStatus.completed.value)
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit for performance
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();
    } catch (e) {
      final orders = await getOrdersByBusinessId(businessId);
      return orders
          .where((order) => order.status == app_order.OrderStatus.completed)
          .toList();
    }
  }

  Future<List<app_order.Order>> getTodaysOrders(String businessId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('businessId', isEqualTo: businessId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();
    } catch (e) {
      final orders = await getOrdersByBusinessId(businessId);
      final today = DateTime.now();
      return orders.where((order) {
        final orderDate = order.createdAt;
        return orderDate.year == today.year &&
            orderDate.month == today.month &&
            orderDate.day == today.day;
      }).toList();
    }
  }

  Future<List<app_order.Order>> getOrdersByTable(
    String businessId,
    int tableNumber,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('businessId', isEqualTo: businessId)
          .where('tableNumber', isEqualTo: tableNumber)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();
    } catch (e) {
      final orders = await getOrdersByBusinessId(businessId);
      return orders.where((order) => order.tableNumber == tableNumber).toList();
    }
  }

  Future<List<app_order.Order>> getOrdersByStatus(
    String businessId,
    app_order.OrderStatus status,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('businessId', isEqualTo: businessId)
          .where('status', isEqualTo: status.value)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();
    } catch (e) {
      final orders = await getOrdersByBusinessId(businessId);
      return orders.where((order) => order.status == status).toList();
    }
  }

  // Order statistics
  Future<Map<String, dynamic>> getOrderStatistics(String businessId) async {
    try {
      // Get today's orders for real-time stats
      final todaysOrders = await getTodaysOrders(businessId);
      final activeOrders = await getActiveOrders(businessId);
      final pendingOrders = await getPendingOrders(businessId);
      
      // Calculate stats
      final todaysRevenue = todaysOrders
          .where((order) => order.status == app_order.OrderStatus.completed)
          .fold(0.0, (sum, order) => sum + order.totalAmount);

      final averageOrderValue = todaysOrders.isNotEmpty
          ? todaysRevenue / todaysOrders.length
          : 0.0;

      return {
        'todaysOrders': todaysOrders.length,
        'activeOrders': activeOrders.length,
        'pendingOrders': pendingOrders.length,
        'todaysRevenue': todaysRevenue,
        'averageOrderValue': averageOrderValue,
      };
    } catch (e) {
      return {
        'todaysOrders': 0,
        'activeOrders': 0,
        'pendingOrders': 0,
        'todaysRevenue': 0.0,
        'averageOrderValue': 0.0,
      };
    }
  }

  // Order filtering and searching
  Future<List<app_order.Order>> searchOrders(String businessId, String query) async {
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

  Future<List<app_order.Order>> filterOrders(
    String businessId, {
    app_order.OrderStatus? status,
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

  // Real-time order notifications for businesses
  Stream<List<app_order.Order>> getOrderStream(String businessId) {
    return _firestore
        .collection(_ordersCollection)
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();
    });
  }

  // Get pending orders stream for real-time updates
  Stream<List<app_order.Order>> getPendingOrdersStream(String businessId) {
    return _firestore
        .collection(_ordersCollection)
        .where('businessId', isEqualTo: businessId)
        .where('status', isEqualTo: app_order.OrderStatus.pending.value)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return app_order.Order.fromJson(data, id: doc.id);
      }).toList();
    });
  }

  // Utility methods
  Future<void> clearAllOrders() async {
    await initialize();
    await _prefs.remove('orders');
    
    // Note: We don't clear Firestore orders as they should persist
    _orderListeners.clear();
    for (final stream in _orderStreams.values) {
      stream?.cancel();
    }
    _orderStreams.clear();
  }

  Future<void> dispose() async {
    _orderListeners.clear();
    for (final stream in _orderStreams.values) {
      stream?.cancel();
    }
    _orderStreams.clear();
  }


}

// Extension for easier null checking
extension on Iterable<app_order.Order> {
  app_order.Order? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
