import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// Müşteri geri bildirim modeli
class CustomerFeedback {
  final String feedbackId;
  final String customerId;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String businessId;
  final String? orderId; // Hangi siparişle ilgili
  final FeedbackType type;
  final FeedbackCategory category;
  final String subject;
  final String message;
  final FeedbackPriority priority;
  final FeedbackStatus status;
  final List<String> attachments; // Resim/dosya URL'leri
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // İşletme yanıtı
  final String? response;
  final DateTime? responseDate;
  final String? responderId;
  final String? responderName;
  
  // Takip
  final bool followUpRequested;
  final DateTime? followUpDate;
  final String? followUpNotes;
  
  // İç notlar (sadece işletme görür)
  final String? internalNotes;
  final List<String> tags;
  final double? satisfactionRating; // 1-5 (geri bildirim sonrası)

  const CustomerFeedback({
    required this.feedbackId,
    required this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.businessId,
    this.orderId,
    required this.type,
    required this.category,
    required this.subject,
    required this.message,
    required this.priority,
    required this.status,
    required this.attachments,
    required this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.response,
    this.responseDate,
    this.responderId,
    this.responderName,
    required this.followUpRequested,
    this.followUpDate,
    this.followUpNotes,
    this.internalNotes,
    required this.tags,
    this.satisfactionRating,
  });

  /// Yeni geri bildirim oluştur
  factory CustomerFeedback.create({
    required String customerId,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
    required String businessId,
    String? orderId,
    required FeedbackType type,
    required FeedbackCategory category,
    required String subject,
    required String message,
    FeedbackPriority? priority,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    bool followUpRequested = false,
  }) {
    final now = DateTime.now();
    final autoPriority = _determinePriority(type, category, message);
    
    return CustomerFeedback(
      feedbackId: 'feedback_${now.millisecondsSinceEpoch}_$customerId',
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      businessId: businessId,
      orderId: orderId,
      type: type,
      category: category,
      subject: subject,
      message: message,
      priority: priority ?? autoPriority,
      status: FeedbackStatus.submitted,
      attachments: attachments ?? [],
      metadata: metadata ?? {},
      createdAt: now,
      followUpRequested: followUpRequested,
      tags: [],
    );
  }

  /// Firestore'dan oluşturma
  factory CustomerFeedback.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CustomerFeedback(
      feedbackId: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Kullanıcı',
      customerEmail: data['customerEmail'],
      customerPhone: data['customerPhone'],
      businessId: data['businessId'] ?? '',
      orderId: data['orderId'],
      type: FeedbackType.values.firstWhere(
        (type) => type.toString() == data['type'],
        orElse: () => FeedbackType.general,
      ),
      category: FeedbackCategory.values.firstWhere(
        (category) => category.toString() == data['category'],
        orElse: () => FeedbackCategory.other,
      ),
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      priority: FeedbackPriority.values.firstWhere(
        (priority) => priority.toString() == data['priority'],
        orElse: () => FeedbackPriority.medium,
      ),
      status: FeedbackStatus.values.firstWhere(
        (status) => status.toString() == data['status'],
        orElse: () => FeedbackStatus.submitted,
      ),
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      response: data['response'],
      responseDate: data['responseDate'] != null
          ? (data['responseDate'] as Timestamp).toDate()
          : null,
      responderId: data['responderId'],
      responderName: data['responderName'],
      followUpRequested: data['followUpRequested'] ?? false,
      followUpDate: data['followUpDate'] != null
          ? (data['followUpDate'] as Timestamp).toDate()
          : null,
      followUpNotes: data['followUpNotes'],
      internalNotes: data['internalNotes'],
      tags: List<String>.from(data['tags'] ?? []),
      satisfactionRating: data['satisfactionRating']?.toDouble(),
    );
  }

  /// Firestore'a dönüştürme
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'businessId': businessId,
      'orderId': orderId,
      'type': type.toString(),
      'category': category.toString(),
      'subject': subject,
      'message': message,
      'priority': priority.toString(),
      'status': status.toString(),
      'attachments': attachments,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'response': response,
      'responseDate': responseDate != null ? Timestamp.fromDate(responseDate!) : null,
      'responderId': responderId,
      'responderName': responderName,
      'followUpRequested': followUpRequested,
      'followUpDate': followUpDate != null ? Timestamp.fromDate(followUpDate!) : null,
      'followUpNotes': followUpNotes,
      'internalNotes': internalNotes,
      'tags': tags,
      'satisfactionRating': satisfactionRating,
    };
  }

  /// Kopya oluşturma
  CustomerFeedback copyWith({
    FeedbackPriority? priority,
    FeedbackStatus? status,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
    String? response,
    DateTime? responseDate,
    String? responderId,
    String? responderName,
    bool? followUpRequested,
    DateTime? followUpDate,
    String? followUpNotes,
    String? internalNotes,
    List<String>? tags,
    double? satisfactionRating,
  }) {
    return CustomerFeedback(
      feedbackId: feedbackId,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      businessId: businessId,
      orderId: orderId,
      type: type,
      category: category,
      subject: subject,
      message: message,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      response: response ?? this.response,
      responseDate: responseDate ?? this.responseDate,
      responderId: responderId ?? this.responderId,
      responderName: responderName ?? this.responderName,
      followUpRequested: followUpRequested ?? this.followUpRequested,
      followUpDate: followUpDate ?? this.followUpDate,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      internalNotes: internalNotes ?? this.internalNotes,
      tags: tags ?? this.tags,
      satisfactionRating: satisfactionRating ?? this.satisfactionRating,
    );
  }

  // ============================================================================
  // STATUS METHODS
  // ============================================================================

  /// Gözden geçirildi olarak işaretle
  CustomerFeedback markAsReviewed({String? notes}) {
    return copyWith(
      status: FeedbackStatus.inReview,
      internalNotes: notes,
      updatedAt: DateTime.now(),
    );
  }

  /// İşleme alındı olarak işaretle
  CustomerFeedback markAsInProgress({String? notes}) {
    return copyWith(
      status: FeedbackStatus.inProgress,
      internalNotes: notes,
      updatedAt: DateTime.now(),
    );
  }

  /// Yanıtla
  CustomerFeedback respond({
    required String response,
    required String responderId,
    required String responderName,
  }) {
    return copyWith(
      response: response,
      responseDate: DateTime.now(),
      responderId: responderId,
      responderName: responderName,
      status: FeedbackStatus.responded,
      updatedAt: DateTime.now(),
    );
  }

  /// Çözüldü olarak işaretle
  CustomerFeedback markAsResolved({String? notes}) {
    return copyWith(
      status: FeedbackStatus.resolved,
      internalNotes: notes,
      updatedAt: DateTime.now(),
    );
  }

  /// Kapatıldı olarak işaretle
  CustomerFeedback markAsClosed({String? notes}) {
    return copyWith(
      status: FeedbackStatus.closed,
      internalNotes: notes,
      updatedAt: DateTime.now(),
    );
  }

  /// Takip planla
  CustomerFeedback scheduleFollowUp({
    required DateTime followUpDate,
    String? notes,
  }) {
    return copyWith(
      followUpRequested: true,
      followUpDate: followUpDate,
      followUpNotes: notes,
      updatedAt: DateTime.now(),
    );
  }

  /// Memnuniyet puanı ekle
  CustomerFeedback addSatisfactionRating(double rating) {
    return copyWith(
      satisfactionRating: rating.clamp(1.0, 5.0),
      updatedAt: DateTime.now(),
    );
  }

  /// Etiket ekle
  CustomerFeedback addTag(String tag) {
    if (tags.contains(tag)) return this;
    
    final newTags = List<String>.from(tags)..add(tag);
    return copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
  }

  /// Etiket çıkar
  CustomerFeedback removeTag(String tag) {
    final newTags = List<String>.from(tags)..remove(tag);
    return copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Yaş (saat)
  int get ageInHours => DateTime.now().difference(createdAt).inHours;

  /// Yaş (gün)
  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  /// Yanıt süresi (saat)
  int? get responseTimeHours {
    if (responseDate == null) return null;
    return responseDate!.difference(createdAt).inHours;
  }

  /// Aktif mi?
  bool get isActive {
    return status == FeedbackStatus.submitted ||
           status == FeedbackStatus.inReview ||
           status == FeedbackStatus.inProgress;
  }

  /// Tamamlanmış mı?
  bool get isCompleted {
    return status == FeedbackStatus.resolved ||
           status == FeedbackStatus.closed;
  }

  /// Yanıtlanmış mı?
  bool get hasResponse => response != null && response!.isNotEmpty;

  /// Takip gerekli mi?
  bool get needsFollowUp {
    if (!followUpRequested || followUpDate == null) return false;
    return DateTime.now().isAfter(followUpDate!);
  }

  /// Gecikmiş mi?
  bool get isOverdue {
    if (!isActive) return false;
    
    final expectedResponseTime = _getExpectedResponseTime(priority, type);
    return ageInHours > expectedResponseTime;
  }

  /// Acil mi?
  bool get isUrgent {
    return priority == FeedbackPriority.high ||
           priority == FeedbackPriority.critical ||
           isOverdue;
  }

  /// Eklenti var mı?
  bool get hasAttachments => attachments.isNotEmpty;

  /// Müşteri memnuniyet puanı var mı?
  bool get hasSatisfactionRating => satisfactionRating != null;

  /// Karmaşık geri bildirim mi? (uzun mesaj)
  bool get isComplex => message.length > 200;

  /// Öncelik renk kodu
  String get priorityColorCode {
    switch (priority) {
      case FeedbackPriority.low:
        return '#4CAF50'; // Yeşil
      case FeedbackPriority.medium:
        return '#2196F3'; // Mavi
      case FeedbackPriority.high:
        return '#FF9800'; // Turuncu
      case FeedbackPriority.critical:
        return '#F44336'; // Kırmızı
    }
  }

  /// Durum renk kodu
  String get statusColorCode {
    switch (status) {
      case FeedbackStatus.submitted:
        return '#FF9800'; // Turuncu
      case FeedbackStatus.inReview:
        return '#2196F3'; // Mavi
      case FeedbackStatus.inProgress:
        return '#9C27B0'; // Mor
      case FeedbackStatus.responded:
        return '#00BCD4'; // Cyan
      case FeedbackStatus.resolved:
        return '#4CAF50'; // Yeşil
      case FeedbackStatus.closed:
        return '#757575'; // Gri
    }
  }

  /// Performans puanı hesapla (işletme için)
  double calculatePerformanceScore() {
    double score = 0;
    
    // Yanıt süresi puanı
    if (hasResponse) {
      final responseHours = responseTimeHours!;
      final expectedHours = _getExpectedResponseTime(priority, type);
      
      if (responseHours <= expectedHours) {
        score += 40; // Zamanında yanıt
      } else {
        score += math.max(0, 40 - (responseHours - expectedHours) * 2);
      }
    }
    
    // Çözüm puanı
    if (status == FeedbackStatus.resolved) {
      score += 30;
    } else if (status == FeedbackStatus.responded) {
      score += 20;
    }
    
    // Müşteri memnuniyeti puanı
    if (hasSatisfactionRating) {
      score += satisfactionRating! * 6; // 1-5 -> 6-30 puan
    }
    
    return score.clamp(0.0, 100.0);
  }

  /// Beklenen yanıt süresi (saat)
  static int _getExpectedResponseTime(FeedbackPriority priority, FeedbackType type) {
    final baseTime = switch (type) {
      FeedbackType.complaint => 2,
      FeedbackType.suggestion => 24,
      FeedbackType.compliment => 48,
      FeedbackType.question => 8,
      FeedbackType.general => 24,
    };
    
    final priorityMultiplier = switch (priority) {
      FeedbackPriority.critical => 0.25,
      FeedbackPriority.high => 0.5,
      FeedbackPriority.medium => 1.0,
      FeedbackPriority.low => 2.0,
    };
    
    return (baseTime * priorityMultiplier).round();
  }

  /// Otomatik öncelik belirleme
  static FeedbackPriority _determinePriority(
    FeedbackType type,
    FeedbackCategory category,
    String message,
  ) {
    // Şikayet otomatik yüksek öncelik
    if (type == FeedbackType.complaint) {
      if (category == FeedbackCategory.foodPoisoning ||
          category == FeedbackCategory.hygiene) {
        return FeedbackPriority.critical;
      }
      return FeedbackPriority.high;
    }
    
    // Kritik kelimeler
    final criticalKeywords = ['kötü', 'berbat', 'iğrenç', 'hasta', 'zehir'];
    final messageLower = message.toLowerCase();
    
    if (criticalKeywords.any((keyword) => messageLower.contains(keyword))) {
      return FeedbackPriority.high;
    }
    
    // Varsayılan orta öncelik
    return FeedbackPriority.medium;
  }

  @override
  String toString() {
    return 'CustomerFeedback(feedbackId: $feedbackId, type: $type, status: $status)';
  }
}

/// Geri bildirim türü
enum FeedbackType {
  complaint('Şikayet'),
  suggestion('Öneri'),
  compliment('Övgü'),
  question('Soru'),
  general('Genel');

  const FeedbackType(this.displayName);
  final String displayName;
}

/// Geri bildirim kategorisi
enum FeedbackCategory {
  foodQuality('Yemek Kalitesi'),
  service('Hizmet'),
  cleanliness('Temizlik'),
  atmosphere('Atmosfer'),
  pricing('Fiyatlandırma'),
  speed('Hız'),
  hygiene('Hijyen'),
  foodPoisoning('Gıda Zehirlenmesi'),
  staff('Personel'),
  facility('Tesis'),
  technology('Teknoloji'),
  other('Diğer');

  const FeedbackCategory(this.displayName);
  final String displayName;
}

/// Geri bildirim önceliği
enum FeedbackPriority {
  low('Düşük'),
  medium('Orta'),
  high('Yüksek'),
  critical('Kritik');

  const FeedbackPriority(this.displayName);
  final String displayName;
}

/// Geri bildirim durumu
enum FeedbackStatus {
  submitted('Gönderildi'),
  inReview('İnceleniyor'),
  inProgress('İşlemde'),
  responded('Yanıtlandı'),
  resolved('Çözüldü'),
  closed('Kapatıldı');

  const FeedbackStatus(this.displayName);
  final String displayName;
}

/// Geri bildirim istatistikleri
class FeedbackStats {
  final int totalFeedbacks;
  final int complaints;
  final int suggestions;
  final int compliments;
  final double averageResponseTime;
  final double resolutionRate;
  final double averageSatisfactionRating;
  final Map<FeedbackCategory, int> feedbacksByCategory;
  final Map<FeedbackStatus, int> feedbacksByStatus;

  const FeedbackStats({
    required this.totalFeedbacks,
    required this.complaints,
    required this.suggestions,
    required this.compliments,
    required this.averageResponseTime,
    required this.resolutionRate,
    required this.averageSatisfactionRating,
    required this.feedbacksByCategory,
    required this.feedbacksByStatus,
  });
}

 