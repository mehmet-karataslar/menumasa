
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/business.dart';
import '../../data/models/product.dart';
import '../../data/models/category.dart';
import '../../data/models/user.dart' as app_user;
import '../../data/models/discount.dart';
import '../../data/models/order.dart' as app_order;


class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _businessesRef => _firestore.collection('businesses');
  CollectionReference get _productsRef => _firestore.collection('products');
  CollectionReference get _categoriesRef => _firestore.collection('categories');
  CollectionReference get _ordersRef => _firestore.collection('orders');
  CollectionReference get _discountsRef => _firestore.collection('discounts');

  // Initialize database with collections if they don't exist
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

  // User Operations
  Future<app_user.User?> getUser(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists) {
        return app_user.User.fromJson(
          doc.data() as Map<String, dynamic>,
          id: doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı bilgileri alınırken bir hata oluştu: $e');
    }
  }

  Future<String> saveUser(app_user.User user) async {
    try {
      final data = user.toFirestore();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (user.id.isEmpty) {
        // New user
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _usersRef.add(data);
        return docRef.id;
      } else {
        // Update existing user
        await _usersRef.doc(user.id).set(data, SetOptions(merge: true));
        return user.id;
      }
    } catch (e) {
      throw Exception('Kullanıcı kaydedilirken bir hata oluştu: $e');
    }
  }

  Future<void> updateUserData(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _usersRef.doc(id).update(data);
    } catch (e) {
      throw Exception('Kullanıcı bilgileri güncellenirken bir hata oluştu: $e');
    }
  }

  // Business Operations
  Future<List<Business>> getBusinesses({String? ownerId}) async {
    try {
      Query query = _businessesRef;
      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => Business.fromJson(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('İşletmeler alınırken bir hata oluştu: $e');
    }
  }

  Future<Business?> getBusiness(String businessId) async {
    try {
      final doc = await _businessesRef.doc(businessId).get();
      if (doc.exists) {
        return Business.fromJson(
          doc.data() as Map<String, dynamic>,
          id: doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('İşletme bilgileri alınırken bir hata oluştu: $e');
    }
  }

  Future<String> saveBusiness(Business business) async {
    try {
      final data = business.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (business.id.isEmpty) {
        // New business
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _businessesRef.add(data);

        // Update user's totalBusinesses count
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userDoc = await _usersRef.doc(currentUser.uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final profile = userData['profile'] as Map<String, dynamic>? ?? {};
            final totalBusinesses = (profile['totalBusinesses'] ?? 0) + 1;

            await _usersRef.doc(currentUser.uid).update({
              'profile.totalBusinesses': totalBusinesses,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        return docRef.id;
      } else {
        // Update existing business
        await _businessesRef.doc(business.id).update(data);
        return business.id;
      }
    } catch (e) {
      throw Exception('İşletme kaydedilirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteBusiness(String businessId) async {
    try {
      // Delete business and all related documents
      await _firestore.runTransaction((transaction) async {
        // Get business to verify owner
        final businessDoc = await _businessesRef.doc(businessId).get();
        if (!businessDoc.exists) {
          throw Exception('İşletme bulunamadı');
        }

        final businessData = businessDoc.data() as Map<String, dynamic>;
        final ownerId = businessData['ownerId'] as String?;

        // Delete the business
        transaction.delete(_businessesRef.doc(businessId));

        // Update user's totalBusinesses count if owner exists
        if (ownerId != null) {
          final userDoc = await _usersRef.doc(ownerId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final profile = userData['profile'] as Map<String, dynamic>? ?? {};
            final totalBusinesses = (profile['totalBusinesses'] ?? 1) - 1;

            transaction.update(_usersRef.doc(ownerId), {
              'profile.totalBusinesses': totalBusinesses >= 0
                  ? totalBusinesses
                  : 0,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      // Now delete related products, categories, discounts, etc.
      await Future.wait([
        _deleteProductsByBusiness(businessId),
        _deleteCategoriesByBusiness(businessId),
        _deleteDiscountsByBusiness(businessId),
      ]);
    } catch (e) {
      throw Exception('İşletme silinirken bir hata oluştu: $e');
    }
  }

  // Business Orders
  Future<List<app_order.Order>> getBusinessOrders(
    String businessId, {
    int limit = 10,
    String? status,
  }) async {
    try {
      Query query = _ordersRef
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => app_order.Order.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('İşletme siparişleri alınırken bir hata oluştu: $e');
    }
  }

  // Business Categories
  Future<List<Category>> getBusinessCategories(String businessId) async {
    try {
      final snapshot = await _categoriesRef
          .where('businessId', isEqualTo: businessId)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs
          .map((doc) => Category.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('İşletme kategorileri alınırken bir hata oluştu: $e');
    }
  }

  // Business Products
  Future<List<Product>> getBusinessProducts(
    String businessId, {
    int limit = 10,
    String? categoryId,
  }) async {
    try {
      Query query = _productsRef
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Product.fromJson(
                doc.data() as Map<String, dynamic>,
                id: doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('İşletme ürünleri alınırken bir hata oluştu: $e');
    }
  }

  // Product Operations
  Future<List<Product>> getProducts({
    String? businessId,
    String? categoryId,
  }) async {
    try {
      Query query = _productsRef;

      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      }

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      final snapshot = await query.orderBy('sortOrder').get();
      return snapshot.docs
          .map(
            (doc) => Product.fromJson(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Ürünler alınırken bir hata oluştu: $e');
    }
  }

  Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _productsRef.doc(productId).get();
      if (doc.exists) {
        return Product.fromJson(doc.data() as Map<String, dynamic>, id: doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Ürün bilgileri alınırken bir hata oluştu: $e');
    }
  }

  Future<String> saveProduct(Product product) async {
    try {
      final data = product.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (product.productId.isEmpty) {
        // New product
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _productsRef.add(data);

        // Update user's totalProducts count
        final business = await getBusiness(product.businessId);
        if (business != null) {
          final userDoc = await _usersRef.doc(business.ownerId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final profile = userData['profile'] as Map<String, dynamic>? ?? {};
            final totalProducts = (profile['totalProducts'] ?? 0) + 1;

            await _usersRef.doc(business.ownerId).update({
              'profile.totalProducts': totalProducts,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        return docRef.id;
      } else {
        // Update existing product
        await _productsRef.doc(product.productId).update(data);
        return product.productId;
      }
    } catch (e) {
      throw Exception('Ürün kaydedilirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      // Get product to update user's totalProducts count
      final productDoc = await _productsRef.doc(productId).get();
      if (productDoc.exists) {
        final productData = productDoc.data() as Map<String, dynamic>;
        final businessId = productData['businessId'] as String?;

        if (businessId != null) {
          final business = await getBusiness(businessId);
          if (business != null) {
            final userDoc = await _usersRef.doc(business.ownerId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final profile =
                  userData['profile'] as Map<String, dynamic>? ?? {};
              final totalProducts = (profile['totalProducts'] ?? 1) - 1;

              await _usersRef.doc(business.ownerId).update({
                'profile.totalProducts': totalProducts >= 0 ? totalProducts : 0,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }

      await _productsRef.doc(productId).delete();
    } catch (e) {
      throw Exception('Ürün silinirken bir hata oluştu: $e');
    }
  }

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

  // Category Operations
  Future<List<Category>> getCategories({
    String? businessId,
    String? parentCategoryId,
  }) async {
    try {
      Query query = _categoriesRef;

      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      }

      if (parentCategoryId != null) {
        query = query.where('parentCategoryId', isEqualTo: parentCategoryId);
      }

      final snapshot = await query.orderBy('sortOrder').get();
      return snapshot.docs
          .map(
            (doc) => Category.fromJson(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Kategoriler alınırken bir hata oluştu: $e');
    }
  }

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
      throw Exception('Kategori bilgileri alınırken bir hata oluştu: $e');
    }
  }

  Future<String> saveCategory(Category category) async {
    try {
      final data = category.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (category.categoryId.isEmpty) {
        // New category
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _categoriesRef.add(data);
        return docRef.id;
      } else {
        // Update existing category
        await _categoriesRef.doc(category.categoryId).update(data);
        return category.categoryId;
      }
    } catch (e) {
      throw Exception('Kategori kaydedilirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoriesRef.doc(categoryId).delete();
    } catch (e) {
      throw Exception('Kategori silinirken bir hata oluştu: $e');
    }
  }

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

  // Discount Operations
  Future<List<Discount>> getDiscounts({String? businessId}) async {
    try {
      Query query = _discountsRef;
      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Discount.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('İndirimler alınırken bir hata oluştu: $e');
    }
  }

  Future<Discount?> getDiscount(String discountId) async {
    try {
      final doc = await _discountsRef.doc(discountId).get();
      if (doc.exists) {
        return Discount.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('İndirim bilgileri alınırken bir hata oluştu: $e');
    }
  }

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
      throw Exception('İndirim kaydedilirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteDiscount(String discountId) async {
    try {
      await _discountsRef.doc(discountId).delete();
    } catch (e) {
      throw Exception('İndirim silinirken bir hata oluştu: $e');
    }
  }

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

  // Order Operations
  Future<List<app_order.Order>> getOrders({
    String? businessId,
    String? customerId,
  }) async {
    try {
      Query query = _ordersRef;

      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map(
            (doc) => app_order.Order.fromJson(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Siparişler alınırken bir hata oluştu: $e');
    }
  }

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
      throw Exception('Sipariş bilgileri alınırken bir hata oluştu: $e');
    }
  }

  Future<String> saveOrder(app_order.Order order) async {
    try {
      final data = order.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (order.orderId.isEmpty) {
        // New order
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _ordersRef.add(data);
        return docRef.id;
      } else {
        // Update existing order
        await _ordersRef.doc(order.orderId).update(data);
        return order.orderId;
      }
    } catch (e) {
      throw Exception('Sipariş kaydedilirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _ordersRef.doc(orderId).delete();
    } catch (e) {
      throw Exception('Sipariş silinirken bir hata oluştu: $e');
    }
  }

  // Customer Data Operations
  Future<List<app_order.Order>> getOrdersByCustomer(String customerId) async {
    try {
      final snapshot = await _ordersRef
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => app_order.Order.fromJson(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Müşteri siparişleri alınırken bir hata oluştu: $e');
    }
  }

  Future<void> updateCustomerData(String userId, Map<String, dynamic> customerData) async {
    try {
      await _usersRef.doc(userId).update({
        'profile.customerData': customerData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Müşteri verileri güncellenirken bir hata oluştu: $e');
    }
  }

  Future<void> addCustomerOrder(String userId, app_user.CustomerOrder order) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};
      final customerData = profile['customerData'] as Map<String, dynamic>? ?? {};

      // Mevcut sipariş geçmişini al
      final orderHistory = (customerData['orderHistory'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      // Yeni siparişi ekle
      orderHistory.insert(0, order.toMap());

      // İstatistikleri güncelle
      final stats = customerData['stats'] as Map<String, dynamic>? ?? {};
      final totalOrders = (stats['totalOrders'] ?? 0) + 1;
      final totalSpent = (stats['totalSpent'] ?? 0.0) + order.totalAmount;

      // İşletme harcama istatistiklerini güncelle
      final businessSpending = Map<String, double>.from(
        stats['businessSpending'] ?? {},
      );
      businessSpending[order.businessId] = 
          (businessSpending[order.businessId] ?? 0.0) + order.totalAmount;

      // Güncellenmiş müşteri verilerini hazırla
      final updatedCustomerData = {
        ...customerData,
        'orderHistory': orderHistory,
        'stats': {
          ...stats,
          'totalOrders': totalOrders,
          'totalSpent': totalSpent,
          'lastOrderDate': order.orderDate.toIso8601String(),
          'businessSpending': businessSpending,
        },
      };

      await updateCustomerData(userId, updatedCustomerData);
    } catch (e) {
      throw Exception('Müşteri siparişi eklenirken bir hata oluştu: $e');
    }
  }

  Future<void> addCustomerFavorite(String userId, app_user.CustomerFavorite favorite) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};
      final customerData = profile['customerData'] as Map<String, dynamic>? ?? {};

      // Mevcut favorileri al
      final favorites = (customerData['favorites'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      // Aynı işletme zaten favorilerde mi kontrol et
      final existingIndex = favorites.indexWhere(
        (f) => f['businessId'] == favorite.businessId,
      );

      if (existingIndex != -1) {
        // Mevcut favoriyi güncelle
        favorites[existingIndex] = favorite.toMap();
      } else {
        // Yeni favori ekle
        favorites.add(favorite.toMap());
      }

      // İstatistikleri güncelle
      final stats = customerData['stats'] as Map<String, dynamic>? ?? {};
      final favoriteBusinessCount = favorites.length;

      // Güncellenmiş müşteri verilerini hazırla
      final updatedCustomerData = {
        ...customerData,
        'favorites': favorites,
        'stats': {
          ...stats,
          'favoriteBusinessCount': favoriteBusinessCount,
        },
      };

      await updateCustomerData(userId, updatedCustomerData);
    } catch (e) {
      throw Exception('Müşteri favorisi eklenirken bir hata oluştu: $e');
    }
  }

  Future<void> addCustomerVisit(String userId, app_user.CustomerVisit visit) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};
      final customerData = profile['customerData'] as Map<String, dynamic>? ?? {};

      // Mevcut ziyaret geçmişini al
      final visitHistory = (customerData['visitHistory'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      // Yeni ziyareti ekle
      visitHistory.insert(0, visit.toMap());

      // İstatistikleri güncelle
      final stats = customerData['stats'] as Map<String, dynamic>? ?? {};
      final totalVisits = (stats['totalVisits'] ?? 0) + 1;

      // Güncellenmiş müşteri verilerini hazırla
      final updatedCustomerData = {
        ...customerData,
        'visitHistory': visitHistory,
        'stats': {
          ...stats,
          'totalVisits': totalVisits,
        },
      };

      await updateCustomerData(userId, updatedCustomerData);
    } catch (e) {
      throw Exception('Müşteri ziyareti eklenirken bir hata oluştu: $e');
    }
  }

  Future<void> updateCustomerPreferences(String userId, app_user.CustomerPreferences preferences) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};
      final customerData = profile['customerData'] as Map<String, dynamic>? ?? {};

      // Güncellenmiş müşteri verilerini hazırla
      final updatedCustomerData = {
        ...customerData,
        'preferences': preferences.toMap(),
      };

      await updateCustomerData(userId, updatedCustomerData);
    } catch (e) {
      throw Exception('Müşteri tercihleri güncellenirken bir hata oluştu: $e');
    }
  }

  Future<void> addCustomerAddress(String userId, app_user.CustomerAddress address) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};
      final customerData = profile['customerData'] as Map<String, dynamic>? ?? {};

      // Mevcut adresleri al
      final addresses = (customerData['addresses'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      // Yeni adresi ekle
      addresses.add(address.toMap());

      // Güncellenmiş müşteri verilerini hazırla
      final updatedCustomerData = {
        ...customerData,
        'addresses': addresses,
      };

      await updateCustomerData(userId, updatedCustomerData);
    } catch (e) {
      throw Exception('Müşteri adresi eklenirken bir hata oluştu: $e');
    }
  }

  Future<void> updateCustomerPaymentInfo(String userId, app_user.CustomerPaymentInfo paymentInfo) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};
      final customerData = profile['customerData'] as Map<String, dynamic>? ?? {};

      // Güncellenmiş müşteri verilerini hazırla
      final updatedCustomerData = {
        ...customerData,
        'paymentInfo': paymentInfo.toMap(),
      };

      await updateCustomerData(userId, updatedCustomerData);
    } catch (e) {
      throw Exception('Müşteri ödeme bilgileri güncellenirken bir hata oluştu: $e');
    }
  }

  Future<app_user.CustomerData?> getCustomerData(String userId) async {
    try {
      final userDoc = await _usersRef.doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};
      final customerData = profile['customerData'] as Map<String, dynamic>?;

      if (customerData == null) {
        return null;
      }

      return app_user.CustomerData.fromMap(customerData);
    } catch (e) {
      throw Exception('Müşteri verileri alınırken bir hata oluştu: $e');
    }
  }
}
