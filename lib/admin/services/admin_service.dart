import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../models/admin_user.dart';
import '../models/admin_session.dart';
import '../models/admin_activity_log.dart';

class AdminService {
  static const String _adminCollection = 'admin_users';
  static const String _adminSessionsCollection = 'admin_sessions';
  static const String _adminLogsCollection = 'admin_activity_logs';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  AdminUser? _currentAdmin;
  AdminSession? _currentSession;

  // Singleton pattern
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  // Getters
  AdminUser? get currentAdmin => _currentAdmin;
  AdminSession? get currentSession => _currentSession;
  bool get isLoggedIn => _currentAdmin != null && _currentSession?.isValid == true;

  /// Admin girişi
  Future<AdminUser?> signInWithCredentials({
    required String username,
    required String password,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      // Önce Firebase Authentication ile giriş yap
      UserCredential userCredential;
      
      // Admin kullanıcıları için özel email formatı kullan
      final adminEmail = '$username@admin.masamenu.com';
      
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: password,
        );
      } catch (e) {
        // Eğer kullanıcı yoksa, ilk admin için otomatik oluştur
        if (e.toString().contains('user-not-found')) {
          print('İlk admin kullanıcısı oluşturuluyor: $username');
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: adminEmail,
            password: password,
          );
          
          // İlk admin kullanıcısını Firestore'a kaydet
          await _createFirstAdmin(username, password, userCredential.user!.uid);
        } else if (e.toString().contains('wrong-password')) {
          throw AdminException('Geçersiz kullanıcı adı veya şifre');
        } else {
          throw AdminException('Giriş sırasında hata: $e');
        }
      }

      // Firestore'dan admin bilgilerini al
      final adminDoc = await _firestore
          .collection(_adminCollection)
          .doc(userCredential.user!.uid)
          .get();

      if (!adminDoc.exists) {
        // Eğer Firestore'da admin yoksa, oluştur
        print('Firestore\'da admin bulunamadı, oluşturuluyor...');
        await _createFirstAdmin(username, password, userCredential.user!.uid);
        
        // Tekrar al
        final newAdminDoc = await _firestore
            .collection(_adminCollection)
            .doc(userCredential.user!.uid)
            .get();
            
        if (!newAdminDoc.exists) {
          throw AdminException('Admin kullanıcısı oluşturulamadı');
        }
        
        final adminData = newAdminDoc.data()!;
        final admin = AdminUser.fromJson({...adminData, 'id': newAdminDoc.id});
        
        // Session oluştur
        final session = await _createSession(
          adminId: admin.id,
          ipAddress: ipAddress ?? 'unknown',
          userAgent: userAgent ?? 'unknown',
        );

        _currentAdmin = admin;
        _currentSession = session;

        return admin;
      }

      final adminData = adminDoc.data()!;
      if (!adminData['isActive']) {
        throw AdminException('Admin hesabı aktif değil');
      }

      final admin = AdminUser.fromJson({...adminData, 'id': adminDoc.id});

      // Session oluştur
      final session = await _createSession(
        adminId: admin.id,
        ipAddress: ipAddress ?? 'unknown',
        userAgent: userAgent ?? 'unknown',
      );

      // Admin bilgilerini güncelle
      await _firestore
          .collection(_adminCollection)
          .doc(admin.id)
          .update({
        'lastLoginAt': DateTime.now().toIso8601String(),
        'lastLoginIp': ipAddress,
        'sessionToken': session.sessionToken,
      });

      // Activity log kaydet
      await _logActivity(
        adminId: admin.id,
        adminUsername: admin.username,
        action: 'LOGIN',
        targetType: 'SYSTEM',
        targetId: 'login',
        details: 'Admin girişi yapıldı',
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      _currentAdmin = admin;
      _currentSession = session;

      return admin;
    } catch (e) {
      if (e is AdminException) rethrow;
      throw AdminException('Giriş sırasında hata: $e');
    }
  }

  /// İlk admin kullanıcısını oluştur
  Future<void> _createFirstAdmin(String username, String password, String uid) async {
    final adminId = uid;
    final hashedPassword = _hashPassword(password);

    final admin = AdminUser(
      id: adminId,
      username: username,
      email: '$username@admin.masamenu.com',
      name: 'Süper Yönetici',
      role: AdminRole.superAdmin,
      permissions: AdminPermission.values.toList(),
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
    );

    await _firestore
        .collection(_adminCollection)
        .doc(adminId)
        .set({
      ...admin.toJson(),
      'passwordHash': hashedPassword,
    });
    
    print('Admin kullanıcısı Firestore\'a kaydedildi: $username');
  }

  /// Admin çıkışı
  Future<void> signOut() async {
    try {
      // Firebase Authentication'dan çıkış yap
      await _auth.signOut();
      
      if (_currentSession != null) {
        // Session'ı deaktif et
        await _firestore
            .collection(_adminSessionsCollection)
            .doc(_currentSession!.sessionId)
            .update({'isActive': false});

        // Activity log kaydet
        if (_currentAdmin != null) {
          await _logActivity(
            adminId: _currentAdmin!.id,
            adminUsername: _currentAdmin!.username,
            action: 'LOGOUT',
            targetType: 'SYSTEM',
            targetId: 'logout',
            details: 'Admin çıkışı yapıldı',
          );
        }
      }

      _currentAdmin = null;
      _currentSession = null;
    } catch (e) {
      print('Çıkış sırasında hata: $e');
    }
  }

  /// Session doğrulama
  Future<bool> validateSession(String sessionToken) async {
    try {
      // Firebase Authentication durumunu kontrol et
      final user = _auth.currentUser;
      if (user == null) return false;

      final sessionQuery = await _firestore
          .collection(_adminSessionsCollection)
          .where('sessionToken', isEqualTo: sessionToken)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (sessionQuery.docs.isEmpty) return false;

      final sessionData = sessionQuery.docs.first.data();
      final session = AdminSession.fromJson({...sessionData, 'id': sessionQuery.docs.first.id});

      if (!session.isValid) {
        // Session'ı deaktif et
        await _firestore
            .collection(_adminSessionsCollection)
            .doc(session.sessionId)
            .update({'isActive': false});
        return false;
      }

      // Admin bilgilerini al
      final adminDoc = await _firestore
          .collection(_adminCollection)
          .doc(session.adminId)
          .get();

      if (!adminDoc.exists) return false;

      final adminData = adminDoc.data()!;
      if (!adminData['isActive']) return false;

      _currentAdmin = AdminUser.fromJson({...adminData, 'id': adminDoc.id});
      _currentSession = session;

      return true;
    } catch (e) {
      print('Session doğrulama hatası: $e');
      return false;
    }
  }

  /// Tüm admin kullanıcılarını getir
  Future<List<AdminUser>> getAllAdmins({bool skipPermissionCheck = false}) async {
    try {
      // Firebase Authentication kontrolü
      final user = _auth.currentUser;
      if (user == null) {
        throw AdminException('Oturum açmanız gerekiyor');
      }

      // İlk admin oluşturulurken yetki kontrolü yapma
      if (!skipPermissionCheck && !_hasPermission(AdminPermission.manageAdmins)) {
        throw AdminException('Bu işlem için yetkiniz yok');
      }

      final querySnapshot = await _firestore
          .collection(_adminCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AdminUser.fromJson({...(doc.data() as Map<String, dynamic>), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (e is AdminException) rethrow;
      throw AdminException('Admin listesi alınırken hata: $e');
    }
  }

  /// Yeni admin kullanıcısı oluştur
  Future<String> createAdmin({
    required String username,
    required String email,
    required String fullName,
    required String password,
    required AdminRole role,
    required List<AdminPermission> permissions,
    bool skipPermissionCheck = false,
  }) async {
    try {
      // Firebase Authentication kontrolü
      final user = _auth.currentUser;
      if (user == null) {
        throw AdminException('Oturum açmanız gerekiyor');
      }

      // İlk admin oluşturulurken yetki kontrolü yapma
      if (!skipPermissionCheck && !_hasPermission(AdminPermission.manageAdmins)) {
        throw AdminException('Bu işlem için yetkiniz yok');
      }

      // Kullanıcı adı kontrolü
      final existingUser = await _firestore
          .collection(_adminCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw AdminException('Bu kullanıcı adı zaten kullanılıyor');
      }

      // Email kontrolü
      final existingEmail = await _firestore
          .collection(_adminCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingEmail.docs.isNotEmpty) {
        throw AdminException('Bu e-posta adresi zaten kullanılıyor');
      }

      final adminId = 'admin_${DateTime.now().millisecondsSinceEpoch}';
      final hashedPassword = _hashPassword(password);

      final admin = AdminUser(
        id: adminId,
        username: username,
        email: email,
        name: fullName,
        role: role,
        permissions: permissions,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection(_adminCollection)
          .doc(adminId)
          .set({
        ...admin.toJson(),
        'passwordHash': hashedPassword,
      });

      // Activity log kaydet (sadece mevcut admin varsa)
      if (_currentAdmin != null) {
        await _logActivity(
          adminId: _currentAdmin!.id,
          adminUsername: _currentAdmin!.username,
          action: 'CREATE_ADMIN',
          targetType: 'ADMIN_USER',
          targetId: adminId,
          details: 'Yeni admin kullanıcısı oluşturuldu: $username',
        );
      }

      return adminId;
    } catch (e) {
      if (e is AdminException) rethrow;
      throw AdminException('Admin oluşturulurken hata: $e');
    }
  }

  /// Admin kullanıcısını güncelle
  Future<void> updateAdmin({
    required String adminId,
    String? username,
    String? email,
    String? fullName,
    AdminRole? role,
    List<AdminPermission>? permissions,
    bool? isActive,
  }) async {
    try {
      if (!_hasPermission(AdminPermission.manageAdmins)) {
        throw AdminException('Bu işlem için yetkiniz yok');
      }

      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (username != null) updates['username'] = username;
      if (email != null) updates['email'] = email;
      if (fullName != null) updates['fullName'] = fullName;
      if (role != null) updates['role'] = role.value;
      if (permissions != null) {
        updates['permissions'] = permissions.map((p) => p.value).toList();
      }
      if (isActive != null) updates['isActive'] = isActive;

      await _firestore
          .collection(_adminCollection)
          .doc(adminId)
          .update(updates);

      // Activity log kaydet
      await _logActivity(
        adminId: _currentAdmin!.id,
        adminUsername: _currentAdmin!.username,
        action: 'UPDATE_ADMIN',
        targetType: 'ADMIN_USER',
        targetId: adminId,
        details: 'Admin kullanıcısı güncellendi',
      );
    } catch (e) {
      if (e is AdminException) rethrow;
      throw AdminException('Admin güncellenirken hata: $e');
    }
  }

  /// Admin şifresini değiştir
  Future<void> changeAdminPassword({
    required String adminId,
    required String newPassword,
  }) async {
    try {
      if (!_hasPermission(AdminPermission.manageAdmins)) {
        throw AdminException('Bu işlem için yetkiniz yok');
      }

      final hashedPassword = _hashPassword(newPassword);

      await _firestore
          .collection(_adminCollection)
          .doc(adminId)
          .update({
        'passwordHash': hashedPassword,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Activity log kaydet
      await _logActivity(
        adminId: _currentAdmin!.id,
        adminUsername: _currentAdmin!.username,
        action: 'CHANGE_PASSWORD',
        targetType: 'ADMIN_USER',
        targetId: adminId,
        details: 'Admin şifresi değiştirildi',
      );
    } catch (e) {
      if (e is AdminException) rethrow;
      throw AdminException('Şifre değiştirilirken hata: $e');
    }
  }

  /// Admin kullanıcısını sil
  Future<void> deleteAdmin(String adminId) async {
    try {
      if (!_hasPermission(AdminPermission.manageAdmins)) {
        throw AdminException('Bu işlem için yetkiniz yok');
      }

      // Kendini silmeye çalışıyorsa engelle
      if (adminId == _currentAdmin?.id) {
        throw AdminException('Kendi hesabınızı silemezsiniz');
      }

      await _firestore
          .collection(_adminCollection)
          .doc(adminId)
          .delete();

      // Activity log kaydet
      await _logActivity(
        adminId: _currentAdmin!.id,
        adminUsername: _currentAdmin!.username,
        action: 'DELETE_ADMIN',
        targetType: 'ADMIN_USER',
        targetId: adminId,
        details: 'Admin kullanıcısı silindi',
      );
    } catch (e) {
      if (e is AdminException) rethrow;
      throw AdminException('Admin silinirken hata: $e');
    }
  }

  /// Activity logları getir
  Future<List<AdminActivityLog>> getActivityLogs({
    String? adminId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      if (!_hasPermission(AdminPermission.viewAuditLogs)) {
        throw AdminException('Bu işlem için yetkiniz yok');
      }

      Query query = _firestore
          .collection(_adminLogsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (adminId != null) {
        query = query.where('adminId', isEqualTo: adminId);
      }

      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => AdminActivityLog.fromJson({...(doc.data() as Map<String, dynamic>), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (e is AdminException) rethrow;
      throw AdminException('Activity logları alınırken hata: $e');
    }
  }

  // Private helper methods
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _hasPermission(AdminPermission permission) {
    if (_currentAdmin == null) return false;
    return _currentAdmin!.hasPermission(permission);
  }

  Future<AdminSession> _createSession({
    required String adminId,
    required String ipAddress,
    required String userAgent,
  }) async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    final session = AdminSession(
      id: sessionId,
      adminUserId: adminId,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      ipAddress: ipAddress,
      userAgent: userAgent,
      isActive: true,
    );

    await _firestore
        .collection(_adminSessionsCollection)
        .doc(sessionId)
        .set(session.toJson());

    return session;
  }

  String _generateSessionToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _logActivity({
    required String adminId,
    required String adminUsername,
    required String action,
    required String targetType,
    required String targetId,
    String? details,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final logId = 'log_${DateTime.now().millisecondsSinceEpoch}';
      
      final log = AdminActivityLog(
        id: logId,
        adminUserId: adminId,
        adminUserName: adminUsername,
        activityType: AdminActivityType.adminManagement, // Default type
        description: details ?? action,
        details: {'action': action, 'targetType': targetType, 'targetId': targetId},
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      await _firestore
          .collection(_adminLogsCollection)
          .doc(logId)
          .set(log.toJson());
    } catch (e) {
      print('Activity log kaydedilirken hata: $e');
    }
  }
}

class AdminException implements Exception {
  final String message;
  AdminException(this.message);

  @override
  String toString() => 'AdminException: $message';
} 