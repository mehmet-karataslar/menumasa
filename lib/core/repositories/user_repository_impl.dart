import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/user_repository.dart';
import '../entities/user_profile.dart';
import '../entities/user_auth.dart';
import '../enums/user_type.dart';
import '../services/firestore_service.dart';

/// Firestore implementation of UserRepository
class UserRepositoryImpl implements UserRepository {
  final FirestoreService _firestoreService;
  final String _collection = 'users';
  final String _authCollection = 'user_auth';

  UserRepositoryImpl({FirestoreService? firestoreService}) 
      : _firestoreService = firestoreService ?? FirestoreService();

  @override
  Future<UserProfile?> getById(String id) async {
    try {
      final doc = await _firestoreService.firestore
          .collection(_collection)
          .doc(id)
          .get();
      
      if (doc.exists) {
        return UserProfile.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by ID: $e');
    }
  }

  @override
  Future<List<UserProfile>> getAll() async {
    try {
      final snapshot = await _firestoreService.firestore
          .collection(_collection)
          .get();
      
      return snapshot.docs
          .map((doc) => UserProfile.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  @override
  Future<String> save(UserProfile entity) async {
    try {
      final data = entity.toFirestore();
      
      if (entity.id.isEmpty) {
        // Create new user
        final docRef = await _firestoreService.firestore
            .collection(_collection)
            .add(data);
        return docRef.id;
      } else {
        // Update existing user
        await _firestoreService.firestore
            .collection(_collection)
            .doc(entity.id)
            .set(data, SetOptions(merge: true));
        return entity.id;
      }
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestoreService.firestore
          .collection(_collection)
          .doc(id)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Delete user profile
      await _firestoreService.firestore
          .collection(_collection)
          .doc(id)
          .delete();
      
      // Delete auth data
      await _firestoreService.firestore
          .collection(_authCollection)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  @override
  Future<bool> exists(String id) async {
    try {
      final doc = await _firestoreService.firestore
          .collection(_collection)
          .doc(id)
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check user existence: $e');
    }
  }

  @override
  Future<int> count() async {
    try {
      final snapshot = await _firestoreService.firestore
          .collection(_collection)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to count users: $e');
    }
  }

  @override
  Future<List<UserProfile>> getPage({
    int page = 0,
    int size = 10,
    String? sortBy,
    bool descending = false,
  }) async {
    try {
      Query query = _firestoreService.firestore.collection(_collection);
      
      if (sortBy != null) {
        query = query.orderBy(sortBy, descending: descending);
      } else {
        query = query.orderBy('createdAt', descending: true);
      }
      
      query = query.limit(size);
      // Note: Firestore doesn't support offset. For proper pagination, use startAfterDocument
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserProfile.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user page: $e');
    }
  }

  @override
  Future<List<UserProfile>> search(String query) async {
    try {
      // Search by name or email
      final nameQuery = _firestoreService.firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(20);
      
      final emailQuery = _firestoreService.firestore
          .collection(_collection)
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: query + 'z')
          .limit(20);
      
      final nameResults = await nameQuery.get();
      final emailResults = await emailQuery.get();
      
      final results = <UserProfile>[];
      final seenIds = <String>{};
      
      for (final doc in [...nameResults.docs, ...emailResults.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          results.add(UserProfile.fromJson({
            ...doc.data(),
            'id': doc.id,
          }));
        }
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  @override
  Future<List<UserProfile>> getByField(String field, dynamic value) async {
    try {
      final snapshot = await _firestoreService.firestore
          .collection(_collection)
          .where(field, isEqualTo: value)
          .get();
      
      return snapshot.docs
          .map((doc) => UserProfile.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by field: $e');
    }
  }

  @override
  Future<List<String>> saveAll(List<UserProfile> entities) async {
    try {
      final batch = _firestoreService.firestore.batch();
      final ids = <String>[];
      
      for (final entity in entities) {
        final data = entity.toFirestore();
        
        if (entity.id.isEmpty) {
          final docRef = _firestoreService.firestore
              .collection(_collection)
              .doc();
          batch.set(docRef, data);
          ids.add(docRef.id);
        } else {
          final docRef = _firestoreService.firestore
              .collection(_collection)
              .doc(entity.id);
          batch.set(docRef, data, SetOptions(merge: true));
          ids.add(entity.id);
        }
      }
      
      await batch.commit();
      return ids;
    } catch (e) {
      throw Exception('Failed to save all users: $e');
    }
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    try {
      final batch = _firestoreService.firestore.batch();
      
      for (final id in ids) {
        batch.delete(_firestoreService.firestore
            .collection(_collection)
            .doc(id));
        batch.delete(_firestoreService.firestore
            .collection(_authCollection)
            .doc(id));
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all users: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      // This is a dangerous operation - clear all users
      final batch = _firestoreService.firestore.batch();
      
      final snapshot = await _firestoreService.firestore
          .collection(_collection)
          .get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear users: $e');
    }
  }

  // User-specific methods

  @override
  Future<UserProfile?> getByEmail(String email) async {
    try {
      final snapshot = await _firestoreService.firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return UserProfile.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by email: $e');
    }
  }

  @override
  Future<List<UserProfile>> getByType(UserType userType) async {
    return getByField('userType', userType.value);
  }

  @override
  Future<List<UserProfile>> getActiveUsers() async {
    try {
      final authSnapshot = await _firestoreService.firestore
          .collection(_authCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      final activeUserIds = authSnapshot.docs.map((doc) => doc.id).toList();
      
      if (activeUserIds.isEmpty) return [];
      
      final users = <UserProfile>[];
      // Firestore 'in' query limit is 10, so we need to batch
      for (int i = 0; i < activeUserIds.length; i += 10) {
        final batch = activeUserIds.skip(i).take(10).toList();
        final snapshot = await _firestoreService.firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        users.addAll(snapshot.docs.map((doc) => UserProfile.fromJson({
          ...doc.data(),
          'id': doc.id,
        })));
      }
      
      return users;
    } catch (e) {
      throw Exception('Failed to get active users: $e');
    }
  }

  @override
  Future<List<UserProfile>> getInactiveUsers() async {
    try {
      final authSnapshot = await _firestoreService.firestore
          .collection(_authCollection)
          .where('isActive', isEqualTo: false)
          .get();
      
      final inactiveUserIds = authSnapshot.docs.map((doc) => doc.id).toList();
      
      if (inactiveUserIds.isEmpty) return [];
      
      final users = <UserProfile>[];
      for (int i = 0; i < inactiveUserIds.length; i += 10) {
        final batch = inactiveUserIds.skip(i).take(10).toList();
        final snapshot = await _firestoreService.firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        users.addAll(snapshot.docs.map((doc) => UserProfile.fromJson({
          ...doc.data(),
          'id': doc.id,
        })));
      }
      
      return users;
    } catch (e) {
      throw Exception('Failed to get inactive users: $e');
    }
  }

  @override
  Future<void> updateProfile(String userId, UserProfile profile) async {
    await save(profile.copyWith(id: userId));
  }

  @override
  Future<void> updateAuth(String userId, UserAuth auth) async {
    try {
      await _firestoreService.firestore
          .collection(_authCollection)
          .doc(userId)
          .set(auth.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user auth: $e');
    }
  }

  @override
  Future<UserAuth?> getAuthData(String userId) async {
    try {
      final doc = await _firestoreService.firestore
          .collection(_authCollection)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return UserAuth.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user auth data: $e');
    }
  }

  @override
  Future<void> verifyEmail(String userId) async {
    try {
      await _firestoreService.firestore
          .collection(_authCollection)
          .doc(userId)
          .update({'isEmailVerified': true});
    } catch (e) {
      throw Exception('Failed to verify email: $e');
    }
  }

  @override
  Future<void> activateUser(String userId) async {
    try {
      await _firestoreService.firestore
          .collection(_authCollection)
          .doc(userId)
          .update({'isActive': true});
    } catch (e) {
      throw Exception('Failed to activate user: $e');
    }
  }

  @override
  Future<void> deactivateUser(String userId) async {
    try {
      await _firestoreService.firestore
          .collection(_authCollection)
          .doc(userId)
          .update({
        'isActive': false,
        'sessionToken': null,
      });
    } catch (e) {
      throw Exception('Failed to deactivate user: $e');
    }
  }

  @override
  Future<bool> emailExists(String email) async {
    try {
      final snapshot = await _firestoreService.firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check email existence: $e');
    }
  }

  @override
  Future<List<UserProfile>> getRecentUsers({
    required Duration period,
    int? limit,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(period);
      
      Query query = _firestoreService.firestore
          .collection(_collection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserProfile.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent users: $e');
    }
  }

  @override
  Future<List<UserProfile>> getUsersByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _firestoreService.firestore
          .collection(_collection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => UserProfile.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by date range: $e');
    }
  }

  @override
  Future<List<UserProfile>> searchUsers(String query) async {
    return search(query);
  }

  @override
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final totalCount = await count();
      final activeUsers = await getActiveUsers();
      final recentUsers = await getRecentUsers(period: const Duration(days: 30));
      
      final customerCount = await _firestoreService.firestore
          .collection(_collection)
          .where('userType', isEqualTo: 'customer')
          .count()
          .get();
      
      final businessCount = await _firestoreService.firestore
          .collection(_collection)
          .where('userType', isEqualTo: 'business')
          .count()
          .get();
      
      final adminCount = await _firestoreService.firestore
          .collection(_collection)
          .where('userType', isEqualTo: 'admin')
          .count()
          .get();
      
      return {
        'totalUsers': totalCount,
        'activeUsers': activeUsers.length,
        'recentUsers': recentUsers.length,
        'customerCount': customerCount.count ?? 0,
        'businessCount': businessCount.count ?? 0,
        'adminCount': adminCount.count ?? 0,
        'inactiveUsers': totalCount - activeUsers.length,
      };
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }

  @override
  Future<void> bulkUpdate(Map<String, Map<String, dynamic>> updates) async {
    try {
      final batch = _firestoreService.firestore.batch();
      
      for (final entry in updates.entries) {
        final userId = entry.key;
        final data = entry.value;
        data['updatedAt'] = FieldValue.serverTimestamp();
        
        batch.update(
          _firestoreService.firestore.collection(_collection).doc(userId),
          data,
        );
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk update users: $e');
    }
  }

  @override
  Future<List<UserProfile>> getWithFilters({
    UserType? userType,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAfter,
    DateTime? createdBefore,
    int? limit,
    int? offset,
  }) async {
    try {
      Query query = _firestoreService.firestore.collection(_collection);
      
      if (userType != null) {
        query = query.where('userType', isEqualTo: userType.value);
      }
      
      if (createdAfter != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(createdAfter));
      }
      
      if (createdBefore != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(createdBefore));
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      // Note: Firestore doesn't support offset. Use limit only for pagination
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      var users = snapshot.docs
          .map((doc) => UserProfile.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
      
      // Filter by auth-related fields if needed
      if (isActive != null || isEmailVerified != null) {
        final userIds = users.map((u) => u.id).toList();
        final authData = <String, UserAuth>{};
        
        for (int i = 0; i < userIds.length; i += 10) {
          final batch = userIds.skip(i).take(10).toList();
          final authSnapshot = await _firestoreService.firestore
              .collection(_authCollection)
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          
          for (final doc in authSnapshot.docs) {
            authData[doc.id] = UserAuth.fromJson(doc.data());
          }
        }
        
        users = users.where((user) {
          final auth = authData[user.id];
          if (auth == null) return false;
          
          if (isActive != null && auth.isActive != isActive) return false;
          if (isEmailVerified != null && auth.isEmailVerified != isEmailVerified) return false;
          
          return true;
        }).toList();
      }
      
      return users;
    } catch (e) {
      throw Exception('Failed to get users with filters: $e');
    }
  }
} 