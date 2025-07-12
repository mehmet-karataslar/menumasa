import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart' hide Category;
import '../../data/models/business.dart';
import '../../data/models/product.dart';
import '../../data/models/category.dart';
import '../../data/models/user.dart';
import '../../data/models/discount.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Firebase instances (nullable until Firebase is available)
  FirebaseFirestore? _firestore;
  auth.FirebaseAuth? _auth;

  // Check if Firebase is available (imported from main.dart)
  bool get _isFirebaseAvailable {
    try {
      // Try to check Firebase availability
      return _firestore != null && _auth != null;
    } catch (e) {
      return false;
    }
  }

  // Collections
  static const String _businessesCollection = 'businesses';
  static const String _productsCollection = 'products';
  static const String _categoriesCollection = 'categories';
  static const String _usersCollection = 'users';
  static const String _discountsCollection = 'discounts';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();

      // Initialize Firebase instances if available
      try {
        _firestore = FirebaseFirestore.instance;
        _auth = auth.FirebaseAuth.instance;
        debugPrint('🔥 DataService: Firebase instances initialized');
      } catch (e) {
        debugPrint(
          '⚠️ DataService: Firebase not available, using local storage: $e',
        );
        _firestore = null;
        _auth = null;
      }

      _initialized = true;
    }
  }

  // Business Operations
  Future<List<Business>> getBusinesses() async {
    if (_isFirebaseAvailable) {
      try {
        final snapshot = await _firestore!
            .collection(_businessesCollection)
            .get();
        return snapshot.docs
            .map((doc) => Business.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      } catch (e) {
        debugPrint('Get businesses error: $e');
        // Fallback to local storage
        return await _getBusinessesFromLocal();
      }
    } else {
      // Use local storage directly
      return await _getBusinessesFromLocal();
    }
  }

  Future<Business?> getBusiness(String businessId) async {
    if (_isFirebaseAvailable) {
      try {
        final doc = await _firestore!
            .collection(_businessesCollection)
            .doc(businessId)
            .get();
        if (doc.exists) {
          return Business.fromJson({...doc.data()!, 'id': doc.id});
        }
        return null;
      } catch (e) {
        debugPrint('Get business error: $e');
        // Fallback to local storage
        return await _getBusinessFromLocal(businessId);
      }
    } else {
      // Use local storage directly
      return await _getBusinessFromLocal(businessId);
    }
  }

  Future<void> saveBusiness(Business business) async {
    if (_isFirebaseAvailable) {
      try {
        await _firestore!
            .collection(_businessesCollection)
            .doc(business.businessId)
            .set(business.toJson(), SetOptions(merge: true));

        // Also save to local storage as backup
        await _saveBusinessToLocal(business);
      } catch (e) {
        debugPrint('Save business error: $e');
        // Fallback to local storage only
        await _saveBusinessToLocal(business);
      }
    } else {
      // Use local storage directly
      await _saveBusinessToLocal(business);
    }
  }

  Future<void> deleteBusiness(String businessId) async {
    if (_isFirebaseAvailable) {
      try {
        await _firestore!
            .collection(_businessesCollection)
            .doc(businessId)
            .delete();

        // Also delete from local storage
        await _deleteBusinessFromLocal(businessId);

        // Delete related data
        await deleteProductsByBusiness(businessId);
        await deleteCategoriesByBusiness(businessId);
      } catch (e) {
        debugPrint('Delete business error: $e');
        // Fallback to local storage
        await _deleteBusinessFromLocal(businessId);
      }
    } else {
      // Use local storage directly
      await _deleteBusinessFromLocal(businessId);
    }
  }

  // Product Operations
  Future<List<Product>> getProducts({String? businessId}) async {
    if (_isFirebaseAvailable) {
      try {
        Query query = _firestore!.collection(_productsCollection);

        if (businessId != null) {
          query = query.where('businessId', isEqualTo: businessId);
        }

        final snapshot = await query.orderBy('sortOrder').get();
        return snapshot.docs
            .map(
              (doc) => Product.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();
      } catch (e) {
        debugPrint('Get products error: $e');
        // Fallback to local storage
        return await _getProductsFromLocal(businessId: businessId);
      }
    } else {
      // Use local storage directly
      return await _getProductsFromLocal(businessId: businessId);
    }
  }

  Future<Product?> getProduct(String productId) async {
    if (_isFirebaseAvailable) {
      try {
        final doc = await _firestore!
            .collection(_productsCollection)
            .doc(productId)
            .get();
        if (doc.exists) {
          return Product.fromJson({...doc.data()!, 'id': doc.id});
        }
        return null;
      } catch (e) {
        debugPrint('Get product error: $e');
        // Fallback to local storage
        return await _getProductFromLocal(productId);
      }
    } else {
      // Use local storage directly
      return await _getProductFromLocal(productId);
    }
  }

  Future<void> saveProduct(Product product) async {
    if (_isFirebaseAvailable) {
      try {
        await _firestore!
            .collection(_productsCollection)
            .doc(product.productId)
            .set(product.toJson(), SetOptions(merge: true));

        // Also save to local storage as backup
        await _saveProductToLocal(product);
      } catch (e) {
        debugPrint('Save product error: $e');
        // Fallback to local storage only
        await _saveProductToLocal(product);
      }
    } else {
      // Use local storage directly
      await _saveProductToLocal(product);
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (_isFirebaseAvailable) {
      try {
        await _firestore!
            .collection(_productsCollection)
            .doc(productId)
            .delete();

        // Also delete from local storage
        await _deleteProductFromLocal(productId);
      } catch (e) {
        debugPrint('Delete product error: $e');
        // Fallback to local storage
        await _deleteProductFromLocal(productId);
      }
    } else {
      // Use local storage directly
      await _deleteProductFromLocal(productId);
    }
  }

  Future<void> deleteProductsByBusiness(String businessId) async {
    if (_isFirebaseAvailable) {
      try {
        final batch = _firestore!.batch();
        final snapshot = await _firestore!
            .collection(_productsCollection)
            .where('businessId', isEqualTo: businessId)
            .get();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        // Also delete from local storage
        await _deleteProductsByBusinessFromLocal(businessId);
      } catch (e) {
        debugPrint('Delete products by business error: $e');
        // Fallback to local storage
        await _deleteProductsByBusinessFromLocal(businessId);
      }
    } else {
      // Use local storage directly
      await _deleteProductsByBusinessFromLocal(businessId);
    }
  }

  // Category Operations
  Future<List<Category>> getCategories({String? businessId}) async {
    if (_isFirebaseAvailable) {
      try {
        Query query = _firestore!.collection(_categoriesCollection);

        if (businessId != null) {
          query = query.where('businessId', isEqualTo: businessId);
        }

        final snapshot = await query.orderBy('sortOrder').get();
        return snapshot.docs
            .map(
              (doc) => Category.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }),
            )
            .toList();
      } catch (e) {
        debugPrint('Get categories error: $e');
        // Fallback to local storage
        return await _getCategoriesFromLocal(businessId: businessId);
      }
    } else {
      // Use local storage directly
      return await _getCategoriesFromLocal(businessId: businessId);
    }
  }

  Future<Category?> getCategory(String categoryId) async {
    if (_isFirebaseAvailable) {
      try {
        final doc = await _firestore!
            .collection(_categoriesCollection)
            .doc(categoryId)
            .get();
        if (doc.exists) {
          return Category.fromJson({...doc.data()!, 'id': doc.id});
        }
        return null;
      } catch (e) {
        debugPrint('Get category error: $e');
        // Fallback to local storage
        return await _getCategoryFromLocal(categoryId);
      }
    } else {
      // Use local storage directly
      return await _getCategoryFromLocal(categoryId);
    }
  }

  Future<void> saveCategory(Category category) async {
    if (_isFirebaseAvailable) {
      try {
        await _firestore!
            .collection(_categoriesCollection)
            .doc(category.categoryId)
            .set(category.toJson(), SetOptions(merge: true));

        // Also save to local storage as backup
        await _saveCategoryToLocal(category);
      } catch (e) {
        debugPrint('Save category error: $e');
        // Fallback to local storage only
        await _saveCategoryToLocal(category);
      }
    } else {
      // Use local storage directly
      await _saveCategoryToLocal(category);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    if (_isFirebaseAvailable) {
      try {
        await _firestore!
            .collection(_categoriesCollection)
            .doc(categoryId)
            .delete();

        // Also delete from local storage
        await _deleteCategoryFromLocal(categoryId);
      } catch (e) {
        debugPrint('Delete category error: $e');
        // Fallback to local storage
        await _deleteCategoryFromLocal(categoryId);
      }
    } else {
      // Use local storage directly
      await _deleteCategoryFromLocal(categoryId);
    }
  }

  Future<void> deleteCategoriesByBusiness(String businessId) async {
    if (_isFirebaseAvailable) {
      try {
        final batch = _firestore!.batch();
        final snapshot = await _firestore!
            .collection(_categoriesCollection)
            .where('businessId', isEqualTo: businessId)
            .get();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        // Also delete from local storage
        await _deleteCategoriesByBusinessFromLocal(businessId);
      } catch (e) {
        debugPrint('Delete categories by business error: $e');
        // Fallback to local storage
        await _deleteCategoriesByBusinessFromLocal(businessId);
      }
    } else {
      // Use local storage directly
      await _deleteCategoriesByBusinessFromLocal(businessId);
    }
  }

  // User Operations
  Future<User?> getCurrentUser() async {
    if (_isFirebaseAvailable) {
      try {
        final firebaseUser = _auth!.currentUser;
        if (firebaseUser != null) {
          final doc = await _firestore!
              .collection(_usersCollection)
              .doc(firebaseUser.uid)
              .get();
          if (doc.exists) {
            return User.fromJson({...doc.data()!, 'id': doc.id});
          }
        }
        return null;
      } catch (e) {
        debugPrint('Get current user error: $e');
        // Fallback to local storage
        return await _getCurrentUserFromLocal();
      }
    } else {
      // Use local storage directly
      return await _getCurrentUserFromLocal();
    }
  }

  Future<void> saveCurrentUser(User user) async {
    if (_isFirebaseAvailable) {
      try {
        final firebaseUser = _auth!.currentUser;
        if (firebaseUser != null) {
          await _firestore!
              .collection(_usersCollection)
              .doc(firebaseUser.uid)
              .set(user.toJson(), SetOptions(merge: true));
        }

        // Also save to local storage as backup
        await _saveCurrentUserToLocal(user);
      } catch (e) {
        debugPrint('Save current user error: $e');
        // Fallback to local storage only
        await _saveCurrentUserToLocal(user);
      }
    } else {
      // Use local storage directly
      await _saveCurrentUserToLocal(user);
    }
  }

  Future<void> clearCurrentUser() async {
    if (_isFirebaseAvailable) {
      try {
        final firebaseUser = _auth!.currentUser;
        if (firebaseUser != null) {
          await _firestore!
              .collection(_usersCollection)
              .doc(firebaseUser.uid)
              .delete();
        }

        // Also clear from local storage
        await _clearCurrentUserFromLocal();
      } catch (e) {
        debugPrint('Clear current user error: $e');
        // Fallback to local storage
        await _clearCurrentUserFromLocal();
      }
    } else {
      // Use local storage directly
      await _clearCurrentUserFromLocal();
    }
  }

  // Discount Operations
  Future<List<Discount>> getDiscountsByBusinessId(String businessId) async {
    if (_isFirebaseAvailable) {
      try {
        final snapshot = await _firestore!
            .collection(_discountsCollection)
            .where('businessId', isEqualTo: businessId)
            .get();
        return snapshot.docs
            .map((doc) => Discount.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      } catch (e) {
        debugPrint('Get discounts error: $e');
        // Fallback to local storage
        return await _getDiscountsFromLocal(businessId);
      }
    } else {
      // Use local storage directly
      return await _getDiscountsFromLocal(businessId);
    }
  }

  Future<void> saveDiscount(String businessId, Discount discount) async {
    if (_isFirebaseAvailable) {
      try {
        await _firestore!
            .collection(_discountsCollection)
            .doc(discount.discountId)
            .set(discount.toJson(), SetOptions(merge: true));

        // Also save to local storage as backup
        await _saveDiscountToLocal(businessId, discount);
      } catch (e) {
        debugPrint('Save discount error: $e');
        // Fallback to local storage only
        await _saveDiscountToLocal(businessId, discount);
      }
    } else {
      // Use local storage directly
      await _saveDiscountToLocal(businessId, discount);
    }
  }

  Future<void> deleteDiscount(String businessId, String discountId) async {
    if (_isFirebaseAvailable) {
      try {
        await _firestore!
            .collection(_discountsCollection)
            .doc(discountId)
            .delete();

        // Also delete from local storage
        await _deleteDiscountFromLocal(businessId, discountId);
      } catch (e) {
        debugPrint('Delete discount error: $e');
        // Fallback to local storage
        await _deleteDiscountFromLocal(businessId, discountId);
      }
    } else {
      // Use local storage directly
      await _deleteDiscountFromLocal(businessId, discountId);
    }
  }

  // Realtime subscriptions
  Stream<List<Business>> getBusinessesStream() {
    if (_isFirebaseAvailable) {
      return _firestore!
          .collection(_businessesCollection)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Business.fromJson({...doc.data(), 'id': doc.id}))
                .toList(),
          );
    } else {
      // Return empty stream if Firebase not available
      return Stream.value(<Business>[]);
    }
  }

  Stream<List<Product>> getProductsStream({String? businessId}) {
    if (_isFirebaseAvailable) {
      Query query = _firestore!.collection(_productsCollection);

      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      }

      return query
          .orderBy('sortOrder')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => Product.fromJson({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }),
                )
                .toList(),
          );
    } else {
      // Return empty stream if Firebase not available
      return Stream.value(<Product>[]);
    }
  }

  Stream<List<Category>> getCategoriesStream({String? businessId}) {
    if (_isFirebaseAvailable) {
      Query query = _firestore!.collection(_categoriesCollection);

      if (businessId != null) {
        query = query.where('businessId', isEqualTo: businessId);
      }

      return query
          .orderBy('sortOrder')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => Category.fromJson({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  }),
                )
                .toList(),
          );
    } else {
      // Return empty stream if Firebase not available
      return Stream.value(<Category>[]);
    }
  }

  // Utility Operations
  Future<void> clearAllData() async {
    try {
      // Clear from Firestore (requires proper permissions)
      // This is typically not done in production - users should delete their own data

      // Clear from local storage
      await initialize();
      await _prefs.clear();
    } catch (e) {
      debugPrint('Clear all data error: $e');
      // Still clear local storage
      await initialize();
      await _prefs.clear();
    }
  }

  Future<void> initializeSampleData() async {
    try {
      final businesses = await getBusinesses();
      if (businesses.isEmpty) {
        await _createSampleData();
      }
    } catch (e) {
      debugPrint('Initialize sample data error: $e');
    }
  }

  // Local storage fallback methods
  Future<List<Business>> _getBusinessesFromLocal() async {
    await initialize();
    final businessesJson = _prefs.getStringList('businesses') ?? [];
    return businessesJson
        .map((json) => Business.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<Business?> _getBusinessFromLocal(String businessId) async {
    final businesses = await _getBusinessesFromLocal();
    try {
      return businesses.firstWhere((b) => b.businessId == businessId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveBusinessToLocal(Business business) async {
    await initialize();
    final businesses = await _getBusinessesFromLocal();
    final index = businesses.indexWhere(
      (b) => b.businessId == business.businessId,
    );

    if (index >= 0) {
      businesses[index] = business;
    } else {
      businesses.add(business);
    }

    final businessesJson = businesses
        .map((b) => jsonEncode(b.toJson()))
        .toList();
    await _prefs.setStringList('businesses', businessesJson);
  }

  Future<void> _deleteBusinessFromLocal(String businessId) async {
    await initialize();
    final businesses = await _getBusinessesFromLocal();
    businesses.removeWhere((b) => b.businessId == businessId);

    final businessesJson = businesses
        .map((b) => jsonEncode(b.toJson()))
        .toList();
    await _prefs.setStringList('businesses', businessesJson);
  }

  Future<List<Product>> _getProductsFromLocal({String? businessId}) async {
    await initialize();
    final productsJson = _prefs.getStringList('products') ?? [];
    var products = productsJson
        .map((json) => Product.fromJson(jsonDecode(json)))
        .toList();

    if (businessId != null) {
      products = products.where((p) => p.businessId == businessId).toList();
    }

    return products..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<Product?> _getProductFromLocal(String productId) async {
    final products = await _getProductsFromLocal();
    try {
      return products.firstWhere((p) => p.productId == productId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProductToLocal(Product product) async {
    await initialize();
    final products = await _getProductsFromLocal();
    final index = products.indexWhere((p) => p.productId == product.productId);

    if (index >= 0) {
      products[index] = product;
    } else {
      products.add(product);
    }

    final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList('products', productsJson);
  }

  Future<void> _deleteProductFromLocal(String productId) async {
    await initialize();
    final products = await _getProductsFromLocal();
    products.removeWhere((p) => p.productId == productId);

    final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList('products', productsJson);
  }

  Future<void> _deleteProductsByBusinessFromLocal(String businessId) async {
    await initialize();
    final products = await _getProductsFromLocal();
    products.removeWhere((p) => p.businessId == businessId);

    final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList('products', productsJson);
  }

  Future<List<Category>> _getCategoriesFromLocal({String? businessId}) async {
    await initialize();
    final categoriesJson = _prefs.getStringList('categories') ?? [];
    var categories = categoriesJson
        .map((json) => Category.fromJson(jsonDecode(json)))
        .toList();

    if (businessId != null) {
      categories = categories.where((c) => c.businessId == businessId).toList();
    }

    return categories..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<Category?> _getCategoryFromLocal(String categoryId) async {
    final categories = await _getCategoriesFromLocal();
    try {
      return categories.firstWhere((c) => c.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveCategoryToLocal(Category category) async {
    await initialize();
    final categories = await _getCategoriesFromLocal();
    final index = categories.indexWhere(
      (c) => c.categoryId == category.categoryId,
    );

    if (index >= 0) {
      categories[index] = category;
    } else {
      categories.add(category);
    }

    final categoriesJson = categories
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    await _prefs.setStringList('categories', categoriesJson);
  }

  Future<void> _deleteCategoryFromLocal(String categoryId) async {
    await initialize();
    final categories = await _getCategoriesFromLocal();
    categories.removeWhere((c) => c.categoryId == categoryId);

    final categoriesJson = categories
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    await _prefs.setStringList('categories', categoriesJson);
  }

  Future<void> _deleteCategoriesByBusinessFromLocal(String businessId) async {
    await initialize();
    final categories = await _getCategoriesFromLocal();
    categories.removeWhere((c) => c.businessId == businessId);

    final categoriesJson = categories
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    await _prefs.setStringList('categories', categoriesJson);
  }

  Future<User?> _getCurrentUserFromLocal() async {
    await initialize();
    final userJson = _prefs.getString('current_user');
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> _saveCurrentUserToLocal(User user) async {
    await initialize();
    await _prefs.setString('current_user', jsonEncode(user.toJson()));
  }

  Future<void> _clearCurrentUserFromLocal() async {
    await initialize();
    await _prefs.remove('current_user');
  }

  Future<void> _createSampleData() async {
    // Create sample business in Firestore
    final sampleBusiness = Business(
      businessId: 'demo-business-001',
      ownerId: 'demo-owner',
      businessName: 'Lezzet Durağı',
      businessDescription: 'Geleneksel Türk mutfağının en lezzetli örnekleri',
      logoUrl: 'https://picsum.photos/200/200?random=logo',
      address: Address(
        street: 'Atatürk Caddesi No:123',
        city: 'İstanbul',
        district: 'Beyoğlu',
        postalCode: '34000',
      ),
      contactInfo: ContactInfo(
        phone: '+90 212 555 1234',
        email: 'info@lezzetduragi.com',
        website: 'www.lezzetduragi.com',
      ),
      qrCodeUrl: null,
      menuSettings: MenuSettings(
        theme: 'light',
        primaryColor: '#FF6B35',
        fontFamily: 'Poppins',
        fontSize: 16.0,
        showPrices: true,
        showImages: true,
        imageSize: 'medium',
        language: 'tr',
      ),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveBusiness(sampleBusiness);

    // Create sample categories
    final sampleCategories = [
      Category(
        categoryId: 'cat-001',
        businessId: 'demo-business-001',
        name: 'Ana Yemekler',
        description: 'Geleneksel Türk ana yemekleri',
        imageUrl: 'https://picsum.photos/300/200?random=category1',
        sortOrder: 1,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        categoryId: 'cat-002',
        businessId: 'demo-business-001',
        name: 'Başlangıçlar',
        description: 'Lezzetli başlangıç yemekleri',
        imageUrl: 'https://picsum.photos/300/200?random=category2',
        sortOrder: 2,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        categoryId: 'cat-003',
        businessId: 'demo-business-001',
        name: 'İçecekler',
        description: 'Sıcak ve soğuk içecekler',
        imageUrl: 'https://picsum.photos/300/200?random=category3',
        sortOrder: 3,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final category in sampleCategories) {
      await saveCategory(category);
    }

    // Create sample products
    final sampleProducts = [
      Product(
        productId: 'prod-001',
        businessId: 'demo-business-001',
        categoryId: 'cat-001',
        name: 'Adana Kebabı',
        description: 'Özel baharatlarla hazırlanmış lezzetli Adana kebabı',
        detailedDescription:
            'Özenle seçilmiş dana eti, özel baharat karışımı ve geleneksel pişirme tekniği ile hazırlanan nefis Adana kebabı.',
        price: 45.00,
        currentPrice: 45.00,
        currency: 'TL',
        images: [
          ProductImage(
            url: 'https://picsum.photos/400/300?random=product1',
            alt: 'Adana Kebabı',
            isPrimary: true,
          ),
        ],
        allergens: [],
        tags: ['popular'],
        isActive: true,
        isAvailable: true,
        sortOrder: 1,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        productId: 'prod-002',
        businessId: 'demo-business-001',
        categoryId: 'cat-002',
        name: 'Humus',
        description: 'Geleneksel humus, taze ekmek ile servis edilir',
        detailedDescription:
            'Taze nohut, tahini, limon suyu ve özel baharat karışımı ile hazırlanan geleneksel humus.',
        price: 12.00,
        currentPrice: 12.00,
        currency: 'TL',
        images: [
          ProductImage(
            url: 'https://picsum.photos/400/300?random=product2',
            alt: 'Humus',
            isPrimary: true,
          ),
        ],
        allergens: ['sesame'],
        tags: ['vegetarian'],
        isActive: true,
        isAvailable: true,
        sortOrder: 1,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        productId: 'prod-003',
        businessId: 'demo-business-001',
        categoryId: 'cat-003',
        name: 'Türk Çayı',
        description: 'Geleneksel Türk çayı, ince belli bardakta servis edilir',
        detailedDescription:
            'Özenle seçilmiş çay yaprakları ile demlenmiş geleneksel Türk çayı.',
        price: 3.00,
        currentPrice: 3.00,
        currency: 'TL',
        images: [
          ProductImage(
            url: 'https://picsum.photos/400/300?random=product3',
            alt: 'Türk Çayı',
            isPrimary: true,
          ),
        ],
        allergens: [],
        tags: [],
        isActive: true,
        isAvailable: true,
        sortOrder: 1,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final product in sampleProducts) {
      await saveProduct(product);
    }

    debugPrint('Sample data created successfully');
  }

  // Discount Local Storage Methods
  Future<List<Discount>> _getDiscountsFromLocal(String businessId) async {
    await initialize();
    final discountsJson = _prefs.getStringList('discounts_$businessId') ?? [];
    return discountsJson
        .map((json) => Discount.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _saveDiscountToLocal(
    String businessId,
    Discount discount,
  ) async {
    await initialize();
    final discounts = await _getDiscountsFromLocal(businessId);

    // Remove existing discount with same ID
    discounts.removeWhere((d) => d.discountId == discount.discountId);

    // Add new discount
    discounts.add(discount);

    final discountsJson = discounts.map((d) => jsonEncode(d.toJson())).toList();
    await _prefs.setStringList('discounts_$businessId', discountsJson);
  }

  Future<void> _deleteDiscountFromLocal(
    String businessId,
    String discountId,
  ) async {
    await initialize();
    final discounts = await _getDiscountsFromLocal(businessId);

    // Remove discount with matching ID
    discounts.removeWhere((d) => d.discountId == discountId);

    final discountsJson = discounts.map((d) => jsonEncode(d.toJson())).toList();
    await _prefs.setStringList('discounts_$businessId', discountsJson);
  }
}
