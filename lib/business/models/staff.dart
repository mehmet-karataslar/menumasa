import 'package:cloud_firestore/cloud_firestore.dart';

/// Personel modeli - işletmedeki tüm personelin bilgilerini içerir
class Staff {
  final String staffId;
  final String businessId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final StaffRole role;
  final StaffStatus status;
  final String? currentSection; // Hangi bölümde çalışıyor
  final List<String> assignedTables; // Sorumlu olduğu masalar (sadece garsonlar için)
  final StaffShift currentShift;
  final Map<String, dynamic> workingHours; // Çalışma saatleri
  final StaffStatistics statistics;
  final List<String> languages; // Konuşabildiği diller
  final List<StaffPermission> permissions; // Rol bazlı yetkiler
  final DateTime hireDate;
  final DateTime? lastActiveAt;
  final String notes; // Personel hakkında notlar
  final bool isActive;
  final String passwordHash;
  final String passwordSalt;
  final DateTime? lastPasswordChange;
  final bool requirePasswordChange;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Staff({
    required this.staffId,
    required this.businessId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    required this.role,
    required this.status,
    this.currentSection,
    required this.assignedTables,
    required this.currentShift,
    required this.workingHours,
    required this.statistics,
    required this.languages,
    required this.permissions,
    required this.hireDate,
    this.lastActiveAt,
    required this.notes,
    required this.isActive,
    required this.passwordHash,
    required this.passwordSalt,
    this.lastPasswordChange,
    required this.requirePasswordChange,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Yeni personel oluştur
  factory Staff.create({
    required String businessId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String? profileImageUrl,
    StaffRole? role,
    StaffStatus? status,
    StaffShift? currentShift,
    String? currentSection,
    List<String>? assignedTables,
    Map<String, dynamic>? workingHours,
    List<String>? languages,
    String? notes,
    DateTime? hireDate,
  }) {
    final now = DateTime.now();
    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);
    final staffRole = role ?? StaffRole.waiter;
    
    return Staff(
      staffId: now.millisecondsSinceEpoch.toString(),
      businessId: businessId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      profileImageUrl: profileImageUrl,
      role: staffRole,
      status: status ?? StaffStatus.available,
      currentSection: currentSection,
      assignedTables: assignedTables ?? [],
      currentShift: currentShift ?? StaffShift.none,
      workingHours: workingHours ?? _getDefaultWorkingHours(),
      statistics: StaffStatistics.initial(),
      languages: languages ?? ['tr'],
      permissions: _getDefaultPermissions(staffRole),
      hireDate: hireDate ?? now,
      lastActiveAt: now,
      notes: notes ?? '',
      isActive: true,
      passwordHash: passwordHash,
      passwordSalt: salt,
      lastPasswordChange: now,
      requirePasswordChange: true, // İlk girişte şifre değiştirme zorunlu
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Firestore'dan oluştur
  factory Staff.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Staff(
      staffId: doc.id,
      businessId: data['businessId'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      role: StaffRole.values.firstWhere(
        (role) => role.value == data['role'],
        orElse: () => StaffRole.waiter,
      ),
      status: StaffStatus.values.firstWhere(
        (status) => status.value == data['status'],
        orElse: () => StaffStatus.available,
      ),
      currentSection: data['currentSection'],
      assignedTables: List<String>.from(data['assignedTables'] ?? []),
      currentShift: StaffShift.values.firstWhere(
        (shift) => shift.value == data['currentShift'],
        orElse: () => StaffShift.none,
      ),
      workingHours: Map<String, dynamic>.from(data['workingHours'] ?? {}),
      statistics: StaffStatistics.fromMap(data['statistics'] ?? {}),
      languages: List<String>.from(data['languages'] ?? ['tr']),
      permissions: (data['permissions'] as List<dynamic>? ?? [])
          .map((perm) => StaffPermission.values.firstWhere(
                (p) => p.value == perm,
                orElse: () => StaffPermission.viewOrders,
              ))
          .toList(),
      hireDate: (data['hireDate'] as Timestamp).toDate(),
      lastActiveAt: data['lastActiveAt'] != null 
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'] ?? '',
      isActive: data['isActive'] ?? true,
      passwordHash: data['passwordHash'] ?? '',
      passwordSalt: data['passwordSalt'] ?? '',
      lastPasswordChange: data['lastPasswordChange'] != null
          ? (data['lastPasswordChange'] as Timestamp).toDate()
          : null,
      requirePasswordChange: data['requirePasswordChange'] ?? false,
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
      'role': role.value,
      'status': status.value,
      'currentSection': currentSection,
      'assignedTables': assignedTables,
      'currentShift': currentShift.value,
      'workingHours': workingHours,
      'statistics': statistics.toMap(),
      'languages': languages,
      'permissions': permissions.map((p) => p.value).toList(),
      'hireDate': Timestamp.fromDate(hireDate),
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'notes': notes,
      'isActive': isActive,
      'passwordHash': passwordHash,
      'passwordSalt': passwordSalt,
      'lastPasswordChange': lastPasswordChange != null ? Timestamp.fromDate(lastPasswordChange!) : null,
      'requirePasswordChange': requirePasswordChange,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Şifre doğrulama
  bool verifyPassword(String password) {
    final hashedPassword = _hashPassword(password, passwordSalt);
    return hashedPassword == passwordHash;
  }

  /// Şifre güncelleme
  Staff updatePassword(String newPassword) {
    final salt = _generateSalt();
    final hashedPassword = _hashPassword(newPassword, salt);
    
    return copyWith(
      passwordHash: hashedPassword,
      passwordSalt: salt,
      lastPasswordChange: DateTime.now(),
      requirePasswordChange: false,
    );
  }

  /// Kopya oluştur
  Staff copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profileImageUrl,
    StaffRole? role,
    StaffStatus? status,
    String? currentSection,
    List<String>? assignedTables,
    StaffShift? currentShift,
    Map<String, dynamic>? workingHours,
    StaffStatistics? statistics,
    List<String>? languages,
    List<StaffPermission>? permissions,
    DateTime? hireDate,
    DateTime? lastActiveAt,
    String? notes,
    bool? isActive,
    String? passwordHash,
    String? passwordSalt,
    DateTime? lastPasswordChange,
    bool? requirePasswordChange,
  }) {
    return Staff(
      staffId: staffId,
      businessId: businessId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      currentSection: currentSection ?? this.currentSection,
      assignedTables: assignedTables ?? this.assignedTables,
      currentShift: currentShift ?? this.currentShift,
      workingHours: workingHours ?? this.workingHours,
      statistics: statistics ?? this.statistics,
      languages: languages ?? this.languages,
      permissions: permissions ?? this.permissions,
      hireDate: hireDate ?? this.hireDate,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      requirePasswordChange: requirePasswordChange ?? this.requirePasswordChange,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Yetkisi var mı kontrolü
  bool hasPermission(StaffPermission permission) {
    return permissions.contains(permission);
  }

  /// Tam ad
  String get fullName => '$firstName $lastName';

  /// Profil inisiyalleri
  String get initials => '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}';

  /// Müsait mi?
  bool get isAvailable {
    return isActive && 
           status == StaffStatus.available && 
           currentShift != StaffShift.none;
  }

  /// Şifre yardımcı metotları
  static String _generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random;
  }

  static String _hashPassword(String password, String salt) {
    return (password + salt).hashCode.toString();
  }

  /// Varsayılan izinler
  static List<StaffPermission> _getDefaultPermissions(StaffRole role) {
    switch (role) {
      case StaffRole.manager:
        return StaffPermission.values; // Tüm yetkiler
      case StaffRole.waiter:
        return [
          StaffPermission.viewOrders,
          StaffPermission.createOrders,
          StaffPermission.updateOrderStatus,
          StaffPermission.callWaiter,
          StaffPermission.viewMenu,
        ];
      case StaffRole.kitchen:
        return [
          StaffPermission.viewOrders,
          StaffPermission.receiveOrders,
          StaffPermission.updateOrderStatus,
          StaffPermission.respondToCalls,
          StaffPermission.viewMenu,
        ];
      case StaffRole.cashier:
        return [
          StaffPermission.viewOrders,
          StaffPermission.createOrders,
          StaffPermission.updateOrderStatus,
          StaffPermission.processPayments,
          StaffPermission.viewMenu,
        ];
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
    return 'Staff(id: $staffId, name: $fullName, role: ${role.displayName}, status: ${status.displayName})';
  }
}

/// Personel rolleri
enum StaffRole {
  manager('manager', 'Müdür', 'Tam yetki - tüm işlemleri yapabilir'),
  waiter('waiter', 'Garson', 'Sipariş verme, takip etme, garson çağırma'),
  kitchen('kitchen', 'Mutfak Personeli', 'Sipariş alma, oluşturma, iletme, takip'),
  cashier('cashier', 'Kasiyer', 'Sipariş ve ödeme işlemleri');

  const StaffRole(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;

  static StaffRole fromString(String value) {
    return StaffRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => StaffRole.waiter,
    );
  }
}

/// Personel durumları
enum StaffStatus {
  available('available', 'Müsait'),
  busy('busy', 'Meşgul'),
  break_('break', 'Molada'),
  offline('offline', 'Çevrimdışı');

  const StaffStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static StaffStatus fromString(String value) {
    return StaffStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StaffStatus.available,
    );
  }
}

/// Vardiya türleri
enum StaffShift {
  none('none', 'Vardiya Yok'),
  morning('morning', 'Sabah'),
  afternoon('afternoon', 'Öğlen'),
  evening('evening', 'Akşam'),
  night('night', 'Gece');

  const StaffShift(this.value, this.displayName);

  final String value;
  final String displayName;

  static StaffShift fromString(String value) {
    return StaffShift.values.firstWhere(
      (shift) => shift.value == value,
      orElse: () => StaffShift.none,
    );
  }
}

/// Personel yetkileri
enum StaffPermission {
  // Sipariş işlemleri
  viewOrders('view_orders', 'Siparişleri Görüntüle'),
  createOrders('create_orders', 'Sipariş Oluştur'),
  updateOrderStatus('update_order_status', 'Sipariş Durumu Güncelle'),
  receiveOrders('receive_orders', 'Sipariş Al'),
  
  // Menü işlemleri
  viewMenu('view_menu', 'Menüyü Görüntüle'),
  
  // Garson işlemleri
  callWaiter('call_waiter', 'Garson Çağır'),
  respondToCalls('respond_to_calls', 'Çağrılara Cevap Ver'),
  
  // Ödeme işlemleri
  processPayments('process_payments', 'Ödeme İşlemleri'),
  
  // Yönetici işlemleri
  manageStaff('manage_staff', 'Personel Yönetimi'),
  viewAnalytics('view_analytics', 'Analitikleri Görüntüle'),
  manageSettings('manage_settings', 'Ayarları Yönet');

  const StaffPermission(this.value, this.displayName);

  final String value;
  final String displayName;

  static StaffPermission fromString(String value) {
    return StaffPermission.values.firstWhere(
      (perm) => perm.value == value,
      orElse: () => StaffPermission.viewOrders,
    );
  }
}

/// Personel istatistikleri
class StaffStatistics {
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

  const StaffStatistics({
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
  });

  factory StaffStatistics.initial() {
    return const StaffStatistics(
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
    );
  }

  factory StaffStatistics.fromMap(Map<String, dynamic> data) {
    return StaffStatistics(
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
} 