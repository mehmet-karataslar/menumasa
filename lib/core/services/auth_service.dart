import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user.dart' as app_user;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<app_user.User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Get user data from Firestore first
        final user = await _getUserFromFirestore(credential.user!.uid);
        
        if (user != null) {
          // Update last login time only if user exists
          try {
            await _firestore.collection('users').doc(credential.user!.uid).update({
              'profile.lastLoginAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            print('Failed to update last login time: $e');
            // Continue anyway, this is not critical
          }
        }
        
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    } catch (e) {
      throw AuthException('Giriş yapılırken bir hata oluştu: $e');
    }
  }

  // Register with email and password
  Future<app_user.User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
    String? phone,
  ) async {
    try {
      // First check if email already exists
      final emailCheck = await _auth.fetchSignInMethodsForEmail(email);
      if (emailCheck.isNotEmpty) {
        throw AuthException('Bu e-posta adresi zaten kullanılıyor');
      }

      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name in Firebase Auth
        await credential.user!.updateDisplayName(name);

        // Create user profile in Firestore
        final newUser = app_user.User(
          uid: credential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          subscriptionType: app_user.SubscriptionType.free,
          subscriptionExpiry: null,
          profile: app_user.UserProfile(
            preferences: app_user.UserPreferences(
              language: 'tr',
              currency: 'TL',
              timezone: 'Europe/Istanbul',
              emailNotifications: true,
              pushNotifications: true,
              smsNotifications: false,
              theme: 'light',
              analytics: true,
              marketing: false,
            ),
            lastLoginAt: DateTime.now(),
            totalBusinesses: 0,
            totalProducts: 0,
          ),
        );

        // Save to Firestore with user's UID as document ID
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser.toJson());

        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    } catch (e) {
      throw AuthException('Kayıt olurken bir hata oluştu: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    } catch (e) {
      throw AuthException(
        'Şifre sıfırlama e-postası gönderilirken bir hata oluştu: $e',
      );
    }
  }

  // Update user profile
  Future<void> updateUserProfile(app_user.User user) async {
    try {
      // Update display name in Firebase Auth if it's the current user
      if (currentUser != null && currentUser!.uid == user.uid) {
        await currentUser!.updateDisplayName(user.name);
        if (user.email != currentUser!.email) {
          await currentUser!.updateEmail(user.email);
        }
      }

      // Update in Firestore
      final data = user.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(user.uid).update(data);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    } catch (e) {
      throw AuthException(
        'Kullanıcı profili güncellenirken bir hata oluştu: $e',
      );
    }
  }

  // Update user password
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      if (currentUser == null) {
        throw AuthException('Kullanıcı oturum açmamış');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );

      await currentUser!.reauthenticateWithCredential(credential);

      // Update password
      await currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    } catch (e) {
      throw AuthException('Şifre güncellenirken bir hata oluştu: $e');
    }
  }

  // Get user from Firestore
  Future<app_user.User?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return app_user.User.fromJson(doc.data()!, id: uid);
      }
      // If user document doesn't exist, create a default user
      print('User document not found for UID: $uid, creating default user');
      return _createDefaultUser(uid);
    } catch (e) {
      print('Error getting user from Firestore: $e');
      // Try to create default user as fallback
      return _createDefaultUser(uid);
    }
  }

  // Create default user when document doesn't exist
  app_user.User _createDefaultUser(String uid) {
    final currentUser = _auth.currentUser;
    return app_user.User(
      uid: uid,
      email: currentUser?.email ?? '',
      name: currentUser?.displayName ?? 'Kullanıcı',
      phone: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      subscriptionType: app_user.SubscriptionType.free,
      subscriptionExpiry: null,
      profile: app_user.UserProfile(
        preferences: app_user.UserPreferences(
          language: 'tr',
          currency: 'TL',
          timezone: 'Europe/Istanbul',
          emailNotifications: true,
          pushNotifications: true,
          smsNotifications: false,
          theme: 'light',
          analytics: true,
          marketing: false,
        ),
        lastLoginAt: DateTime.now(),
        totalBusinesses: 0,
        totalProducts: 0,
      ),
    );
  }

  // Get current user data
  Future<app_user.User?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await _getUserFromFirestore(currentUser!.uid);
  }

  // Get user's businesses
  Future<List<String>> getUserBusinessIds() async {
    if (currentUser == null) return [];

    try {
      final snapshot = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: currentUser!.uid)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      if (currentUser == null) {
        throw AuthException('Kullanıcı oturum açmamış');
      }

      // Delete user data from Firestore
      await _firestore.collection('users').doc(currentUser!.uid).delete();

      // Delete user from Firebase Auth
      await currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    } catch (e) {
      throw AuthException('Hesap silinirken bir hata oluştu: $e');
    }
  }

  // Error message translation
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor';
      case 'weak-password':
        return 'Şifre çok zayıf';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin';
      case 'network-request-failed':
        return 'İnternet bağlantısı hatası';
      case 'requires-recent-login':
        return 'Bu işlem için yeniden giriş yapmanız gerekiyor';
      case 'operation-not-allowed':
        return 'Bu işlem için yetkiniz yok';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}

// Custom exception class
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
