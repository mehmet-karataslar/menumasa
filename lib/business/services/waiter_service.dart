import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waiter.dart';
import '../../core/services/notification_service.dart';

/// Garson yönetim servisi
class WaiterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  static const String _collection = 'waiters';

  // ============================================================================
  // CRUD İŞLEMLERİ
  // ============================================================================

  /// Yeni garson ekle
  Future<String> addWaiter(Waiter waiter) async {
    try {
      final docRef = await _firestore.collection(_collection).add(waiter.toFirestore());
      
      // Garson başarıyla eklendi bildirimi gönder
      await _notificationService.sendNotification(
        businessId: waiter.businessId,
        recipientId: waiter.businessId,
        title: 'Yeni Garson Eklendi',
        message: '${waiter.fullName} ekibe katıldı',
        type: NotificationType.system,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Garson eklenirken hata oluştu: $e');
    }
  }

  /// Garson güncelle
  Future<void> updateWaiter(Waiter waiter) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(waiter.waiterId)
          .update(waiter.toFirestore());
    } catch (e) {
      throw Exception('Garson güncellenirken hata oluştu: $e');
    }
  }

  /// Garson sil
  Future<void> deleteWaiter(String waiterId) async {
    try {
      await _firestore.collection(_collection).doc(waiterId).delete();
    } catch (e) {
      throw Exception('Garson silinirken hata oluştu: $e');
    }
  }

  /// Garson durumunu güncelle
  Future<void> updateWaiterStatus(String waiterId, WaiterStatus status) async {
    try {
      await _firestore.collection(_collection).doc(waiterId).update({
        'status': status.toString(),
        'lastActiveAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Garson durumu güncellenirken hata oluştu: $e');
    }
  }

  /// Garson vardiyasını güncelle
  Future<void> updateWaiterShift(String waiterId, WaiterShift shift) async {
    try {
      await _firestore.collection(_collection).doc(waiterId).update({
        'currentShift': shift.toString(),
        'lastActiveAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Garson vardiyası güncellenirken hata oluştu: $e');
    }
  }

  /// Garson masalarını güncelle
  Future<void> updateWaiterTables(String waiterId, List<String> tables) async {
    try {
      await _firestore.collection(_collection).doc(waiterId).update({
        'assignedTables': tables,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Garson masaları güncellenirken hata oluştu: $e');
    }
  }

  // ============================================================================
  // SORGULAR
  // ============================================================================

  /// Tek garson getir
  Future<Waiter?> getWaiter(String waiterId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(waiterId).get();
      
      if (doc.exists) {
        return Waiter.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Garson bilgisi alınırken hata oluştu: $e');
    }
  }

  /// İşletme garsonlarını getir
  Future<List<Waiter>> getWaitersByBusiness(String businessId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .orderBy('rank')
          .orderBy('firstName')
          .get();

      return query.docs.map((doc) => Waiter.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Garsonlar alınırken hata oluştu: $e');
    }
  }

  /// Müsait garsonları getir
  Future<List<Waiter>> getAvailableWaiters(String businessId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: WaiterStatus.available.toString())
          .orderBy('rank')
          .get();

      final waiters = query.docs.map((doc) => Waiter.fromFirestore(doc)).toList();
      
      // Çevrimiçi olanları filtrele
      return waiters.where((waiter) => waiter.isOnline).toList();
    } catch (e) {
      throw Exception('Müsait garsonlar alınırken hata oluştu: $e');
    }
  }

  /// Vardiyada olan garsonları getir
  Future<List<Waiter>> getOnShiftWaiters(String businessId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .get();

      final waiters = query.docs.map((doc) => Waiter.fromFirestore(doc)).toList();
      
      // Vardiyada olanları filtrele
      return waiters.where((waiter) => waiter.isOnShift).toList();
    } catch (e) {
      throw Exception('Vardiyada olan garsonlar alınırken hata oluştu: $e');
    }
  }

  /// Rütbeye göre garsonları getir
  Future<List<Waiter>> getWaitersByRank(String businessId, WaiterRank rank) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .where('rank', isEqualTo: rank.toString())
          .orderBy('firstName')
          .get();

      return query.docs.map((doc) => Waiter.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Rütbeye göre garsonlar alınırken hata oluştu: $e');
    }
  }

  /// Masa sorumlusu garson bul
  Future<Waiter?> getTableWaiter(String businessId, String tableNumber) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('isActive', isEqualTo: true)
          .where('assignedTables', arrayContains: tableNumber)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Waiter.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Masa sorumlusu garson bulunurken hata oluştu: $e');
    }
  }

  // ============================================================================
  // STREAMLERİ
  // ============================================================================

  /// İşletme garsonları stream'i
  Stream<List<Waiter>> getWaitersStream(String businessId) {
    return _firestore
        .collection(_collection)
        .where('businessId', isEqualTo: businessId)
        .where('isActive', isEqualTo: true)
        .orderBy('rank')
        .orderBy('firstName')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Waiter.fromFirestore(doc)).toList()
        );
  }

  /// Müsait garsonlar stream'i
  Stream<List<Waiter>> getAvailableWaitersStream(String businessId) {
    return _firestore
        .collection(_collection)
        .where('businessId', isEqualTo: businessId)
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: WaiterStatus.available.toString())
        .snapshots()
        .map((snapshot) {
          final waiters = snapshot.docs.map((doc) => Waiter.fromFirestore(doc)).toList();
          return waiters.where((waiter) => waiter.isOnline).toList();
        });
  }

  // ============================================================================
  // İSTATİSTİKLER
  // ============================================================================

  /// İşletme garson istatistikleri
  Future<Map<String, dynamic>> getBusinessWaiterStats(String businessId) async {
    try {
      final waiters = await getWaitersByBusiness(businessId);
      
      int totalWaiters = waiters.length;
      int availableWaiters = waiters.where((w) => w.isAvailable).length;
      int onShiftWaiters = waiters.where((w) => w.isOnShift).length;
      int onlineWaiters = waiters.where((w) => w.isOnline).length;
      
      Map<WaiterRank, int> rankDistribution = {};
      Map<WaiterStatus, int> statusDistribution = {};
      
      for (final waiter in waiters) {
        rankDistribution[waiter.rank] = (rankDistribution[waiter.rank] ?? 0) + 1;
        statusDistribution[waiter.status] = (statusDistribution[waiter.status] ?? 0) + 1;
      }
      
      double averagePerformance = waiters.isEmpty ? 0.0 :
          waiters.map((w) => w.statistics.performanceScore).reduce((a, b) => a + b) / waiters.length;
      
      return {
        'totalWaiters': totalWaiters,
        'availableWaiters': availableWaiters,
        'onShiftWaiters': onShiftWaiters,
        'onlineWaiters': onlineWaiters,
        'rankDistribution': rankDistribution.map((k, v) => MapEntry(k.toString(), v)),
        'statusDistribution': statusDistribution.map((k, v) => MapEntry(k.toString(), v)),
        'averagePerformance': averagePerformance,
        'utilizationRate': totalWaiters > 0 ? (onShiftWaiters / totalWaiters) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Garson istatistikleri alınırken hata oluştu: $e');
    }
  }

  /// En iyi performans gösteren garsonlar
  Future<List<Waiter>> getTopPerformingWaiters(String businessId, {int limit = 5}) async {
    try {
      final waiters = await getWaitersByBusiness(businessId);
      
      // Performans skoruna göre sırala
      waiters.sort((a, b) => b.statistics.performanceScore.compareTo(a.statistics.performanceScore));
      
      return waiters.take(limit).toList();
    } catch (e) {
      throw Exception('En iyi garsonlar alınırken hata oluştu: $e');
    }
  }

  // ============================================================================
  // GARSON ÇAĞIRMA ENTEGRASYONALİ
  // ============================================================================

  /// Garson çağrısı aldı - istatistikleri güncelle
  Future<void> waiterReceivedCall(String waiterId) async {
    try {
      await _firestore.collection(_collection).doc(waiterId).update({
        'statistics.callsReceived': FieldValue.increment(1),
        'lastActiveAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Garson çağrı istatistiği güncellenirken hata oluştu: $e');
    }
  }

  /// Garson çağrıyı tamamladı - istatistikleri güncelle  
  Future<void> waiterCompletedCall(String waiterId, double responseTimeMinutes) async {
    try {
      final waiterDoc = await _firestore.collection(_collection).doc(waiterId).get();
      
      if (waiterDoc.exists) {
        final waiter = Waiter.fromFirestore(waiterDoc);
        final stats = waiter.statistics;
        
        // Yeni ortalama yanıt süresi hesapla
        final newCallsCompleted = stats.callsCompleted + 1;
        final newAverageResponseTime = 
            ((stats.responseTime * stats.callsCompleted) + responseTimeMinutes) / newCallsCompleted;
        
        await _firestore.collection(_collection).doc(waiterId).update({
          'statistics.callsCompleted': FieldValue.increment(1),
          'statistics.responseTime': newAverageResponseTime,
          'lastActiveAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Garson çağrı tamamlama istatistiği güncellenirken hata oluştu: $e');
    }
  }

  /// Garson aktiflik durumunu güncelle (ping)
  Future<void> updateWaiterActivity(String waiterId) async {
    try {
      await _firestore.collection(_collection).doc(waiterId).update({
        'lastActiveAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      // Hata logla ama exception fırlatma (ping operasyonu)
      print('Garson aktiflik güncellenirken hata: $e');
    }
  }

  // ============================================================================
  // BULK OPERASYONLARİ
  // ============================================================================

  /// Toplu durum güncelleme
  Future<void> bulkUpdateWaiterStatus(List<String> waiterIds, WaiterStatus status) async {
    try {
      final batch = _firestore.batch();
      
      for (final waiterId in waiterIds) {
        final docRef = _firestore.collection(_collection).doc(waiterId);
        batch.update(docRef, {
          'status': status.toString(),
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
  Future<void> bulkUpdateWaiterShift(List<String> waiterIds, WaiterShift shift) async {
    try {
      final batch = _firestore.batch();
      
      for (final waiterId in waiterIds) {
        final docRef = _firestore.collection(_collection).doc(waiterId);
        batch.update(docRef, {
          'currentShift': shift.toString(),
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