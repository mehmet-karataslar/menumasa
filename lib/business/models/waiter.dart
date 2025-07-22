import 'package:cloud_firestore/cloud_firestore.dart';

/// Garson modeli - işletmedeki garsonların bilgilerini içerir
class Waiter {
  final String waiterId;
  final String businessId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final WaiterRank rank;
  final WaiterStatus status;
  final String? currentSection; // Hangi bölümde çalışıyor
  final List<String> assignedTables; // Sorumlu olduğu masalar
  final WaiterShift currentShift;
  final Map<String, dynamic> workingHours; // Çalışma saatleri
  final WaiterStatistics statistics;
  final List<String> languages; // Konuşabildiği diller
  final List<String> specialSkills; // Özel yetenekler
  final DateTime hireDate;
  final DateTime? lastActiveAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Waiter({
    required this.waiterId,
    required this.businessId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    required this.rank,
    required this.status,
    this.currentSection,
    required this.assignedTables,
    required this.currentShift,
    required this.workingHours,
    required this.statistics,
    required this.languages,
    required this.specialSkills,
    required this.hireDate,
    this.lastActiveAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Yeni garson oluştur
  factory Waiter.create({
    required String businessId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? profileImageUrl,
    WaiterRank? rank,
    String? currentSection,
    List<String>? assignedTables,
    Map<String, dynamic>? workingHours,
    List<String>? languages,
    List<String>? specialSkills,
    DateTime? hireDate,
  }) {
    final now = DateTime.now();
    return Waiter(
      waiterId: now.millisecondsSinceEpoch.toString(),
      businessId: businessId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      profileImageUrl: profileImageUrl,
      rank: rank ?? WaiterRank.trainee,
      status: WaiterStatus.available,
      currentSection: currentSection,
      assignedTables: assignedTables ?? [],
      currentShift: WaiterShift.none,
      workingHours: workingHours ?? _getDefaultWorkingHours(),
      statistics: WaiterStatistics.initial(),
      languages: languages ?? ['tr'],
      specialSkills: specialSkills ?? [],
      hireDate: hireDate ?? now,
      lastActiveAt: now,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Firestore'dan oluştur
  factory Waiter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Waiter(
      waiterId: doc.id,
      businessId: data['businessId'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      rank: WaiterRank.values.firstWhere(
        (rank) => rank.toString() == data['rank'],
        orElse: () => WaiterRank.trainee,
      ),
      status: WaiterStatus.values.firstWhere(
        (status) => status.toString() == data['status'],
        orElse: () => WaiterStatus.available,
      ),
      currentSection: data['currentSection'],
      assignedTables: List<String>.from(data['assignedTables'] ?? []),
      currentShift: WaiterShift.values.firstWhere(
        (shift) => shift.toString() == data['currentShift'],
        orElse: () => WaiterShift.none,
      ),
      workingHours: Map<String, dynamic>.from(data['workingHours'] ?? {}),
      statistics: WaiterStatistics.fromMap(data['statistics'] ?? {}),
      languages: List<String>.from(data['languages'] ?? ['tr']),
      specialSkills: List<String>.from(data['specialSkills'] ?? []),
      hireDate: (data['hireDate'] as Timestamp).toDate(),
      lastActiveAt: data['lastActiveAt'] != null 
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Firestore'a kaydet
  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'rank': rank.toString(),
      'status': status.toString(),
      'currentSection': currentSection,
      'assignedTables': assignedTables,
      'currentShift': currentShift.toString(),
      'workingHours': workingHours,
      'statistics': statistics.toMap(),
      'languages': languages,
      'specialSkills': specialSkills,
      'hireDate': Timestamp.fromDate(hireDate),
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Kopya oluştur
  Waiter copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profileImageUrl,
    WaiterRank? rank,
    WaiterStatus? status,
    String? currentSection,
    List<String>? assignedTables,
    WaiterShift? currentShift,
    Map<String, dynamic>? workingHours,
    WaiterStatistics? statistics,
    List<String>? languages,
    List<String>? specialSkills,
    DateTime? hireDate,
    DateTime? lastActiveAt,
    bool? isActive,
  }) {
    return Waiter(
      waiterId: waiterId,
      businessId: businessId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rank: rank ?? this.rank,
      status: status ?? this.status,
      currentSection: currentSection ?? this.currentSection,
      assignedTables: assignedTables ?? this.assignedTables,
      currentShift: currentShift ?? this.currentShift,
      workingHours: workingHours ?? this.workingHours,
      statistics: statistics ?? this.statistics,
      languages: languages ?? this.languages,
      specialSkills: specialSkills ?? this.specialSkills,
      hireDate: hireDate ?? this.hireDate,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Tam ad
  String get fullName => '$firstName $lastName';

  /// Kısa ad (ilk harf + soyad)
  String get shortName => '${firstName[0]}. $lastName';

  /// Profil inisiyalleri
  String get initials => '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}';

  /// Deneyim süresi (yıl)
  int get experienceYears {
    final now = DateTime.now();
    return now.difference(hireDate).inDays ~/ 365;
  }

  /// Çevrimiçi mi?
  bool get isOnline {
    if (lastActiveAt == null) return false;
    final now = DateTime.now();
    return now.difference(lastActiveAt!).inMinutes < 5;
  }

  /// Müsait mi?
  bool get isAvailable {
    return isActive && 
           status == WaiterStatus.available && 
           currentShift != WaiterShift.none &&
           isOnline;
  }

  /// Vardiya kontrolü
  bool get isOnShift {
    return currentShift != WaiterShift.none;
  }

  /// Rütbe rengi
  String get rankColor {
    switch (rank) {
      case WaiterRank.trainee:
        return '#9E9E9E'; // Gri
      case WaiterRank.junior:
        return '#2196F3'; // Mavi
      case WaiterRank.senior:
        return '#4CAF50'; // Yeşil
      case WaiterRank.lead:
        return '#FF9800'; // Turuncu
      case WaiterRank.supervisor:
        return '#F44336'; // Kırmızı
      case WaiterRank.manager:
        return '#9C27B0'; // Mor
    }
  }

  /// Durum rengi
  String get statusColor {
    switch (status) {
      case WaiterStatus.available:
        return '#4CAF50'; // Yeşil
      case WaiterStatus.busy:
        return '#FF9800'; // Turuncu
      case WaiterStatus.break_:
        return '#2196F3'; // Mavi
      case WaiterStatus.offline:
        return '#9E9E9E'; // Gri
      case WaiterStatus.sick:
        return '#F44336'; // Kırmızı
    }
  }

  /// Varsayılan çalışma saatleri
  static Map<String, dynamic> _getDefaultWorkingHours() {
    return {
      'monday': {'start': '09:00', 'end': '17:00', 'isWorking': true},
      'tuesday': {'start': '09:00', 'end': '17:00', 'isWorking': true},
      'wednesday': {'start': '09:00', 'end': '17:00', 'isWorking': true},
      'thursday': {'start': '09:00', 'end': '17:00', 'isWorking': true},
      'friday': {'start': '09:00', 'end': '17:00', 'isWorking': true},
      'saturday': {'start': '10:00', 'end': '15:00', 'isWorking': true},
      'sunday': {'start': '10:00', 'end': '15:00', 'isWorking': false},
    };
  }

  @override
  String toString() {
    return 'Waiter(id: $waiterId, name: $fullName, rank: $rank, status: $status)';
  }
}

/// Garson rütbeleri
enum WaiterRank {
  trainee('Stajyer'),
  junior('Garson'),
  senior('Kıdemli Garson'),
  lead('Baş Garson'),
  supervisor('Süpervizör'),
  manager('Müdür');

  const WaiterRank(this.displayName);
  final String displayName;

  String get description {
    switch (this) {
      case WaiterRank.trainee:
        return 'Yeni başlayan, eğitim aşamasındaki personel';
      case WaiterRank.junior:
        return 'Temel hizmet verebilen garson';
      case WaiterRank.senior:
        return 'Deneyimli ve uzman garson';
      case WaiterRank.lead:
        return 'Diğer garsonlara liderlik eden baş garson';
      case WaiterRank.supervisor:
        return 'Operasyonları denetleyen süpervizör';
      case WaiterRank.manager:
        return 'Restoranı yöneten müdür';
    }
  }

  int get level {
    switch (this) {
      case WaiterRank.trainee:
        return 1;
      case WaiterRank.junior:
        return 2;
      case WaiterRank.senior:
        return 3;
      case WaiterRank.lead:
        return 4;
      case WaiterRank.supervisor:
        return 5;
      case WaiterRank.manager:
        return 6;
    }
  }
}

/// Garson durumları
enum WaiterStatus {
  available('Müsait'),
  busy('Meşgul'),
  break_('Molada'),
  offline('Çevrimdışı'),
  sick('Hasta');

  const WaiterStatus(this.displayName);
  final String displayName;

  String get description {
    switch (this) {
      case WaiterStatus.available:
        return 'Yeni sipariş alabilir';
      case WaiterStatus.busy:
        return 'Müşterilerle ilgileniyor';
      case WaiterStatus.break_:
        return 'Mola arası';
      case WaiterStatus.offline:
        return 'Vardiyada değil';
      case WaiterStatus.sick:
        return 'Hastalık izni';
    }
  }
}

/// Vardiya türleri
enum WaiterShift {
  none('Vardiya Yok'),
  morning('Sabah'),
  afternoon('Öğlen'),
  evening('Akşam'),
  night('Gece'),
  split('Bölünmüş');

  const WaiterShift(this.displayName);
  final String displayName;

  String get timeRange {
    switch (this) {
      case WaiterShift.none:
        return '--:--';
      case WaiterShift.morning:
        return '06:00-14:00';
      case WaiterShift.afternoon:
        return '14:00-22:00';
      case WaiterShift.evening:
        return '18:00-02:00';
      case WaiterShift.night:
        return '22:00-06:00';
      case WaiterShift.split:
        return 'Esnek';
    }
  }
}

/// Garson istatistikleri
class WaiterStatistics {
  final int totalOrders;
  final int totalCustomers;
  final double totalRevenue;
  final double averageRating;
  final int totalReviews;
  final int callsReceived;
  final int callsCompleted;
  final double responseTime; // dakika
  final int workingDays;
  final double workingHours;
  final DateTime? lastOrderAt;
  final DateTime? bestDayDate;
  final double bestDayRevenue;

  const WaiterStatistics({
    required this.totalOrders,
    required this.totalCustomers,
    required this.totalRevenue,
    required this.averageRating,
    required this.totalReviews,
    required this.callsReceived,
    required this.callsCompleted,
    required this.responseTime,
    required this.workingDays,
    required this.workingHours,
    this.lastOrderAt,
    this.bestDayDate,
    required this.bestDayRevenue,
  });

  factory WaiterStatistics.initial() {
    return const WaiterStatistics(
      totalOrders: 0,
      totalCustomers: 0,
      totalRevenue: 0.0,
      averageRating: 0.0,
      totalReviews: 0,
      callsReceived: 0,
      callsCompleted: 0,
      responseTime: 0.0,
      workingDays: 0,
      workingHours: 0.0,
      bestDayRevenue: 0.0,
    );
  }

  factory WaiterStatistics.fromMap(Map<String, dynamic> data) {
    return WaiterStatistics(
      totalOrders: data['totalOrders'] ?? 0,
      totalCustomers: data['totalCustomers'] ?? 0,
      totalRevenue: (data['totalRevenue'] ?? 0.0).toDouble(),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      callsReceived: data['callsReceived'] ?? 0,
      callsCompleted: data['callsCompleted'] ?? 0,
      responseTime: (data['responseTime'] ?? 0.0).toDouble(),
      workingDays: data['workingDays'] ?? 0,
      workingHours: (data['workingHours'] ?? 0.0).toDouble(),
      lastOrderAt: data['lastOrderAt'] != null 
          ? (data['lastOrderAt'] as Timestamp).toDate()
          : null,
      bestDayDate: data['bestDayDate'] != null 
          ? (data['bestDayDate'] as Timestamp).toDate()
          : null,
      bestDayRevenue: (data['bestDayRevenue'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalOrders': totalOrders,
      'totalCustomers': totalCustomers,
      'totalRevenue': totalRevenue,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'callsReceived': callsReceived,
      'callsCompleted': callsCompleted,
      'responseTime': responseTime,
      'workingDays': workingDays,
      'workingHours': workingHours,
      'lastOrderAt': lastOrderAt != null ? Timestamp.fromDate(lastOrderAt!) : null,
      'bestDayDate': bestDayDate != null ? Timestamp.fromDate(bestDayDate!) : null,
      'bestDayRevenue': bestDayRevenue,
    };
  }

  /// Yanıt oranı (%)
  double get responseRate {
    if (callsReceived == 0) return 0.0;
    return (callsCompleted / callsReceived) * 100;
  }

  /// Sipariş başına ortalama gelir
  double get averageOrderValue {
    if (totalOrders == 0) return 0.0;
    return totalRevenue / totalOrders;
  }

  /// Performans skoru (0-100)
  double get performanceScore {
    double score = 0.0;
    
    // Rating'e göre puan (40%)
    score += (averageRating / 5.0) * 40;
    
    // Yanıt oranına göre puan (30%)
    score += (responseRate / 100.0) * 30;
    
    // Sipariş sayısına göre puan (20%)
    score += (totalOrders > 50 ? 20 : (totalOrders / 50.0) * 20);
    
    // Müşteri sayısına göre puan (10%)
    score += (totalCustomers > 25 ? 10 : (totalCustomers / 25.0) * 10);
    
    return score.clamp(0.0, 100.0);
  }
} 