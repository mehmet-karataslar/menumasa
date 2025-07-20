import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPreferences {
  final String customerId;
  final String theme; // 'light', 'dark', 'system'
  final String language; // 'tr', 'en'
  final bool notificationsEnabled;
  final bool orderUpdatesEnabled;
  final bool marketingEmailsEnabled;
  final bool locationServicesEnabled;
  final String defaultPaymentMethod;
  final List<String> favoriteBusinessIds;
  final List<String> favoriteProductIds;
  final Map<String, dynamic> dietaryRestrictions;
  final Map<String, dynamic> allergens;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerPreferences({
    required this.customerId,
    required this.theme,
    required this.language,
    required this.notificationsEnabled,
    required this.orderUpdatesEnabled,
    required this.marketingEmailsEnabled,
    required this.locationServicesEnabled,
    required this.defaultPaymentMethod,
    required this.favoriteBusinessIds,
    required this.favoriteProductIds,
    required this.dietaryRestrictions,
    required this.allergens,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for default preferences
  factory CustomerPreferences.defaultPreferences(String customerId) {
    final now = DateTime.now();
    return CustomerPreferences(
      customerId: customerId,
      theme: 'system',
      language: 'tr',
      notificationsEnabled: true,
      orderUpdatesEnabled: true,
      marketingEmailsEnabled: false,
      locationServicesEnabled: false,
      defaultPaymentMethod: 'cash',
      favoriteBusinessIds: [],
      favoriteProductIds: [],
      dietaryRestrictions: {},
      allergens: {},
      createdAt: now,
      updatedAt: now,
    );
  }

  // Factory constructor from Firestore document
  factory CustomerPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CustomerPreferences(
      customerId: doc.id,
      theme: data['theme'] ?? 'system',
      language: data['language'] ?? 'tr',
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      orderUpdatesEnabled: data['orderUpdatesEnabled'] ?? true,
      marketingEmailsEnabled: data['marketingEmailsEnabled'] ?? false,
      locationServicesEnabled: data['locationServicesEnabled'] ?? false,
      defaultPaymentMethod: data['defaultPaymentMethod'] ?? 'cash',
      favoriteBusinessIds: List<String>.from(data['favoriteBusinessIds'] ?? []),
      favoriteProductIds: List<String>.from(data['favoriteProductIds'] ?? []),
      dietaryRestrictions: Map<String, dynamic>.from(data['dietaryRestrictions'] ?? {}),
      allergens: Map<String, dynamic>.from(data['allergens'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'theme': theme,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'orderUpdatesEnabled': orderUpdatesEnabled,
      'marketingEmailsEnabled': marketingEmailsEnabled,
      'locationServicesEnabled': locationServicesEnabled,
      'defaultPaymentMethod': defaultPaymentMethod,
      'favoriteBusinessIds': favoriteBusinessIds,
      'favoriteProductIds': favoriteProductIds,
      'dietaryRestrictions': dietaryRestrictions,
      'allergens': allergens,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method for updates
  CustomerPreferences copyWith({
    String? theme,
    String? language,
    bool? notificationsEnabled,
    bool? orderUpdatesEnabled,
    bool? marketingEmailsEnabled,
    bool? locationServicesEnabled,
    String? defaultPaymentMethod,
    List<String>? favoriteBusinessIds,
    List<String>? favoriteProductIds,
    Map<String, dynamic>? dietaryRestrictions,
    Map<String, dynamic>? allergens,
    DateTime? updatedAt,
  }) {
    return CustomerPreferences(
      customerId: customerId,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      orderUpdatesEnabled: orderUpdatesEnabled ?? this.orderUpdatesEnabled,
      marketingEmailsEnabled: marketingEmailsEnabled ?? this.marketingEmailsEnabled,
      locationServicesEnabled: locationServicesEnabled ?? this.locationServicesEnabled,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      favoriteBusinessIds: favoriteBusinessIds ?? this.favoriteBusinessIds,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      allergens: allergens ?? this.allergens,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods for favorites
  bool isFavoriteBusiness(String businessId) {
    return favoriteBusinessIds.contains(businessId);
  }

  bool isFavoriteProduct(String productId) {
    return favoriteProductIds.contains(productId);
  }

  CustomerPreferences addFavoriteBusiness(String businessId) {
    if (isFavoriteBusiness(businessId)) return this;
    
    final updatedFavorites = List<String>.from(favoriteBusinessIds)..add(businessId);
    return copyWith(
      favoriteBusinessIds: updatedFavorites,
      updatedAt: DateTime.now(),
    );
  }

  CustomerPreferences removeFavoriteBusiness(String businessId) {
    if (!isFavoriteBusiness(businessId)) return this;
    
    final updatedFavorites = List<String>.from(favoriteBusinessIds)..remove(businessId);
    return copyWith(
      favoriteBusinessIds: updatedFavorites,
      updatedAt: DateTime.now(),
    );
  }

  CustomerPreferences addFavoriteProduct(String productId) {
    if (isFavoriteProduct(productId)) return this;
    
    final updatedFavorites = List<String>.from(favoriteProductIds)..add(productId);
    return copyWith(
      favoriteProductIds: updatedFavorites,
      updatedAt: DateTime.now(),
    );
  }

  CustomerPreferences removeFavoriteProduct(String productId) {
    if (!isFavoriteProduct(productId)) return this;
    
    final updatedFavorites = List<String>.from(favoriteProductIds)..remove(productId);
    return copyWith(
      favoriteProductIds: updatedFavorites,
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods for dietary restrictions
  bool hasDietaryRestriction(String restriction) {
    return dietaryRestrictions[restriction] == true;
  }

  bool hasAllergen(String allergen) {
    return allergens[allergen] == true;
  }

  CustomerPreferences updateDietaryRestriction(String restriction, bool value) {
    final updated = Map<String, dynamic>.from(dietaryRestrictions);
    updated[restriction] = value;
    
    return copyWith(
      dietaryRestrictions: updated,
      updatedAt: DateTime.now(),
    );
  }

  CustomerPreferences updateAllergen(String allergen, bool value) {
    final updated = Map<String, dynamic>.from(allergens);
    updated[allergen] = value;
    
    return copyWith(
      allergens: updated,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CustomerPreferences(customerId: $customerId, theme: $theme, language: $language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CustomerPreferences &&
        other.customerId == customerId &&
        other.theme == theme &&
        other.language == language &&
        other.notificationsEnabled == notificationsEnabled &&
        other.orderUpdatesEnabled == orderUpdatesEnabled &&
        other.marketingEmailsEnabled == marketingEmailsEnabled &&
        other.locationServicesEnabled == locationServicesEnabled &&
        other.defaultPaymentMethod == defaultPaymentMethod;
  }

  @override
  int get hashCode {
    return customerId.hashCode ^
        theme.hashCode ^
        language.hashCode ^
        notificationsEnabled.hashCode ^
        orderUpdatesEnabled.hashCode ^
        marketingEmailsEnabled.hashCode ^
        locationServicesEnabled.hashCode ^
        defaultPaymentMethod.hashCode;
  }
} 