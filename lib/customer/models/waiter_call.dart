import 'package:cloud_firestore/cloud_firestore.dart';

/// Garson çağırma modeli
class WaiterCall {
  final String callId;
  final String businessId;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final int tableNumber;
  final WaiterCallType requestType;
  final String? message;
  final WaiterCallPriority priority;
  final WaiterCallStatus status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? respondedAt;
  final DateTime? completedAt;
  final String? waiterId;
  final String? waiterName;
  final String? responseNotes;
  final List<String> actionsTaken;
  final Map<String, dynamic> metadata;

  const WaiterCall({
    required this.callId,
    required this.businessId,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.tableNumber,
    required this.requestType,
    this.message,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.acknowledgedAt,
    this.respondedAt,
    this.completedAt,
    this.waiterId,
    this.waiterName,
    this.responseNotes,
    required this.actionsTaken,
    required this.metadata,
  });

  /// Yeni garson çağrısı oluştur
  factory WaiterCall.create({
    required String businessId,
    required String customerId,
    String? customerName,
    String? customerPhone,
    required int tableNumber,
    required WaiterCallType requestType,
    String? message,
    WaiterCallPriority? priority,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return WaiterCall(
      callId: 'call_${now.millisecondsSinceEpoch}_${tableNumber}',
      businessId: businessId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      tableNumber: tableNumber,
      requestType: requestType,
      message: message,
      priority: priority ?? _determinePriority(requestType),
      status: WaiterCallStatus.pending,
      createdAt: now,
      actionsTaken: [],
      metadata: metadata ?? {},
    );
  }

  /// Firestore'dan oluşturma
  factory WaiterCall.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return WaiterCall(
      callId: doc.id,
      businessId: data['businessId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      tableNumber: data['tableNumber'] ?? 0,
      requestType: WaiterCallType.values.firstWhere(
        (type) => type.toString() == data['requestType'],
        orElse: () => WaiterCallType.service,
      ),
      message: data['message'],
      priority: WaiterCallPriority.values.firstWhere(
        (priority) => priority.toString() == data['priority'],
        orElse: () => WaiterCallPriority.normal,
      ),
      status: WaiterCallStatus.values.firstWhere(
        (status) => status.toString() == data['status'],
        orElse: () => WaiterCallStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acknowledgedAt: data['acknowledgedAt'] != null
          ? (data['acknowledgedAt'] as Timestamp).toDate()
          : null,
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      waiterId: data['waiterId'],
      waiterName: data['waiterName'],
      responseNotes: data['responseNotes'],
      actionsTaken: List<String>.from(data['actionsTaken'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Firestore'a dönüştürme
  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'tableNumber': tableNumber,
      'requestType': requestType.toString(),
      'message': message,
      'priority': priority.toString(),
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'acknowledgedAt': acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'waiterId': waiterId,
      'waiterName': waiterName,
      'responseNotes': responseNotes,
      'actionsTaken': actionsTaken,
      'metadata': metadata,
    };
  }

  /// Kopya oluşturma
  WaiterCall copyWith({
    WaiterCallPriority? priority,
    WaiterCallStatus? status,
    DateTime? acknowledgedAt,
    DateTime? respondedAt,
    DateTime? completedAt,
    String? waiterId,
    String? waiterName,
    String? responseNotes,
    List<String>? actionsTaken,
    Map<String, dynamic>? metadata,
  }) {
    return WaiterCall(
      callId: callId,
      businessId: businessId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      tableNumber: tableNumber,
      requestType: requestType,
      message: message,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      completedAt: completedAt ?? this.completedAt,
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      responseNotes: responseNotes ?? this.responseNotes,
      actionsTaken: actionsTaken ?? this.actionsTaken,
      metadata: metadata ?? this.metadata,
    );
  }

  // ============================================================================
  // STATUS METHODS
  // ============================================================================

  /// Çağrıyı onayla
  WaiterCall acknowledge({
    required String waiterId,
    required String waiterName,
  }) {
    return copyWith(
      status: WaiterCallStatus.acknowledged,
      waiterId: waiterId,
      waiterName: waiterName,
      acknowledgedAt: DateTime.now(),
      actionsTaken: [...actionsTaken, 'Çağrı onaylandı'],
    );
  }

  /// İşleme başla
  WaiterCall startProcessing() {
    return copyWith(
      status: WaiterCallStatus.inProgress,
      respondedAt: DateTime.now(),
      actionsTaken: [...actionsTaken, 'İşleme başlandı'],
    );
  }

  /// Tamamla
  WaiterCall complete({String? responseNotes}) {
    return copyWith(
      status: WaiterCallStatus.completed,
      completedAt: DateTime.now(),
      responseNotes: responseNotes,
      actionsTaken: [...actionsTaken, 'Tamamlandı'],
    );
  }

  /// İptal et
  WaiterCall cancel({String? reason}) {
    return copyWith(
      status: WaiterCallStatus.cancelled,
      completedAt: DateTime.now(),
      responseNotes: reason,
      actionsTaken: [...actionsTaken, 'İptal edildi: ${reason ?? "Sebep belirtilmedi"}'],
    );
  }

  /// Eskalt et
  WaiterCall escalate({required WaiterCallPriority newPriority, String? reason}) {
    return copyWith(
      priority: newPriority,
      actionsTaken: [...actionsTaken, 'Eskalat edildi: ${reason ?? "Yüksek öncelik"}'],
      metadata: {...metadata, 'escalated': true, 'escalation_reason': reason},
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Bekleyen süre (dakika)
  int get waitingTimeMinutes {
    final endTime = acknowledgedAt ?? DateTime.now();
    return endTime.difference(createdAt).inMinutes;
  }

  /// Toplam işlem süresi (dakika)
  int? get totalProcessingTimeMinutes {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt).inMinutes;
  }

  /// Yanıt süresi (dakika)
  int? get responseTimeMinutes {
    if (acknowledgedAt == null) return null;
    return acknowledgedAt!.difference(createdAt).inMinutes;
  }

  /// Aktif mi?
  bool get isActive {
    return status == WaiterCallStatus.pending ||
           status == WaiterCallStatus.acknowledged ||
           status == WaiterCallStatus.inProgress;
  }

  /// Tamamlanmış mı?
  bool get isCompleted {
    return status == WaiterCallStatus.completed ||
           status == WaiterCallStatus.cancelled;
  }

  /// Gecikmiş mi?
  bool get isOverdue {
    if (!isActive) return false;
    
    final expectedResponseTime = _getExpectedResponseTime(requestType, priority);
    return waitingTimeMinutes > expectedResponseTime;
  }

  /// Acil mi?
  bool get isUrgent {
    return priority == WaiterCallPriority.urgent ||
           priority == WaiterCallPriority.emergency ||
           isOverdue;
  }

  /// Müşteri memnuniyet puanı hesapla
  double calculateSatisfactionScore() {
    if (!isCompleted) return 0.0;
    
    double score = 100.0;
    
    // Yanıt süresine göre puan düşür
    final responseTime = responseTimeMinutes ?? waitingTimeMinutes;
    final expectedTime = _getExpectedResponseTime(requestType, priority);
    
    if (responseTime > expectedTime) {
      final overTime = responseTime - expectedTime;
      score -= (overTime * 2); // Her fazla dakika için 2 puan düş
    }
    
    // İptal edildiyse ciddi puan düşür
    if (status == WaiterCallStatus.cancelled) {
      score -= 50;
    }
    
    // Eskalt edildiyse puan düşür
    if (metadata['escalated'] == true) {
      score -= 20;
    }
    
    return score.clamp(0.0, 100.0);
  }

  /// Öncelik renk kodu
  String get priorityColorCode {
    switch (priority) {
      case WaiterCallPriority.low:
        return '#4CAF50'; // Yeşil
      case WaiterCallPriority.normal:
        return '#2196F3'; // Mavi
      case WaiterCallPriority.high:
        return '#FF9800'; // Turuncu
      case WaiterCallPriority.urgent:
        return '#F44336'; // Kırmızı
      case WaiterCallPriority.emergency:
        return '#9C27B0'; // Mor
    }
  }

  /// Durum renk kodu
  String get statusColorCode {
    switch (status) {
      case WaiterCallStatus.pending:
        return '#FF9800'; // Turuncu
      case WaiterCallStatus.acknowledged:
        return '#2196F3'; // Mavi
      case WaiterCallStatus.inProgress:
        return '#9C27B0'; // Mor
      case WaiterCallStatus.completed:
        return '#4CAF50'; // Yeşil
      case WaiterCallStatus.cancelled:
        return '#757575'; // Gri
    }
  }

  /// Beklenen yanıt süresi hesapla (dakika)
  static int _getExpectedResponseTime(WaiterCallType type, WaiterCallPriority priority) {
    final baseTime = switch (type) {
      WaiterCallType.service => 3,
      WaiterCallType.order => 2,
      WaiterCallType.payment => 5,
      WaiterCallType.complaint => 1,
      WaiterCallType.assistance => 2,
      WaiterCallType.bill => 5,
      WaiterCallType.help => 2,
      WaiterCallType.cleaning => 8,
      WaiterCallType.emergency => 1,
    };
    
    final priorityMultiplier = switch (priority) {
      WaiterCallPriority.low => 2.0,
      WaiterCallPriority.normal => 1.0,
      WaiterCallPriority.high => 0.7,
      WaiterCallPriority.urgent => 0.5,
      WaiterCallPriority.emergency => 0.3,
    };
    
    return (baseTime * priorityMultiplier).round();
  }

  /// İstek türüne göre öncelik belirle
  static WaiterCallPriority _determinePriority(WaiterCallType type) {
    switch (type) {
      case WaiterCallType.emergency:
        return WaiterCallPriority.emergency;
      case WaiterCallType.complaint:
        return WaiterCallPriority.urgent;
      case WaiterCallType.assistance:
      case WaiterCallType.help:
        return WaiterCallPriority.high;
      case WaiterCallType.order:
        return WaiterCallPriority.high;
      case WaiterCallType.service:
        return WaiterCallPriority.normal;
      case WaiterCallType.payment:
      case WaiterCallType.bill:
        return WaiterCallPriority.normal;
      case WaiterCallType.cleaning:
        return WaiterCallPriority.low;
    }
  }

  @override
  String toString() {
    return 'WaiterCall(callId: $callId, table: $tableNumber, type: $requestType, status: $status)';
  }
}

/// Garson çağırma türleri
enum WaiterCallType {
  service('Hizmet'),
  order('Sipariş'),
  payment('Hesap'),
  complaint('Şikayet'),
  assistance('Yardım'),
  bill('Hesap'),
  help('Yardım'),
  cleaning('Temizlik'),
  emergency('Acil Durum');

  const WaiterCallType(this.displayName);
  final String displayName;

  String get description {
    switch (this) {
      case WaiterCallType.service:
        return 'Genel hizmet talebi';
      case WaiterCallType.order:
        return 'Sipariş alma';
      case WaiterCallType.payment:
        return 'Hesap isteme';
      case WaiterCallType.complaint:
        return 'Şikayet bildirimi';
      case WaiterCallType.assistance:
        return 'Yardım talebi';
      case WaiterCallType.bill:
        return 'Hesap isteme';
      case WaiterCallType.help:
        return 'Yardım talebi';
      case WaiterCallType.cleaning:
        return 'Masa temizleme';
      case WaiterCallType.emergency:
        return 'Acil durum';
    }
  }

  String get iconName {
    switch (this) {
      case WaiterCallType.service:
        return 'room_service';
      case WaiterCallType.order:
        return 'restaurant_menu';
      case WaiterCallType.payment:
        return 'receipt';
      case WaiterCallType.complaint:
        return 'report_problem';
      case WaiterCallType.assistance:
        return 'help';
      case WaiterCallType.bill:
        return 'receipt';
      case WaiterCallType.help:
        return 'help';
      case WaiterCallType.cleaning:
        return 'cleaning_services';
      case WaiterCallType.emergency:
        return 'emergency';
    }
  }
}

/// Garson çağırma öncelik seviyeleri
enum WaiterCallPriority {
  low('Düşük'),
  normal('Normal'),
  high('Yüksek'),
  urgent('Acil'),
  emergency('Kritik');

  const WaiterCallPriority(this.displayName);
  final String displayName;
}

/// Garson çağırma durumları
enum WaiterCallStatus {
  pending('Bekliyor'),
  acknowledged('Onaylandı'),
  inProgress('İşlemde'),
  completed('Tamamlandı'),
  cancelled('İptal Edildi');

  const WaiterCallStatus(this.displayName);
  final String displayName;
}

/// Garson çağırma istatistikleri
class WaiterCallStats {
  final int totalCalls;
  final int completedCalls;
  final int cancelledCalls;
  final double averageResponseTime;
  final double averageCompletionTime;
  final double satisfactionScore;
  final Map<WaiterCallType, int> callsByType;
  final Map<WaiterCallPriority, int> callsByPriority;

  const WaiterCallStats({
    required this.totalCalls,
    required this.completedCalls,
    required this.cancelledCalls,
    required this.averageResponseTime,
    required this.averageCompletionTime,
    required this.satisfactionScore,
    required this.callsByType,
    required this.callsByPriority,
  });

  double get completionRate => totalCalls > 0 ? (completedCalls / totalCalls) * 100 : 0;
  double get cancellationRate => totalCalls > 0 ? (cancelledCalls / totalCalls) * 100 : 0;
} 