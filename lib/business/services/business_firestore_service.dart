import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/discount.dart';
import '../../data/models/order.dart' as app_order;
import 'dart:async';

class BusinessFirestoreService {
  static final BusinessFirestoreService _instance = BusinessFirestoreService._internal();
  factory BusinessFirestoreService() => _instance;
  BusinessFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _businessesRef => _firestore.collection('businesses');
  CollectionReference get _productsRef => _firestore.collection('products');
  CollectionReference get _categoriesRef => _firestore.collection('categories');
  CollectionReference get _ordersRef => _firestore.collection('orders');
  CollectionReference get _discountsRef => _firestore.collection('discounts');

  // Real-time order listeners for businesses
  final Map<String, StreamSubscription<QuerySnapshot>?> _orderStreams = {};
  final Map<String, List<Function(List<app_order.Order>)>> _orderListeners = {};

  // =============================================================================
  // BUSINESS OPERATIONS
  // =============================================================================

  /// Gets all businesses (admin view) or by owner ID
  Future<List<Business>> getBusinesses({String? ownerId}) async {
    try {
      Query query = _businessesRef;
      
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Business.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting businesses: $e');
      return [];
    }
  }

  /// Gets businesses by owner ID
  Future<List<Business>> getBusinessesByOwnerId(String ownerId) async {
    try {
      final snapshot = await _businessesRef
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return snapshot.docs
          .map((doc) => Business.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting businesses by owner: $e');
      return [];
    }
  }

  /// Gets a specific business
  Future<Business?> getBusiness(String businessId) async {
    try {
      final doc = await _businessesRef.doc(businessId).get();
      if (doc.exists) {
        return Business.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('Error getting business: $e');
      return null;
    }
  }

  /// Saves or updates a business
  Future<String> saveBusiness(Business business) async {
    try {
      final data = business.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (business.id.isEmpty) {
        // New business
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _businessesRef.add(data);
        return docRef.id;
      } else {
        // Update existing business
        await _businessesRef.doc(business.id).update(data);
        return business.id;
      }
    } catch (e) {
      throw Exception('İşletme kaydedilirken hata oluştu: $e');
    }
  }

  /// Deletes a business and all its related data
  Future<void> deleteBusiness(String businessId) async {
    try {
      // Start a batch to delete all related data
      final batch = _firestore.batch();
      
      // Delete business document
      batch.delete(_businessesRef.doc(businessId));
      
      // Delete all products of this business
      await _deleteProductsByBusiness(businessId);
      
      // Delete all categories of this business
      await _deleteCategoriesByBusiness(businessId);
      
      // Delete all discounts of this business
      await _deleteDiscountsByBusiness(businessId);
      
      // Note: We don't delete orders as they are historical data
      // but we could mark them as archived
      
      await batch.commit();
    } catch (e) {
      throw Exception('İşletme silinirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // PRODUCT OPERATIONS
  // =============================================================================

  /// Gets products with various filters
  Future<List<Product>> getProducts({
    String? businessId,
    String? categoryId,
    int? limit,
  }) async {
    try {
      Query query = _productsRef;
      
      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      }
      
      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Product.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  /// Gets products for a specific business
  Future<List<Product>> getBusinessProducts(
    String businessId, {
    int? limit,
  }) async {
    try {
      Query query = _productsRef.where('businessId', isEqualTo: businessId);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Product.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting business products: $e');
      return [];
    }
  }

  /// Gets a specific product
  Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _productsRef.doc(productId).get();
      if (doc.exists) {
        return Product.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  /// Saves or updates a product
  Future<String> saveProduct(Product product) async {
    try {
      final data = product.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (product.id.isEmpty) {
        // New product
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _productsRef.add(data);
        return docRef.id;
      } else {
        // Update existing product
        await _productsRef.doc(product.id).update(data);
        return product.id;
      }
    } catch (e) {
      throw Exception('Ürün kaydedilirken hata oluştu: $e');
    }
  }

  /// Deletes a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsRef.doc(productId).delete();
    } catch (e) {
      throw Exception('Ürün silinirken hata oluştu: $e');
    }
  }

  /// Deletes all products of a business (private helper)
  Future<void> _deleteProductsByBusiness(String businessId) async {
    final snapshot = await _productsRef
        .where('businessId', isEqualTo: businessId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // =============================================================================
  // CATEGORY OPERATIONS
  // =============================================================================

  /// Gets categories with optional business filter
  Future<List<Category>> getCategories({
    String? businessId,
    int? limit,
  }) async {
    try {
      Query query = _categoriesRef;
      
      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Category.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  /// Gets categories for a specific business
  Future<List<Category>> getBusinessCategories(String businessId) async {
    try {
      final snapshot = await _categoriesRef
          .where('businessId', isEqualTo: businessId)
          .get();

      return snapshot.docs
          .map((doc) => Category.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error getting business categories: $e');
      return [];
    }
  }

  /// Gets a specific category
  Future<Category?> getCategory(String categoryId) async {
    try {
      final doc = await _categoriesRef.doc(categoryId).get();
      if (doc.exists) {
        return Category.fromJson(
          doc.data() as Map<String, dynamic>,
          id: doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }

  /// Saves or updates a category
  Future<String> saveCategory(Category category) async {
    try {
      final data = category.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (category.id.isEmpty) {
        // New category
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _categoriesRef.add(data);
        return docRef.id;
      } else {
        // Update existing category
        await _categoriesRef.doc(category.id).update(data);
        return category.id;
      }
    } catch (e) {
      throw Exception('Kategori kaydedilirken hata oluştu: $e');
    }
  }

  /// Deletes a category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoriesRef.doc(categoryId).delete();
    } catch (e) {
      throw Exception('Kategori silinirken hata oluştu: $e');
    }
  }

  /// Deletes all categories of a business (private helper)
  Future<void> _deleteCategoriesByBusiness(String businessId) async {
    final snapshot = await _categoriesRef
        .where('businessId', isEqualTo: businessId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // =============================================================================
  // DISCOUNT OPERATIONS
  // =============================================================================

  /// Gets discounts with optional business filter
  Future<List<Discount>> getDiscounts({String? businessId}) async {
    try {
      Query query = _discountsRef;
      
      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Discount.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'discountId': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting discounts: $e');
      return [];
    }
  }

  /// Gets discounts by business ID
  Future<List<Discount>> getDiscountsByBusinessId(String businessId) async {
    try {
      final snapshot = await _discountsRef
          .where('businessId', isEqualTo: businessId)
          .get();

      return snapshot.docs
          .map((doc) => Discount.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'discountId': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting discounts by business ID: $e');
      return [];
    }
  }

  /// Gets a specific discount
  Future<Discount?> getDiscount(String discountId) async {
    try {
      final doc = await _discountsRef.doc(discountId).get();
      if (doc.exists) {
        return Discount.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'discountId': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('Error getting discount: $e');
      return null;
    }
  }

  /// Saves or updates a discount
  Future<String> saveDiscount(Discount discount) async {
    try {
      final data = discount.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (discount.discountId.isEmpty) {
        // New discount
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _discountsRef.add(data);
        return docRef.id;
      } else {
        // Update existing discount
        await _discountsRef.doc(discount.discountId).update(data);
        return discount.discountId;
      }
    } catch (e) {
      throw Exception('İndirim kaydedilirken hata oluştu: $e');
    }
  }

  /// Deletes a discount
  Future<void> deleteDiscount(String discountId) async {
    try {
      await _discountsRef.doc(discountId).delete();
    } catch (e) {
      throw Exception('İndirim silinirken hata oluştu: $e');
    }
  }

  /// Deletes all discounts of a business (private helper)
  Future<void> _deleteDiscountsByBusiness(String businessId) async {
    final snapshot = await _discountsRef
        .where('businessId', isEqualTo: businessId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Gets active discounts for a business
  Future<List<Discount>> getActiveDiscounts(String businessId) async {
    try {
      final discounts = await getDiscountsByBusinessId(businessId);
      return discounts.where((d) => d.isCurrentlyActive).toList();
    } catch (e) {
      print('Error getting active discounts: $e');
      return [];
    }
  }

  /// Gets discounts applicable to a specific product
  Future<List<Discount>> getDiscountsForProduct(
    String businessId,
    String productId,
    String categoryId,
  ) async {
    try {
      final discounts = await getActiveDiscounts(businessId);
      return discounts
          .where((d) => d.appliesToProduct(productId, categoryId))
          .toList();
    } catch (e) {
      print('Error getting discounts for product: $e');
      return [];
    }
  }

  /// Increments usage count for a discount
  Future<void> incrementDiscountUsage(String discountId) async {
    try {
      final doc = await _discountsRef.doc(discountId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final currentUsage = data['usageCount'] ?? 0;
        
        await _discountsRef.doc(discountId).update({
          'usageCount': currentUsage + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error incrementing discount usage: $e');
    }
  }

  // =============================================================================
  // ORDER MANAGEMENT OPERATIONS
  // =============================================================================

  /// Gets orders for a business
  Future<List<app_order.Order>> getBusinessOrders(
    String businessId, {
    app_order.OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    try {
      Query query = _ordersRef.where('businessId', isEqualTo: businessId);
      
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
      print('Error getting business orders: $e');
      return [];
    }
  }

  /// Gets orders by business ID (simpler version)
  Future<List<app_order.Order>> getOrdersByBusiness(String businessId) async {
    try {
      final snapshot = await _ordersRef
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => app_order.Order.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error getting orders by business: $e');
      return [];
    }
  }

  /// Gets orders by business and customer phone
  Future<List<app_order.Order>> getOrdersByBusinessAndPhone(String businessId, String customerPhone) async {
    try {
      final snapshot = await _ordersRef
          .where('businessId', isEqualTo: businessId)
          .where('customerPhone', isEqualTo: customerPhone)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => app_order.Order.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error getting orders by business and phone: $e');
      return [];
    }
  }

  /// Updates order status
  Future<void> updateOrderStatus(String orderId, app_order.OrderStatus status) async {
    try {
      // Check if document exists first
      final docSnapshot = await _ordersRef.doc(orderId).get();
      if (!docSnapshot.exists) {
        throw Exception('Sipariş bulunamadı: $orderId');
      }

      await _ordersRef.doc(orderId).update({
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Sipariş durumu güncellenirken hata oluştu: $e');
    }
  }

  /// Gets daily order statistics for a business
  Future<Map<String, int>> getDailyOrderStats(String businessId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _ordersRef
          .where('businessId', isEqualTo: businessId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .get();

      final orders = snapshot.docs
          .map((doc) => app_order.Order.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();

      final stats = <String, int>{
        'total': orders.length,
        'pending': 0,
        'confirmed': 0,
        'preparing': 0,
        'ready': 0,
        'delivered': 0,
        'cancelled': 0,
      };

      for (final order in orders) {
        switch (order.status) {
          case app_order.OrderStatus.pending:
            stats['pending'] = (stats['pending'] ?? 0) + 1;
            break;
          case app_order.OrderStatus.confirmed:
            stats['confirmed'] = (stats['confirmed'] ?? 0) + 1;
            break;
          case app_order.OrderStatus.preparing:
            stats['preparing'] = (stats['preparing'] ?? 0) + 1;
            break;
          case app_order.OrderStatus.ready:
            stats['ready'] = (stats['ready'] ?? 0) + 1;
            break;
          case app_order.OrderStatus.delivered:
            stats['delivered'] = (stats['delivered'] ?? 0) + 1;
            break;
          case app_order.OrderStatus.inProgress:
            stats['inProgress'] = (stats['inProgress'] ?? 0) + 1;
            break;
          case app_order.OrderStatus.completed:
            stats['completed'] = (stats['completed'] ?? 0) + 1;
            break;
          case app_order.OrderStatus.cancelled:
            stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting daily order stats: $e');
      return {'total': 0};
    }
  }

  // =============================================================================
  // REAL-TIME ORDER LISTENERS
  // =============================================================================

  /// Starts listening to real-time order updates for a business
  void startOrderListener(String businessId, Function(List<app_order.Order>) onOrdersUpdated) {
    // Cancel existing listener if any
    stopOrderListener(businessId);

    final stream = _ordersRef
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    _orderStreams[businessId] = stream.listen((snapshot) {
      final orders = snapshot.docs
          .map((doc) => app_order.Order.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();

      // Notify all listeners for this business
      final listeners = _orderListeners[businessId] ?? [];
      for (final listener in listeners) {
        listener(orders);
      }
    });

    // Add this callback to listeners
    _orderListeners[businessId] = _orderListeners[businessId] ?? [];
    _orderListeners[businessId]!.add(onOrdersUpdated);
  }

  /// Stops listening to real-time order updates for a business
  void stopOrderListener(String businessId) {
    _orderStreams[businessId]?.cancel();
    _orderStreams[businessId] = null;
    _orderListeners[businessId]?.clear();
  }

  /// Stops all order listeners
  void stopAllOrderListeners() {
    for (final stream in _orderStreams.values) {
      stream?.cancel();
    }
    _orderStreams.clear();
    _orderListeners.clear();
  }
} 