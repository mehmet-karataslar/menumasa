// Firebase imports removed for Windows compatibility

class Category {
  final String categoryId;
  final String businessId;
  final String name;
  final String description;
  final String? imageUrl;
  final String? parentCategoryId;
  final int sortOrder;
  final bool isActive;
  final List<TimeRule> timeRules;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.categoryId,
    required this.businessId,
    required this.name,
    required this.description,
    this.imageUrl,
    this.parentCategoryId,
    required this.sortOrder,
    required this.isActive,
    required this.timeRules,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> data, {String? id}) {
    return Category(
      categoryId: id ?? data['categoryId'] ?? '',
      businessId: data['businessId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      parentCategoryId: data['parentCategoryId'],
      sortOrder: data['sortOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
      timeRules: (data['timeRules'] as List<dynamic>? ?? [])
          .map((rule) => TimeRule.fromMap(rule))
          .toList(),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'businessId': businessId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'parentCategoryId': parentCategoryId,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'timeRules': timeRules.map((rule) => rule.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? categoryId,
    String? businessId,
    String? name,
    String? description,
    String? imageUrl,
    String? parentCategoryId,
    int? sortOrder,
    bool? isActive,
    List<TimeRule>? timeRules,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      categoryId: categoryId ?? this.categoryId,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      timeRules: timeRules ?? this.timeRules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isMainCategory => parentCategoryId == null;
  bool get isSubCategory => parentCategoryId != null;

  /// Şu anki zaman kurallarına göre kategorinin aktif olup olmadığını kontrol eder
  bool get isActiveNow {
    if (!isActive) return false;
    if (timeRules.isEmpty) return true;

    final now = DateTime.now();
    final currentDay = now.weekday % 7; // Pazar = 0, Pazartesi = 1, ...
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

  @override
  String toString() {
    return 'Category(categoryId: $categoryId, name: $name, businessId: $businessId, sortOrder: $sortOrder, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.categoryId == categoryId;
  }

  @override
  int get hashCode => categoryId.hashCode;
}

class TimeRule {
  final String ruleId;
  final String name;
  final List<int> dayOfWeek; // 0 = Pazar, 1 = Pazartesi, ..., 6 = Cumartesi
  final String startTime; // "HH:MM" formatı
  final String endTime; // "HH:MM" formatı
  final bool isActive;

  TimeRule({
    required this.ruleId,
    required this.name,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory TimeRule.fromMap(Map<String, dynamic> map) {
    return TimeRule(
      ruleId: map['ruleId'] ?? '',
      name: map['name'] ?? '',
      dayOfWeek: List<int>.from(map['dayOfWeek'] ?? []),
      startTime: map['startTime'] ?? '00:00',
      endTime: map['endTime'] ?? '23:59',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ruleId': ruleId,
      'name': name,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
    };
  }

  TimeRule copyWith({
    String? ruleId,
    String? name,
    List<int>? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isActive,
  }) {
    return TimeRule(
      ruleId: ruleId ?? this.ruleId,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods
  List<String> get dayNames {
    const dayNames = [
      'Pazar',
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
    ];
    return dayOfWeek.map((day) => dayNames[day]).toList();
  }

  String get dayNamesString => dayNames.join(', ');

  String get timeRangeString => '$startTime - $endTime';

  /// Şu anki zamanın bu kurala uyup uymadığını kontrol eder
  bool get isActiveNow {
    if (!isActive) return false;

    final now = DateTime.now();
    final currentDay = now.weekday % 7;
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    if (!dayOfWeek.contains(currentDay)) return false;

    final currentMinutes = _timeToMinutes(currentTime);
    final startMinutes = _timeToMinutes(startTime);
    final endMinutes = _timeToMinutes(endTime);

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  String toString() {
    return 'TimeRule(ruleId: $ruleId, name: $name, dayOfWeek: $dayOfWeek, startTime: $startTime, endTime: $endTime, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeRule && other.ruleId == ruleId;
  }

  @override
  int get hashCode => ruleId.hashCode;
}

// Default instances and helper methods
class CategoryDefaults {
  static Category createDefault({
    required String categoryId,
    required String businessId,
    required String name,
    String? description,
    String? parentCategoryId,
    int sortOrder = 0,
  }) {
    return Category(
      categoryId: categoryId,
      businessId: businessId,
      name: name,
      description: description ?? '',
      parentCategoryId: parentCategoryId,
      sortOrder: sortOrder,
      isActive: true,
      timeRules: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static TimeRule createDefaultTimeRule({
    required String ruleId,
    required String name,
    List<int>? dayOfWeek,
    String? startTime,
    String? endTime,
  }) {
    return TimeRule(
      ruleId: ruleId,
      name: name,
      dayOfWeek: dayOfWeek ?? [0, 1, 2, 3, 4, 5, 6], // Tüm günler
      startTime: startTime ?? '00:00',
      endTime: endTime ?? '23:59',
      isActive: true,
    );
  }

  // Yaygın kullanılan zaman kuralları
  static TimeRule get breakfastTimeRule => TimeRule(
    ruleId: 'breakfast',
    name: 'Kahvaltı Saatleri',
    dayOfWeek: [0, 1, 2, 3, 4, 5, 6],
    startTime: '08:00',
    endTime: '12:00',
    isActive: true,
  );

  static TimeRule get lunchTimeRule => TimeRule(
    ruleId: 'lunch',
    name: 'Öğle Yemeği Saatleri',
    dayOfWeek: [0, 1, 2, 3, 4, 5, 6],
    startTime: '12:00',
    endTime: '16:00',
    isActive: true,
  );

  static TimeRule get dinnerTimeRule => TimeRule(
    ruleId: 'dinner',
    name: 'Akşam Yemeği Saatleri',
    dayOfWeek: [0, 1, 2, 3, 4, 5, 6],
    startTime: '18:00',
    endTime: '23:00',
    isActive: true,
  );

  static TimeRule get weekendOnlyRule => TimeRule(
    ruleId: 'weekend',
    name: 'Sadece Hafta Sonu',
    dayOfWeek: [0, 6], // Pazar ve Cumartesi
    startTime: '00:00',
    endTime: '23:59',
    isActive: true,
  );

  static TimeRule get weekdayOnlyRule => TimeRule(
    ruleId: 'weekday',
    name: 'Sadece Hafta İçi',
    dayOfWeek: [1, 2, 3, 4, 5], // Pazartesi - Cuma
    startTime: '00:00',
    endTime: '23:59',
    isActive: true,
  );
}

// Enum for common category types
enum CategoryType {
  appetizer('Mezeler'),
  soup('Çorbalar'),
  salad('Salatalar'),
  mainCourse('Ana Yemekler'),
  dessert('Tatlılar'),
  beverage('İçecekler'),
  hotBeverage('Sıcak İçecekler'),
  coldBeverage('Soğuk İçecekler'),
  alcohol('Alkollü İçecekler'),
  breakfast('Kahvaltı'),
  lunch('Öğle Yemeği'),
  dinner('Akşam Yemeği'),
  snack('Atıştırmalıklar'),
  pizza('Pizza'),
  burger('Burger'),
  pasta('Makarna'),
  seafood('Deniz Ürünleri'),
  meat('Et Yemekleri'),
  chicken('Tavuk Yemekleri'),
  vegetarian('Vejetaryen'),
  vegan('Vegan'),
  kids('Çocuk Menüsü'),
  special('Özel Menü');

  const CategoryType(this.displayName);
  final String displayName;
}

// Extension methods for better usability
extension CategoryExtensions on Category {
  /// Kategori hiyerarşisini string olarak döndürür
  String getHierarchyString(List<Category> allCategories) {
    if (isMainCategory) return name;

    final parentCategory = allCategories.firstWhere(
      (cat) => cat.categoryId == parentCategoryId,
      orElse: () => Category(
        categoryId: '',
        businessId: businessId,
        name: 'Bilinmeyen',
        description: '',
        sortOrder: 0,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return '${parentCategory.name} > $name';
  }

  /// Kategorinin alt kategorilerini bulur
  List<Category> getSubCategories(List<Category> allCategories) {
    return allCategories
        .where((cat) => cat.parentCategoryId == categoryId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Kategorinin ana kategorisini bulur
  Category? getParentCategory(List<Category> allCategories) {
    if (isMainCategory) return null;

    try {
      return allCategories.firstWhere(
        (cat) => cat.categoryId == parentCategoryId,
      );
    } catch (e) {
      return null;
    }
  }
}
