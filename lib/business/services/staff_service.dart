import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/staff.dart';
import '../../core/services/notification_service.dart';

/// Personel yönetim servisi
class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  static const String _collection = 'staff';

  // ============================================================================
  // CRUD İŞLEMLERİ
  // ============================================================================

  /// Yeni personel ekle
  Future<String> addStaff(Staff staff) async {
    try {
      final docRef = await _firestore.collection(_collection).add(staff.toFirestore());
      
      // Personel başarıyla eklendi bildirimi gönder
      await _notificationService.sendNotification(
        businessId: staff.businessId,
        recipientId: staff.businessId,
        title: 'Yeni Personel Eklendi',
        message: '${staff.fullName} (${staff.role.displayName}) ekibe katıldı',
        type: NotificationType.system,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Personel eklenirken hata oluştu: $e');
    }
  }

  /// Personel güncelle
  Future<void> updateStaff(Staff staff) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(staff.staffId)
          .update(staff.toFirestore());
    } catch (e) {
      throw Exception('Personel güncellenirken hata oluştu: $e');
    }
  }

  /// Personel sil (soft delete)
  Future<void> deleteStaff(String staffId) async {
    try {
      await _firestore.collection(_collection).doc(staffId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Personel silinirken hata oluştu: $e');
    }
  }

  /// Personel durumunu güncelle
  Future<void> updateStaffStatus(String staffId, StaffStatus status) async {
    try {
      await _firestore.collection(_collection).doc(staffId).update({
        'status': status.value,
        'lastActiveAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Personel durumu güncellenirken hata oluştu: $e');
    }
  }

  /// Personel vardiyasını güncelle
  Future<void> updateStaffShift(String staffId, StaffShift shift) async {
    try {
      await _firestore.collection(_collection).doc(staffId).update({
        'currentShift': shift.value,
        'lastActiveAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Personel vardiyası güncellenirken hata oluştu: $e');
    }
  }

  /// Personel şifresini güncelle
  Future<void> updateStaffPassword(String staffId, String newPassword) async {
    try {
      final staffDoc = await _firestore.collection(_collection).doc(staffId).get();
      if (!staffDoc.exists) {
        throw Exception('Personel bulunamadı');
      }

      final staff = Staff.fromFirestore(staffDoc);
      final updatedStaff = staff.updatePassword(newPassword);

      await _firestore.collection(_collection).doc(staffId).update({
        'passwordHash': updatedStaff.passwordHash,
        'passwordSalt': updatedStaff.passwordSalt,
        'lastPasswordChange': Timestamp.fromDate(updatedStaff.lastPasswordChange!),
        'requirePasswordChange': updatedStaff.requirePasswordChange,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Personel şifresi güncellenirken hata oluştu: $e');
    }
  }

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// E-mail ile personel girişi
  Future<Staff?> authenticateStaff(String email, String password) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null; // Personel bulunamadı
      }

      final staff = Staff.fromFirestore(query.docs.first);
      
      // Şifre kontrolü
      if (staff.verifyPassword(password)) {
        // Son aktiflik zamanını güncelle
        await updateStaffActivity(staff.staffId);
        return staff;
      }

      return null; // Şifre yanlış
    } catch (e) {
      throw Exception('Personel girişi yapılırken hata oluştu: $e');
    }
  }

  /// Personel e-mail ile kontrol
  Future<Staff?> getStaffByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return Staff.fromFirestore(query.docs.first);
    } catch (e) {
      throw Exception('Personel email ile aranırken hata oluştu: $e');
    }
  }

  // ============================================================================
  // SORGULAR
  // ============================================================================

  /// Tek personel getir
  Future<Staff?> getStaff(String staffId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(staffId).get();
      
      if (doc.exists) {
        return Staff.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Personel bilgisi alınırken hata oluştu: $e');
    }
  }

  /// İşletme personellerini getir
  Future<List<Staff>> getStaffByBusiness(String businessId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .get();

      final staffList = query.docs
          .map((doc) => Staff.fromFirestore(doc))
          .toList();

      // Sıralama: Rol sonra isim
      staffList.sort((a, b) {
        final roleComparison = _getRoleOrder(a.role).compareTo(_getRoleOrder(b.role));
        if (roleComparison != 0) return roleComparison;
        return a.firstName.compareTo(b.firstName);
      });

      return staffList;
    } catch (e) {
      throw Exception('Personeller alınırken hata oluştu: $e');
    }
  }

  /// Role göre personelleri getir
  Future<List<Staff>> getStaffByRole(String businessId, StaffRole role) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('role', isEqualTo: role.value)
          .where('isActive', isEqualTo: true)
          .get();

      final staffList = query.docs
          .map((doc) => Staff.fromFirestore(doc))
          .toList();
      
      staffList.sort((a, b) => a.firstName.compareTo(b.firstName));
      
      return staffList;
    } catch (e) {
      throw Exception('Role göre personeller alınırken hata oluştu: $e');
    }
  }

  /// Müsait personelleri getir
  Future<List<Staff>> getAvailableStaff(String businessId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: StaffStatus.available.value)
          .get();

      final staffList = query.docs
          .map((doc) => Staff.fromFirestore(doc))
          .where((staff) => staff.isAvailable)
          .toList();
      
      return staffList;
    } catch (e) {
      throw Exception('Müsait personeller alınırken hata oluştu: $e');
    }
  }

  /// Garsonları getir (masa sorumluluğu için)
  Future<List<Staff>> getWaiters(String businessId) async {
    return await getStaffByRole(businessId, StaffRole.waiter);
  }

  /// Mutfak personelini getir
  Future<List<Staff>> getKitchenStaff(String businessId) async {
    return await getStaffByRole(businessId, StaffRole.kitchen);
  }

  /// Müdürleri getir
  Future<List<Staff>> getManagers(String businessId) async {
    return await getStaffByRole(businessId, StaffRole.manager);
  }

  // ============================================================================
  // STREAMLERİ
  // ============================================================================

  /// İşletme personelleri stream'i
  Stream<List<Staff>> getStaffStream(String businessId) {
    return _firestore
        .collection(_collection)
        .where('businessId', isEqualTo: businessId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final staffList = snapshot.docs
              .map((doc) => Staff.fromFirestore(doc))
              .toList();
          
          // Sıralama: Rol sonra isim
          staffList.sort((a, b) {
            final roleComparison = _getRoleOrder(a.role).compareTo(_getRoleOrder(b.role));
            if (roleComparison != 0) return roleComparison;
            return a.firstName.compareTo(b.firstName);
          });
          
          return staffList;
        });
  }

  /// Müsait personeller stream'i
  Stream<List<Staff>> getAvailableStaffStream(String businessId) {
    return _firestore
        .collection(_collection)
        .where('businessId', isEqualTo: businessId)
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: StaffStatus.available.value)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Staff.fromFirestore(doc))
              .where((staff) => staff.isAvailable)
              .toList();
        });
  }

  // ============================================================================
  // YETKİ KONTROLLARI
  // ============================================================================

  /// Personel yetkisi kontrol et
  bool hasPermission(Staff staff, StaffPermission permission) {
    return staff.hasPermission(permission);
  }

  /// Personelin işlemi yapma yetkisi var mı
  Future<bool> canPerformAction(String staffId, StaffPermission permission) async {
    try {
      final staff = await getStaff(staffId);
      if (staff == null) return false;
      
      return staff.hasPermission(permission);
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // GARSON ÇAĞIRMA SİSTEMİ
  // ============================================================================

  /// Garson çağrısı aldı
  Future<void> staffReceivedCall(String staffId) async {
    try {
      await _firestore.collection(_collection).doc(staffId).update({
        'statistics.callsReceived': FieldValue.increment(1),
        'lastActiveAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Personel çağrı istatistiği güncellenirken hata oluştu: $e');
    }
  }

  /// Garson çağrıyı tamamladı
  Future<void> staffCompletedCall(String staffId, double responseTimeMinutes) async {
    try {
      final staffDoc = await _firestore.collection(_collection).doc(staffId).get();
      
      if (staffDoc.exists) {
        final staff = Staff.fromFirestore(staffDoc);
        final stats = staff.statistics;
        
        // Yeni ortalama yanıt süresi hesapla
        final newCallsCompleted = stats.callsCompleted + 1;
        final newAverageResponseTime = 
            ((stats.responseTime * stats.callsCompleted) + responseTimeMinutes) / newCallsCompleted;
        
        await _firestore.collection(_collection).doc(staffId).update({
          'statistics.callsCompleted': FieldValue.increment(1),
          'statistics.responseTime': newAverageResponseTime,
          'lastActiveAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Personel çağrı tamamlama istatistiği güncellenirken hata oluştu: $e');
    }
  }

  /// Personel aktiflik durumunu güncelle
  Future<void> updateStaffActivity(String staffId) async {
    try {
      await _firestore.collection(_collection).doc(staffId).update({
        'lastActiveAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      // Hata logla ama exception fırlatma (ping operasyonu)
      print('Personel aktiflik güncellenirken hata: $e');
    }
  }

  // ============================================================================
  // İSTATİSTİKLER
  // ============================================================================

  /// İşletme personel istatistikleri
  Future<Map<String, dynamic>> getBusinessStaffStats(String businessId) async {
    try {
      final staffList = await getStaffByBusiness(businessId);
      
      int totalStaff = staffList.length;
      int availableStaff = staffList.where((s) => s.isAvailable).length;
      int onShiftStaff = staffList.where((s) => s.currentShift != StaffShift.none).length;
      
      Map<StaffRole, int> roleDistribution = {};
      Map<StaffStatus, int> statusDistribution = {};
      
      for (final staff in staffList) {
        roleDistribution[staff.role] = (roleDistribution[staff.role] ?? 0) + 1;
        statusDistribution[staff.status] = (statusDistribution[staff.status] ?? 0) + 1;
      }
      
      return {
        'totalStaff': totalStaff,
        'availableStaff': availableStaff,
        'onShiftStaff': onShiftStaff,
        'managers': roleDistribution[StaffRole.manager] ?? 0,
        'waiters': roleDistribution[StaffRole.waiter] ?? 0,
        'kitchenStaff': roleDistribution[StaffRole.kitchen] ?? 0,
        'cashiers': roleDistribution[StaffRole.cashier] ?? 0,
        'roleDistribution': roleDistribution.map((k, v) => MapEntry(k.value, v)),
        'statusDistribution': statusDistribution.map((k, v) => MapEntry(k.value, v)),
        'utilizationRate': totalStaff > 0 ? (onShiftStaff / totalStaff) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Personel istatistikleri alınırken hata oluştu: $e');
    }
  }

  // ============================================================================
  // YARDIMCI METODLAR
  // ============================================================================

  /// Rol sıralaması için order belirle
  int _getRoleOrder(StaffRole role) {
    switch (role) {
      case StaffRole.manager:
        return 1;
      case StaffRole.cashier:
        return 2;
      case StaffRole.kitchen:
        return 3;
      case StaffRole.waiter:
        return 4;
    }
  }

  /// Toplu durum güncelleme
  Future<void> bulkUpdateStaffStatus(List<String> staffIds, StaffStatus status) async {
    try {
      final batch = _firestore.batch();
      
      for (final staffId in staffIds) {
        final docRef = _firestore.collection(_collection).doc(staffId);
        batch.update(docRef, {
          'status': status.value,
          'lastActiveAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Toplu durum güncelleme yapılırken hata oluştu: $e');
    }
  }

  /// Toplu vardiya güncelleme
  Future<void> bulkUpdateStaffShift(List<String> staffIds, StaffShift shift) async {
    try {
      final batch = _firestore.batch();
      
      for (final staffId in staffIds) {
        final docRef = _firestore.collection(_collection).doc(staffId);
        batch.update(docRef, {
          'currentShift': shift.value,
          'lastActiveAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Toplu vardiya güncelleme yapılırken hata oluştu: $e');
    }
  }
} 