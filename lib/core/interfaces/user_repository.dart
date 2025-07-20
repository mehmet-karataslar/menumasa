import '../entities/user_profile.dart';
import '../entities/user_auth.dart';
import '../enums/user_type.dart';
import 'repository.dart';

/// User repository interface with user-specific operations
abstract class UserRepository extends Repository<UserProfile, String> {
  /// Get user by email
  Future<UserProfile?> getByEmail(String email);

  /// Get users by type
  Future<List<UserProfile>> getByType(UserType userType);

  /// Get active users
  Future<List<UserProfile>> getActiveUsers();

  /// Get inactive users
  Future<List<UserProfile>> getInactiveUsers();

  /// Update user profile
  Future<void> updateProfile(String userId, UserProfile profile);

  /// Update user authentication data
  Future<void> updateAuth(String userId, UserAuth auth);

  /// Get user authentication data
  Future<UserAuth?> getAuthData(String userId);

  /// Verify email
  Future<void> verifyEmail(String userId);

  /// Activate user
  Future<void> activateUser(String userId);

  /// Deactivate user
  Future<void> deactivateUser(String userId);

  /// Check if email exists
  Future<bool> emailExists(String email);

  /// Get recently registered users
  Future<List<UserProfile>> getRecentUsers({
    required Duration period,
    int? limit,
  });

  /// Get users by creation date range
  Future<List<UserProfile>> getUsersByDateRange({
    required DateTime start,
    required DateTime end,
  });

  /// Search users by name or email
  Future<List<UserProfile>> searchUsers(String query);

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats();

  /// Bulk update users
  Future<void> bulkUpdate(Map<String, Map<String, dynamic>> updates);

  /// Get users with filters
  Future<List<UserProfile>> getWithFilters({
    UserType? userType,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAfter,
    DateTime? createdBefore,
    int? limit,
    int? offset,
  });
} 