import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user.dart' as app_user;
import '../../data/models/order.dart' as app_order;
import '../../business/models/business.dart';
import '../../business/models/category.dart';
import '../../business/models/product.dart';
import '../../business/models/detailed_nutrition_info.dart';
import '../models/allergen_profile.dart';
import '../models/review_rating.dart';
import '../models/customer_feedback.dart';

class CustomerFirestoreService {
  static final CustomerFirestoreService _instance = CustomerFirestoreService._internal();
  factory CustomerFirestoreService() => _instance;
  CustomerFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _ordersRef => _firestore.collection('orders');
  CollectionReference get _businessesRef => _firestore.collection('businesses');
  CollectionReference get _categoriesRef => _firestore.collection('categories');
  CollectionReference get _productsRef => _firestore.collection('products');

  // =============================================================================
  // CUSTOMER USER OPERATIONS
  // =============================================================================

  /// Gets a user by UID
  Future<app_user.User?> getUser(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists) {
        return app_user.User.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Saves or updates a user
  Future<String> saveUser(app_user.User user) async {
    try {
      final data = user.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (user.id.isEmpty) {
        // New user
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _usersRef.add(data);
        return docRef.id;
      } else {
        // Update existing user
        await _usersRef.doc(user.id).update(data);
        return user.id;
      }
    } catch (e) {
      throw Exception('Kullanıcı kaydedilirken hata oluştu: $e');
    }
  }

  /// Updates user data with specific fields
  Future<void> updateUserData(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _usersRef.doc(id).update(data);
    } catch (e) {
      throw Exception('Kullanıcı verileri güncellenirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // CUSTOMER DATA OPERATIONS
  // =============================================================================

  /// Updates customer-specific data within user document
  Future<void> updateCustomerData(String userId, Map<String, dynamic> customerData) async {
    try {
      final updateData = <String, dynamic>{
        'customerData': customerData,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _usersRef.doc(userId).update(updateData);
    } catch (e) {
      throw Exception('Müşteri verileri güncellenirken hata oluştu: $e');
    }
  }

  /// Gets customer data from user document
  Future<app_user.CustomerData?> getCustomerData(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final customerData = data['customerData'] as Map<String, dynamic>?;
        
        if (customerData != null) {
          return app_user.CustomerData.fromJson(customerData);
        }
      }
      return null;
    } catch (e) {
      print('Error getting customer data: $e');
      return null;
    }
  }

  // =============================================================================
  // CUSTOMER ORDER OPERATIONS
  // =============================================================================

  /// Adds an order to customer's order history
  Future<void> addCustomerOrder(String userId, app_user.CustomerOrder order) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final customerData = data['customerData'] as Map<String, dynamic>? ?? {};
        final orders = List<Map<String, dynamic>>.from(customerData['orders'] ?? []);
        
        orders.add(order.toJson());
        
        // Keep only the last 50 orders to prevent document size issues
        if (orders.length > 50) {
          orders.removeRange(0, orders.length - 50);
        }
        
        customerData['orders'] = orders;
        customerData['lastOrderDate'] = FieldValue.serverTimestamp();
        customerData['totalOrders'] = orders.length;
        
        await updateCustomerData(userId, customerData);
      }
    } catch (e) {
      throw Exception('Müşteri siparişi eklenirken hata oluştu: $e');
    }
  }

  /// Gets customer's order history
  Future<List<app_order.Order>> getOrdersByCustomer(String customerId) async {
    try {
      final snapshot = await _ordersRef
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => app_order.Order.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error getting customer orders: $e');
      return [];
    }
  }

  // =============================================================================
  // CUSTOMER FAVORITES OPERATIONS
  // =============================================================================

  /// Adds a business/product to customer's favorites
  Future<void> addCustomerFavorite(String userId, app_user.CustomerFavorite favorite) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final customerData = data['customerData'] as Map<String, dynamic>? ?? {};
        final favorites = List<Map<String, dynamic>>.from(customerData['favorites'] ?? []);
        
        // Check if already exists
        final existingIndex = favorites.indexWhere(
          (f) => f['businessId'] == favorite.businessId && 
                 f['productId'] == favorite.productId
        );
        
        if (existingIndex >= 0) {
          favorites[existingIndex] = favorite.toJson();
        } else {
          favorites.add(favorite.toJson());
        }
        
        customerData['favorites'] = favorites;
        await updateCustomerData(userId, customerData);
      }
    } catch (e) {
      throw Exception('Favori eklenirken hata oluştu: $e');
    }
  }

  /// Removes a favorite from customer's list
  Future<void> removeCustomerFavorite(String userId, String businessId, {String? productId}) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final customerData = data['customerData'] as Map<String, dynamic>? ?? {};
        final favorites = List<Map<String, dynamic>>.from(customerData['favorites'] ?? []);
        
        favorites.removeWhere(
          (f) => f['businessId'] == businessId && 
                 (productId == null || f['productId'] == productId)
        );
        
        customerData['favorites'] = favorites;
        await updateCustomerData(userId, customerData);
      }
    } catch (e) {
      throw Exception('Favori kaldırılırken hata oluştu: $e');
    }
  }

  /// Add business to favorites
  Future<void> addToFavorites(String userId, String businessId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final customerData = data['customerData'] as Map<String, dynamic>? ?? {};
        final favorites = List<Map<String, dynamic>>.from(customerData['favorites'] ?? []);
        
        // Check if already exists
        final exists = favorites.any((f) => f['businessId'] == businessId);
        if (!exists) {
          favorites.add({
            'businessId': businessId,
            'addedAt': FieldValue.serverTimestamp(),
          });
          
          customerData['favorites'] = favorites;
          await updateCustomerData(userId, customerData);
        }
      }
    } catch (e) {
      throw Exception('Favori eklenirken hata oluştu: $e');
    }
  }

  /// Remove business from favorites  
  Future<void> removeFromFavorites(String userId, String businessId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final customerData = data['customerData'] as Map<String, dynamic>? ?? {};
        final favorites = List<Map<String, dynamic>>.from(customerData['favorites'] ?? []);
        
        // Remove business from favorites
        favorites.removeWhere((f) => f['businessId'] == businessId);
        
        customerData['favorites'] = favorites;
        await updateCustomerData(userId, customerData);
      }
    } catch (e) {
      throw Exception('Favori kaldırılırken hata oluştu: $e');
    }
  }

  // =============================================================================
  // CUSTOMER VISITS OPERATIONS
  // =============================================================================

  /// Records a customer visit to a business
  Future<void> addCustomerVisit(String userId, app_user.CustomerVisit visit) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final customerData = data['customerData'] as Map<String, dynamic>? ?? {};
        final visits = List<Map<String, dynamic>>.from(customerData['visits'] ?? []);
        
        visits.add(visit.toJson());
        
        // Keep only the last 100 visits
        if (visits.length > 100) {
          visits.removeRange(0, visits.length - 100);
        }
        
        customerData['visits'] = visits;
        customerData['lastVisitDate'] = FieldValue.serverTimestamp();
        customerData['totalVisits'] = visits.length;
        
        await updateCustomerData(userId, customerData);
      }
    } catch (e) {
      throw Exception('Müşteri ziyareti kaydedilirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // CUSTOMER PREFERENCES OPERATIONS
  // =============================================================================

  /// Updates customer preferences
  Future<void> updateCustomerPreferences(String userId, app_user.CustomerPreferences preferences) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final customerData = data['customerData'] as Map<String, dynamic>? ?? {};
        
        customerData['preferences'] = preferences.toJson();
        await updateCustomerData(userId, customerData);
      }
    } catch (e) {
      throw Exception('Müşteri tercihleri güncellenirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // CUSTOMER ADDRESS OPERATIONS
  // =============================================================================

  /// Adds an address to customer's address list
  Future<void> addCustomerAddress(String userId, app_user.CustomerAddress address) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final customerData = data['customerData'] as Map<String, dynamic>? ?? {};
        final addresses = List<Map<String, dynamic>>.from(customerData['addresses'] ?? []);
        
        // Check if it's a default address
        if (address.isDefault) {
          // Remove default flag from other addresses
          for (var addr in addresses) {
            addr['isDefault'] = false;
          }
        }
        
        addresses.add(address.toJson());
        customerData['addresses'] = addresses;
        
        await updateCustomerData(userId, customerData);
      }
    } catch (e) {
      throw Exception('Müşteri adresi eklenirken hata oluştu: $e');
    }
  }

  /// Removes an address from customer's list
  Future<void> removeCustomerAddress(String userId, String addressId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final customerData = data['customerData'] as Map<String, dynamic>? ?? {};
        final addresses = List<Map<String, dynamic>>.from(customerData['addresses'] ?? []);
        
        addresses.removeWhere((addr) => addr['id'] == addressId);
        customerData['addresses'] = addresses;
        
        await updateCustomerData(userId, customerData);
      }
    } catch (e) {
      throw Exception('Müşteri adresi kaldırılırken hata oluştu: $e');
    }
  }

  // =============================================================================
  // CUSTOMER PAYMENT OPERATIONS
  // =============================================================================

  /// Updates customer payment information
  Future<void> updateCustomerPaymentInfo(String userId, app_user.CustomerPaymentInfo paymentInfo) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final customerData = data['customerData'] as Map<String, dynamic>? ?? {};
        
        customerData['paymentInfo'] = paymentInfo.toJson();
        await updateCustomerData(userId, customerData);
      }
    } catch (e) {
      throw Exception('Müşteri ödeme bilgileri güncellenirken hata oluştu: $e');
    }
  }

  // =============================================================================
  // BUSINESS DISCOVERY OPERATIONS
  // =============================================================================

  /// Gets all businesses for customer discovery
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

  /// Gets a specific business for customer viewing
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

  // =============================================================================
  // ORDER OPERATIONS
  // =============================================================================

  /// Gets a specific order for customer viewing
  Future<app_order.Order?> getOrder(String orderId) async {
    try {
      final doc = await _ordersRef.doc(orderId).get();
      if (doc.exists) {
        return app_order.Order.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  /// Creates a new order
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

  // =============================================================================
  // ADDITIONAL ORDER METHODS NEEDED BY CUSTOMER PAGES
  // =============================================================================

  /// Gets orders by business ID and customer phone
  Future<List<app_order.Order>> getOrdersByBusinessAndPhone(String businessId, String customerPhone) async {
    try {
      final snapshot = await _ordersRef
          .where('businessId', isEqualTo: businessId)
          .where('customerPhone', isEqualTo: customerPhone)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => app_order.Order.fromJson(
        doc.data() as Map<String, dynamic>,
        id: doc.id,
      )).toList();
    } catch (e) {
      print('Error getting orders by business and phone: $e');
      return [];
    }
  }

  /// Gets orders by business ID only
  Future<List<app_order.Order>> getOrdersByBusiness(String businessId) async {
    try {
      final snapshot = await _ordersRef
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => app_order.Order.fromJson(
        doc.data() as Map<String, dynamic>,
        id: doc.id,
      )).toList();
    } catch (e) {
      print('Error getting orders by business: $e');
      return [];
    }
  }

  // =============================================================================
  // PRODUCT AND CATEGORY METHODS FOR BUSINESS DETAIL PAGE
  // =============================================================================

  /// Gets products for a business
  Future<List<Map<String, dynamic>>> getBusinessProducts(String businessId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('businessId', isEqualTo: businessId)
          .get();

      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
    } catch (e) {
      print('Error getting business products: $e');
      return [];
    }
  }

  /// Gets categories for a business
  Future<List<Map<String, dynamic>>> getBusinessCategories(String businessId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('businessId', isEqualTo: businessId)
          .get();

      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
    } catch (e) {
      print('Error getting business categories: $e');
      return [];
    }
  }

  // =============================================================================
  // REAL-TIME ORDER LISTENERS FOR CUSTOMERS
  // =============================================================================

  final Map<String, StreamSubscription<QuerySnapshot>?> _customerOrderStreams = {};
  final Map<String, List<Function(List<app_order.Order>)>> _customerOrderListeners = {};

  /// Starts listening to real-time order updates for a customer
  void startCustomerOrderListener(String customerId, Function(List<app_order.Order>) onOrdersUpdated) {
    // Cancel existing listener if any
    stopCustomerOrderListener(customerId);

    final stream = _ordersRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    _customerOrderStreams[customerId] = stream.listen((snapshot) {
      final orders = snapshot.docs
          .map((doc) => app_order.Order.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();

      // Notify all listeners for this customer
      final listeners = _customerOrderListeners[customerId] ?? [];
      for (final listener in listeners) {
        listener(orders);
      }
    });

    // Add this callback to listeners
    _customerOrderListeners[customerId] = _customerOrderListeners[customerId] ?? [];
    _customerOrderListeners[customerId]!.add(onOrdersUpdated);
  }

  /// Stops listening to real-time order updates for a customer
  void stopCustomerOrderListener(String customerId) {
    _customerOrderStreams[customerId]?.cancel();
    _customerOrderStreams.remove(customerId);
    _customerOrderListeners.remove(customerId);
  }

  // Real-time order listeners already implemented above

  /// Dispose all customer order listeners
  void disposeCustomerOrderListeners() {
    for (final stream in _customerOrderStreams.values) {
      stream?.cancel();
    }
    _customerOrderStreams.clear();
    _customerOrderListeners.clear();
  }

  // =============================================================================
  // BUSINESS OPERATIONS
  // =============================================================================

  /// Get business by ID
  Future<Business?> getBusinessById(String businessId) async {
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
      print('Error getting business by ID: $e');
      return null;
    }
  }

  // =============================================================================
  // CATEGORY OPERATIONS
  // =============================================================================

  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _categoriesRef
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      
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

  /// Get categories by business ID
  Future<List<Category>> getCategoriesByBusiness(String businessId) async {
    try {
      final snapshot = await _categoriesRef
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      
      return snapshot.docs
          .map((doc) => Category.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting categories by business: $e');
      return [];
    }
  }

  // =============================================================================
  // PRODUCT OPERATIONS
  // =============================================================================

  /// Get products by business ID
  Future<List<Product>> getProductsByBusiness(String businessId) async {
    try {
      print('🔍 Ürünler sorgulanıyor: businessId=$businessId');
      
      // Önce sadece businessId ile sorgula (index gerektirmez)
      final snapshot = await _productsRef
          .where('businessId', isEqualTo: businessId)
          .get();
      
      print('📦 Ham sorgu sonucu: ${snapshot.docs.length} döküman');
      
      // Client-side filtering ve sorting
      final products = snapshot.docs
          .map((doc) => Product.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
      
      print('🥘 Tüm ürünler: ${products.length}');
      print('✅ Mevcut ürünler: ${products.where((p) => p.isAvailable).length}');
      
      // Client-side sorting by sortOrder
      products.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
      
      return products;
    } catch (e) {
      print('❌ Ürün yükleme hatası: $e');
      return [];
    }
  }

  /// Get products by category ID
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final snapshot = await _productsRef
          .where('categoryId', isEqualTo: categoryId)
          .where('isAvailable', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      
      return snapshot.docs
          .map((doc) => Product.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error getting products by category: $e');
      return [];
    }
  }

  // =============================================================================
  // NUTRITION & ALLERGEN OPERATIONS
  // =============================================================================

  /// Ürün için detaylı beslenme bilgisi al
  Future<DetailedNutritionInfo?> getDetailedNutritionInfo(String productId) async {
    try {
      final doc = await _firestore.collection('detailed_nutrition_info').doc(productId).get();
      
      if (doc.exists) {
        return DetailedNutritionInfo.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      print('Detaylı beslenme bilgisi alınırken hata: $e');
      return null;
    }
  }

  /// Müşteri alerjen profili al
  Future<AllergenProfile?> getAllergenProfile(String customerId) async {
    try {
      final doc = await _firestore.collection('allergen_profiles').doc(customerId).get();
      
      if (doc.exists) {
        return AllergenProfile.fromFirestore(doc);
      }
      
      // Profil yoksa varsayılan profil oluştur
      final defaultProfile = AllergenProfile.defaultProfile(customerId);
      await saveAllergenProfile(defaultProfile);
      return defaultProfile;
    } catch (e) {
      print('Alerjen profili alınırken hata: $e');
      return null;
    }
  }

  /// Müşteri alerjen profili kaydet
  Future<void> saveAllergenProfile(AllergenProfile profile) async {
    try {
      await _firestore
          .collection('allergen_profiles')
          .doc(profile.customerId)
          .set(profile.toFirestore());
    } catch (e) {
      print('Alerjen profili kaydedilirken hata: $e');
      rethrow;
    }
  }

  /// Beslenme bilgisi kaydet (işletme için)
  Future<void> saveDetailedNutritionInfo(DetailedNutritionInfo nutritionInfo) async {
    try {
      await _firestore
          .collection('detailed_nutrition_info')
          .doc(nutritionInfo.productId)
          .set(nutritionInfo.toFirestore());
    } catch (e) {
      print('Beslenme bilgisi kaydedilirken hata: $e');
      rethrow;
    }
  }

  /// Değerlendirme kaydet
  Future<void> saveReview(ReviewRating review) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(review.reviewId)
          .set(review.toFirestore());
    } catch (e) {
      print('Değerlendirme kaydedilirken hata: $e');
      rethrow;
    }
  }

  /// Geri bildirim kaydet
  Future<void> saveFeedback(CustomerFeedback feedback) async {
    try {
      await _firestore
          .collection('customer_feedback')
          .doc(feedback.feedbackId)
          .set(feedback.toFirestore());
    } catch (e) {
      print('Geri bildirim kaydedilirken hata: $e');
      rethrow;
    }
  }
} 