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

      // Şifre doğrulama (yeni method ile)
      if (!business.verifyPassword(password)) {
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
        'updatedAt': DateTime.now().toIso8601String(),
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
  Future<BusinessUser> createBusiness({
    required String username,
    required String email,
    required String fullName,
    required String password,
    required BusinessRole role,
    required List<BusinessPermission> permissions,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
  }) async {
    try {
      // Check if username already exists
      final existingUserQuery = await _firestore
          .collection(_businessCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        throw BusinessException('Bu kullanıcı adı zaten kullanımda');
      }

      // Check if email already exists
      final existingEmailQuery = await _firestore
          .collection(_businessCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingEmailQuery.docs.isNotEmpty) {
        throw BusinessException('Bu e-posta adresi zaten kullanımda');
      }

      // Create new business user
      final businessId = _firestore.collection(_businessCollection).doc().id;
      
      final businessUser = BusinessUser.createWithPassword(
        businessId: businessId,
        username: username,
        email: email,
        fullName: fullName,
        password: password,
        role: role,
        permissions: permissions,
        businessName: businessName,
        businessAddress: businessAddress,
        businessPhone: businessPhone,
        isOwner: role == BusinessRole.owner,
      );

      // Save to Firestore
      await _firestore
          .collection(_businessCollection)
          .doc(businessId)
          .set(businessUser.toJson());

      // Log activity
      await _logActivity(
        businessId: businessId,
        businessUsername: username,
        action: 'REGISTER',
        targetType: 'USER',
        targetId: businessId,
        details: 'Yeni business kullanıcısı oluşturuldu',
      );

      return businessUser;
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw BusinessException('Business kullanıcısı oluşturulurken hata: $e');
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

      // Get the business user and update password
      final businessDoc = await _firestore
          .collection(_businessCollection)
          .doc(businessId)
          .get();
      
      if (!businessDoc.exists) {
        throw BusinessException('Business kullanıcısı bulunamadı');
      }

      final businessUser = BusinessUser.fromJson(businessDoc.data()!, id: businessDoc.id);
      final updatedBusinessUser = businessUser.updatePassword(newPassword);

      await _firestore
          .collection(_businessCollection)
          .doc(businessId)
          .update({
        'passwordHash': updatedBusinessUser.passwordHash,
        'passwordSalt': updatedBusinessUser.passwordSalt,
        'lastPasswordChange': updatedBusinessUser.lastPasswordChange?.toIso8601String(),
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

  /// Business şifre güncelleme
  Future<void> updatePassword(String oldPassword, String newPassword) async {
    try {
      if (_currentBusiness == null) {
        throw BusinessException('Giriş yapılması gerekli');
      }

      // Mevcut şifre doğrulama
      if (!_currentBusiness!.verifyPassword(oldPassword)) {
        throw BusinessException('Mevcut şifre yanlış');
      }

      // Yeni şifre ile business kullanıcısını güncelle
      final updatedBusiness = _currentBusiness!.updatePassword(newPassword);

      // Firestore'da güncelle
      await _firestore
          .collection(_businessCollection)
          .doc(_currentBusiness!.businessId)
          .update({
        'passwordHash': updatedBusiness.passwordHash,
        'passwordSalt': updatedBusiness.passwordSalt,
        'lastPasswordChange': updatedBusiness.lastPasswordChange?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Activity log kaydet
      await _logActivity(
        businessId: _currentBusiness!.businessId,
        businessUsername: _currentBusiness!.username,
        action: 'PASSWORD_CHANGE',
        targetType: 'USER',
        targetId: _currentBusiness!.businessId,
        details: 'Şifre güncellendi',
      );

      _currentBusiness = updatedBusiness;
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw BusinessException('Şifre güncellenirken hata: $e');
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
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    final combined = '$timestamp-$random';
    final bytes = utf8.encode(combined);
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