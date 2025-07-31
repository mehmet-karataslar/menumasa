// Firebase imports removed for Windows compatibility
import 'category.dart';
import 'discount.dart';

class Product {
  final String productId;
  final String businessId;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final String currency;
  final List<ProductImage> images;
  final NutritionInfo? nutritionInfo;
  final List<String> allergens;
  final List<String> tags;
  final bool isActive;
  final bool isAvailable;
  final int sortOrder;
  final List<TimeRule> timeRules;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Getter for id to match expected interface
  String get id => productId;

  Product({
    required this.productId,
    required this.businessId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.images,
    this.nutritionInfo,
    required this.allergens,
    required this.tags,
    required this.isActive,
    required this.isAvailable,
    required this.sortOrder,
    required this.timeRules,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> data, {String? id}) {
    return Product(
      productId: id ?? data['productId'] ?? '',
      businessId: data['businessId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: _parsePrice(data['price']),
      currency: data['currency'] ?? 'TL',
      images: (data['images'] as List<dynamic>? ?? [])
          .map((image) => ProductImage.fromMap(image))
          .toList(),
      nutritionInfo: data['nutritionInfo'] != null
          ? NutritionInfo.fromMap(data['nutritionInfo'])
          : null,
      allergens: List<String>.from(data['allergens'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      isActive: data['isActive'] ?? true,
      isAvailable: data['isAvailable'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
      timeRules: (data['timeRules'] as List<dynamic>? ?? [])
          .map((rule) => TimeRule.fromMap(rule))
          .toList(),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  // Firestore factory method - alias for fromJson
  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product.fromJson(data, id: id);
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      // Try to parse string as number, return 0.0 if it fails
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      } else {
        print(
            'Warning: Could not parse price value "$value" as double, using 0.0');
        return 0.0;
      }
    }

    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    // Handle Firestore Timestamp
    if (value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate();
    }

    // Handle String
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle DateTime (already parsed)
    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'businessId': businessId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'images': images.map((image) => image.toMap()).toList(),
      'nutritionInfo': nutritionInfo?.toMap(),
      'allergens': allergens,
      'tags': tags,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'sortOrder': sortOrder,
      'timeRules': timeRules.map((rule) => rule.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? productId,
    String? businessId,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    String? currency,
    List<ProductImage>? images,
    NutritionInfo? nutritionInfo,
    List<String>? allergens,
    List<String>? tags,
    bool? isActive,
    bool? isAvailable,
    int? sortOrder,
    List<TimeRule>? timeRules,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      productId: productId ?? this.productId,
      businessId: businessId ?? this.businessId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      images: images ?? this.images,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      allergens: allergens ?? this.allergens,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
      timeRules: timeRules ?? this.timeRules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  String get formattedPrice => '${price.toStringAsFixed(2)} $currency';

  String get displayName => name;

  ProductImage? get primaryImage => images.firstWhere(
        (img) => img.isPrimary,
        orElse: () => images.isNotEmpty ? images.first : ProductImage.empty(),
      );

  List<ProductImage> get secondaryImages =>
      images.where((img) => !img.isPrimary).toList();

  /// Şu anki zaman kurallarına göre ürünün aktif olup olmadığını kontrol eder
  bool get isActiveNow {
    if (!isActive || !isAvailable) return false;
    if (timeRules.isEmpty) return true;

    final now = DateTime.now();
    final currentDay = now.weekday % 7;
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    for (final rule in timeRules) {
      if (!rule.isActive) continue;

      if (rule.dayOfWeek.contains(currentDay)) {
        if (_isTimeBetween(currentTime, rule.startTime, rule.endTime)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isTimeBetween(String current, String start, String end) {
    final currentMinutes = _timeToMinutes(current);
    final startMinutes = _timeToMinutes(start);
    final endMinutes = _timeToMinutes(end);

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Ürünün belirli bir tag'e sahip olup olmadığını kontrol eder
  bool hasTag(String tag) => tags.contains(tag);

  /// Ürünün belirli bir alerjene sahip olup olmadığını kontrol eder
  bool hasAllergen(String allergen) => allergens.contains(allergen);

  /// Ürünün vejetaryen olup olmadığını kontrol eder
  bool get isVegetarian => hasTag('vegetarian');

  /// Ürünün vegan olup olmadığını kontrol eder
  bool get isVegan => hasTag('vegan');

  /// Ürünün halal olup olmadığını kontrol eder
  bool get isHalal => hasTag('halal');

  /// Ürünün acı olup olmadığını kontrol eder
  bool get isSpicy => hasTag('spicy');

  /// Ürünün yeni olup olmadığını kontrol eder
  bool get isNew => hasTag('new');

  /// Ürünün popüler olup olmadığını kontrol eder
  bool get isPopular => hasTag('popular');

  @override
  String toString() {
    return 'Product(productId: $productId, name: $name, price: $price, isActive: $isActive, isAvailable: $isAvailable)';
  }

  // Convenience getters for backward compatibility
  String get productName => name;
  String? get imageUrl => images.isNotEmpty ? images.first.url : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.productId == productId;
  }

  @override
  int get hashCode => productId.hashCode;
}

class ProductImage {
  final String url;
  final String alt;
  final bool isPrimary;

  ProductImage({required this.url, required this.alt, required this.isPrimary});

  factory ProductImage.fromMap(Map<String, dynamic> map) {
    return ProductImage(
      url: map['url'] ?? '',
      alt: map['alt'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'url': url, 'alt': alt, 'isPrimary': isPrimary};
  }

  ProductImage copyWith({String? url, String? alt, bool? isPrimary}) {
    return ProductImage(
      url: url ?? this.url,
      alt: alt ?? this.alt,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  static ProductImage empty() =>
      ProductImage(url: '', alt: '', isPrimary: false);

  @override
  String toString() {
    return 'ProductImage(url: $url, alt: $alt, isPrimary: $isPrimary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}

class NutritionInfo {
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;

  NutritionInfo({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
  });

  factory NutritionInfo.fromMap(Map<String, dynamic> map) {
    return NutritionInfo(
      calories: _parseNutritionValue(map['calories']),
      protein: _parseNutritionValue(map['protein']),
      carbs: _parseNutritionValue(map['carbs']),
      fat: _parseNutritionValue(map['fat']),
      fiber: _parseNutritionValue(map['fiber']),
      sugar: _parseNutritionValue(map['sugar']),
      sodium: _parseNutritionValue(map['sodium']),
    );
  }

  static double? _parseNutritionValue(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      } else {
        print(
            'Warning: Could not parse nutrition value "$value" as double, using null');
        return null;
      }
    }

    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
    };
  }

  NutritionInfo copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
  }) {
    return NutritionInfo(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
    );
  }

  @override
  String toString() {
    return 'NutritionInfo(calories: $calories, protein: $protein, carbs: $carbs, fat: $fat)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutritionInfo &&
        other.calories == calories &&
        other.protein == protein &&
        other.carbs == carbs &&
        other.fat == fat;
  }

  @override
  int get hashCode {
    return calories.hashCode ^ protein.hashCode ^ carbs.hashCode ^ fat.hashCode;
  }
}

// Default instances and helper methods
class ProductDefaults {
  static Product createDefault({
    required String productId,
    required String businessId,
    required String categoryId,
    required String name,
    String? description,
    double price = 0.0,
    String currency = 'TL',
  }) {
    return Product(
      productId: productId,
      businessId: businessId,
      categoryId: categoryId,
      name: name,
      description: description ?? '',
      price: price,
      currency: currency,
      images: [],
      allergens: [],
      tags: [],
      isActive: true,
      isAvailable: true,
      sortOrder: 0,
      timeRules: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static ProductImage createDefaultImage({
    required String url,
    String? alt,
    bool isPrimary = false,
  }) {
    return ProductImage(url: url, alt: alt ?? '', isPrimary: isPrimary);
  }

  static NutritionInfo createDefaultNutrition() {
    return NutritionInfo(
      calories: 0.0,
      protein: 0.0,
      carbs: 0.0,
      fat: 0.0,
      fiber: 0.0,
      sugar: 0.0,
      sodium: 0.0,
    );
  }
}

// Common tags enum
enum ProductTag {
  vegetarian('vegetarian', 'Vejetaryen'),
  vegan('vegan', 'Vegan'),
  halal('halal', 'Helal'),
  spicy('spicy', 'Acı'),
  new_('new', 'Yeni'),
  popular('popular', 'Popüler'),
  recommended('recommended', 'Tavsiye Edilen'),
  glutenFree('gluten_free', 'Glutensiz'),
  dairyFree('dairy_free', 'Sütsüz'),
  organic('organic', 'Organik'),
  seasonal('seasonal', 'Mevsimlik'),
  signature('signature', 'Özel'),
  kids('kids', 'Çocuk'),
  healthy('healthy', 'Sağlıklı'),
  lowCalorie('low_calorie', 'Düşük Kalorili'),
  highProtein('high_protein', 'Yüksek Protein'),
  keto('keto', 'Keto'),
  paleo('paleo', 'Paleo');

  const ProductTag(this.value, this.displayName);
  final String value;
  final String displayName;
}

// Common allergens enum
enum ProductAllergen {
  gluten('gluten', 'Gluten'),
  lactose('lactose', 'Laktoz'),
  nuts('nuts', 'Fındık/Fıstık'),
  peanuts('peanuts', 'Yer Fıstığı'),
  eggs('eggs', 'Yumurta'),
  fish('fish', 'Balık'),
  shellfish('shellfish', 'Kabuklu Deniz Ürünleri'),
  soy('soy', 'Soya'),
  sesame('sesame', 'Susam'),
  mustard('mustard', 'Hardal'),
  celery('celery', 'Kereviz'),
  sulphites('sulphites', 'Sülfitler');

  const ProductAllergen(this.value, this.displayName);
  final String value;
  final String displayName;
}

// Extension methods for better usability
extension ProductExtensions on Product {
  /// Ürünün kategori bilgilerini alır
  String getCategoryName(List<Category> categories) {
    try {
      final category = categories.firstWhere(
        (cat) => cat.categoryId == categoryId,
      );
      return category.name;
    } catch (e) {
      return 'Bilinmeyen Kategori';
    }
  }

  /// Ürünün fiyat bilgilerini formatted string olarak döndürür
  String getPriceDisplay() {
    return formattedPrice;
  }

  /// Ürünün tag'lerini görüntülenebilir isimlerle döndürür
  List<String> getDisplayTags() {
    return tags.map((tag) {
      try {
        final productTag = ProductTag.values.firstWhere(
          (pt) => pt.value == tag,
        );
        return productTag.displayName;
      } catch (e) {
        return tag;
      }
    }).toList();
  }

  /// Ürünün alerjenlerini görüntülenebilir isimlerle döndürür
  List<String> getDisplayAllergens() {
    return allergens.map((allergen) {
      try {
        final productAllergen = ProductAllergen.values.firstWhere(
          (pa) => pa.value == allergen,
        );
        return productAllergen.displayName;
      } catch (e) {
        return allergen;
      }
    }).toList();
  }

  /// Ürünün arama kriterlerine uyup uymadığını kontrol eder
  bool matchesSearchQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        description.toLowerCase().contains(lowerQuery) ||
        tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
        allergens.any(
          (allergen) => allergen.toLowerCase().contains(lowerQuery),
        );
  }

  /// Ürünün filtreleme kriterlerine uyup uymadığını kontrol eder
  bool matchesFilters({
    List<String>? tagFilters,
    List<String>? allergenFilters,
    double? minPrice,
    double? maxPrice,
    bool? isVegetarian,
    bool? isVegan,
    bool? isHalal,
    bool? isSpicy,
  }) {
    // Tag filtreleri
    if (tagFilters != null && tagFilters.isNotEmpty) {
      if (!tagFilters.any((filter) => tags.contains(filter))) {
        return false;
      }
    }

    // Alerjen filtreleri
    if (allergenFilters != null && allergenFilters.isNotEmpty) {
      if (allergenFilters.any((filter) => allergens.contains(filter))) {
        return false; // Alerjen içeriyorsa false döner
      }
    }

    // Fiyat filtreleri
    if (minPrice != null && price < minPrice) return false;
    if (maxPrice != null && price > maxPrice) return false;

    // Özel filtreler
    if (isVegetarian == true && !this.isVegetarian) return false;
    if (isVegan == true && !this.isVegan) return false;
    if (isHalal == true && !this.isHalal) return false;
    if (isSpicy == true && !this.isSpicy) return false;

    return true;
  }

  /// İndirim hesaplama methodları
  /// Ürüne uygulanan tüm indirimleri hesaplar
  double calculateFinalPrice(
    List<Discount> discounts, {
    PriceRoundingRule? roundingRule,
  }) {
    double finalPrice = price; // Tek fiyat sistemi - price kullan

    for (final discount in discounts) {
      if (discount.isCurrentlyActive &&
          discount.appliesToProduct(productId, categoryId)) {
        finalPrice = discount.calculateDiscountedPrice(finalPrice);
      }
    }

    if (roundingRule != null) {
      finalPrice = _roundPrice(finalPrice, roundingRule);
    }

    return finalPrice;
  }

  /// En büyük indirimi bulur
  Discount? getBestDiscount(List<Discount> discounts) {
    Discount? bestDiscount;
    double maxDiscountAmount = 0.0;

    for (final discount in discounts) {
      if (discount.isCurrentlyActive &&
          discount.appliesToProduct(productId, categoryId)) {
        final discountAmount = price - discount.calculateDiscountedPrice(price);
        if (discountAmount > maxDiscountAmount) {
          maxDiscountAmount = discountAmount;
          bestDiscount = discount;
        }
      }
    }

    return bestDiscount;
  }

  /// Ürüne uygulanan tüm aktif indirimleri döndürür
  List<Discount> getApplicableDiscounts(List<Discount> discounts) {
    return discounts
        .where(
          (discount) =>
              discount.isCurrentlyActive &&
              discount.appliesToProduct(productId, categoryId),
        )
        .toList();
  }

  /// İndirimli fiyatı formatted string olarak döndürür
  String getDiscountedPriceDisplay(
    List<Discount> discounts, {
    PriceRoundingRule? roundingRule,
  }) {
    final finalPrice = calculateFinalPrice(
      discounts,
      roundingRule: roundingRule,
    );
    final bestDiscount = getBestDiscount(discounts);

    if (bestDiscount != null && finalPrice < price) {
      return '${finalPrice.toStringAsFixed(2)} $currency (${bestDiscount.formattedDescription})';
    }

    return formattedPrice;
  }

  /// Fiyat yuvarlama fonksiyonu
  double _roundPrice(double price, PriceRoundingRule rule) {
    switch (rule) {
      case PriceRoundingRule.noRounding:
        return price;
      case PriceRoundingRule.roundToNearest:
        return price.round().toDouble();
      case PriceRoundingRule.roundUp:
        return price.ceil().toDouble();
      case PriceRoundingRule.roundDown:
        return price.floor().toDouble();
      case PriceRoundingRule.roundToNearest5:
        return (price / 5).round() * 5.0;
      case PriceRoundingRule.roundToNearest10:
        return (price / 10).round() * 10.0;
    }
  }
}
