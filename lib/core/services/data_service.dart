import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/business.dart';
import '../../data/models/product.dart';
import '../../data/models/category.dart';
import '../../data/models/user.dart';
import '../../data/models/discount.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Business Operations
  Future<List<Business>> getBusinesses() async {
    await initialize();
    final businessesJson = _prefs.getStringList('businesses') ?? [];
    return businessesJson
        .map((json) => Business.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<Business?> getBusiness(String businessId) async {
    final businesses = await getBusinesses();
    try {
      return businesses.firstWhere((b) => b.id == businessId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveBusiness(Business business) async {
    await initialize();
    final businesses = await getBusinesses();
    final index = businesses.indexWhere(
      (b) => b.id == business.id,
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

  Future<void> deleteBusiness(String businessId) async {
    await initialize();
    final businesses = await getBusinesses();
    businesses.removeWhere((b) => b.id == businessId);

    final businessesJson = businesses
        .map((b) => jsonEncode(b.toJson()))
        .toList();
    await _prefs.setStringList('businesses', businessesJson);

    // Also delete related products and categories
    await deleteProductsByBusiness(businessId);
    await deleteCategoriesByBusiness(businessId);
  }

  // Product Operations
  Future<List<Product>> getProducts({String? businessId}) async {
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

  Future<Product?> getProduct(String productId) async {
    final products = await getProducts();
    try {
      return products.firstWhere((p) => p.productId == productId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveProduct(Product product) async {
    await initialize();
    final products = await getProducts();
    final index = products.indexWhere((p) => p.productId == product.productId);

    if (index >= 0) {
      products[index] = product;
    } else {
      products.add(product);
    }

    final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList('products', productsJson);
  }

  Future<void> deleteProduct(String productId) async {
    await initialize();
    final products = await getProducts();
    products.removeWhere((p) => p.productId == productId);

    final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList('products', productsJson);
  }

  Future<void> deleteProductsByBusiness(String businessId) async {
    await initialize();
    final products = await getProducts();
    products.removeWhere((p) => p.businessId == businessId);

    final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList('products', productsJson);
  }

  // Category Operations
  Future<List<Category>> getCategories({String? businessId}) async {
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

  Future<Category?> getCategory(String categoryId) async {
    final categories = await getCategories();
    try {
      return categories.firstWhere((c) => c.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveCategory(Category category) async {
    await initialize();
    final categories = await getCategories();
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

  Future<void> deleteCategory(String categoryId) async {
    await initialize();
    final categories = await getCategories();
    categories.removeWhere((c) => c.categoryId == categoryId);

    final categoriesJson = categories
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    await _prefs.setStringList('categories', categoriesJson);
  }

  Future<void> deleteCategoriesByBusiness(String businessId) async {
    await initialize();
    final categories = await getCategories();
    categories.removeWhere((c) => c.businessId == businessId);

    final categoriesJson = categories
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    await _prefs.setStringList('categories', categoriesJson);
  }

  // Sample Data Creation (Removed - Using real user data only)
  Future<void> initializeEmptyDatabase() async {
    await initialize();
    
    // Clear all sample data
    await _prefs.remove('businesses');
    await _prefs.remove('products');
    await _prefs.remove('categories');
    await _prefs.remove('discounts');
    
    print('Database initialized with empty collections');
  }

  // Discount CRUD Operations
  Future<List<Discount>> getDiscounts() async {
    await initialize();
    final discountStrings = _prefs.getStringList('discounts') ?? [];
    return discountStrings
        .map((str) => Discount.fromJson(jsonDecode(str)))
        .toList();
  }

  Future<List<Discount>> getDiscountsByBusinessId(String businessId) async {
    final discounts = await getDiscounts();
    return discounts.where((d) => d.businessId == businessId).toList();
  }

  Future<Discount?> getDiscount(String discountId) async {
    final discounts = await getDiscounts();
    try {
      return discounts.firstWhere((d) => d.discountId == discountId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveDiscount(Discount discount) async {
    await initialize();
    final discounts = await getDiscounts();
    final index = discounts.indexWhere(
      (d) => d.discountId == discount.discountId,
    );

    if (index >= 0) {
      discounts[index] = discount;
    } else {
      discounts.add(discount);
    }

    final discountsJson = discounts.map((d) => jsonEncode(d.toJson())).toList();
    await _prefs.setStringList('discounts', discountsJson);
  }

  Future<void> deleteDiscount(String discountId) async {
    await initialize();
    final discounts = await getDiscounts();
    discounts.removeWhere((d) => d.discountId == discountId);

    final discountsJson = discounts.map((d) => jsonEncode(d.toJson())).toList();
    await _prefs.setStringList('discounts', discountsJson);
  }

  Future<void> deleteDiscountsByBusinessId(String businessId) async {
    await initialize();
    final discounts = await getDiscounts();
    discounts.removeWhere((d) => d.businessId == businessId);

    final discountsJson = discounts.map((d) => jsonEncode(d.toJson())).toList();
    await _prefs.setStringList('discounts', discountsJson);
  }

  // Advanced discount operations
  Future<List<Discount>> getActiveDiscounts(String businessId) async {
    final discounts = await getDiscountsByBusinessId(businessId);
    return discounts.where((d) => d.isCurrentlyActive).toList();
  }

  Future<List<Discount>> getDiscountsForProduct(
    String businessId,
    String productId,
    String categoryId,
  ) async {
    final discounts = await getActiveDiscounts(businessId);
    return discounts
        .where((d) => d.appliesToProduct(productId, categoryId))
        .toList();
  }

  Future<void> incrementDiscountUsage(String discountId) async {
    final discount = await getDiscount(discountId);
    if (discount != null) {
      await saveDiscount(
        discount.copyWith(
          usageCount: discount.usageCount + 1,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }
}
