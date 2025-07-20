import '../entities/user_profile.dart';
import '../entities/user_auth.dart';

/// Abstract authentication service interface
abstract class AuthService {
  /// Get current authenticated user
  UserProfile? get currentUser;

  /// Authentication state stream
  Stream<UserProfile?> get authStateChanges;

  /// Sign in with email and password
  Future<UserProfile?> signInWithEmailAndPassword(String email, String password);

  /// Sign in with username and password (for business users)
  Future<UserProfile?> signInWithUsernameAndPassword(String username, String password);

  /// Create user account with email and password
  Future<UserProfile?> createUserWithEmailAndPassword(
    String email,
    String password,
    String name, {
    String? phone,
  });

  /// Sign out current user
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Change user password
  Future<void> changePassword(String currentPassword, String newPassword);

  /// Verify email address
  Future<void> sendEmailVerification();

  /// Check if email is verified
  Future<bool> isEmailVerified();

  /// Update user profile
  Future<void> updateProfile(UserProfile profile);

  /// Get user authentication data
  Future<UserAuth?> getAuthData(String userId);

  /// Update user authentication data
  Future<void> updateAuthData(String userId, UserAuth authData);

  /// Delete user account
  Future<void> deleteAccount();

  /// Check if user exists with email
  Future<bool> userExistsWithEmail(String email);

  /// Check if user exists with username
  Future<bool> userExistsWithUsername(String username);

  /// Refresh authentication token
  Future<String?> refreshToken();

  /// Validate current session
  Future<bool> validateSession();

  /// Get user ID token
  Future<String?> getIdToken();

  /// Sign in anonymously
  Future<UserProfile?> signInAnonymously();

  /// Link anonymous account with email/password
  Future<UserProfile?> linkWithEmailAndPassword(String email, String password);

  /// Reauthenticate user
  Future<void> reauthenticate(String password);
} 