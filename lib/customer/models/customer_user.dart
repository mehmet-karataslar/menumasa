import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_profile.dart';

// Customer Exception for error handling
class CustomerException implements Exception {
  final String message;
  final String code;
  final Map<String, dynamic>? details;

  const CustomerException(this.message, {this.code = 'CUSTOMER_ERROR', this.details});

  @override
  String toString() => 'CustomerException: $message (Code: $code)';
}

// Customer Action Types for activity logging
enum CustomerActionType {
  login,
  logout,
  register,
  qrScan,
  businessVisit,
  orderPlace,
  orderCancel,
  favoriteAdd,
  favoriteRemove,
  profileUpdate,
  preferencesUpdate,
  sessionStart,
  sessionEnd,
}

enum CustomerRole {
  guest,
  member,
  premium,
  vip,
}

enum CustomerStatus {
  active,
  inactive,
  banned,
  suspended,
}

class CustomerUser {
  final String customerId;
  final String? phone;
  final String? email;
  final String? fullName;
  final String? profileImageUrl;
  final CustomerRole role;
  final CustomerStatus status;
  final List<String> favoriteBusinessIds;
  final List<String> favoriteProductIds;
  final Map<String, dynamic> preferences;
  final CustomerStats stats;
  final List<CustomerOrder> recentOrders;
  final List<CustomerFavorite> favorites;
  final List<CustomerAddress> addresses;
  final List<CustomerPaymentMethod> paymentMethods;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActiveAt;

  CustomerUser({
    required this.customerId,
    this.phone,
    this.email,
    this.fullName,
    this.profileImageUrl,
    required this.role,
    required this.status,
    required this.favoriteBusinessIds,
    required this.favoriteProductIds,
    required this.preferences,
    required this.stats,
    required this.recentOrders,
    required this.favorites,
    required this.addresses,
    required this.paymentMethods,
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveAt,
  });

  // Factory constructor for guest customer
  factory CustomerUser.guest() {
    final now = DateTime.now();
    return CustomerUser(
      customerId: 'guest_${now.millisecondsSinceEpoch}',
      role: CustomerRole.guest,
      status: CustomerStatus.active,
      favoriteBusinessIds: [],
      favoriteProductIds: [],
      preferences: {},
      stats: CustomerStats.empty(),
      recentOrders: [],
      favorites: [],
      addresses: [],
      paymentMethods: [],
      createdAt: now,
      updatedAt: now,
      lastActiveAt: now,
    );
  }

  // Factory constructor from Firestore document
  factory CustomerUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CustomerUser(
      customerId: doc.id,
      phone: data['phone'],
      email: data['email'],
      fullName: data['fullName'],
      profileImageUrl: data['profileImageUrl'],
      role: CustomerRole.values.firstWhere(
        (e) => e.toString() == 'CustomerRole.${data['role']}',
        orElse: () => CustomerRole.guest,
      ),
      status: CustomerStatus.values.firstWhere(
        (e) => e.toString() == 'CustomerStatus.${data['status']}',
        orElse: () => CustomerStatus.active,
      ),
      favoriteBusinessIds: List<String>.from(data['favoriteBusinessIds'] ?? []),
      favoriteProductIds: List<String>.from(data['favoriteProductIds'] ?? []),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      stats: CustomerStats.fromMap(data['stats'] ?? {}),
      recentOrders: (data['recentOrders'] as List?)
          ?.map((order) => CustomerOrder.fromMap(order))
          .toList() ?? [],
      favorites: (data['favorites'] as List?)
          ?.map((fav) => CustomerFavorite.fromMap(fav))
          .toList() ?? [],
      addresses: (data['addresses'] as List?)
          ?.map((addr) => CustomerAddress.fromMap(addr))
          .toList() ?? [],
      paymentMethods: (data['paymentMethods'] as List?)
          ?.map((pm) => CustomerPaymentMethod.fromMap(pm))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastActiveAt: data['lastActiveAt'] != null 
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'phone': phone,
      'email': email,
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
      'role': role.toString().split('.').last,
      'status': status.toString().split('.').last,
      'favoriteBusinessIds': favoriteBusinessIds,
      'favoriteProductIds': favoriteProductIds,
      'preferences': preferences,
      'stats': stats.toMap(),
      'recentOrders': recentOrders.map((order) => order.toMap()).toList(),
      'favorites': favorites.map((fav) => fav.toMap()).toList(),
      'addresses': addresses.map((addr) => addr.toMap()).toList(),
      'paymentMethods': paymentMethods.map((pm) => pm.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastActiveAt': lastActiveAt != null 
          ? Timestamp.fromDate(lastActiveAt!)
          : null,
    };
  }

  // Copy with method for updates
  CustomerUser copyWith({
    String? phone,
    String? email,
    String? fullName,
    String? profileImageUrl,
    CustomerRole? role,
    CustomerStatus? status,
    List<String>? favoriteBusinessIds,
    List<String>? favoriteProductIds,
    Map<String, dynamic>? preferences,
    CustomerStats? stats,
    List<CustomerOrder>? recentOrders,
    List<CustomerFavorite>? favorites,
    List<CustomerAddress>? addresses,
    List<CustomerPaymentMethod>? paymentMethods,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
  }) {
    return CustomerUser(
      customerId: customerId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      favoriteBusinessIds: favoriteBusinessIds ?? this.favoriteBusinessIds,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      recentOrders: recentOrders ?? this.recentOrders,
      favorites: favorites ?? this.favorites,
      addresses: addresses ?? this.addresses,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  // Helper methods
  bool get isGuest => role == CustomerRole.guest;
  bool get isActive => status == CustomerStatus.active;
  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasFullName => fullName != null && fullName!.isNotEmpty;

  String get displayName {
    if (hasFullName) return fullName!;
    if (hasPhone) return phone!;
    if (hasEmail) return email!;
    return 'Misafir Kullanıcı';
  }

  // Alias getters for compatibility
  String get id => customerId;
  String get name => displayName;

  @override
  String toString() {
    return 'CustomerUser(customerId: $customerId, phone: $phone, role: $role, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CustomerUser &&
        other.customerId == customerId &&
        other.phone == phone &&
        other.email == email &&
        other.role == role &&
        other.status == status;
  }

  @override
  int get hashCode {
    return customerId.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        role.hashCode ^
        status.hashCode;
  }
}

// Supporting classes for CustomerUser
class CustomerStats {
  final int totalOrders;
  final double totalSpent;
  final int totalVisits;
  final int scannedQRCount;
  final int favoriteBusinessesCount;
  final int favoriteProductsCount;
  final String mostVisitedBusinessId;
  final String mostOrderedProductId;
  final Map<String, int> businessVisitCounts;
  final Map<String, int> productOrderCounts;
  final Map<String, double> categorySpending;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerStats({
    required this.totalOrders,
    required this.totalSpent,
    required this.totalVisits,
    required this.scannedQRCount,
    required this.favoriteBusinessesCount,
    required this.favoriteProductsCount,
    required this.mostVisitedBusinessId,
    required this.mostOrderedProductId,
    required this.businessVisitCounts,
    required this.productOrderCounts,
    required this.categorySpending,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for new customer
  factory CustomerStats.newCustomer() {
    final now = DateTime.now();
    return CustomerStats(
      totalOrders: 0,
      totalSpent: 0.0,
      totalVisits: 0,
      scannedQRCount: 0,
      favoriteBusinessesCount: 0,
      favoriteProductsCount: 0,
      mostVisitedBusinessId: '',
      mostOrderedProductId: '',
      businessVisitCounts: {},
      productOrderCounts: {},
      categorySpending: {},
      createdAt: now,
      updatedAt: now,
    );
  }
  
  // Copy with method
  CustomerStats copyWith({
    int? totalOrders,
    double? totalSpent,
    int? totalVisits,
    int? scannedQRCount,
    int? favoriteBusinessesCount,
    int? favoriteProductsCount,
    String? mostVisitedBusinessId,
    String? mostOrderedProductId,
    Map<String, int>? businessVisitCounts,
    Map<String, int>? productOrderCounts,
    Map<String, double>? categorySpending,
    DateTime? updatedAt,
  }) {
    return CustomerStats(
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      totalVisits: totalVisits ?? this.totalVisits,
      scannedQRCount: scannedQRCount ?? this.scannedQRCount,
      favoriteBusinessesCount: favoriteBusinessesCount ?? this.favoriteBusinessesCount,
      favoriteProductsCount: favoriteProductsCount ?? this.favoriteProductsCount,
      mostVisitedBusinessId: mostVisitedBusinessId ?? this.mostVisitedBusinessId,
      mostOrderedProductId: mostOrderedProductId ?? this.mostOrderedProductId,
      businessVisitCounts: businessVisitCounts ?? this.businessVisitCounts,
      productOrderCounts: productOrderCounts ?? this.productOrderCounts,
      categorySpending: categorySpending ?? this.categorySpending,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory CustomerStats.empty() {
    final now = DateTime.now();
    return CustomerStats(
      totalOrders: 0,
      totalSpent: 0.0,
      totalVisits: 0,
      scannedQRCount: 0,
      favoriteBusinessesCount: 0,
      favoriteProductsCount: 0,
      mostVisitedBusinessId: '',
      mostOrderedProductId: '',
      businessVisitCounts: {},
      productOrderCounts: {},
      categorySpending: {},
      createdAt: now,
      updatedAt: now,
    );
  }

  factory CustomerStats.fromMap(Map<String, dynamic> map) {
    return CustomerStats(
      totalOrders: map['totalOrders'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      totalVisits: map['totalVisits'] ?? 0,
      scannedQRCount: map['scannedQRCount'] ?? 0,
      favoriteBusinessesCount: map['favoriteBusinessesCount'] ?? 0,
      favoriteProductsCount: map['favoriteProductsCount'] ?? 0,
      mostVisitedBusinessId: map['mostVisitedBusinessId'] ?? '',
      mostOrderedProductId: map['mostOrderedProductId'] ?? '',
      businessVisitCounts: Map<String, int>.from(map['businessVisitCounts'] ?? {}),
      productOrderCounts: Map<String, int>.from(map['productOrderCounts'] ?? {}),
      categorySpending: Map<String, double>.from(map['categorySpending'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'totalVisits': totalVisits,
      'scannedQRCount': scannedQRCount,
      'favoriteBusinessesCount': favoriteBusinessesCount,
      'favoriteProductsCount': favoriteProductsCount,
      'mostVisitedBusinessId': mostVisitedBusinessId,
      'mostOrderedProductId': mostOrderedProductId,
      'businessVisitCounts': businessVisitCounts,
      'productOrderCounts': productOrderCounts,
      'categorySpending': categorySpending,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class CustomerOrder {
  final String orderId;
  final String businessId;
  final double totalAmount;
  final String status;
  final DateTime orderDate;

  CustomerOrder({
    required this.orderId,
    required this.businessId,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
  });

  factory CustomerOrder.fromMap(Map<String, dynamic> map) {
    return CustomerOrder(
      orderId: map['orderId'] ?? '',
      businessId: map['businessId'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: map['status'] ?? '',
      orderDate: DateTime.parse(map['orderDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'businessId': businessId,
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': orderDate.toIso8601String(),
    };
  }
}

class CustomerFavorite {
  final String businessId;
  final String? productId;
  final String type; // 'business' or 'product'
  final DateTime addedAt;

  CustomerFavorite({
    required this.businessId,
    this.productId,
    required this.type,
    required this.addedAt,
  });

  factory CustomerFavorite.fromMap(Map<String, dynamic> map) {
    return CustomerFavorite(
      businessId: map['businessId'] ?? '',
      productId: map['productId'],
      type: map['type'] ?? 'business',
      addedAt: DateTime.parse(map['addedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'productId': productId,
      'type': type,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}

// CustomerAddress is now defined in customer_profile.dart
// This is kept for backward compatibility - will be removed in future versions

class CustomerPaymentMethod {
  final String paymentId;
  final String type; // 'cash', 'card', 'mobile'
  final String title;
  final Map<String, dynamic> details;
  final bool isDefault;

  CustomerPaymentMethod({
    required this.paymentId,
    required this.type,
    required this.title,
    required this.details,
    required this.isDefault,
  });

  factory CustomerPaymentMethod.fromMap(Map<String, dynamic> map) {
    return CustomerPaymentMethod(
      paymentId: map['paymentId'] ?? '',
      type: map['type'] ?? 'cash',
      title: map['title'] ?? '',
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'type': type,
      'title': title,
      'details': details,
      'isDefault': isDefault,
    };
  }
} 