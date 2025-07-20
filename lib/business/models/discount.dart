import 'category.dart';

class Discount {
  final String discountId;
  final String businessId;
  final String name;
  final String description;
  final DiscountType type;
  final double value; // Percentage (0-100) or fixed amount
  final DateTime startDate;
  final DateTime endDate;
  final List<TimeRule> timeRules; // When discount is active
  final List<String> targetProductIds; // Empty means all products
  final List<String> targetCategoryIds; // Empty means all categories
  final double? minOrderAmount; // Minimum order amount to apply discount
  final double? maxDiscountAmount; // Maximum discount amount (for percentage)
  final int? usageLimit; // How many times can be used
  final int usageCount; // How many times has been used
  final bool isActive;
  final bool combineWithOtherDiscounts;
  final DateTime createdAt;
  final DateTime updatedAt;

  Discount({
    required this.discountId,
    required this.businessId,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
    required this.timeRules,
    required this.targetProductIds,
    required this.targetCategoryIds,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.usageLimit,
    required this.usageCount,
    required this.isActive,
    required this.combineWithOtherDiscounts,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      discountId: json['discountId'] ?? '',
      businessId: json['businessId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: DiscountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DiscountType.percentage,
      ),
      value: (json['value'] ?? 0.0).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      timeRules:
          (json['timeRules'] as List<dynamic>?)
              ?.map((rule) => TimeRule.fromMap(rule))
              .toList() ??
          [],
      targetProductIds: List<String>.from(json['targetProductIds'] ?? []),
      targetCategoryIds: List<String>.from(json['targetCategoryIds'] ?? []),
      minOrderAmount: json['minOrderAmount']?.toDouble(),
      maxDiscountAmount: json['maxDiscountAmount']?.toDouble(),
      usageLimit: json['usageLimit'],
      usageCount: json['usageCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      combineWithOtherDiscounts: json['combineWithOtherDiscounts'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discountId': discountId,
      'businessId': businessId,
      'name': name,
      'description': description,
      'type': type.name,
      'value': value,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'timeRules': timeRules.map((rule) => rule.toMap()).toList(),
      'targetProductIds': targetProductIds,
      'targetCategoryIds': targetCategoryIds,
      'minOrderAmount': minOrderAmount,
      'maxDiscountAmount': maxDiscountAmount,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'isActive': isActive,
      'combineWithOtherDiscounts': combineWithOtherDiscounts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Discount copyWith({
    String? discountId,
    String? businessId,
    String? name,
    String? description,
    DiscountType? type,
    double? value,
    DateTime? startDate,
    DateTime? endDate,
    List<TimeRule>? timeRules,
    List<String>? targetProductIds,
    List<String>? targetCategoryIds,
    double? minOrderAmount,
    double? maxDiscountAmount,
    int? usageLimit,
    int? usageCount,
    bool? isActive,
    bool? combineWithOtherDiscounts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Discount(
      discountId: discountId ?? this.discountId,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timeRules: timeRules ?? this.timeRules,
      targetProductIds: targetProductIds ?? this.targetProductIds,
      targetCategoryIds: targetCategoryIds ?? this.targetCategoryIds,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      isActive: isActive ?? this.isActive,
      combineWithOtherDiscounts:
          combineWithOtherDiscounts ?? this.combineWithOtherDiscounts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if discount is currently active
  bool get isCurrentlyActive {
    if (!isActive) return false;

    final now = DateTime.now();
    if (now.isBefore(startDate) || now.isAfter(endDate)) return false;

    // Check usage limit
    if (usageLimit != null && usageCount >= usageLimit!) return false;

    // Check time rules
    if (timeRules.isNotEmpty) {
      final currentDay = now.weekday % 7; // 0=Sunday, 1=Monday
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      bool hasActiveRule = false;
      for (final rule in timeRules) {
        if (!rule.isActive) continue;
        if (!rule.dayOfWeek.contains(currentDay)) continue;
        if (_isTimeInRange(currentTime, rule.startTime, rule.endTime)) {
          hasActiveRule = true;
          break;
        }
      }

      if (!hasActiveRule) return false;
    }

    return true;
  }

  /// Check if discount applies to a specific product
  bool appliesToProduct(String productId, String categoryId) {
    // If no targets specified, applies to all
    if (targetProductIds.isEmpty && targetCategoryIds.isEmpty) return true;

    // Check product IDs
    if (targetProductIds.contains(productId)) return true;

    // Check category IDs
    if (targetCategoryIds.contains(categoryId)) return true;

    return false;
  }

  /// Calculate discounted price
  double calculateDiscountedPrice(double originalPrice) {
    if (!isCurrentlyActive) return originalPrice;

    double discountAmount = 0.0;

    switch (type) {
      case DiscountType.percentage:
        discountAmount = originalPrice * (value / 100);
        break;
      case DiscountType.fixedAmount:
        discountAmount = value;
        break;
    }

    // Apply maximum discount limit
    if (maxDiscountAmount != null && discountAmount > maxDiscountAmount!) {
      discountAmount = maxDiscountAmount!;
    }

    final discountedPrice = originalPrice - discountAmount;

    // Don't allow negative prices
    if (discountedPrice < 0) return 0.0;

    return discountedPrice;
  }

  /// Calculate rounded discounted price
  double calculateRoundedDiscountedPrice(
    double originalPrice, {
    PriceRoundingRule? roundingRule,
  }) {
    final discountedPrice = calculateDiscountedPrice(originalPrice);

    if (roundingRule == null) return discountedPrice;

    return _roundPrice(discountedPrice, roundingRule);
  }

  /// Round price according to rounding rule
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

  /// Check if time is in range
  bool _isTimeInRange(String currentTime, String startTime, String endTime) {
    final current = _timeToMinutes(currentTime);
    final start = _timeToMinutes(startTime);
    final end = _timeToMinutes(endTime);

    if (start <= end) {
      return current >= start && current <= end;
    } else {
      // Crosses midnight
      return current >= start || current <= end;
    }
  }

  /// Convert time to minutes
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  String toString() {
    return 'Discount(discountId: $discountId, name: $name, type: $type, value: $value, isActive: $isActive)';
  }

  // Convenience getters for backward compatibility
  List<String> get applicableCategories => targetCategoryIds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Discount && other.discountId == discountId;
  }

  @override
  int get hashCode => discountId.hashCode;
}

enum DiscountType {
  percentage('Yüzde'),
  fixedAmount('Sabit Tutar');

  const DiscountType(this.displayName);
  final String displayName;
}

enum PriceRoundingRule {
  noRounding('Yuvarlama Yok'),
  roundToNearest('En Yakın Tam Sayı'),
  roundUp('Yukarı Yuvarlama'),
  roundDown('Aşağı Yuvarlama'),
  roundToNearest5('En Yakın 5'),
  roundToNearest10('En Yakın 10');

  const PriceRoundingRule(this.displayName);
  final String displayName;
}

class DiscountDefaults {
  static Discount createDefault({
    required String discountId,
    required String businessId,
    required String name,
    String? description,
    required DiscountType type,
    required double value,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();

    return Discount(
      discountId: discountId,
      businessId: businessId,
      name: name,
      description: description ?? '',
      type: type,
      value: value,
      startDate: startDate ?? now,
      endDate: endDate ?? now.add(const Duration(days: 30)),
      timeRules: [],
      targetProductIds: [],
      targetCategoryIds: [],
      usageCount: 0,
      isActive: true,
      combineWithOtherDiscounts: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Common discount templates
  static Discount get coffeeDiscount => createDefault(
    discountId: 'coffee-discount',
    businessId: 'demo-business',
    name: 'Kahve İndirimi',
    description: 'Tüm kahve ürünlerinde %15 indirim',
    type: DiscountType.percentage,
    value: 15.0,
  );

  static Discount get happyHourDiscount => Discount(
    discountId: 'happy-hour',
    businessId: 'demo-business',
    name: 'Happy Hour',
    description: 'Öğleden sonra 3-6 arası tüm içeceklerde %20 indirim',
    type: DiscountType.percentage,
    value: 20.0,
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 365)),
    timeRules: [
      TimeRule(
        ruleId: 'happy-hour-time',
        name: 'Happy Hour Saatleri',
        dayOfWeek: [1, 2, 3, 4, 5], // Monday to Friday
        startTime: '15:00',
        endTime: '18:00',
        isActive: true,
      ),
    ],
    targetProductIds: [],
    targetCategoryIds: ['beverages'],
    usageCount: 0,
    isActive: true,
    combineWithOtherDiscounts: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static Discount get weekendSpecial => Discount(
    discountId: 'weekend-special',
    businessId: 'demo-business',
    name: 'Hafta Sonu Özel',
    description: 'Hafta sonu tüm ürünlerde 25 TL indirim',
    type: DiscountType.fixedAmount,
    value: 25.0,
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 90)),
    timeRules: [
      TimeRule(
        ruleId: 'weekend-time',
        name: 'Hafta Sonu',
        dayOfWeek: [0, 6], // Sunday and Saturday
        startTime: '00:00',
        endTime: '23:59',
        isActive: true,
      ),
    ],
    targetProductIds: [],
    targetCategoryIds: [],
    minOrderAmount: 100.0,
    maxDiscountAmount: 25.0,
    usageCount: 0,
    isActive: true,
    combineWithOtherDiscounts: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

// Extension methods for better usability
extension DiscountExtensions on Discount {
  /// Get human-readable discount description
  String get formattedDescription {
    final typeText = type == DiscountType.percentage
        ? '%${value.toInt()}'
        : '${value.toInt()} TL';

    String targets = '';
    if (targetProductIds.isNotEmpty || targetCategoryIds.isNotEmpty) {
      targets = ' (belirli ürünlerde)';
    }

    return '$typeText indirim$targets';
  }

  /// Get remaining days until expiration
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Check if discount is expiring soon (within 7 days)
  bool get isExpiringSoon {
    return remainingDays <= 7 && remainingDays > 0;
  }

  /// Get usage percentage
  double get usagePercentage {
    if (usageLimit == null) return 0.0;
    return (usageCount / usageLimit!) * 100;
  }
}
