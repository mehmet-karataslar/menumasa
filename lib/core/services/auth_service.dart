import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static const String _lastLoginKey = 'last_login_type';
  static const String _lastUserIdKey = 'last_user_id';
  static const String _lastBusinessIdKey = 'last_business_id';

  // Firebase Auth instance (nullable until Firebase is available)
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  // Check if Firebase is available
  bool get _isFirebaseAvailable => _auth != null && _firestore != null;

  // Demo business credentials
  static const Map<String, String> _demoBusinessCredentials = {
    'admin': 'admin123',
    'business': 'business123',
    'demo': 'demo123',
  };

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initializeFirebase();
  }

  /// Initialize Firebase instances
  void _initializeFirebase() {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      debugPrint('🔥 AuthService: Firebase instances initialized');
    } catch (e) {
      debugPrint(
        '⚠️ AuthService: Firebase not available, using local storage: $e',
      );
      _auth = null;
      _firestore = null;
    }
  }

  /// Mevcut kullanıcıyı al
  User? get currentUser => _auth?.currentUser;

  /// Giriş durumunu dinle
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  /// Kullanıcı girişini doğrula
  Future<LoginResult> authenticateUser(
    String identifier,
    String password,
  ) async {
    try {
      // Boş değer kontrolü
      if (identifier.trim().isEmpty) {
        return LoginResult(success: false, message: 'Giriş bilgisi gereklidir');
      }

      final cleanIdentifier = identifier.trim().toLowerCase();
      final cleanPassword = password.trim();

      // İşletme girişi kontrolü
      if (await _isBusinessLogin(cleanIdentifier, cleanPassword)) {
        final result = await _authenticateBusinessUser(
          cleanIdentifier,
          cleanPassword,
        );
        if (result.success) {
          await _saveLastLogin(LoginType.business, cleanIdentifier);
        }
        return result;
      }

      // Müşteri girişi kontrolü
      if (await _isCustomerLogin(cleanIdentifier)) {
        final result = await _authenticateCustomerUser(cleanIdentifier);
        if (result.success) {
          await _saveLastLogin(LoginType.customer, cleanIdentifier);
        }
        return result;
      }

      // Hatalı giriş
      return LoginResult(success: false, message: 'Geçersiz giriş bilgileri');
    } catch (e) {
      debugPrint('Auth error: $e');
      return LoginResult(
        success: false,
        message: 'Giriş işlemi sırasında hata oluştu',
      );
    }
  }

  /// İşletme kullanıcısını doğrula
  Future<LoginResult> _authenticateBusinessUser(
    String identifier,
    String password,
  ) async {
    try {
      // Demo business credentials kontrolü
      if (_demoBusinessCredentials.containsKey(identifier)) {
        if (_demoBusinessCredentials[identifier] == password) {
          if (_isFirebaseAvailable) {
            // Firebase available - use Firebase Auth
            final email = '$identifier@demo.com';
            try {
              // Önce giriş yapmayı dene
              await _auth!.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
            } catch (e) {
              // Kullanıcı yoksa oluştur
              await _auth!.createUserWithEmailAndPassword(
                email: email,
                password: password,
              );

              // Firestore'da business profili oluştur
              await _createBusinessProfile(identifier, email);
            }
          } else {
            // Firebase not available - use local storage
            debugPrint('⚠️ Using local auth for business: $identifier');
          }

          return LoginResult(
            success: true,
            loginType: LoginType.business,
            businessId: identifier,
            message: 'İşletme girişi başarılı',
          );
        }
      }

      return LoginResult(success: false, message: 'Geçersiz işletme bilgileri');
    } catch (e) {
      debugPrint('Business auth error: $e');
      return LoginResult(
        success: false,
        message: 'İşletme girişi sırasında hata oluştu',
      );
    }
  }

  /// Müşteri kullanıcısını doğrula
  Future<LoginResult> _authenticateCustomerUser(String identifier) async {
    try {
      if (_isFirebaseAvailable) {
        // Firebase available - use anonymous auth
        await _auth!.signInAnonymously();

        // Firestore'da müşteri profili oluştur/güncelle
        await _createCustomerProfile(identifier);
      } else {
        // Firebase not available - use local storage
        debugPrint('⚠️ Using local auth for customer: $identifier');
      }

      return LoginResult(
        success: true,
        loginType: LoginType.customer,
        customerId: identifier,
        message: 'Müşteri girişi başarılı',
      );
    } catch (e) {
      debugPrint('Customer auth error: $e');
      return LoginResult(
        success: false,
        message: 'Müşteri girişi sırasında hata oluştu',
      );
    }
  }

  /// İşletme profili oluştur
  Future<void> _createBusinessProfile(String businessId, String email) async {
    if (!_isFirebaseAvailable) return;

    try {
      final user = _auth!.currentUser;
      if (user != null) {
        await _firestore!.collection('businesses').doc(businessId).set({
          'businessId': businessId,
          'email': email,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Create business profile error: $e');
    }
  }

  /// Müşteri profili oluştur
  Future<void> _createCustomerProfile(String identifier) async {
    if (!_isFirebaseAvailable) return;

    try {
      final user = _auth!.currentUser;
      if (user != null) {
        await _firestore!.collection('customers').doc(user.uid).set({
          'identifier': identifier,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Create customer profile error: $e');
    }
  }

  /// İşletme girişi kontrolü
  Future<bool> _isBusinessLogin(String identifier, String password) async {
    // Demo business credentials kontrolü
    if (_demoBusinessCredentials.containsKey(identifier)) {
      return _demoBusinessCredentials[identifier] == password;
    }

    // İşletme kodu pattern kontrolü
    if (identifier.contains('admin') ||
        identifier.contains('business') ||
        identifier.contains('demo')) {
      return password.isNotEmpty;
    }

    return false;
  }

  /// Müşteri girişi kontrolü
  Future<bool> _isCustomerLogin(String identifier) async {
    // Müşteri kodu pattern kontrolü
    if (identifier.startsWith('m') ||
        identifier.startsWith('customer') ||
        identifier.startsWith('c')) {
      return true;
    }

    // Masa numarası kontrolü
    if (RegExp(r'^[0-9]+$').hasMatch(identifier)) {
      return true;
    }

    return false;
  }

  /// Son giriş bilgisini kaydet
  Future<void> _saveLastLogin(LoginType loginType, String identifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLoginKey, loginType.toString());
      await prefs.setString(_lastUserIdKey, identifier);

      if (loginType == LoginType.business) {
        await prefs.setString(_lastBusinessIdKey, identifier);
      }
    } catch (e) {
      debugPrint('Save last login error: $e');
    }
  }

  /// Son giriş bilgisini al
  Future<LastLogin?> getLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginTypeString = prefs.getString(_lastLoginKey);
      final userId = prefs.getString(_lastUserIdKey);

      if (loginTypeString == null || userId == null) {
        return null;
      }

      final loginType = LoginType.values.firstWhere(
        (type) => type.toString() == loginTypeString,
        orElse: () => LoginType.customer,
      );

      return LastLogin(
        loginType: loginType,
        userId: userId,
        businessId: prefs.getString(_lastBusinessIdKey),
      );
    } catch (e) {
      debugPrint('Get last login error: $e');
      return null;
    }
  }

  /// Kullanıcıyı oturumu kapat
  Future<void> signOut() async {
    try {
      if (_isFirebaseAvailable) {
        await _auth!.signOut();
      }

      // Local storage'dan da temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastLoginKey);
      await prefs.remove(_lastUserIdKey);
      await prefs.remove(_lastBusinessIdKey);
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Kullanıcı verilerini Firestore'dan al
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    if (!_isFirebaseAvailable) return null;

    try {
      final doc = await _firestore!.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Get user data error: $e');
      return null;
    }
  }

  /// Kullanıcı verilerini Firestore'a kaydet
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    if (!_isFirebaseAvailable) return;

    try {
      await _firestore!.collection('users').doc(userId).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Update user data error: $e');
    }
  }
}

/// Giriş sonucu sınıfı
class LoginResult {
  final bool success;
  final String message;
  final LoginType? loginType;
  final String? businessId;
  final String? customerId;

  LoginResult({
    required this.success,
    required this.message,
    this.loginType,
    this.businessId,
    this.customerId,
  });
}

/// Giriş türü enum
enum LoginType { business, customer }

/// Son giriş bilgisi sınıfı
class LastLogin {
  final LoginType loginType;
  final String userId;
  final String? businessId;

  LastLogin({required this.loginType, required this.userId, this.businessId});
}
