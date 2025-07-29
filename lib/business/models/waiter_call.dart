import 'package:cloud_firestore/cloud_firestore.dart';

/// Garson çağırma modeli
class WaiterCall {
  final String callId;
  final String businessId;
  final String customerId;
  final String customerName;
  final String waiterId;
  final String waiterName;
  final String tableNumber;
  final String? floorNumber;
  final String? message;
  final WaiterCallStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;
  final DateTime? completedAt;

  const WaiterCall({
    required this.callId,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.waiterId,
    required this.waiterName,
    required this.tableNumber,
    this.floorNumber,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
    this.completedAt,
  });

  /// Yeni çağrı oluştur
  factory WaiterCall.create({
    required String businessId,
    required String customerId,
    required String customerName,
    required String waiterId,
    required String waiterName,
    required String tableNumber,
    String? floorNumber,
    String? message,
  }) {
    final now = DateTime.now();
    return WaiterCall(
      callId: 'call_${now.millisecondsSinceEpoch}_${waiterId}',
      businessId: businessId,
      customerId: customerId,
      customerName: customerName,
      waiterId: waiterId,
      waiterName: waiterName,
      tableNumber: tableNumber,
      floorNumber: floorNumber,
      message: message,
      status: WaiterCallStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Firestore'dan oluştur
  factory WaiterCall.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final now = DateTime.now();

      return WaiterCall(
        callId: doc.id,
        businessId: data['businessId'] ?? '',
        customerId: data['customerId'] ?? '',
        customerName: data['customerName'] ?? '',
        waiterId: data['waiterId'] ?? '',
        waiterName: data['waiterName'] ?? '',
        tableNumber: data['tableNumber'] ?? '',
        floorNumber: data['floorNumber'],
        message: data['message'],
        status: WaiterCallStatus.values.firstWhere(
          (status) => status.value == data['status'],
          orElse: () => WaiterCallStatus.pending,
        ),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : now,
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : now,
        respondedAt: data['respondedAt'] != null
            ? (data['respondedAt'] as Timestamp).toDate()
            : null,
        completedAt: data['completedAt'] != null
            ? (data['completedAt'] as Timestamp).toDate()
            : null,
      );
    } catch (e) {
      print('❌ Error parsing WaiterCall from Firestore: $e');
      print('📄 Document data: ${doc.data()}');

      // Return a default waiter call in case of error
      final now = DateTime.now();
      return WaiterCall(
        callId: doc.id,
        businessId: '',
        customerId: '',
        customerName: 'Unknown',
        waiterId: '',
        waiterName: 'Unknown',
        tableNumber: 'Unknown',
        status: WaiterCallStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  /// Firestore'a kaydet
  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'waiterId': waiterId,
      'waiterName': waiterName,
      'tableNumber': tableNumber,
      'floorNumber': floorNumber,
      'message': message,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  /// Çağrıyı kabul et
  WaiterCall markAsResponded() {
    return copyWith(
      status: WaiterCallStatus.responded,
      respondedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Çağrıyı tamamla
  WaiterCall markAsCompleted() {
    return copyWith(
      status: WaiterCallStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Çağrıyı iptal et
  WaiterCall markAsCancelled() {
    return copyWith(
      status: WaiterCallStatus.cancelled,
      updatedAt: DateTime.now(),
    );
  }

  /// Kopya oluştur
  WaiterCall copyWith({
    String? customerId,
    String? customerName,
    String? waiterId,
    String? waiterName,
    String? tableNumber,
    String? floorNumber,
    String? message,
    WaiterCallStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? respondedAt,
    DateTime? completedAt,
  }) {
    return WaiterCall(
      callId: callId,
      businessId: businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      tableNumber: tableNumber ?? this.tableNumber,
      floorNumber: floorNumber ?? this.floorNumber,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Yanıt süresi (dakika)
  double? get responseTimeMinutes {
    if (respondedAt == null) return null;
    return respondedAt!.difference(createdAt).inMinutes.toDouble();
  }

  /// Tamamlanma süresi (dakika)
  double? get completionTimeMinutes {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt).inMinutes.toDouble();
  }

  /// Çağrı geçerli mi?
  bool get isActive {
    return status == WaiterCallStatus.pending ||
        status == WaiterCallStatus.responded;
  }

  /// Masa ve kat bilgisi
  String get tableInfo {
    if (floorNumber != null && floorNumber!.isNotEmpty) {
      return 'Masa $tableNumber (${floorNumber}. Kat)';
    }
    return 'Masa $tableNumber';
  }

  /// Durum rengi
  String get statusColor {
    switch (status) {
      case WaiterCallStatus.pending:
        return '#FF9800'; // Turuncu
      case WaiterCallStatus.responded:
        return '#2196F3'; // Mavi
      case WaiterCallStatus.completed:
        return '#4CAF50'; // Yeşil
      case WaiterCallStatus.cancelled:
        return '#F44336'; // Kırmızı
    }
  }

  @override
  String toString() {
    return 'WaiterCall(id: $callId, waiter: $waiterName, table: $tableInfo, status: ${status.displayName})';
  }
}

/// Garson çağırma durumları
enum WaiterCallStatus {
  pending('pending', 'Bekleyen', 'Garson çağrıldı, yanıt bekleniyor'),
  responded('responded', 'Kabul Edildi', 'Garson çağrıyı kabul etti'),
  completed('completed', 'Tamamlandı', 'Çağrı tamamlandı'),
  cancelled('cancelled', 'İptal Edildi', 'Çağrı iptal edildi');

  const WaiterCallStatus(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;

  static WaiterCallStatus fromString(String value) {
    return WaiterCallStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => WaiterCallStatus.pending,
    );
  }
}
