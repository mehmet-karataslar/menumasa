import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../models/business_user.dart';
import '../models/business_session.dart';
import '../models/business_activity_log.dart';

class BusinessService {
  static const String _businessCollection = 'business_users';
  static const String _businessSessionsCollection = 'business_sessions';
  static const String _businessLogsCollection = 'business_activity_logs';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  BusinessUser? _currentBusiness;
  BusinessSession? _currentSession;

  // Singleton pattern
  static final BusinessService _instance = BusinessService._internal();
  factory BusinessService() => _instance;
  BusinessService._internal();

  // Getters
  BusinessUser? get currentBusiness => _currentBusiness;
  BusinessSession? get currentSession => _currentSession;
  bool get isLoggedIn => _currentBusiness != null && _currentSession?.isValid == true;

  /// Business girişi
  Future<BusinessUser?> signInWithCredentials({
    required String username,
    required String password,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      // Kullanıcı adı ile business kullanıcısını bul
      final businessQuery = await _firestore
          .collection(_businessCollection)
          .where('username', isEqualTo: username)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (businessQuery.docs.isEmpty) {
        throw BusinessException('Geçersiz kullanıcı adı veya şifre');
      }

      final businessData = businessQuery.docs.first.data();
      final business = BusinessUser.fromJson(businessData, id: businessQuery.docs.first.id);

      // Şifre doğrulama (hash ile)
      final hashedPassword = _hashPassword(password);
      if (businessData['passwordHash'] != hashedPassword) {
        throw BusinessException('Geçersiz kullanıcı adı veya şifre');
      }

      // Session oluştur
      final session = await _createSession(
        businessId: business.businessId,
        ipAddress: ipAddress ?? 'unknown',
        userAgent: userAgent ?? 'unknown',
      );

      // Business bilgilerini güncelle
      await _firestore
          .collection(_businessCollection)
          .doc(business.businessId)
          .update({
        'lastLoginAt': DateTime.now().toIso8601String(),
        'lastLoginIp': ipAddress,
        'sessionToken': session.sessionToken,
      });

      // Activity log kaydet
      await _logActivity(
        businessId: business.businessId,
        businessUsername: business.username,
        action: 'LOGIN',
        targetType: 'SYSTEM',
        targetId: 'login',
        details: 'Business girişi yapıldı',
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      _currentBusiness = business;
      _currentSession = session;

      return business;
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw BusinessException('Giriş sırasında hata: $e');
    }
  }

  /// Business çıkışı
  Future<void> signOut() async {
    try {
      if (_currentSession != null) {
        // Session'ı deaktif et
        await _firestore
            .collection(_businessSessionsCollection)
            .doc(_currentSession!.sessionId)
            .update({'isActive': false});

        // Activity log kaydet
        if (_currentBusiness != null) {
          await _logActivity(
            businessId: _currentBusiness!.businessId,
            businessUsername: _currentBusiness!.username,
            action: 'LOGOUT',
            targetType: 'SYSTEM',
            targetId: 'logout',
            details: 'Business çıkışı yapıldı',
          );
        }
      }

      _currentBusiness = null;
      _currentSession = null;
    } catch (e) {
      print('Çıkış sırasında hata: $e');
    }
  }

  /// Session doğrulama
  Future<bool> validateSession(String sessionToken) async {
    try {
      final sessionQuery = await _firestore
          .collection(_businessSessionsCollection)
          .where('sessionToken', isEqualTo: sessionToken)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (sessionQuery.docs.isEmpty) return false;

      final sessionData = sessionQuery.docs.first.data();
      final session = BusinessSession.fromJson({...sessionData, 'id': sessionQuery.docs.first.id});

      if (!session.isValid) {
        // Session'ı deaktif et
        await _firestore
            .collection(_businessSessionsCollection)
            .doc(session.sessionId)
            .update({'isActive': false});
        return false;
      }

      // Business bilgilerini al
      final businessDoc = await _firestore
          .collection(_businessCollection)
          .doc(session.businessId)
          .get();

      if (!businessDoc.exists) return false;

      final businessData = businessDoc.data()!;
      if (!businessData['isActive']) return false;

      _currentBusiness = BusinessUser.fromJson(businessData, id: businessDoc.id);
      _currentSession = session;

      return true;
    } catch (e) {
      print('Session doğrulama hatası: $e');
      return false;
    }
  }

  /// Tüm business kullanıcılarını getir
  Future<List<BusinessUser>> getAllBusinesses() async {
    try {
      if (!_hasPermission(BusinessPermission.manageStaff)) {
        throw BusinessException('Bu işlem için yetkiniz yok');
      }

      final querySnapshot = await _firestore
          .collection(_businessCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BusinessUser.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw BusinessException('Business listesi alınırken hata: $e');
    }
  }

  /// Yeni business kullanıcısı oluştur
  Future<String> createBusiness({
    required String username,
    required String email,
    required String fullName,
    required String password,
    required BusinessRole role,
    required List<BusinessPermission> permissions,
  }) async {
    try {
      if (!_hasPermission(BusinessPermission.manageStaff)) {
        throw BusinessException('Bu işlem için yetkiniz yok');
      }

      // Kullanıcı adı kontrolü
      final existingUser = await _firestore
          .collection(_businessCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw BusinessException('Bu kullanıcı adı zaten kullanılıyor');
      }

      // Email kontrolü
      final existingEmail = await _firestore
          .collection(_businessCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingEmail.docs.isNotEmpty) {
        throw BusinessException('Bu email adresi zaten kullanılıyor');
      }

      final businessId = _firestore.collection(_businessCollection).doc().id;
      final hashedPassword = _hashPassword(password);

      final business = BusinessUser(
        businessId: businessId,
        username: username,
        email: email,
        fullName: fullName,
        role: role,
        permissions: permissions,
        isActive: true,
        isOwner: false,
        lastLoginAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_businessCollection)
          .doc(businessId)
          .set({
        ...business.toJson(),
        'passwordHash': hashedPassword,
      });

      // Activity log kaydet
      await _logActivity(
        businessId: _currentBusiness!.businessId,
        businessUsername: _currentBusiness!.username,
        action: 'CREATE_BUSINESS',
        targetType: 'BUSINESS',
        targetId: businessId,
        details: 'Yeni business kullanıcısı oluşturuldu: $username',
      );

      return businessId;
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw BusinessException('Business oluşturulurken hata: $e');
    }
  }

  /// Business kullanıcısını güncelle
  Future<void> updateBusiness({
    required String businessId,
    String? username,
    String? email,
    String? fullName,
    BusinessRole? role,
    List<BusinessPermission>? permissions,
  }) async {
    try {
      if (!_hasPermission(BusinessPermission.manageStaff)) {
        throw BusinessException('Bu işlem için yetkiniz yok');
      }

      final updateData = <String, dynamic>{};
      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;
      if (fullName != null) updateData['fullName'] = fullName;
      if (role != null) updateData['role'] = role.value;
      if (permissions != null) {
        updateData['permissions'] = permissions.map((p) => p.value).toList();
      }
      updateData['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore
          .collection(_businessCollection)
          .doc(businessId)
          .update(updateData);

      // Activity log kaydet
      await _logActivity(
        businessId: _currentBusiness!.businessId,
        businessUsername: _currentBusiness!.username,
        action: 'UPDATE_BUSINESS',
        targetType: 'BUSINESS',
        targetId: businessId,
        details: 'Business kullanıcısı güncellendi',
      );
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw BusinessException('Business güncellenirken hata: $e');
    }
  }

  /// Business kullanıcısının aktiflik durumunu güncelle
  Future<void> updateBusinessStatus({
    required String businessId,
    required bool isActive,
  }) async {
    try {
      if (!_hasPermission(BusinessPermission.manageStaff)) {
        throw BusinessException('Bu işlem için yetkiniz yok');
      }

      await _firestore
          .collection(_businessCollection)
          .doc(businessId)
          .update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Activity log kaydet
      await _logActivity(
        businessId: _currentBusiness!.businessId,
        businessUsername: _currentBusiness!.username,
        action: 'UPDATE_BUSINESS_STATUS',
        targetType: 'BUSINESS',
        targetId: businessId,
        details: 'Business durumu güncellendi: ${isActive ? "Aktif" : "Pasif"}',
      );
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw BusinessException('Business durumu güncellenirken hata: $e');
    }
  }

  /// Business şifresini değiştir
  Future<void> changeBusinessPassword({
    required String businessId,
    required String newPassword,
  }) async {
    try {
      if (!_hasPermission(BusinessPermission.manageStaff)) {
        throw BusinessException('Bu işlem için yetkiniz yok');
      }

      final hashedPassword = _hashPassword(newPassword);

      await _firestore
          .collection(_businessCollection)
          .doc(businessId)
          .update({
        'passwordHash': hashedPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Activity log kaydet
      await _logActivity(
        businessId: _currentBusiness!.businessId,
        businessUsername: _currentBusiness!.username,
        action: 'CHANGE_PASSWORD',
        targetType: 'BUSINESS',
        targetId: businessId,
        details: 'Business şifresi değiştirildi',
      );
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw BusinessException('Şifre değiştirilirken hata: $e');
    }
  }

  /// Business kullanıcısını sil
  Future<void> deleteBusiness(String businessId) async {
    try {
      if (!_hasPermission(BusinessPermission.manageStaff)) {
        throw BusinessException('Bu işlem için yetkiniz yok');
      }

      // Kendini silmeye çalışıyorsa engelle
      if (businessId == _currentBusiness?.businessId) {
        throw BusinessException('Kendi hesabınızı silemezsiniz');
      }

      await _firestore
          .collection(_businessCollection)
          .doc(businessId)
          .delete();

      // Activity log kaydet
      await _logActivity(
        businessId: _currentBusiness!.businessId,
        businessUsername: _currentBusiness!.username,
        action: 'DELETE_BUSINESS',
        targetType: 'BUSINESS',
        targetId: businessId,
        details: 'Business kullanıcısı silindi',
      );
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw BusinessException('Business silinirken hata: $e');
    }
  }

  /// Activity logları getir
  Future<List<BusinessActivityLog>> getActivityLogs({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_hasPermission(BusinessPermission.viewReports)) {
        throw BusinessException('Bu işlem için yetkiniz yok');
      }

      Query query = _firestore
          .collection(_businessLogsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => BusinessActivityLog.fromJson({...(doc.data() as Map<String, dynamic>), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw BusinessException('Activity logları alınırken hata: $e');
    }
  }

  // Private methods

  /// Yetki kontrolü
  bool _hasPermission(BusinessPermission permission) {
    if (_currentBusiness == null) return false;
    return _currentBusiness!.hasPermission(permission);
  }

  /// Şifre hash'leme
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Session oluştur
  Future<BusinessSession> _createSession({
    required String businessId,
    required String ipAddress,
    required String userAgent,
  }) async {
    final sessionId = _firestore.collection(_businessSessionsCollection).doc().id;
    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    final session = BusinessSession(
      id: sessionId,
      businessUserId: businessId,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      ipAddress: ipAddress,
      userAgent: userAgent,
      isActive: true,
    );

    await _firestore
        .collection(_businessSessionsCollection)
        .doc(sessionId)
        .set(session.toJson());

    return session;
  }

  /// Session token oluştur
  String _generateSessionToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Activity log kaydet
  Future<void> _logActivity({
    required String businessId,
    required String businessUsername,
    required String action,
    required String targetType,
    required String targetId,
    String? details,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final logId = _firestore.collection(_businessLogsCollection).doc().id;
      final log = BusinessActivityLog(
        id: logId,
        businessUserId: businessId,
        businessUserName: businessUsername,
        activityType: BusinessActivityType.businessManagement, // Default type
        description: details ?? action,
        details: {'action': action, 'targetType': targetType, 'targetId': targetId},
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      await _firestore
          .collection(_businessLogsCollection)
          .doc(logId)
          .set(log.toJson());
    } catch (e) {
      print('Activity log kaydedilirken hata: $e');
    }
  }
}

/// Business Exception sınıfı
class BusinessException implements Exception {
  final String message;
  BusinessException(this.message);

  @override
  String toString() => message;
}