import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waiter_call.dart';
import '../models/staff.dart';
import '../services/staff_service.dart';
import '../../core/services/notification_service.dart';

/// Garson çağırma yönetim servisi
class WaiterCallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final StaffService _staffService = StaffService();

  static const String _collection = 'waiter_calls';

  // ============================================================================
  // CRUD İŞLEMLERİ
  // ============================================================================

  /// Yeni garson çağırma kaydı oluştur
  Future<String> createWaiterCall(WaiterCall waiterCall) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(waiterCall.toFirestore());

      // Belirli garsona bildirim gönder
      await _sendWaiterNotification(waiterCall);

      // Staff istatistiklerini güncelle
      await _staffService.staffReceivedCall(waiterCall.waiterId);

      return docRef.id;
    } catch (e) {
      throw Exception('Garson çağırma kaydı oluşturulurken hata oluştu: $e');
    }
  }

  /// Garson çağrısını güncelle
  Future<void> updateWaiterCall(WaiterCall waiterCall) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(waiterCall.callId)
          .update(waiterCall.toFirestore());

      // Eğer çağrı tamamlandıysa, staff istatistiklerini güncelle
      if (waiterCall.status == WaiterCallStatus.completed &&
          waiterCall.responseTimeMinutes != null) {
        await _staffService.staffCompletedCall(
          waiterCall.waiterId,
          waiterCall.responseTimeMinutes!,
        );
      }
    } catch (e) {
      throw Exception('Garson çağırma kaydı güncellenirken hata oluştu: $e');
    }
  }

  /// Garson çağrısını sil
  Future<void> deleteWaiterCall(String callId) async {
    try {
      await _firestore.collection(_collection).doc(callId).delete();
    } catch (e) {
      throw Exception('Garson çağırma kaydı silinirken hata oluştu: $e');
    }
  }

  // ============================================================================
  // SORGULAR
  // ============================================================================

  /// Tek garson çağrısını getir
  Future<WaiterCall?> getWaiterCall(String callId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(callId).get();

      if (doc.exists) {
        return WaiterCall.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Garson çağırma kaydı alınırken hata oluştu: $e');
    }
  }

  /// İşletmenin tüm garson çağrılarını getir
  Future<List<WaiterCall>> getWaiterCallsByBusiness(String businessId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => WaiterCall.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('İşletme garson çağrıları alınırken hata oluştu: $e');
    }
  }

  /// İşletme aktif garson çağrılarını getir
  Future<List<WaiterCall>> getActiveWaiterCallsByBusiness(
      String businessId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('status', whereIn: ['pending', 'responded'])
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => WaiterCall.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception(
          'İşletme aktif garson çağrıları alınırken hata oluştu: $e');
    }
  }

  /// Belirli garsonun çağrılarını getir
  Future<List<WaiterCall>> getWaiterCallsByWaiterId(String waiterId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('waiterId', isEqualTo: waiterId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => WaiterCall.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Garson çağrıları alınırken hata oluştu: $e');
    }
  }

  /// Aktif garson çağrılarını getir
  Future<List<WaiterCall>> getActiveWaiterCalls(String businessId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('status', whereIn: ['pending', 'responded'])
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => WaiterCall.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Aktif garson çağrıları alınırken hata oluştu: $e');
    }
  }

  /// Belirli garsonun aktif çağrılarını getir
  Future<List<WaiterCall>> getActiveCallsForWaiter(String waiterId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('waiterId', isEqualTo: waiterId)
          .where('status', whereIn: ['pending', 'responded'])
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => WaiterCall.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Garsonun aktif çağrıları alınırken hata oluştu: $e');
    }
  }

  // ============================================================================
  // STREAMLERİ
  // ============================================================================

  /// İşletme garson çağrıları stream'i
  Stream<List<WaiterCall>> getWaiterCallsStream(String businessId) {
    return _firestore
        .collection(_collection)
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => WaiterCall.fromFirestore(doc)).toList();
    });
  }

  /// Belirli garsonun çağrıları stream'i
  Stream<List<WaiterCall>> getWaiterCallsStreamForWaiter(String waiterId) {
    return _firestore
        .collection(_collection)
        .where('waiterId', isEqualTo: waiterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => WaiterCall.fromFirestore(doc)).toList();
    });
  }

  /// Aktif çağrılar stream'i (belirli garson için)
  Stream<List<WaiterCall>> getActiveCallsStreamForWaiter(String waiterId) {
    return _firestore
        .collection(_collection)
        .where('waiterId', isEqualTo: waiterId)
        .where('status', whereIn: ['pending', 'responded'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WaiterCall.fromFirestore(doc))
              .toList();
        });
  }

  // ============================================================================
  // ÇAĞRI YÖNETİMİ
  // ============================================================================

  /// Müşteri tarafından garson çağır
  Future<String> callWaiter({
    required String businessId,
    required String customerId,
    required String customerName,
    required String waiterId,
    required String waiterName,
    required String tableNumber,
    String? floorNumber,
    String? message,
  }) async {
    final waiterCall = WaiterCall.create(
      businessId: businessId,
      customerId: customerId,
      customerName: customerName,
      waiterId: waiterId,
      waiterName: waiterName,
      tableNumber: tableNumber,
      floorNumber: floorNumber,
      message: message,
    );

    return await createWaiterCall(waiterCall);
  }

  /// Garson çağrıyı kabul et
  Future<void> respondToCall(String callId) async {
    try {
      final call = await getWaiterCall(callId);
      if (call == null) {
        throw Exception('Çağrı bulunamadı');
      }

      final respondedCall = call.markAsResponded();
      await updateWaiterCall(respondedCall);

      // Müşteriye bildirim gönder
      await _notificationService.sendNotification(
        businessId: call.businessId,
        recipientId: call.customerId,
        title: 'Garson Geliyor! 👨‍🍳',
        message: '${call.waiterName} çağrınızı kabul etti ve geliyor.',
        type: NotificationType.orderUpdate,
        data: {
          'callId': callId,
          'waiterId': call.waiterId,
          'waiterName': call.waiterName,
          'tableNumber': call.tableNumber,
        },
      );
    } catch (e) {
      throw Exception('Çağrı kabul edilirken hata oluştu: $e');
    }
  }

  /// Garson çağrıyı tamamla
  Future<void> completeCall(String callId) async {
    try {
      final call = await getWaiterCall(callId);
      if (call == null) {
        throw Exception('Çağrı bulunamadı');
      }

      final completedCall = call.markAsCompleted();
      await updateWaiterCall(completedCall);

      // Müşteriye bildirim gönder
      await _notificationService.sendNotification(
        businessId: call.businessId,
        recipientId: call.customerId,
        title: 'Hizmet Tamamlandı ✅',
        message: '${call.waiterName} hizmetinizi tamamladı.',
        type: NotificationType.orderUpdate,
        data: {
          'callId': callId,
          'waiterId': call.waiterId,
          'waiterName': call.waiterName,
          'tableNumber': call.tableNumber,
        },
      );
    } catch (e) {
      throw Exception('Çağrı tamamlanırken hata oluştu: $e');
    }
  }

  /// Çağrıyı iptal et
  Future<void> cancelCall(String callId) async {
    try {
      final call = await getWaiterCall(callId);
      if (call == null) {
        throw Exception('Çağrı bulunamadı');
      }

      final cancelledCall = call.markAsCancelled();
      await updateWaiterCall(cancelledCall);
    } catch (e) {
      throw Exception('Çağrı iptal edilirken hata oluştu: $e');
    }
  }

  // ============================================================================
  // İSTATİSTİKLER
  // ============================================================================

  /// İşletme çağrı istatistikleri
  Future<Map<String, dynamic>> getBusinessCallStats(String businessId) async {
    try {
      final calls = await getWaiterCallsByBusiness(businessId);

      final today = DateTime.now();
      final todayCalls = calls.where((call) {
        return call.createdAt.year == today.year &&
            call.createdAt.month == today.month &&
            call.createdAt.day == today.day;
      }).toList();

      int totalCalls = todayCalls.length;
      int pendingCalls =
          todayCalls.where((c) => c.status == WaiterCallStatus.pending).length;
      int respondedCalls = todayCalls
          .where((c) => c.status == WaiterCallStatus.responded)
          .length;
      int completedCalls = todayCalls
          .where((c) => c.status == WaiterCallStatus.completed)
          .length;

      double averageResponseTime = 0.0;
      final respondedCallsWithTime =
          todayCalls.where((c) => c.responseTimeMinutes != null).toList();

      if (respondedCallsWithTime.isNotEmpty) {
        averageResponseTime = respondedCallsWithTime
                .map((c) => c.responseTimeMinutes!)
                .reduce((a, b) => a + b) /
            respondedCallsWithTime.length;
      }

      return {
        'totalCalls': totalCalls,
        'pendingCalls': pendingCalls,
        'respondedCalls': respondedCalls,
        'completedCalls': completedCalls,
        'averageResponseTimeMinutes': averageResponseTime,
        'responseRate': totalCalls > 0
            ? (respondedCalls + completedCalls) / totalCalls * 100
            : 0.0,
      };
    } catch (e) {
      throw Exception('Çağrı istatistikleri alınırken hata oluştu: $e');
    }
  }

  /// Garson çağrı istatistikleri
  Future<Map<String, dynamic>> getWaiterCallStats(String waiterId) async {
    try {
      final calls = await getWaiterCallsByWaiterId(waiterId);

      final today = DateTime.now();
      final todayCalls = calls.where((call) {
        return call.createdAt.year == today.year &&
            call.createdAt.month == today.month &&
            call.createdAt.day == today.day;
      }).toList();

      int totalCalls = todayCalls.length;
      int respondedCalls = todayCalls
          .where((c) =>
              c.status == WaiterCallStatus.responded ||
              c.status == WaiterCallStatus.completed)
          .length;
      int completedCalls = todayCalls
          .where((c) => c.status == WaiterCallStatus.completed)
          .length;

      double averageResponseTime = 0.0;
      final respondedCallsWithTime =
          todayCalls.where((c) => c.responseTimeMinutes != null).toList();

      if (respondedCallsWithTime.isNotEmpty) {
        averageResponseTime = respondedCallsWithTime
                .map((c) => c.responseTimeMinutes!)
                .reduce((a, b) => a + b) /
            respondedCallsWithTime.length;
      }

      return {
        'totalCalls': totalCalls,
        'respondedCalls': respondedCalls,
        'completedCalls': completedCalls,
        'averageResponseTimeMinutes': averageResponseTime,
        'responseRate':
            totalCalls > 0 ? respondedCalls / totalCalls * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Garson çağrı istatistikleri alınırken hata oluştu: $e');
    }
  }

  // ============================================================================
  // YARDIMCI METODLAR
  // ============================================================================

  /// Garsona bildirim gönder
  Future<void> _sendWaiterNotification(WaiterCall waiterCall) async {
    try {
      await _notificationService.sendNotification(
        businessId: waiterCall.businessId,
        recipientId: waiterCall.waiterId,
        title: 'Garson Çağrısı! 🔔',
        message:
            '${waiterCall.customerName} sizi ${waiterCall.tableInfo} için çağırıyor',
        type: NotificationType.waiterCall,
        data: {
          'callId': waiterCall.callId,
          'customerId': waiterCall.customerId,
          'customerName': waiterCall.customerName,
          'tableNumber': waiterCall.tableNumber,
          'floorNumber': waiterCall.floorNumber,
          'message': waiterCall.message,
        },
      );
    } catch (e) {
      print('Garson bildirimi gönderilirken hata: $e');
      // Bildirim hatası ana işlemi etkilememelidır
    }
  }

  /// İşletmenin tüm müsait garsonlarını getir (müşteriler için)
  Future<List<Staff>> getAvailableWaitersForCustomer(String businessId) async {
    try {
      // Tüm müsait garsonları getir
      final availableStaff = await _staffService.getAvailableStaff(businessId);

      // Sadece garsonları filtrele
      return availableStaff
          .where((staff) => staff.role == StaffRole.waiter)
          .toList();
    } catch (e) {
      throw Exception('Müsait garsonlar alınırken hata oluştu: $e');
    }
  }
}
