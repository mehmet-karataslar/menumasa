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
      return businesses.firstWhere((b) => b.businessId == businessId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveBusiness(Business business) async {
    await initialize();
    final businesses = await getBusinesses();
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

  Future<void> deleteBusiness(String businessId) async {
    await initialize();
    final businesses = await getBusinesses();
    businesses.removeWhere((b) => b.businessId == businessId);

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

  // User Operations
  Future<User?> getCurrentUser() async {
    await initialize();
    final userJson = _prefs.getString('current_user');
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> saveCurrentUser(User user) async {
    await initialize();
    await _prefs.setString('current_user', jsonEncode(user.toJson()));
  }

  Future<void> clearCurrentUser() async {
    await initialize();
    await _prefs.remove('current_user');
  }

  // Utility Operations
  Future<void> clearAllData() async {
    await initialize();
    await _prefs.clear();
  }

  Future<void> initializeSampleData() async {
    final businesses = await getBusinesses();
    if (businesses.isEmpty) {
      await _createSampleData();
    }
  }

  Future<void> _createSampleData() async {
    // Create sample business
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
      qrCodeUrl: null, // Will be generated
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
    final categories = [
      Category(
        categoryId: 'cat-001',
        businessId: sampleBusiness.businessId,
        name: 'Ana Yemekler',
        description: 'Doyurucu ve lezzetli ana yemeklerimiz',
        imageUrl: 'https://picsum.photos/300/200?random=main',
        parentCategoryId: null,
        sortOrder: 1,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        categoryId: 'cat-002',
        businessId: sampleBusiness.businessId,
        name: 'Başlangıçlar',
        description: 'Yemeğe lezzetli bir başlangıç',
        imageUrl: 'https://picsum.photos/300/200?random=starter',
        parentCategoryId: null,
        sortOrder: 2,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        categoryId: 'cat-003',
        businessId: sampleBusiness.businessId,
        name: 'İçecekler',
        description: 'Serinletici ve enerji verici içecekler',
        imageUrl: 'https://picsum.photos/300/200?random=drinks',
        parentCategoryId: null,
        sortOrder: 3,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final category in categories) {
      await saveCategory(category);
    }

    // Create sample products
    final products = [
      Product(
        productId: 'prod-001',
        businessId: sampleBusiness.businessId,
        categoryId: 'cat-001',
        name: 'Adana Kebap',
        description:
            'Geleneksel baharat karışımı ile hazırlanmış lezzetli Adana kebap',
        detailedDescription:
            'Özenle seçilmiş dana eti, özel baharat karışımı ve geleneksel pişirme tekniği ile hazırlanan nefis Adana kebap. Yanında bulgur pilavı, közlenmiş domates ve biber ile servis edilir.',
        price: 85.0,
        currentPrice: 85.0,
        currency: 'TL',
        images: [
          ProductImage(
            url: 'https://picsum.photos/400/300?random=adana',
            alt: 'Adana Kebap',
            isPrimary: true,
          ),
        ],
        nutritionInfo: null,
        allergens: [],
        tags: ['popular', 'spicy'],
        isActive: true,
        isAvailable: true,
        sortOrder: 1,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        productId: 'prod-002',
        businessId: sampleBusiness.businessId,
        categoryId: 'cat-001',
        name: 'Kuzu Şiş',
        description: 'Yumuşacık kuzu eti ile hazırlanan özel şiş kebap',
        detailedDescription:
            'Taze kuzu eti, özel marine ile yumuşatılarak şişe geçirilip közde pişirilen nefis şiş kebap.',
        price: 95.0,
        currentPrice: 95.0,
        currency: 'TL',
        images: [
          ProductImage(
            url: 'https://picsum.photos/400/300?random=lamb',
            alt: 'Kuzu Şiş',
            isPrimary: true,
          ),
        ],
        nutritionInfo: null,
        allergens: [],
        tags: ['new'],
        isActive: true,
        isAvailable: true,
        sortOrder: 2,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        productId: 'prod-003',
        businessId: sampleBusiness.businessId,
        categoryId: 'cat-002',
        name: 'Humus',
        description: 'Ev yapımı humus, taze sebzeler ile',
        detailedDescription:
            'Taze nohut, tahini, limon suyu ve özel baharat karışımı ile hazırlanan geleneksel humus.',
        price: 25.0,
        currentPrice: 25.0,
        currency: 'TL',
        images: [
          ProductImage(
            url: 'https://picsum.photos/400/300?random=humus',
            alt: 'Humus',
            isPrimary: true,
          ),
        ],
        nutritionInfo: null,
        allergens: ['sesame'],
        tags: ['vegetarian', 'vegan'],
        isActive: true,
        isAvailable: true,
        sortOrder: 1,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        productId: 'prod-004',
        businessId: sampleBusiness.businessId,
        categoryId: 'cat-003',
        name: 'Ayran',
        description: 'Ev yapımı taze ayran',
        detailedDescription:
            'Taze yoğurt ve tuz ile geleneksel yöntemlerle hazırlanan serinletici ayran.',
        price: 8.0,
        currentPrice: 8.0,
        currency: 'TL',
        images: [
          ProductImage(
            url: 'https://picsum.photos/400/300?random=ayran',
            alt: 'Ayran',
            isPrimary: true,
          ),
        ],
        nutritionInfo: null,
        allergens: ['milk'],
        tags: [],
        isActive: true,
        isAvailable: true,
        sortOrder: 1,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final product in products) {
      await saveProduct(product);
    }

    // Create sample discounts
    final discounts = [
      DiscountDefaults.happyHourDiscount.copyWith(
        businessId: sampleBusiness.businessId,
        targetCategoryIds: ['cat-003'], // İçecekler kategorisi
      ),
      DiscountDefaults.weekendSpecial.copyWith(
        businessId: sampleBusiness.businessId,
      ),
      Discount(
        discountId: 'breakfast-discount',
        businessId: sampleBusiness.businessId,
        name: 'Kahvaltı Saatleri İndirimi',
        description: 'Sabah 8-11 arası başlangıçlarda %10 indirim',
        type: DiscountType.percentage,
        value: 10.0,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        timeRules: [
          CategoryDefaults.breakfastTimeRule.copyWith(
            ruleId: 'breakfast-discount-time',
            startTime: '08:00',
            endTime: '11:00',
          ),
        ],
        targetProductIds: [],
        targetCategoryIds: ['cat-002'], // Başlangıçlar kategorisi
        usageCount: 0,
        isActive: true,
        combineWithOtherDiscounts: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final discount in discounts) {
      await saveDiscount(discount);
    }
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
