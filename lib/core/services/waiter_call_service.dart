import 'package:cloud_firestore/cloud_firestore.dart';
import '../../customer/models/waiter_call.dart';
import 'notification_service.dart';

/// Garson çağırma servisi
class WaiterCallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  static const String _collection = 'waiter_calls';
  static const String _businessStaffCollection = 'business_staff';

  // ============================================================================
  // CUSTOMER METHODS (Müşteri işlemleri)
  // ============================================================================

  /// Garson çağır
  Future<String> callWaiter({
    required String businessId,
    required String customerId,
    String? customerName,
    String? customerPhone,
    required int tableNumber,
    required WaiterCallType requestType,
    String? message,
    WaiterCallPriority? priority,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Aynı masada aktif çağrı var mı kontrol et
      final existingCall = await _getActiveCallForTable(businessId, tableNumber);
      if (existingCall != null) {
        throw Exception('Bu masa için zaten aktif bir çağrı bulunuyor');
      }

      // Yeni çağrı oluştur
      final call = WaiterCall.create(
        businessId: businessId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        tableNumber: tableNumber,
        requestType: requestType,
        message: message,
        priority: priority,
        metadata: metadata,
      );

      // Firestore'a kaydet
      await _firestore.collection(_collection).doc(call.callId).set(call.toFirestore());

      // İşletme personeline bildirim gönder
      await _notifyBusinessStaff(call);

      // Müşteriye onay bildirimi
      await _notifyCustomer(call, 'Çağrınız alındı. Garson en kısa sürede gelecek.');

      return call.callId;
    } catch (e) {
      print('Garson çağırırken hata: $e');
      rethrow;
    }
  }

  /// Müşterinin aktif çağrılarını al
  Future<List<WaiterCall>> getCustomerActiveCalls(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('customerId', isEqualTo: customerId)
          .where('status', whereIn: ['pending', 'acknowledged', 'inProgress'])
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WaiterCall.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Müşteri aktif çağrıları alınırken hata: $e');
      return [];
    }
  }

  /// Müşterinin çağrı geçmişini al
  Future<List<WaiterCall>> getCustomerCallHistory(
    String customerId, {
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => WaiterCall.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Müşteri çağrı geçmişi alınırken hata: $e');
      return [];
    }
  }

  /// Çağrıyı iptal et (müşteri)
  Future<void> cancelCall(String callId, {String? reason}) async {
    try {
      final doc = await _firestore.collection(_collection).doc(callId).get();
      if (!doc.exists) {
        throw Exception('Çağrı bulunamadı');
      }

      final call = WaiterCall.fromFirestore(doc);
      
      if (!call.isActive) {
        throw Exception('Bu çağrı zaten tamamlanmış veya iptal edilmiş');
      }

      final updatedCall = call.cancel(reason: reason);
      await _firestore.collection(_collection).doc(callId).update(updatedCall.toFirestore());

      // Bildirimler gönder
      await _notifyCustomer(updatedCall, 'Çağrınız iptal edildi.');
      if (call.waiterId != null) {
        await _notifyWaiter(updatedCall, 'Masa ${call.tableNumber} çağrısı iptal edildi.');
      }
    } catch (e) {
      print('Çağrı iptal edilirken hata: $e');
      rethrow;
    }
  }

  // ============================================================================
  // BUSINESS STAFF METHODS (İşletme personeli işlemleri)
  // ============================================================================

  /// İşletmenin aktif çağrılarını al
  Future<List<WaiterCall>> getBusinessActiveCalls(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('status', whereIn: [
            WaiterCallStatus.pending.toString(),
            WaiterCallStatus.acknowledged.toString(),
            WaiterCallStatus.inProgress.toString(),
          ])
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => WaiterCall.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('İşletme aktif çağrıları alınırken hata: $e');
      return [];
    }
  }

  /// Çağrıyı onayla (garson)
  Future<void> acknowledgeCall(
    String callId, {
    required String waiterId,
    required String waiterName,
  }) async {
    try {
      final doc = await _firestore.collection(_collection).doc(callId).get();
      if (!doc.exists) {
        throw Exception('Çağrı bulunamadı');
      }

      final call = WaiterCall.fromFirestore(doc);
      
      if (call.status != WaiterCallStatus.pending) {
        throw Exception('Bu çağrı zaten onaylanmış');
      }

      final updatedCall = call.acknowledge(waiterId: waiterId, waiterName: waiterName);
      await _firestore.collection(_collection).doc(callId).update(updatedCall.toFirestore());

      // Müşteriye bildirim gönder
      await _notifyCustomer(
        updatedCall, 
        '$waiterName çağrınızı aldı ve geliyor.',
      );
    } catch (e) {
      print('Çağrı onaylanırken hata: $e');
      rethrow;
    }
  }

  /// İşleme başla (garson)
  Future<void> startProcessingCall(String callId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(callId).get();
      if (!doc.exists) {
        throw Exception('Çağrı bulunamadı');
      }

      final call = WaiterCall.fromFirestore(doc);
      
      if (call.status != WaiterCallStatus.acknowledged) {
        throw Exception('Çağrı önce onaylanmalı');
      }

      final updatedCall = call.startProcessing();
      await _firestore.collection(_collection).doc(callId).update(updatedCall.toFirestore());

      // Müşteriye bildirim gönder
      await _notifyCustomer(
        updatedCall, 
        'Garson masanızda. Talebiniz işleniyor.',
      );
    } catch (e) {
      print('Çağrı işleme başlatılırken hata: $e');
      rethrow;
    }
  }

  /// Çağrıyı tamamla (garson)
  Future<void> completeCall(String callId, {String? responseNotes}) async {
    try {
      final doc = await _firestore.collection(_collection).doc(callId).get();
      if (!doc.exists) {
        throw Exception('Çağrı bulunamadı');
      }

      final call = WaiterCall.fromFirestore(doc);
      
      if (!call.isActive) {
        throw Exception('Bu çağrı zaten tamamlanmış');
      }

      final updatedCall = call.complete(responseNotes: responseNotes);
      await _firestore.collection(_collection).doc(callId).update(updatedCall.toFirestore());

      // Müşteriye bildirim gönder
      await _notifyCustomer(
        updatedCall, 
        'Talebiniz tamamlandı. Başka bir ihtiyacınız olursa tekrar çağırabilirsiniz.',
      );

      // İstatistikleri güncelle
      await _updateCallStatistics(updatedCall);
    } catch (e) {
      print('Çağrı tamamlanırken hata: $e');
      rethrow;
    }
  }

  /// Çağrıyı eskalt et
  Future<void> escalateCall(
    String callId, {
    required WaiterCallPriority newPriority,
    String? reason,
  }) async {
    try {
      final doc = await _firestore.collection(_collection).doc(callId).get();
      if (!doc.exists) {
        throw Exception('Çağrı bulunamadı');
      }

      final call = WaiterCall.fromFirestore(doc);
      final updatedCall = call.escalate(newPriority: newPriority, reason: reason);
      
      await _firestore.collection(_collection).doc(callId).update(updatedCall.toFirestore());

      // Yöneticiye bildirim gönder
      await _notifyManagement(updatedCall, 'Çağrı eskalt edildi: $reason');
    } catch (e) {
      print('Çağrı eskalt edilirken hata: $e');
      rethrow;
    }
  }

  // ============================================================================
  // ANALYTICS & STATISTICS
  // ============================================================================

  /// İşletme çağrı istatistikleri
  Future<WaiterCallStats> getBusinessCallStats(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final calls = snapshot.docs.map((doc) => WaiterCall.fromFirestore(doc)).toList();

      return _calculateStats(calls);
    } catch (e) {
      print('İstatistik hesaplanırken hata: $e');
      return WaiterCallStats(
        totalCalls: 0,
        completedCalls: 0,
        cancelledCalls: 0,
        averageResponseTime: 0,
        averageCompletionTime: 0,
        satisfactionScore: 0,
        callsByType: {},
        callsByPriority: {},
      );
    }
  }

  /// Garson performans istatistikleri
  Future<Map<String, dynamic>> getWaiterPerformance(
    String waiterId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('waiterId', isEqualTo: waiterId);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final calls = snapshot.docs.map((doc) => WaiterCall.fromFirestore(doc)).toList();

      final completedCalls = calls.where((c) => c.status == WaiterCallStatus.completed).toList();
      final avgResponseTime = completedCalls.isNotEmpty
          ? completedCalls.map((c) => c.responseTimeMinutes ?? 0).reduce((a, b) => a + b) / completedCalls.length
          : 0.0;
      
      final avgSatisfaction = completedCalls.isNotEmpty
          ? completedCalls.map((c) => c.calculateSatisfactionScore()).reduce((a, b) => a + b) / completedCalls.length
          : 0.0;

      return {
        'totalCalls': calls.length,
        'completedCalls': completedCalls.length,
        'averageResponseTime': avgResponseTime,
        'averageSatisfactionScore': avgSatisfaction,
        'completionRate': calls.isNotEmpty ? (completedCalls.length / calls.length) * 100 : 0,
      };
    } catch (e) {
      print('Garson performansı hesaplanırken hata: $e');
      return {};
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Masa için aktif çağrı var mı kontrol et
  Future<WaiterCall?> _getActiveCallForTable(String businessId, int tableNumber) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('businessId', isEqualTo: businessId)
          .where('tableNumber', isEqualTo: tableNumber)
          .where('status', whereIn: [
            WaiterCallStatus.pending.toString(),
            WaiterCallStatus.acknowledged.toString(),
            WaiterCallStatus.inProgress.toString(),
          ])
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return WaiterCall.fromFirestore(snapshot.docs.first);
      }

      return null;
    } catch (e) {
      print('Aktif çağrı kontrol edilirken hata: $e');
      return null;
    }
  }

  /// İşletme personeline bildirim gönder
  Future<void> _notifyBusinessStaff(WaiterCall call) async {
    try {
      // Tüm aktif personele bildirim gönder
      final staffSnapshot = await _firestore
          .collection(_businessStaffCollection)
          .where('businessId', isEqualTo: call.businessId)
          .where('isActive', isEqualTo: true)
          .where('role', whereIn: ['waiter', 'manager', 'supervisor'])
          .get();

      for (final staffDoc in staffSnapshot.docs) {
        final staffData = staffDoc.data();
        final fcmToken = staffData['fcmToken'] as String?;
        
        if (fcmToken != null) {
          await _notificationService.sendNotification(
            businessId: call.businessId,
            recipientId: staffDoc.id,
            title: '🔔 Yeni Garson Çağrısı - Masa ${call.tableNumber}',
            message: '${call.requestType.displayName} - ${call.message ?? "Mesaj yok"}',
            type: NotificationType.waiterCall,
            data: {
              'type': 'waiter_call',
              'callId': call.callId,
              'businessId': call.businessId,
              'tableNumber': call.tableNumber.toString(),
              'requestType': call.requestType.toString(),
              'priority': call.priority.toString(),
            },
          );
        }
      }
    } catch (e) {
      print('Personel bildirimi gönderilirken hata: $e');
    }
  }

  /// Müşteriye bildirim gönder
  Future<void> _notifyCustomer(WaiterCall call, String message) async {
    try {
      // Müşteri bildirim gönder
      await _notificationService.sendNotification(
        businessId: call.businessId,
        recipientId: call.customerId,
        title: 'Garson Çağrısı Güncellemesi',
        message: message,
        type: NotificationType.waiterCall,
        data: {
          'type': 'waiter_call_update',
          'callId': call.callId,
          'status': call.status.toString(),
        },
      );
    } catch (e) {
      print('Müşteri bildirimi gönderilirken hata: $e');
    }
  }

  /// Garsona bildirim gönder
  Future<void> _notifyWaiter(WaiterCall call, String message) async {
    try {
      if (call.waiterId != null) {
        await _notificationService.sendNotification(
          businessId: call.businessId,
          recipientId: call.waiterId!,
          title: 'Çağrı Güncellemesi',
          message: message,
          type: NotificationType.waiterCall,
          data: {
            'type': 'waiter_call_update',
            'callId': call.callId,
          },
        );
      }
    } catch (e) {
      print('Garson bildirimi gönderilirken hata: $e');
    }
  }

  /// Yöneticiye bildirim gönder
  Future<void> _notifyManagement(WaiterCall call, String message) async {
    try {
      // Yöneticilere bildirim gönder
      final managersSnapshot = await _firestore
          .collection(_businessStaffCollection)
          .where('businessId', isEqualTo: call.businessId)
          .where('role', whereIn: ['manager', 'owner'])
          .where('isActive', isEqualTo: true)
          .get();

      for (final managerDoc in managersSnapshot.docs) {
        final managerData = managerDoc.data();
        final fcmToken = managerData['fcmToken'] as String?;
        
        if (fcmToken != null) {
          await _notificationService.sendNotification(
            businessId: call.businessId,
            recipientId: managerDoc.id,
            title: '⚠️ Çağrı Eskalasyonu',
            message: message,
            type: NotificationType.waiterCall,
            data: {
              'type': 'call_escalation',
              'callId': call.callId,
              'tableNumber': call.tableNumber.toString(),
            },
          );
        }
      }
    } catch (e) {
      print('Yönetici bildirimi gönderilirken hata: $e');
    }
  }

  /// İstatistikleri güncelle
  Future<void> _updateCallStatistics(WaiterCall call) async {
    try {
      final satisfactionScore = call.calculateSatisfactionScore();
      
      // İşletme istatistiklerini güncelle
      await _firestore
          .collection('business_stats')
          .doc(call.businessId)
          .collection('waiter_calls')
          .doc('daily_stats_${DateTime.now().toString().substring(0, 10)}')
          .set({
        'totalCalls': FieldValue.increment(1),
        'completedCalls': FieldValue.increment(1),
        'totalSatisfactionScore': FieldValue.increment(satisfactionScore),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Garson istatistiklerini güncelle
      if (call.waiterId != null) {
        await _firestore
            .collection('waiter_stats')
            .doc(call.waiterId!)
            .set({
          'totalCalls': FieldValue.increment(1),
          'completedCalls': FieldValue.increment(1),
          'totalSatisfactionScore': FieldValue.increment(satisfactionScore),
          'lastCallCompletedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('İstatistik güncellenirken hata: $e');
    }
  }

  /// İstatistik hesapla
  WaiterCallStats _calculateStats(List<WaiterCall> calls) {
    final completedCalls = calls.where((c) => c.status == WaiterCallStatus.completed).toList();
    final cancelledCalls = calls.where((c) => c.status == WaiterCallStatus.cancelled).toList();

    final avgResponseTime = completedCalls.isNotEmpty
        ? completedCalls.map((c) => c.responseTimeMinutes ?? 0).reduce((a, b) => a + b) / completedCalls.length
        : 0.0;

    final avgCompletionTime = completedCalls.isNotEmpty
        ? completedCalls.map((c) => c.totalProcessingTimeMinutes ?? 0).reduce((a, b) => a + b) / completedCalls.length
        : 0.0;

    final avgSatisfaction = completedCalls.isNotEmpty
        ? completedCalls.map((c) => c.calculateSatisfactionScore()).reduce((a, b) => a + b) / completedCalls.length
        : 0.0;

    final callsByType = <WaiterCallType, int>{};
    final callsByPriority = <WaiterCallPriority, int>{};

    for (final call in calls) {
      callsByType[call.requestType] = (callsByType[call.requestType] ?? 0) + 1;
      callsByPriority[call.priority] = (callsByPriority[call.priority] ?? 0) + 1;
    }

    return WaiterCallStats(
      totalCalls: calls.length,
      completedCalls: completedCalls.length,
      cancelledCalls: cancelledCalls.length,
      averageResponseTime: avgResponseTime,
      averageCompletionTime: avgCompletionTime,
      satisfactionScore: avgSatisfaction,
      callsByType: callsByType,
      callsByPriority: callsByPriority,
    );
  }

  // ============================================================================
  // REAL-TIME STREAMS
  // ============================================================================

  /// İşletme aktif çağrıları stream
  Stream<List<WaiterCall>> getBusinessActiveCallsStream(String businessId) {
    return _firestore
        .collection(_collection)
        .where('businessId', isEqualTo: businessId)
        .where('status', whereIn: [
          WaiterCallStatus.pending.toString(),
          WaiterCallStatus.acknowledged.toString(),
          WaiterCallStatus.inProgress.toString(),
        ])
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WaiterCall.fromFirestore(doc))
            .toList());
  }

  /// Müşteri aktif çağrıları stream
  Stream<List<WaiterCall>> getCustomerActiveCallsStream(String customerId) {
    return _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .where('status', whereIn: [
          WaiterCallStatus.pending.toString(),
          WaiterCallStatus.acknowledged.toString(),
          WaiterCallStatus.inProgress.toString(),
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WaiterCall.fromFirestore(doc))
            .toList());
  }
} 