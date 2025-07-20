import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user.dart' as app_user;
import '../../data/models/business.dart';

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
        final newUser = app_user.User.customer(
          id: credential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          createdAt: DateTime.now(),
          isActive: true,
          isEmailVerified: false,
          lastLoginAt: DateTime.now(),
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

  // Register business user with email and password
  Future<app_user.User?> createBusinessUserWithEmailAndPassword(
    String email,
    String password,
    String businessName,
    String? phone,
    String businessId,
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
        await credential.user!.updateDisplayName(businessName);

        // Create business user record in users collection with business type
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'id': credential.user!.uid,
          'email': email,
          'name': businessName,
          'phone': phone,
          'userType': app_user.UserType.business.name,
          'isActive': true,
          'isEmailVerified': false,
          'createdAt': DateTime.now().toIso8601String(),
          'lastLoginAt': DateTime.now().toIso8601String(),
          'businessData': app_user.BusinessData(
             role: app_user.BusinessRole.fromString('owner'),
             permissions: [
               app_user.BusinessPermission.manageStaff,
               app_user.BusinessPermission.addProducts,
               app_user.BusinessPermission.editProducts,
               app_user.BusinessPermission.deleteProducts,
               app_user.BusinessPermission.editOrders,
               app_user.BusinessPermission.viewOrders,
               app_user.BusinessPermission.manageSettings,
               app_user.BusinessPermission.viewAnalytics,
             ],
             businessIds: [businessId],
             stats: BusinessStats.empty(),
             settings: BusinessSettings.defaultRestaurant(),
           ).toJson(),
        });

        // Also create detailed business_users record for BusinessService
        await _firestore.collection('business_users').doc(credential.user!.uid).set({
          'businessId': businessId,
          'uid': credential.user!.uid,
          'username': email.split('@').first.toLowerCase(),
          'email': email,
          'fullName': businessName,
          'role': 'owner',
          'permissions': [
            'manage_staff',
            'add_products',
            'edit_products',
            'delete_products',
            'edit_orders',
            'view_orders',
            'manage_settings',
            'view_analytics',
          ],
          'isActive': true,
          'isOwner': true,
          'lastLoginAt': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'businessName': businessName,
          'businessPhone': phone,
          'passwordHash': '', // Not used for Firebase Auth users
          'passwordSalt': '', // Not used for Firebase Auth users
          'requirePasswordChange': false,
        });

        return app_user.User.business(
          id: credential.user!.uid,
          email: email,
          name: businessName,
          phone: phone,
          createdAt: DateTime.now(),
          isActive: true,
          isEmailVerified: false,
          lastLoginAt: DateTime.now(),
          businessData: app_user.BusinessData(
            role: app_user.BusinessRole.owner,
            permissions: [
              app_user.BusinessPermission.manageStaff,
              app_user.BusinessPermission.addProducts,
              app_user.BusinessPermission.editProducts,
              app_user.BusinessPermission.deleteProducts,
              app_user.BusinessPermission.editOrders,
              app_user.BusinessPermission.viewOrders,
              app_user.BusinessPermission.manageSettings,
              app_user.BusinessPermission.viewAnalytics,
            ],
            businessIds: [businessId],
            stats: BusinessStats.empty(),
            settings: BusinessSettings.defaultRestaurant(),
          ),
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    } catch (e) {
      throw AuthException('İşletme hesabı oluşturulurken bir hata oluştu: $e');
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
      if (currentUser != null && currentUser!.uid == user.id) {
        await currentUser!.updateDisplayName(user.name);
        if (user.email != currentUser!.email) {
          await currentUser!.updateEmail(user.email);
        }
      }

      // Update in Firestore
      final data = user.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(user.id).update(data);
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
      // First check users collection (for customers and admins)
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return app_user.User.fromJson(userDoc.data()!, id: uid);
      }

      // If not found, check business_users collection (for businesses)
      final businessDoc = await _firestore.collection('business_users').doc(uid).get();
      if (businessDoc.exists) {
        final businessData = businessDoc.data()!;
        // Convert BusinessUser to User for authentication purposes
        return app_user.User.business(
          id: uid,
          email: businessData['email'] ?? '',
          name: businessData['fullName'] ?? '',
          phone: businessData['businessPhone'],
          createdAt: _parseTimestamp(businessData['createdAt']) ?? DateTime.now(),
          isActive: businessData['isActive'] ?? true,
          isEmailVerified: false, // Business users don't use email verification
          lastLoginAt: _parseTimestamp(businessData['lastLoginAt']) ?? DateTime.now(),
          businessData: app_user.BusinessData(
            role: app_user.BusinessRole.fromString(businessData['role'] ?? 'owner'),
            permissions: (businessData['permissions'] as List<dynamic>? ?? [])
                .map((perm) => app_user.BusinessPermission.fromString(perm))
                .toList(),
            businessIds: [businessData['businessId'] ?? uid],
            stats: BusinessStats.empty(),
            settings: BusinessSettings.defaultRestaurant(),
          ),
        );
      }

      // If user document doesn't exist in either collection, create a default user
      print('User document not found for UID: $uid, creating default user');
      return _createDefaultUser(uid);
    } catch (e) {
      print('Error getting user from Firestore: $e');
      // Try to create default user as fallback
      return _createDefaultUser(uid);
    }
  }

  // Helper method to parse Firestore timestamp
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Create default user when document doesn't exist
  app_user.User _createDefaultUser(String uid) {
    final currentUser = _auth.currentUser;
    return app_user.User.customer(
      id: uid,
      email: currentUser?.email ?? '',
      name: currentUser?.displayName ?? 'Kullanıcı',
      phone: null,
      createdAt: DateTime.now(),
      isActive: true,
      isEmailVerified: currentUser?.emailVerified ?? false,
      lastLoginAt: DateTime.now(),
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
