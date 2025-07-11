// Firebase imports removed for Windows compatibility

class User {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final SubscriptionType subscriptionType;
  final DateTime? subscriptionExpiry;
  final UserProfile profile;

  User({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.subscriptionType,
    this.subscriptionExpiry,
    required this.profile,
  });

  factory User.fromJson(Map<String, dynamic> data, {String? id}) {
    return User(
      uid: id ?? data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      subscriptionType: SubscriptionType.fromString(
        data['subscriptionType'] ?? 'free',
      ),
      subscriptionExpiry: data['subscriptionExpiry'] != null
          ? DateTime.parse(data['subscriptionExpiry'] as String)
          : null,
      profile: UserProfile.fromMap(data['profile'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'subscriptionType': subscriptionType.value,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'profile': profile.toMap(),
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    SubscriptionType? subscriptionType,
    DateTime? subscriptionExpiry,
    UserProfile? profile,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      profile: profile ?? this.profile,
    );
  }

  // Helper methods
  bool get hasActiveSubscription {
    if (subscriptionType == SubscriptionType.free) return true;
    if (subscriptionExpiry == null) return false;
    return DateTime.now().isBefore(subscriptionExpiry!);
  }

  bool get isSubscriptionExpired {
    if (subscriptionType == SubscriptionType.free) return false;
    if (subscriptionExpiry == null) return true;
    return DateTime.now().isAfter(subscriptionExpiry!);
  }

  int get daysUntilExpiry {
    if (subscriptionExpiry == null) return 0;
    return subscriptionExpiry!.difference(DateTime.now()).inDays;
  }

  bool get isSubscriptionExpiringSoon {
    return daysUntilExpiry > 0 && daysUntilExpiry <= 7;
  }

  String get displayName {
    return name.isNotEmpty ? name : email.split('@').first;
  }

  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  String toString() {
    return 'User(uid: $uid, email: $email, name: $name, subscriptionType: $subscriptionType, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

class UserProfile {
  final String? avatarUrl;
  final String? bio;
  final String? company;
  final String? website;
  final String? location;
  final UserPreferences preferences;
  final DateTime? lastLoginAt;
  final int totalBusinesses;
  final int totalProducts;

  UserProfile({
    this.avatarUrl,
    this.bio,
    this.company,
    this.website,
    this.location,
    required this.preferences,
    this.lastLoginAt,
    required this.totalBusinesses,
    required this.totalProducts,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      avatarUrl: map['avatarUrl'],
      bio: map['bio'],
      company: map['company'],
      website: map['website'],
      location: map['location'],
      preferences: UserPreferences.fromMap(map['preferences'] ?? {}),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'] as String)
          : null,
      totalBusinesses: map['totalBusinesses'] ?? 0,
      totalProducts: map['totalProducts'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'avatarUrl': avatarUrl,
      'bio': bio,
      'company': company,
      'website': website,
      'location': location,
      'preferences': preferences.toMap(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'totalBusinesses': totalBusinesses,
      'totalProducts': totalProducts,
    };
  }

  UserProfile copyWith({
    String? avatarUrl,
    String? bio,
    String? company,
    String? website,
    String? location,
    UserPreferences? preferences,
    DateTime? lastLoginAt,
    int? totalBusinesses,
    int? totalProducts,
  }) {
    return UserProfile(
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      company: company ?? this.company,
      website: website ?? this.website,
      location: location ?? this.location,
      preferences: preferences ?? this.preferences,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      totalBusinesses: totalBusinesses ?? this.totalBusinesses,
      totalProducts: totalProducts ?? this.totalProducts,
    );
  }

  @override
  String toString() {
    return 'UserProfile(company: $company, totalBusinesses: $totalBusinesses, totalProducts: $totalProducts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.avatarUrl == avatarUrl &&
        other.company == company;
  }

  @override
  int get hashCode => avatarUrl.hashCode ^ company.hashCode;
}

class UserPreferences {
  final String language;
  final String currency;
  final String timezone;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final String theme;
  final bool analytics;
  final bool marketing;

  UserPreferences({
    required this.language,
    required this.currency,
    required this.timezone,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.smsNotifications,
    required this.theme,
    required this.analytics,
    required this.marketing,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      language: map['language'] ?? 'tr',
      currency: map['currency'] ?? 'TL',
      timezone: map['timezone'] ?? 'Europe/Istanbul',
      emailNotifications: map['emailNotifications'] ?? true,
      pushNotifications: map['pushNotifications'] ?? true,
      smsNotifications: map['smsNotifications'] ?? false,
      theme: map['theme'] ?? 'light',
      analytics: map['analytics'] ?? true,
      marketing: map['marketing'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'currency': currency,
      'timezone': timezone,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'theme': theme,
      'analytics': analytics,
      'marketing': marketing,
    };
  }

  UserPreferences copyWith({
    String? language,
    String? currency,
    String? timezone,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    String? theme,
    bool? analytics,
    bool? marketing,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      theme: theme ?? this.theme,
      analytics: analytics ?? this.analytics,
      marketing: marketing ?? this.marketing,
    );
  }

  @override
  String toString() {
    return 'UserPreferences(language: $language, currency: $currency, theme: $theme)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferences &&
        other.language == language &&
        other.currency == currency &&
        other.theme == theme;
  }

  @override
  int get hashCode => language.hashCode ^ currency.hashCode ^ theme.hashCode;
}

enum SubscriptionType {
  free('free', 'Ücretsiz', 1, 50),
  premium('premium', 'Premium', 3, 200),
  business('business', 'İşletme', 10, 1000),
  enterprise('enterprise', 'Kurumsal', -1, -1);

  const SubscriptionType(
    this.value,
    this.displayName,
    this.maxBusinesses,
    this.maxProducts,
  );

  final String value;
  final String displayName;
  final int maxBusinesses; // -1 = unlimited
  final int maxProducts; // -1 = unlimited

  static SubscriptionType fromString(String value) {
    return SubscriptionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SubscriptionType.free,
    );
  }

  bool get isUnlimited => maxBusinesses == -1 && maxProducts == -1;

  bool canCreateBusiness(int currentBusinessCount) {
    return isUnlimited || currentBusinessCount < maxBusinesses;
  }

  bool canCreateProduct(int currentProductCount) {
    return isUnlimited || currentProductCount < maxProducts;
  }

  String get businessLimit =>
      isUnlimited ? 'Sınırsız' : '$maxBusinesses işletme';
  String get productLimit => isUnlimited ? 'Sınırsız' : '$maxProducts ürün';
}

// Default instances and helper methods
class UserDefaults {
  static User createDefault({
    required String uid,
    required String email,
    required String name,
    String? phone,
  }) {
    return User(
      uid: uid,
      email: email,
      name: name,
      phone: phone,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      subscriptionType: SubscriptionType.free,
      profile: defaultUserProfile,
    );
  }

  static UserProfile get defaultUserProfile => UserProfile(
    preferences: defaultUserPreferences,
    totalBusinesses: 0,
    totalProducts: 0,
  );

  static UserPreferences get defaultUserPreferences => UserPreferences(
    language: 'tr',
    currency: 'TL',
    timezone: 'Europe/Istanbul',
    emailNotifications: true,
    pushNotifications: true,
    smsNotifications: false,
    theme: 'light',
    analytics: true,
    marketing: false,
  );
}

// Extension methods for better usability
extension UserExtensions on User {
  /// Kullanıcının abonelik durumunu kontrol eder
  String getSubscriptionStatus() {
    if (subscriptionType == SubscriptionType.free) {
      return 'Ücretsiz Plan';
    }

    if (hasActiveSubscription) {
      if (isSubscriptionExpiringSoon) {
        return '${subscriptionType.displayName} - ${daysUntilExpiry} gün kaldı';
      }
      return '${subscriptionType.displayName} - Aktif';
    }

    return '${subscriptionType.displayName} - Süresi Dolmuş';
  }

  /// Kullanıcının yeni işletme oluşturup oluşturamayacağını kontrol eder
  bool canCreateNewBusiness() {
    return subscriptionType.canCreateBusiness(profile.totalBusinesses);
  }

  /// Kullanıcının yeni ürün oluşturup oluşturamayacağını kontrol eder
  bool canCreateNewProduct() {
    return subscriptionType.canCreateProduct(profile.totalProducts);
  }

  /// Kullanıcının hesap yaşını döndürür
  int get accountAgeInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Kullanıcının son giriş tarihini döndürür
  String get lastLoginString {
    if (profile.lastLoginAt == null) return 'Hiç giriş yapmamış';

    final difference = DateTime.now().difference(profile.lastLoginAt!);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }

  /// Kullanıcının aktiflik durumunu döndürür
  String get activityStatus {
    if (!isActive) return 'Pasif';

    if (profile.lastLoginAt == null) return 'Yeni Kullanıcı';

    final daysSinceLogin = DateTime.now()
        .difference(profile.lastLoginAt!)
        .inDays;

    if (daysSinceLogin == 0) return 'Aktif';
    if (daysSinceLogin <= 7) return 'Düzenli';
    if (daysSinceLogin <= 30) return 'Ara sıra';
    return 'Pasif';
  }
}
 