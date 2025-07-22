import 'package:cloud_firestore/cloud_firestore.dart';

/// Müşteri değerlendirme ve puanlama modeli
class ReviewRating {
  final String reviewId;
  final String customerId;
  final String customerName;
  final String? customerAvatar;
  final String businessId;
  final String? orderId; // Hangi siparişle ilgili
  final String? productId; // Hangi ürünle ilgili (opsiyonel)
  
  // Puanlama
  final double overallRating; // 1-5 genel puan
  final Map<String, double> detailedRatings; // kategori bazlı puanlar
  
  // Yorum
  final String? comment;
  final List<String> tags; // 'hızlı', 'lezzetli', 'pahalı' vb.
  final List<ReviewImage> images; // Değerlendirme fotoğrafları
  
  // Meta bilgiler
  final bool isVerified; // Doğrulanmış müşteri mi?
  final bool isAnonymous; // Anonim değerlendirme mi?
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Etkileşim
  final int helpfulCount; // Kaç kişi yararlı buldu
  final int notHelpfulCount; // Kaç kişi yararlı bulmadı
  final List<String> helpfulVoters; // Yararlı bulan kullanıcı ID'leri
  final List<String> reportedBy; // Şikayet eden kullanıcılar
  
  // İşletme yanıtı
  final String? businessResponse;
  final DateTime? businessResponseDate;
  final String? businessResponderId;
  
  // Durum
  final ReviewStatus status;
  final String? moderationNotes;

  const ReviewRating({
    required this.reviewId,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    required this.businessId,
    this.orderId,
    this.productId,
    required this.overallRating,
    required this.detailedRatings,
    this.comment,
    required this.tags,
    required this.images,
    required this.isVerified,
    required this.isAnonymous,
    required this.createdAt,
    this.updatedAt,
    required this.helpfulCount,
    required this.notHelpfulCount,
    required this.helpfulVoters,
    required this.reportedBy,
    this.businessResponse,
    this.businessResponseDate,
    this.businessResponderId,
    required this.status,
    this.moderationNotes,
  });

  /// Yeni değerlendirme oluştur
  factory ReviewRating.create({
    required String customerId,
    required String customerName,
    String? customerAvatar,
    required String businessId,
    String? orderId,
    String? productId,
    required double overallRating,
    Map<String, double>? detailedRatings,
    String? comment,
    List<String>? tags,
    List<ReviewImage>? images,
    bool isVerified = false,
    bool isAnonymous = false,
  }) {
    final now = DateTime.now();
    return ReviewRating(
      reviewId: 'review_${now.millisecondsSinceEpoch}_$customerId',
      customerId: customerId,
      customerName: isAnonymous ? 'Anonim Kullanıcı' : customerName,
      customerAvatar: isAnonymous ? null : customerAvatar,
      businessId: businessId,
      orderId: orderId,
      productId: productId,
      overallRating: overallRating.clamp(1.0, 5.0),
      detailedRatings: detailedRatings ?? {},
      comment: comment,
      tags: tags ?? [],
      images: images ?? [],
      isVerified: isVerified,
      isAnonymous: isAnonymous,
      createdAt: now,
      helpfulCount: 0,
      notHelpfulCount: 0,
      helpfulVoters: [],
      reportedBy: [],
      status: ReviewStatus.active,
    );
  }

  /// Firestore'dan oluşturma
  factory ReviewRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ReviewRating(
      reviewId: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Kullanıcı',
      customerAvatar: data['customerAvatar'],
      businessId: data['businessId'] ?? '',
      orderId: data['orderId'],
      productId: data['productId'],
      overallRating: (data['overallRating'] ?? 5.0).toDouble().clamp(1.0, 5.0),
      detailedRatings: Map<String, double>.from(data['detailedRatings'] ?? {}),
      comment: data['comment'],
      tags: List<String>.from(data['tags'] ?? []),
      images: (data['images'] as List?)
          ?.map((img) => ReviewImage.fromMap(img))
          .toList() ?? [],
      isVerified: data['isVerified'] ?? false,
      isAnonymous: data['isAnonymous'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      helpfulCount: data['helpfulCount'] ?? 0,
      notHelpfulCount: data['notHelpfulCount'] ?? 0,
      helpfulVoters: List<String>.from(data['helpfulVoters'] ?? []),
      reportedBy: List<String>.from(data['reportedBy'] ?? []),
      businessResponse: data['businessResponse'],
      businessResponseDate: data['businessResponseDate'] != null
          ? (data['businessResponseDate'] as Timestamp).toDate()
          : null,
      businessResponderId: data['businessResponderId'],
      status: ReviewStatus.values.firstWhere(
        (status) => status.toString() == data['status'],
        orElse: () => ReviewStatus.active,
      ),
      moderationNotes: data['moderationNotes'],
    );
  }

  /// Firestore'a dönüştürme
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerAvatar': customerAvatar,
      'businessId': businessId,
      'orderId': orderId,
      'productId': productId,
      'overallRating': overallRating,
      'detailedRatings': detailedRatings,
      'comment': comment,
      'tags': tags,
      'images': images.map((img) => img.toMap()).toList(),
      'isVerified': isVerified,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'helpfulCount': helpfulCount,
      'notHelpfulCount': notHelpfulCount,
      'helpfulVoters': helpfulVoters,
      'reportedBy': reportedBy,
      'businessResponse': businessResponse,
      'businessResponseDate': businessResponseDate != null 
          ? Timestamp.fromDate(businessResponseDate!) 
          : null,
      'businessResponderId': businessResponderId,
      'status': status.toString(),
      'moderationNotes': moderationNotes,
    };
  }

  /// Kopya oluşturma
  ReviewRating copyWith({
    double? overallRating,
    Map<String, double>? detailedRatings,
    String? comment,
    List<String>? tags,
    List<ReviewImage>? images,
    DateTime? updatedAt,
    int? helpfulCount,
    int? notHelpfulCount,
    List<String>? helpfulVoters,
    List<String>? reportedBy,
    String? businessResponse,
    DateTime? businessResponseDate,
    String? businessResponderId,
    ReviewStatus? status,
    String? moderationNotes,
  }) {
    return ReviewRating(
      reviewId: reviewId,
      customerId: customerId,
      customerName: customerName,
      customerAvatar: customerAvatar,
      businessId: businessId,
      orderId: orderId,
      productId: productId,
      overallRating: overallRating ?? this.overallRating,
      detailedRatings: detailedRatings ?? this.detailedRatings,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      isVerified: isVerified,
      isAnonymous: isAnonymous,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      helpfulCount: helpfulCount ?? this.helpfulCount,
      notHelpfulCount: notHelpfulCount ?? this.notHelpfulCount,
      helpfulVoters: helpfulVoters ?? this.helpfulVoters,
      reportedBy: reportedBy ?? this.reportedBy,
      businessResponse: businessResponse ?? this.businessResponse,
      businessResponseDate: businessResponseDate ?? this.businessResponseDate,
      businessResponderId: businessResponderId ?? this.businessResponderId,
      status: status ?? this.status,
      moderationNotes: moderationNotes ?? this.moderationNotes,
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Yararlı bulundu oyu ekle
  ReviewRating addHelpfulVote(String userId) {
    if (helpfulVoters.contains(userId)) return this;
    
    final newVoters = List<String>.from(helpfulVoters)..add(userId);
    return copyWith(
      helpfulVoters: newVoters,
      helpfulCount: helpfulCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Yararlı bulundu oyunu çıkar
  ReviewRating removeHelpfulVote(String userId) {
    if (!helpfulVoters.contains(userId)) return this;
    
    final newVoters = List<String>.from(helpfulVoters)..remove(userId);
    return copyWith(
      helpfulVoters: newVoters,
      helpfulCount: helpfulCount - 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Şikayet ekle
  ReviewRating addReport(String userId) {
    if (reportedBy.contains(userId)) return this;
    
    final newReports = List<String>.from(reportedBy)..add(userId);
    return copyWith(
      reportedBy: newReports,
      updatedAt: DateTime.now(),
    );
  }

  /// İşletme yanıtı ekle
  ReviewRating addBusinessResponse({
    required String response,
    required String responderId,
  }) {
    return copyWith(
      businessResponse: response,
      businessResponseDate: DateTime.now(),
      businessResponderId: responderId,
      updatedAt: DateTime.now(),
    );
  }

  /// Durumu güncelle
  ReviewRating updateStatus(ReviewStatus newStatus, {String? notes}) {
    return copyWith(
      status: newStatus,
      moderationNotes: notes,
      updatedAt: DateTime.now(),
    );
  }

  /// Yıldız dağılımı
  Map<int, double> get starDistribution {
    final stars = <int, double>{};
    for (int i = 1; i <= 5; i++) {
      stars[i] = overallRating >= i ? 1.0 : 
                 overallRating > i - 1 ? overallRating - (i - 1) : 0.0;
    }
    return stars;
  }

  /// Pozitif değerlendirme mi?
  bool get isPositive => overallRating >= 4.0;

  /// Negatif değerlendirme mi?
  bool get isNegative => overallRating <= 2.0;

  /// Orta değerlendirme mi?
  bool get isNeutral => overallRating > 2.0 && overallRating < 4.0;

  /// Resimli değerlendirme mi?
  bool get hasImages => images.isNotEmpty;

  /// Uzun yorum mu?
  bool get hasDetailedComment => comment != null && comment!.length > 50;

  /// İşletme yanıtı var mı?
  bool get hasBusinessResponse => businessResponse != null && businessResponse!.isNotEmpty;

  /// Değerlendirme yaşı (gün)
  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  /// Güncel mi? (30 gün içinde)
  bool get isRecent => ageInDays <= 30;

  /// Yararlılık oranı
  double get helpfulnessRatio {
    final totalVotes = helpfulCount + notHelpfulCount;
    if (totalVotes == 0) return 0.0;
    return helpfulCount / totalVotes;
  }

  /// Değerlendirme puanı (algoritmik)
  double calculateReviewScore() {
    double score = overallRating * 20; // 1-5 -> 20-100

    // Detaylı yorum bonusu
    if (hasDetailedComment) score += 5;
    
    // Resim bonusu
    if (hasImages) score += 3;
    
    // Doğrulanmış kullanıcı bonusu
    if (isVerified) score += 2;
    
    // Yararlılık bonusu
    score += helpfulnessRatio * 5;
    
    // Yaş maliyeti (eski değerlendirmeler daha az önemli)
    final ageFactor = 1.0 - (ageInDays / 365.0 * 0.1);
    score *= ageFactor.clamp(0.5, 1.0);

    return score.clamp(0.0, 100.0);
  }

  /// Kategori puanlarının ortalaması
  double get detailedRatingsAverage {
    if (detailedRatings.isEmpty) return overallRating;
    return detailedRatings.values.reduce((a, b) => a + b) / detailedRatings.length;
  }

  /// En düşük kategori puanı
  String? get lowestRatedCategory {
    if (detailedRatings.isEmpty) return null;
    
    var lowestCategory = detailedRatings.entries.first.key;
    var lowestRating = detailedRatings.entries.first.value;
    
    for (final entry in detailedRatings.entries) {
      if (entry.value < lowestRating) {
        lowestRating = entry.value;
        lowestCategory = entry.key;
      }
    }
    
    return lowestCategory;
  }

  /// En yüksek kategori puanı
  String? get highestRatedCategory {
    if (detailedRatings.isEmpty) return null;
    
    var highestCategory = detailedRatings.entries.first.key;
    var highestRating = detailedRatings.entries.first.value;
    
    for (final entry in detailedRatings.entries) {
      if (entry.value > highestRating) {
        highestRating = entry.value;
        highestCategory = entry.key;
      }
    }
    
    return highestCategory;
  }

  @override
  String toString() {
    return 'ReviewRating(reviewId: $reviewId, rating: $overallRating, customer: $customerName)';
  }
}

/// Değerlendirme resmi modeli
class ReviewImage {
  final String imageId;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final int? width;
  final int? height;
  final DateTime uploadedAt;

  const ReviewImage({
    required this.imageId,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    this.width,
    this.height,
    required this.uploadedAt,
  });

  factory ReviewImage.fromMap(Map<String, dynamic> map) {
    return ReviewImage(
      imageId: map['imageId'] ?? '',
      url: map['url'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      caption: map['caption'],
      width: map['width']?.toInt(),
      height: map['height']?.toInt(),
      uploadedAt: DateTime.fromMillisecondsSinceEpoch(
        map['uploadedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageId': imageId,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'width': width,
      'height': height,
      'uploadedAt': uploadedAt.millisecondsSinceEpoch,
    };
  }
}

/// Değerlendirme durumu
enum ReviewStatus {
  active('Aktif'),
  pending('Beklemede'),
  hidden('Gizli'),
  flagged('İşaretli'),
  removed('Kaldırıldı');

  const ReviewStatus(this.displayName);
  final String displayName;
}

/// Yaygın değerlendirme kategorileri
class ReviewCategories {
  static const Map<String, String> restaurant = {
    'food_quality': 'Yemek Kalitesi',
    'service': 'Hizmet',
    'atmosphere': 'Atmosfer',
    'value': 'Fiyat/Performans',
    'cleanliness': 'Temizlik',
    'speed': 'Hız',
  };

  static const Map<String, String> cafe = {
    'coffee_quality': 'Kahve Kalitesi',
    'service': 'Hizmet',
    'atmosphere': 'Atmosfer',
    'value': 'Fiyat/Performans',
    'wifi': 'WiFi',
    'seating': 'Oturma Alanı',
  };

  static const Map<String, String> fastFood = {
    'food_quality': 'Yemek Kalitesi',
    'speed': 'Hız',
    'value': 'Fiyat/Performans',
    'cleanliness': 'Temizlik',
    'packaging': 'Paketleme',
  };
}

/// Yaygın değerlendirme etiketleri
class ReviewTags {
  static const List<String> positive = [
    'lezzetli',
    'hızlı',
    'temiz',
    'güler yüzlü',
    'uygun fiyat',
    'tavsiye ederim',
    'mükemmel',
    'kaliteli',
    'taze',
    'sıcak',
  ];

  static const List<String> negative = [
    'soğuk',
    'pahalı',
    'yavaş',
    'kaba',
    'kirli',
    'tadımsız',
    'eski',
    'eksik',
    'yanlış',
    'kalitesiz',
  ];

  static const List<String> neutral = [
    'normal',
    'ortalama',
    'standart',
    'beklediğim gibi',
    'fena değil',
    'idare eder',
  ];
}

/// Değerlendirme filtreleme seçenekleri
class ReviewFilters {
  static const Map<String, String> rating = {
    '5': '5 Yıldız',
    '4': '4 Yıldız',
    '3': '3 Yıldız',
    '2': '2 Yıldız',
    '1': '1 Yıldız',
  };

  static const Map<String, String> timeframe = {
    'week': 'Son Hafta',
    'month': 'Son Ay',
    'quarter': 'Son 3 Ay',
    'year': 'Son Yıl',
    'all': 'Tümü',
  };

  static const Map<String, String> type = {
    'verified': 'Doğrulanmış',
    'with_photos': 'Fotoğraflı',
    'detailed': 'Detaylı Yorum',
    'recent': 'Güncel',
  };
} 