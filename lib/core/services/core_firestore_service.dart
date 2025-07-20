import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/order.dart' as app_order;
import 'notification_service.dart';

class CoreFirestoreService {
  static final CoreFirestoreService _instance = CoreFirestoreService._internal();
  factory CoreFirestoreService() => _instance;
  CoreFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Public getter for Firestore instance
  FirebaseFirestore get firestore => _firestore;

  // Collection references
  CollectionReference get _ordersRef => _firestore.collection('orders');

  // =============================================================================
  // DATABASE INITIALIZATION
  // =============================================================================

  /// Initialize database with collections if they don't exist
  Future<void> initializeDatabase() async {
    try {
      // Check if collections exist and create them if needed
      // We don't need to explicitly create collections in Firestore
      // They are created automatically when documents are added

      // However, we can add some security rules programmatically if needed
      // For now, let's just print confirmation
      print('Database initialization successful');
    } catch (e) {
      print('Error initializing database: $e');
      throw Exception('Database initialization failed: $e');
    }
  }

  // =============================================================================
  // SHARED ORDER OPERATIONS
  // =============================================================================

  /// Gets a specific order (shared across modules)
  Future<app_order.Order?> getOrder(String orderId) async {
    try {
      final doc = await _ordersRef.doc(orderId).get();
      if (doc.exists) {
        return app_order.Order.fromJson(
          doc.data() as Map<String, dynamic>,
          id: doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  /// Saves or updates an order (shared across modules)
  Future<String> saveOrder(app_order.Order order) async {
    try {
      final data = order.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Check if this is a new order (empty ID or temporary ID starting with 'order_')
      if (order.id.isEmpty || order.id.startsWith('order_')) {
        // New order - create a new document
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _ordersRef.add(data);
        return docRef.id;
      } else {
        // Update existing order - check if document exists first
        final docSnapshot = await _ordersRef.doc(order.id).get();
        if (docSnapshot.exists) {
          await _ordersRef.doc(order.id).update(data);
          return order.id;
        } else {
          // Document doesn't exist, create new one
          data['createdAt'] = FieldValue.serverTimestamp();
          final docRef = await _ordersRef.add(data);
          return docRef.id;
        }
      }
    } catch (e) {
      throw Exception('Sipariş kaydedilirken hata oluştu: $e');
    }
  }

  /// Deletes an order (admin only)
  Future<void> deleteOrder(String orderId) async {
    try {
      await _ordersRef.doc(orderId).delete();
    } catch (e) {
      throw Exception('Sipariş silinirken hata oluştu: $e');
    }
  }

  /// Updates order status with optional notification
  Future<void> updateOrderStatus(String orderId, app_order.OrderStatus status) async {
    try {
      // Check if document exists first
      final docSnapshot = await _ordersRef.doc(orderId).get();
      if (!docSnapshot.exists) {
        throw Exception('Sipariş bulunamadı: $orderId');
      }

      await _ordersRef.doc(orderId).update({
        'status': status.value, // Use .value instead of .toString()
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification based on status
      final order = await getOrder(orderId);
      if (order != null) {
        await _sendOrderStatusNotification(order, status);
      }
    } catch (e) {
      throw Exception('Sipariş durumu güncellenirken hata oluştu: $e');
    }
  }

  /// Creates an order with automatic notification
  Future<String> createOrderWithNotification(app_order.Order order) async {
    try {
      final orderId = await saveOrder(order);
      
      // Send notification to business
      final notificationService = NotificationService();
      
      await notificationService.sendOrderNotification(
        businessId: order.businessId,
        customerId: order.customerId,
        title: 'Yeni Sipariş',
        message: '${order.customerName} - Masa ${order.tableNumber} (${order.total.toStringAsFixed(2)}₺)',
        orderId: orderId,
      );

      return orderId;
    } catch (e) {
      throw Exception('Sipariş oluşturulurken hata oluştu: $e');
    }
  }

  /// Gets orders with flexible filtering (shared utility)
  Future<List<app_order.Order>> getOrders({
    String? businessId,
    String? customerId,
    app_order.OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    try {
      Query query = _ordersRef;
      
      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      }
      
      if (customerId != null) {
        query = query.where('customerId', isEqualTo: customerId);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.toString());
      }
      
      if (fromDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: fromDate);
      }
      
      if (toDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: toDate);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => app_order.Order.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting orders: $e');
      return [];
    }
  }

  // =============================================================================
  // NOTIFICATION HELPERS (PRIVATE)
  // =============================================================================

  /// Sends notification based on order status change
  Future<void> _sendOrderStatusNotification(app_order.Order order, app_order.OrderStatus status) async {
    try {
      final notificationService = NotificationService();
      
      switch (status) {
        case app_order.OrderStatus.confirmed:
          await notificationService.sendOrderConfirmationNotification(
            order.customerId,
            order.id,
          );
          break;
        case app_order.OrderStatus.preparing:
          await notificationService.sendOrderPreparingNotification(
            order.customerId,
            order.id,
          );
          break;
        case app_order.OrderStatus.ready:
          await notificationService.sendOrderReadyNotification(
            order.customerId,
            order.id,
          );
          break;
        case app_order.OrderStatus.delivered:
          await notificationService.sendOrderDeliveredNotification(
            order.customerId,
            order.id,
          );
          break;
        case app_order.OrderStatus.cancelled:
          await notificationService.sendOrderCancelledNotification(
            order.customerId,
            order.id,
          );
          break;
        default:
          // No notification for pending status
          break;
      }
    } catch (e) {
      print('Error sending order status notification: $e');
      // Don't throw error for notification failures
    }
  }

  // =============================================================================
  // BATCH OPERATIONS (SHARED UTILITIES)
  // =============================================================================

  /// Creates a new batch for atomic operations
  WriteBatch createBatch() {
    return _firestore.batch();
  }

  /// Gets a document reference for batch operations
  DocumentReference getDocumentReference(String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId);
  }

  /// Gets a collection reference for queries
  CollectionReference getCollectionReference(String collection) {
    return _firestore.collection(collection);
  }

  // =============================================================================
  // TRANSACTION HELPERS
  // =============================================================================

  /// Executes a transaction with retry logic
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await _firestore.runTransaction<T>(
        updateFunction,
        timeout: timeout,
      );
    } catch (e) {
      throw Exception('Transaction failed: $e');
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Converts Firestore Timestamp to DateTime
  DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is DateTime) {
      return timestamp;
    }
    return null;
  }

  /// Creates a server timestamp field value
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Creates an array union field value
  FieldValue arrayUnion(List<dynamic> elements) => FieldValue.arrayUnion(elements);

  /// Creates an array remove field value
  FieldValue arrayRemove(List<dynamic> elements) => FieldValue.arrayRemove(elements);

  /// Creates an increment field value
  FieldValue increment(num value) => FieldValue.increment(value);

  // =============================================================================
  // CONNECTION AND STATUS
  // =============================================================================

  /// Checks if Firestore is available
  Future<bool> isFirestoreAvailable() async {
    try {
      // Try to read from a system collection
      await _firestore.collection('_health_check').limit(1).get();
      return true;
    } catch (e) {
      print('Firestore availability check failed: $e');
      return false;
    }
  }

  /// Enables offline persistence (call during app initialization)
  Future<void> enableOfflinePersistence() async {
    try {
      await _firestore.enablePersistence();
      print('Offline persistence enabled');
    } catch (e) {
      print('Failed to enable offline persistence: $e');
      // Don't throw error as this might not be supported on all platforms
    }
  }

  /// Disables network access (for testing offline functionality)
  Future<void> disableNetwork() async {
    try {
      await _firestore.disableNetwork();
    } catch (e) {
      print('Failed to disable network: $e');
    }
  }

  /// Enables network access
  Future<void> enableNetwork() async {
    try {
      await _firestore.enableNetwork();
    } catch (e) {
      print('Failed to enable network: $e');
    }
  }

  // =============================================================================
  // CLEANUP AND DISPOSAL
  // =============================================================================

  /// Terminates the Firestore instance
  Future<void> terminate() async {
    try {
      await _firestore.terminate();
    } catch (e) {
      print('Error terminating Firestore: $e');
    }
  }

  /// Clears persistence data
  Future<void> clearPersistence() async {
    try {
      await _firestore.clearPersistence();
    } catch (e) {
      print('Error clearing persistence: $e');
    }
  }
} 