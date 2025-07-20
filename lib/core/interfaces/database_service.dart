import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstract database service interface
/// This allows switching between different database implementations
abstract class DatabaseService {
  /// Initialize the database service
  Future<void> initialize();

  /// Get a document by collection and ID
  Future<Map<String, dynamic>?> getDocument(String collection, String id);

  /// Get multiple documents from a collection
  Future<List<Map<String, dynamic>>> getCollection(String collection, {
    Map<String, dynamic>? where,
    String? orderBy,
    bool descending = false,
    int? limit,
    int? offset,
  });

  /// Save a document (create or update)
  Future<String> saveDocument(String collection, Map<String, dynamic> data, {String? id});

  /// Update a document
  Future<void> updateDocument(String collection, String id, Map<String, dynamic> data);

  /// Delete a document
  Future<void> deleteDocument(String collection, String id);

  /// Check if a document exists
  Future<bool> documentExists(String collection, String id);

  /// Count documents in a collection
  Future<int> countDocuments(String collection, {Map<String, dynamic>? where});

  /// Batch operations
  Future<void> batchWrite(List<BatchOperation> operations);

  /// Listen to document changes
  Stream<Map<String, dynamic>?> listenToDocument(String collection, String id);

  /// Listen to collection changes
  Stream<List<Map<String, dynamic>>> listenToCollection(String collection, {
    Map<String, dynamic>? where,
    String? orderBy,
    bool descending = false,
    int? limit,
  });

  /// Search documents (if supported)
  Future<List<Map<String, dynamic>>> searchDocuments(String collection, String query, List<String> fields);

  /// Transaction support
  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) action);

  /// Close the database connection
  Future<void> close();
}

/// Batch operation for bulk writes
class BatchOperation {
  final String type; // 'set', 'update', 'delete'
  final String collection;
  final String? id;
  final Map<String, dynamic>? data;

  const BatchOperation({
    required this.type,
    required this.collection,
    this.id,
    this.data,
  });

  factory BatchOperation.set(String collection, String id, Map<String, dynamic> data) {
    return BatchOperation(type: 'set', collection: collection, id: id, data: data);
  }

  factory BatchOperation.update(String collection, String id, Map<String, dynamic> data) {
    return BatchOperation(type: 'update', collection: collection, id: id, data: data);
  }

  factory BatchOperation.delete(String collection, String id) {
    return BatchOperation(type: 'delete', collection: collection, id: id);
  }
}

/// Database transaction interface
abstract class Transaction {
  Future<Map<String, dynamic>?> get(String collection, String id);
  void set(String collection, String id, Map<String, dynamic> data);
  void update(String collection, String id, Map<String, dynamic> data);
  void delete(String collection, String id);
} 