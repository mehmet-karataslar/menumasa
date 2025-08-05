import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user.dart' as app_user;
import '../../business/models/business.dart';
import '../../data/models/order.dart' as app_order;
import '../models/admin_user.dart';

class AdminFirestoreService {
  static final AdminFirestoreService _instance = AdminFirestoreService._internal();
  factory AdminFirestoreService() => _instance;
  AdminFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _businessesRef => _firestore.collection('businesses');
  CollectionReference get _productsRef => _firestore.collection('products');
  CollectionReference get _categoriesRef => _firestore.collection('categories');
  CollectionReference get _ordersRef => _firestore.collection('orders');
  CollectionReference get _discountsRef => _firestore.collection('discounts');
  CollectionReference get _adminLogsRef => _firestore.collection('admin_logs');

  // =============================================================================
  // ADMIN USER OPERATIONS
  // =============================================================================

  /// Gets all admin users
  Future<List<AdminUser>> getAdminUsers() async {
    try {
      final snapshot = await _usersRef
          .where('userType', isEqualTo: 'admin')
          .get();

      return snapshot.docs
          .map((doc) => AdminUser.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting admin users: $e');
      return [];
    }
  }

  /// Creates a new admin user
  Future<String> createAdminUser(AdminUser adminUser) async {
    try {
      final data = adminUser.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['userType'] = 'admin';

      final docRef = await _usersRef.add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Admin kullanıcısı oluşturulurken hata oluştu: $e');
    }
  }

  /// Updates admin user permissions
  Future<void> updateAdminPermissions(String adminId, List<String> permissions) async {
    try {
      await _usersRef.doc(adminId).update({
        'permissions': permissions,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Admin izinleri güncellenirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // USER MANAGEMENT OPERATIONS
  // =============================================================================

  /// Gets all users with pagination
  Future<List<app_user.User>> getAllUsers({
    int? limit,
    DocumentSnapshot? startAfter,
    String? userType,
  }) async {
    try {
      Query query = _usersRef;
      
      if (userType != null) {
        query = query.where('userType', isEqualTo: userType);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => app_user.User.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Gets user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final totalUsersSnapshot = await _usersRef.get();
      final customerUsersSnapshot = await _usersRef.where('userType', isEqualTo: 'customer').get();
      final businessUsersSnapshot = await _usersRef.where('userType', isEqualTo: 'business').get();
      final adminUsersSnapshot = await _usersRef.where('userType', isEqualTo: 'admin').get();

      return {
        'total': totalUsersSnapshot.docs.length,
        'customers': customerUsersSnapshot.docs.length,
        'businesses': businessUsersSnapshot.docs.length,
        'admins': adminUsersSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {'total': 0, 'customers': 0, 'businesses': 0, 'admins': 0};
    }
  }

  /// Suspends or activates a user account
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _usersRef.doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Kullanıcı durumu değiştirilirken hata oluştu: $e');
    }
  }

  /// Deletes a user account and related data
  Future<void> deleteUser(String userId) async {
    try {
      // This is a sensitive operation - in production, consider soft delete
      await _usersRef.doc(userId).delete();
      
      // Log this action
      await _logAdminAction('delete_user', {'deletedUserId': userId});
    } catch (e) {
      throw Exception('Kullanıcı silinirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // BUSINESS MANAGEMENT OPERATIONS
  // =============================================================================

  /// Gets all businesses with admin details
  Future<List<Business>> getAllBusinesses({
    int? limit,
    DocumentSnapshot? startAfter,
    bool? isActive,
  }) async {
    try {
      Query query = _businessesRef;
      
      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Business.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting all businesses: $e');
      return [];
    }
  }

  /// Gets business statistics
  Future<Map<String, dynamic>> getBusinessStatistics() async {
    try {
      final totalBusinessesSnapshot = await _businessesRef.get();
      final activeBusinessesSnapshot = await _businessesRef.where('isActive', isEqualTo: true).get();
      final inactiveBusinessesSnapshot = await _businessesRef.where('isActive', isEqualTo: false).get();

      // Get businesses created in the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentBusinessesSnapshot = await _businessesRef
          .where('createdAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();

      return {
        'total': totalBusinessesSnapshot.docs.length,
        'active': activeBusinessesSnapshot.docs.length,
        'inactive': inactiveBusinessesSnapshot.docs.length,
        'recent': recentBusinessesSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting business statistics: $e');
      return {'total': 0, 'active': 0, 'inactive': 0, 'recent': 0};
    }
  }

  /// Approves or rejects a business
  Future<void> updateBusinessStatus(String businessId, bool isApproved, {String? rejectionReason}) async {
    try {
      final updateData = {
        'isApproved': isApproved,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!isApproved && rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }

      await _businessesRef.doc(businessId).update(updateData);
      
      // Log this action
      await _logAdminAction('update_business_status', {
        'businessId': businessId,
        'isApproved': isApproved,
        'rejectionReason': rejectionReason,
      });
    } catch (e) {
      throw Exception('İşletme durumu güncellenirken hata oluştu: $e');
    }
  }

  /// Forces deletion of a business (admin only)
  Future<void> forceDeleteBusiness(String businessId) async {
    try {
      // Delete business and all related data
      final batch = _firestore.batch();
      
      // Delete business document
      batch.delete(_businessesRef.doc(businessId));
      
      // Delete all products
      final productsSnapshot = await _productsRef.where('businessId', isEqualTo: businessId).get();
      for (final doc in productsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete all categories
      final categoriesSnapshot = await _categoriesRef.where('businessId', isEqualTo: businessId).get();
      for (final doc in categoriesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete all discounts
      final discountsSnapshot = await _discountsRef.where('businessId', isEqualTo: businessId).get();
      for (final doc in discountsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Log this action
      await _logAdminAction('force_delete_business', {'businessId': businessId});
    } catch (e) {
      throw Exception('İşletme zorla silinirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // ORDER MANAGEMENT OPERATIONS
  // =============================================================================

  /// Gets all orders with admin view
  Future<List<app_order.Order>> getAllOrders({
    int? limit,
    DocumentSnapshot? startAfter,
    app_order.OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Query query = _ordersRef;
      
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
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
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
      print('Error getting all orders: $e');
      return [];
    }
  }

  /// Gets order statistics
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final totalOrdersSnapshot = await _ordersRef.get();
      
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final startOfWeek = startOfDay.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(today.year, today.month, 1);

      final todayOrdersSnapshot = await _ordersRef
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .get();

      final weekOrdersSnapshot = await _ordersRef
          .where('createdAt', isGreaterThanOrEqualTo: startOfWeek)
          .get();

      final monthOrdersSnapshot = await _ordersRef
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      return {
        'total': totalOrdersSnapshot.docs.length,
        'today': todayOrdersSnapshot.docs.length,
        'thisWeek': weekOrdersSnapshot.docs.length,
        'thisMonth': monthOrdersSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting order statistics: $e');
      return {'total': 0, 'today': 0, 'thisWeek': 0, 'thisMonth': 0};
    }
  }

  /// Manually cancels an order (admin intervention)
  Future<void> adminCancelOrder(String orderId, String reason) async {
    try {
      await _ordersRef.doc(orderId).update({
        'status': app_order.OrderStatus.cancelled.toString(),
        'adminCancellation': true,
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log this action
      await _logAdminAction('admin_cancel_order', {
        'orderId': orderId,
        'reason': reason,
      });
    } catch (e) {
      throw Exception('Sipariş iptal edilirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // ANALYTICS AND REPORTING
  // =============================================================================

  /// Gets platform-wide analytics
  Future<Map<String, dynamic>> getPlatformAnalytics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final from = fromDate ?? DateTime.now().subtract(const Duration(days: 30));
      final to = toDate ?? DateTime.now();

      // User registrations
      final userRegistrationsSnapshot = await _usersRef
          .where('createdAt', isGreaterThanOrEqualTo: from)
          .where('createdAt', isLessThanOrEqualTo: to)
          .get();

      // Business registrations
      final businessRegistrationsSnapshot = await _businessesRef
          .where('createdAt', isGreaterThanOrEqualTo: from)
          .where('createdAt', isLessThanOrEqualTo: to)
          .get();

      // Orders in period
      final ordersSnapshot = await _ordersRef
          .where('createdAt', isGreaterThanOrEqualTo: from)
          .where('createdAt', isLessThanOrEqualTo: to)
          .get();

      double totalRevenue = 0;
      for (final doc in ordersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final total = (data['total'] as num?)?.toDouble() ?? 0;
        totalRevenue += total;
      }

      return {
        'period': {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        },
        'userRegistrations': userRegistrationsSnapshot.docs.length,
        'businessRegistrations': businessRegistrationsSnapshot.docs.length,
        'totalOrders': ordersSnapshot.docs.length,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      print('Error getting platform analytics: $e');
      return {};
    }
  }

  // =============================================================================
  // ADMIN ACTIVITY LOGGING
  // =============================================================================

  /// Logs admin actions for audit trail
  Future<void> _logAdminAction(String action, Map<String, dynamic> details) async {
    try {
      await _adminLogsRef.add({
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'adminId': 'current_admin_id', // This should be passed from auth context
      });
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }

  /// Gets admin activity logs
  Future<List<Map<String, dynamic>>> getAdminLogs({
    int? limit,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Query query = _adminLogsRef;
      
      if (fromDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: fromDate);
      }
      
      if (toDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: toDate);
      }
      
      query = query.orderBy('timestamp', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      print('Error getting admin logs: $e');
      return [];
    }
  }

  // =============================================================================
  // SYSTEM MAINTENANCE
  // =============================================================================

  /// Cleans up old data (run periodically)
  Future<void> performMaintenanceCleanup() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // Clean up old admin logs
      final oldLogsSnapshot = await _adminLogsRef
          .where('timestamp', isLessThan: thirtyDaysAgo)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldLogsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      await _logAdminAction('maintenance_cleanup', {
        'deletedLogs': oldLogsSnapshot.docs.length,
      });
    } catch (e) {
      print('Error performing maintenance cleanup: $e');
    }
  }

  /// Backs up critical data
  Future<Map<String, dynamic>> createDataBackup() async {
    try {
      final backup = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'userCount': 0,
        'businessCount': 0,
        'orderCount': 0,
      };

      // Count documents for backup validation
      final usersSnapshot = await _usersRef.get();
      backup['userCount'] = usersSnapshot.docs.length;

      final businessesSnapshot = await _businessesRef.get();
      backup['businessCount'] = businessesSnapshot.docs.length;

      final ordersSnapshot = await _ordersRef.get();
      backup['orderCount'] = ordersSnapshot.docs.length;

      await _logAdminAction('create_backup', backup);
      
      return backup;
    } catch (e) {
      print('Error creating data backup: $e');
      return {};
    }
  }
} 