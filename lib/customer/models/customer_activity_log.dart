import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomerActivityType {
  qrScan,
  businessView,
  menuView,
  orderPlace,
  orderCancel,
  favoriteAdd,
  favoriteRemove,
  login,
  logout,
  profileUpdate,
  searchPerformed,
  categoryFilter,
  productView,
  cartAdd,
  cartRemove,
  paymentComplete,
}

class CustomerActivityLog {
  final String logId;
  final String customerId;
  final CustomerActivityType activityType;
  final Map<String, dynamic> activityData;
  final String? businessId;
  final String? productId;
  final String? orderId;
  final String? sessionId;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  CustomerActivityLog({
    required this.logId,
    required this.customerId,
    required this.activityType,
    required this.activityData,
    this.businessId,
    this.productId,
    this.orderId,
    this.sessionId,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  // Static create method for convenience
  static CustomerActivityLog create({
    required String customerId,
    required CustomerActivityType activityType,
    Map<String, dynamic>? activityData,
    String? businessId,
    String? productId,
    String? orderId,
    String? sessionId,
    String? ipAddress,
    String? userAgent,
  }) {
    return CustomerActivityLog(
      logId: '',
      customerId: customerId,
      activityType: activityType,
      activityData: activityData ?? {},
      businessId: businessId,
      productId: productId,
      orderId: orderId,
      sessionId: sessionId,
      ipAddress: ipAddress,
      userAgent: userAgent,
      createdAt: DateTime.now(),
    );
  }

  // Factory constructor from Firestore document
  factory CustomerActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CustomerActivityLog(
      logId: doc.id,
      customerId: data['customerId'] ?? '',
      activityType: CustomerActivityType.values.firstWhere(
        (e) => e.toString() == 'CustomerActivityType.${data['activityType']}',
        orElse: () => CustomerActivityType.qrScan,
      ),
      activityData: Map<String, dynamic>.from(data['activityData'] ?? {}),
      businessId: data['businessId'],
      productId: data['productId'],
      orderId: data['orderId'],
      sessionId: data['sessionId'],
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'activityType': activityType.toString().split('.').last,
      'activityData': activityData,
      'businessId': businessId,
      'productId': productId,
      'orderId': orderId,
      'sessionId': sessionId,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create activity log entries
  static CustomerActivityLog qrScan({
    required String customerId,
    required String businessId,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) {
    return CustomerActivityLog(
      logId: '',
      customerId: customerId,
      activityType: CustomerActivityType.qrScan,
      activityData: {
        'businessId': businessId,
        'scanResult': 'success',
        ...?metadata,
      },
      businessId: businessId,
      sessionId: sessionId,
      createdAt: DateTime.now(),
    );
  }

  static CustomerActivityLog orderPlace({
    required String customerId,
    required String businessId,
    required String orderId,
    required double orderAmount,
    required int itemCount,
    String? sessionId,
  }) {
    return CustomerActivityLog(
      logId: '',
      customerId: customerId,
      activityType: CustomerActivityType.orderPlace,
      activityData: {
        'businessId': businessId,
        'orderId': orderId,
        'orderAmount': orderAmount,
        'itemCount': itemCount,
      },
      businessId: businessId,
      orderId: orderId,
      sessionId: sessionId,
      createdAt: DateTime.now(),
    );
  }

  static CustomerActivityLog favoriteAdd({
    required String customerId,
    required String businessId,
    String? productId,
    String? sessionId,
  }) {
    return CustomerActivityLog(
      logId: '',
      customerId: customerId,
      activityType: CustomerActivityType.favoriteAdd,
      activityData: {
        'businessId': businessId,
        'productId': productId,
        'type': productId != null ? 'product' : 'business',
      },
      businessId: businessId,
      productId: productId,
      sessionId: sessionId,
      createdAt: DateTime.now(),
    );
  }

  // Helper methods
  String get activityDescription {
    switch (activityType) {
      case CustomerActivityType.qrScan:
        return 'QR kod tarandı';
      case CustomerActivityType.businessView:
        return 'İşletme görüntülendi';
      case CustomerActivityType.menuView:
        return 'Menü görüntülendi';
      case CustomerActivityType.orderPlace:
        return 'Sipariş verildi';
      case CustomerActivityType.orderCancel:
        return 'Sipariş iptal edildi';
      case CustomerActivityType.favoriteAdd:
        return 'Favorilere eklendi';
      case CustomerActivityType.favoriteRemove:
        return 'Favorilerden çıkarıldı';
      case CustomerActivityType.login:
        return 'Giriş yapıldı';
      case CustomerActivityType.logout:
        return 'Çıkış yapıldı';
      case CustomerActivityType.profileUpdate:
        return 'Profil güncellendi';
      case CustomerActivityType.searchPerformed:
        return 'Arama yapıldı';
      case CustomerActivityType.categoryFilter:
        return 'Kategori filtrelendi';
      case CustomerActivityType.productView:
        return 'Ürün görüntülendi';
      case CustomerActivityType.cartAdd:
        return 'Sepete eklendi';
      case CustomerActivityType.cartRemove:
        return 'Sepetten çıkarıldı';
      case CustomerActivityType.paymentComplete:
        return 'Ödeme tamamlandı';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  @override
  String toString() {
    return 'CustomerActivityLog(logId: $logId, customerId: $customerId, activityType: $activityType, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CustomerActivityLog &&
        other.logId == logId &&
        other.customerId == customerId &&
        other.activityType == activityType &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return logId.hashCode ^
        customerId.hashCode ^
        activityType.hashCode ^
        createdAt.hashCode;
  }
} 