import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../data/models/order.dart';
import '../../data/models/product.dart';
import '../../data/models/business.dart';

class RealtimeService {
  static const String _ordersKey = 'realtime_orders';
  static const String _notificationsKey = 'realtime_notifications';

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Singleton pattern
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  // Stream controllers
  final _ordersController = StreamController<List<Order>>.broadcast();
  final _orderStatusController =
      StreamController<OrderStatusUpdate>.broadcast();
  final _notificationsController =
      StreamController<RealtimeNotification>.broadcast();
  final _menuUpdatesController = StreamController<MenuUpdate>.broadcast();

  // Firestore subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};

  // Timer for fallback polling
  Timer? _updateTimer;
  bool _isActive = false;

  // Streams
  Stream<List<Order>> get ordersStream => _ordersController.stream;
  Stream<OrderStatusUpdate> get orderStatusStream =>
      _orderStatusController.stream;
  Stream<RealtimeNotification> get notificationsStream =>
      _notificationsController.stream;
  Stream<MenuUpdate> get menuUpdatesStream => _menuUpdatesController.stream;

  /// Gerçek zamanlı servisi başlat
  Future<void> startRealtimeService() async {
    if (_isActive) return;

    _isActive = true;
    debugPrint('Realtime service started');

    // Firebase realtime listeners'ı başlat
    await _initializeFirebaseListeners();

    // Fallback timer (Firebase bağlantısı yoksa)
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForUpdates();
    });

    // İlk veri yükleme
    await _loadInitialData();
  }

  /// Gerçek zamanlı servisi durdur
  Future<void> stopRealtimeService() async {
    if (!_isActive) return;

    _isActive = false;
    _updateTimer?.cancel();

    // Tüm Firebase subscriptions'ı iptal et
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    debugPrint('Realtime service stopped');
  }

  /// Firebase realtime listeners'ı initialize et
  Future<void> _initializeFirebaseListeners() async {
    try {
      // Sipariş değişikliklerini dinle
      _subscriptions['orders'] = _firestore
          .collection('orders')
          .snapshots()
          .listen((snapshot) {
            _handleOrdersSnapshot(snapshot);
          });

      // Menü güncellemelerini dinle
      _subscriptions['menu_updates'] = _firestore
          .collection('menu_updates')
          .snapshots()
          .listen((snapshot) {
            _handleMenuUpdatesSnapshot(snapshot);
          });

      // Bildirimleri dinle
      _subscriptions['notifications'] = _firestore
          .collection('notifications')
          .snapshots()
          .listen((snapshot) {
            _handleNotificationsSnapshot(snapshot);
          });
    } catch (e) {
      debugPrint('Firebase listeners initialization error: $e');
    }
  }

  /// Firebase orders snapshot handler
  void _handleOrdersSnapshot(QuerySnapshot snapshot) {
    try {
      final orders = snapshot.docs
          .map(
            (doc) => Order.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();

      _ordersController.add(orders);

      // Durum değişikliklerini kontrol et
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final order = Order.fromJson({
            ...change.doc.data() as Map<String, dynamic>,
            'id': change.doc.id,
          });
          _orderStatusController.add(
            OrderStatusUpdate(
              orderId: order.orderId,
              newStatus: order.status,
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Handle orders snapshot error: $e');
    }
  }

  /// Firebase menu updates snapshot handler
  void _handleMenuUpdatesSnapshot(QuerySnapshot snapshot) {
    try {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final update = MenuUpdate(
            businessId: data['businessId'] ?? '',
            updateType: data['updateType'] ?? '',
            details: data['details'] ?? '',
            timestamp:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
          _menuUpdatesController.add(update);
        }
      }
    } catch (e) {
      debugPrint('Handle menu updates snapshot error: $e');
    }
  }

  /// Firebase notifications snapshot handler
  void _handleNotificationsSnapshot(QuerySnapshot snapshot) {
    try {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final notification = RealtimeNotification(
            id: change.doc.id,
            title: data['title'] ?? '',
            message: data['message'] ?? '',
            type: NotificationType.values.firstWhere(
              (type) => type.name == data['type'],
              orElse: () => NotificationType.info,
            ),
            timestamp:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
          _notificationsController.add(notification);
        }
      }
    } catch (e) {
      debugPrint('Handle notifications snapshot error: $e');
    }
  }

  /// Sipariş durumu güncelle
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      // Firebase'de güncelle
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Yerel storage'ı da güncelle (fallback)
      await _updateOrderStatusLocally(orderId, newStatus);

      // Bildirim gönder
      await _sendNotification(
        RealtimeNotification(
          id: 'order_$orderId',
          title: 'Sipariş Durumu Güncellendi',
          message: 'Sipariş #$orderId durumu: ${newStatus.displayName}',
          type: NotificationType.orderUpdate,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Update order status error: $e');
      // Fallback to local update
      await _updateOrderStatusLocally(orderId, newStatus);
    }
  }

  /// Yeni sipariş ekle
  Future<void> addNewOrder(Order order) async {
    try {
      // Firebase'e ekle
      await _firestore
          .collection('orders')
          .doc(order.orderId)
          .set(order.toJson());

      // Yerel storage'a da ekle (fallback)
      await _addOrderLocally(order);

      // Yeni sipariş bildirimi
      await _sendNotification(
        RealtimeNotification(
          id: 'new_order_${order.orderId}',
          title: 'Yeni Sipariş',
          message: 'Yeni sipariş alındı: #${order.orderId}',
          type: NotificationType.newOrder,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Add new order error: $e');
      // Fallback to local storage
      await _addOrderLocally(order);
    }
  }

  /// Belirli işletme için siparişleri al
  Future<List<Order>> getOrdersForBusiness(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .get();

      return snapshot.docs
          .map((doc) => Order.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Get orders for business error: $e');
      // Fallback to local storage
      return await _getOrdersForBusinessLocally(businessId);
    }
  }

  /// Belirli işletme için siparişleri realtime dinle
  Stream<List<Order>> getOrdersStreamForBusiness(String businessId) {
    return _firestore
        .collection('orders')
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Order.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Müşteri siparişlerini al
  Future<List<Order>> getOrdersForCustomer(
    String businessId,
    String customerPhone,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('customerPhone', isEqualTo: customerPhone)
          .get();

      return snapshot.docs
          .map((doc) => Order.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Get orders for customer error: $e');
      // Fallback to local storage
      return await _getOrdersForCustomerLocally(businessId, customerPhone);
    }
  }

  /// Müşteri siparişlerini realtime dinle
  Stream<List<Order>> getOrdersStreamForCustomer(
    String businessId,
    String customerPhone,
  ) {
    return _firestore
        .collection('orders')
        .where('businessId', isEqualTo: businessId)
        .where('customerPhone', isEqualTo: customerPhone)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Order.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Menü güncelleme bildirimi gönder
  Future<void> notifyMenuUpdate(
    String businessId,
    String updateType,
    String details,
  ) async {
    try {
      // Firebase'e ekle
      await _firestore.collection('menu_updates').add({
        'businessId': businessId,
        'updateType': updateType,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Yerel bildirim gönder
      await _sendNotification(
        RealtimeNotification(
          id: 'menu_update_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Menü Güncellendi',
          message: details,
          type: NotificationType.menuUpdate,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Notify menu update error: $e');
    }
  }

  /// Canlı sipariş sayısını al
  Future<int> getLiveOrderCount(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      return snapshot.size;
    } catch (e) {
      debugPrint('Get live order count error: $e');
      // Fallback to local storage
      return await _getLiveOrderCountLocally(businessId);
    }
  }

  /// Canlı sipariş sayısını realtime dinle
  Stream<int> getLiveOrderCountStream(String businessId) {
    return _firestore
        .collection('orders')
        .where('businessId', isEqualTo: businessId)
        .where('status', whereIn: ['pending', 'in_progress'])
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Bildirim gönder
  Future<void> _sendNotification(RealtimeNotification notification) async {
    try {
      // Firebase'e ekle
      await _firestore.collection('notifications').add({
        'title': notification.title,
        'message': notification.message,
        'type': notification.type.name,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
      });

      // Yerel storage'a da ekle
      await _addNotificationLocally(notification);
    } catch (e) {
      debugPrint('Send notification error: $e');
      // Fallback to local storage
      await _addNotificationLocally(notification);
    }
  }

  /// Güncellemeleri kontrol et (fallback)
  Future<void> _checkForUpdates() async {
    if (!_isActive) return;

    try {
      // Firebase bağlantısı yoksa local polling yap
      await _checkOrderStatusChanges();
      await _simulateOrderUpdates();
    } catch (e) {
      debugPrint('Check for updates error: $e');
    }
  }

  /// İlk veri yükleme
  Future<void> _loadInitialData() async {
    try {
      // Demo veri oluştur
      await _createDemoOrders();
    } catch (e) {
      debugPrint('Load initial data error: $e');
    }
  }

  /// Demo siparişleri oluştur
  Future<void> _createDemoOrders() async {
    try {
      // Demo sipariş oluştur
      final demoOrder = Order(
        orderId: 'demo_order_${DateTime.now().millisecondsSinceEpoch}',
        businessId: 'demo-business-001',
        customerName: 'Demo Müşteri',
        customerPhone: '5551234567',
        tableNumber: 1,
        items: [],
        totalAmount: 45.0,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await addNewOrder(demoOrder);
    } catch (e) {
      debugPrint('Create demo orders error: $e');
    }
  }

  // Local storage fallback methods
  Future<void> _updateOrderStatusLocally(
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString(_ordersKey) ?? '[]';
      final List<dynamic> ordersData = jsonDecode(ordersJson);

      for (int i = 0; i < ordersData.length; i++) {
        if (ordersData[i]['orderId'] == orderId) {
          ordersData[i]['status'] = newStatus.name;
          ordersData[i]['updatedAt'] = DateTime.now().toIso8601String();
          break;
        }
      }

      await prefs.setString(_ordersKey, jsonEncode(ordersData));
      await _broadcastOrderUpdates();
    } catch (e) {
      debugPrint('Update order status locally error: $e');
    }
  }

  Future<void> _addOrderLocally(Order order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString(_ordersKey) ?? '[]';
      final List<dynamic> ordersData = jsonDecode(ordersJson);

      ordersData.add(order.toJson());
      await prefs.setString(_ordersKey, jsonEncode(ordersData));
      await _broadcastOrderUpdates();
    } catch (e) {
      debugPrint('Add order locally error: $e');
    }
  }

  Future<List<Order>> _getOrdersForBusinessLocally(String businessId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString(_ordersKey) ?? '[]';
      final List<dynamic> ordersData = jsonDecode(ordersJson);

      return ordersData
          .where((orderData) => orderData['businessId'] == businessId)
          .map((orderData) => Order.fromJson(orderData))
          .toList();
    } catch (e) {
      debugPrint('Get orders for business locally error: $e');
      return [];
    }
  }

  Future<List<Order>> _getOrdersForCustomerLocally(
    String businessId,
    String customerPhone,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString(_ordersKey) ?? '[]';
      final List<dynamic> ordersData = jsonDecode(ordersJson);

      return ordersData
          .where(
            (orderData) =>
                orderData['businessId'] == businessId &&
                orderData['customerPhone'] == customerPhone,
          )
          .map((orderData) => Order.fromJson(orderData))
          .toList();
    } catch (e) {
      debugPrint('Get orders for customer locally error: $e');
      return [];
    }
  }

  Future<int> _getLiveOrderCountLocally(String businessId) async {
    try {
      final orders = await _getOrdersForBusinessLocally(businessId);
      return orders
          .where(
            (order) =>
                order.status == OrderStatus.pending ||
                order.status == OrderStatus.inProgress,
          )
          .length;
    } catch (e) {
      debugPrint('Get live order count locally error: $e');
      return 0;
    }
  }

  Future<void> _addNotificationLocally(
    RealtimeNotification notification,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_notificationsKey) ?? '[]';
      final List<dynamic> notificationsData = jsonDecode(notificationsJson);

      notificationsData.add({
        'id': notification.id,
        'title': notification.title,
        'message': notification.message,
        'type': notification.type.name,
        'timestamp': notification.timestamp.toIso8601String(),
      });

      await prefs.setString(_notificationsKey, jsonEncode(notificationsData));
      _notificationsController.add(notification);
    } catch (e) {
      debugPrint('Add notification locally error: $e');
    }
  }

  Future<void> _broadcastOrderUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString(_ordersKey) ?? '[]';
      final List<dynamic> ordersData = jsonDecode(ordersJson);

      final orders = ordersData
          .map((orderData) => Order.fromJson(orderData))
          .toList();
      _ordersController.add(orders);
    } catch (e) {
      debugPrint('Broadcast order updates error: $e');
    }
  }

  Future<void> _checkOrderStatusChanges() async {
    // Placeholder for local status checking
  }

  Future<void> _simulateOrderUpdates() async {
    // Placeholder for simulated updates
  }

  /// Dispose resources
  void dispose() {
    _ordersController.close();
    _orderStatusController.close();
    _notificationsController.close();
    _menuUpdatesController.close();

    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _updateTimer?.cancel();
  }
}

/// Sipariş durumu güncelleme bilgisi
class OrderStatusUpdate {
  final String orderId;
  final OrderStatus newStatus;
  final DateTime timestamp;

  OrderStatusUpdate({
    required this.orderId,
    required this.newStatus,
    required this.timestamp,
  });
}

/// Realtime bildirim
class RealtimeNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;

  RealtimeNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

/// Bildirim türü
enum NotificationType {
  newOrder,
  orderUpdate,
  menuUpdate,
  info,
  warning,
  error,
}

/// Menü güncelleme bilgisi
class MenuUpdate {
  final String businessId;
  final String updateType;
  final String details;
  final DateTime timestamp;

  MenuUpdate({
    required this.businessId,
    required this.updateType,
    required this.details,
    required this.timestamp,
  });
}

/// Sipariş durumu extension
extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Beklemede';
      case OrderStatus.inProgress:
        return 'Hazırlanıyor';
      case OrderStatus.completed:
        return 'Tamamlandı';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
      default:
        return value;
    }
  }
}
