import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static const String _lastLoginKey = 'last_login_type';
  static const String _lastUserIdKey = 'last_user_id';
  static const String _lastBusinessIdKey = 'last_business_id';

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Demo business credentials
  static const Map<String, String> _demoBusinessCredentials = {
    'admin': 'admin123',
    'business': 'business123',
    'demo': 'demo123',
  };

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  /// Giriş durumunu dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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
          // Anonymous auth veya email/password auth
          final email = '$identifier@demo.com';
          try {
            // Önce giriş yapmayı dene
            await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (e) {
            // Kullanıcı yoksa oluştur
            await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );

            // Firestore'da business profili oluştur
            await _createBusinessProfile(identifier, email);
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
      // Anonymous auth ile müşteri girişi
      await _auth.signInAnonymously();

      // Firestore'da müşteri profili oluştur/güncelle
      await _createCustomerProfile(identifier);

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
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('businesses').doc(businessId).set({
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
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('customers').doc(user.uid).set({
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
    // Telefon numarası pattern kontrolü
    if (_isPhoneNumber(identifier)) {
      return true;
    }

    // Masa numarası pattern kontrolü
    if (_isTableNumber(identifier)) {
      return true;
    }

    // Email pattern kontrolü
    if (_isEmail(identifier)) {
      return true;
    }

    return false;
  }

  /// Telefon numarası kontrolü
  bool _isPhoneNumber(String value) {
    // Türkiye telefon numarası pattern'leri
    final phonePatterns = [
      RegExp(r'^0[5][0-9]{9}$'), // 05xxxxxxxxx
      RegExp(r'^[5][0-9]{9}$'), // 5xxxxxxxxx
      RegExp(r'^\+90[5][0-9]{9}$'), // +905xxxxxxxxx
    ];

    return phonePatterns.any((pattern) => pattern.hasMatch(value));
  }

  /// Masa numarası kontrolü
  bool _isTableNumber(String value) {
    final tablePatterns = [
      RegExp(r'^(masa|table|m|t)\d+$', caseSensitive: false),
      RegExp(r'^\d+$'), // Sadece rakam
    ];

    return tablePatterns.any((pattern) => pattern.hasMatch(value));
  }

  /// Email kontrolü
  bool _isEmail(String value) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value);
  }

  /// Son giriş bilgisini kaydet
  Future<void> _saveLastLogin(LoginType type, String identifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLoginKey, type.name);

      if (type == LoginType.business) {
        await prefs.setString(_lastBusinessIdKey, identifier);
      } else {
        await prefs.setString(_lastUserIdKey, identifier);
      }
    } catch (e) {
      debugPrint('Error saving last login: $e');
    }
  }

  /// Son giriş bilgisini al
  Future<LastLoginInfo?> getLastLoginInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final typeString = prefs.getString(_lastLoginKey);

      if (typeString == null) return null;

      final type = LoginType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => LoginType.customer,
      );

      final identifier = type == LoginType.business
          ? prefs.getString(_lastBusinessIdKey)
          : prefs.getString(_lastUserIdKey);

      if (identifier == null) return null;

      return LastLoginInfo(type: type, identifier: identifier);
    } catch (e) {
      debugPrint('Error getting last login info: $e');
      return null;
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    try {
      await _auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastLoginKey);
      await prefs.remove(_lastUserIdKey);
      await prefs.remove(_lastBusinessIdKey);
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  /// Demo veri oluştur
  Future<void> createDemoData() async {
    try {
      // Demo business data'sını Firestore'a ekle
      await _firestore.collection('businesses').doc('demo-business-001').set({
        'businessId': 'demo-business-001',
        'businessName': 'Lezzet Durağı',
        'businessDescription':
            'Geleneksel Türk mutfağının en lezzetli örnekleri',
        'logoUrl': 'https://picsum.photos/200/200?random=logo',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Demo data created');
    } catch (e) {
      debugPrint('Demo data creation error: $e');
    }
  }
}

/// Giriş sonucu
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

/// Giriş türü
enum LoginType { business, customer }

/// Son giriş bilgisi
class LastLoginInfo {
  final LoginType type;
  final String identifier;

  LastLoginInfo({required this.type, required this.identifier});
}
