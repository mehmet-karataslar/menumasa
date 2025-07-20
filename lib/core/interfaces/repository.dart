/// Base repository interface for common CRUD operations
abstract class Repository<T, ID> {
  /// Get an entity by its ID
  Future<T?> getById(ID id);

  /// Get all entities
  Future<List<T>> getAll();

  /// Save an entity (create or update)
  Future<ID> save(T entity);

  /// Update an entity
  Future<void> update(ID id, Map<String, dynamic> data);

  /// Delete an entity by ID
  Future<void> delete(ID id);

  /// Check if entity exists
  Future<bool> exists(ID id);

  /// Count total entities
  Future<int> count();

  /// Get entities with pagination
  Future<List<T>> getPage({
    int page = 0,
    int size = 10,
    String? sortBy,
    bool descending = false,
  });

  /// Search entities
  Future<List<T>> search(String query);

  /// Get entities by field value
  Future<List<T>> getByField(String field, dynamic value);

  /// Batch save entities
  Future<List<ID>> saveAll(List<T> entities);

  /// Batch delete entities
  Future<void> deleteAll(List<ID> ids);

  /// Clear all entities (use with caution)
  Future<void> clear();
} 