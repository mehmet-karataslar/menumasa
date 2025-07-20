import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_models.dart';
import 'business_firestore_service.dart';

/// Stock management service for inventory control
class StockService {
  static final StockService _instance = StockService._internal();
  factory StockService() => _instance;
  StockService._internal();

  final BusinessFirestoreService _businessFirestoreService = BusinessFirestoreService();
  final String _stockCollection = 'stock_items';
  final String _movementsCollection = 'stock_movements';
  final String _alertsCollection = 'stock_alerts';

  // Stock listeners
  final List<Function(List<StockItem>)> _stockListeners = [];
  final List<Function(List<StockAlert>)> _alertListeners = [];

  void addStockListener(Function(List<StockItem>) listener) {
    _stockListeners.add(listener);
  }

  void removeStockListener(Function(List<StockItem>) listener) {
    _stockListeners.remove(listener);
  }

  void addAlertListener(Function(List<StockAlert>) listener) {
    _alertListeners.add(listener);
  }

  void removeAlertListener(Function(List<StockAlert>) listener) {
    _alertListeners.remove(listener);
  }

  void _notifyStockListeners(String businessId) async {
    final stocks = await getBusinessStock(businessId);
    for (final listener in _stockListeners) {
      listener(stocks);
    }
  }

  void _notifyAlertListeners(String businessId) async {
    final alerts = await getActiveAlerts(businessId);
    for (final listener in _alertListeners) {
      listener(alerts);
    }
  }

  /// Get all stock items for a business
  Future<List<StockItem>> getBusinessStock(String businessId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_stockCollection)
          .where('businessId', isEqualTo: businessId)
          .orderBy('productName')
          .get();

      return snapshot.docs
          .map((doc) => StockItem.fromJson({
                ...doc.data(),
                'stockId': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch business stock: $e');
    }
  }

  /// Get stock item by ID
  Future<StockItem?> getStockItem(String stockId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_stockCollection)
          .doc(stockId)
          .get();

      if (doc.exists) {
        return StockItem.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'stockId': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch stock item: $e');
    }
  }

  /// Get stock item by product ID
  Future<StockItem?> getStockByProductId(String businessId, String productId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_stockCollection)
          .where('businessId', isEqualTo: businessId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return StockItem.fromJson({
          ...doc.data(),
          'stockId': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch stock by product ID: $e');
    }
  }

  /// Create new stock item
  Future<String> createStockItem(StockItem stockItem) async {
    try {
      final data = stockItem.toFirestore();
      data.remove('stockId'); // Remove ID for auto-generation
      
      final docRef = await FirebaseFirestore.instance
          .collection(_stockCollection)
          .add(data);

      // Record initial stock movement
      await _recordStockMovement(
        stockId: docRef.id,
        movementType: StockMovementType.stockIn,
        quantity: stockItem.currentStock,
        newStock: stockItem.currentStock,
        reason: 'Initial stock entry',
      );

      _notifyStockListeners(stockItem.businessId);
      await _checkAndCreateAlerts(stockItem.businessId, docRef.id);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create stock item: $e');
    }
  }

  /// Update stock item
  Future<void> updateStockItem(StockItem stockItem) async {
    try {
      final data = stockItem.toFirestore();
      data.remove('stockId');
      
      await FirebaseFirestore.instance
          .collection(_stockCollection)
          .doc(stockItem.stockId)
          .update(data);

      _notifyStockListeners(stockItem.businessId);
      await _checkAndCreateAlerts(stockItem.businessId, stockItem.stockId);
    } catch (e) {
      throw Exception('Failed to update stock item: $e');
    }
  }

  /// Update stock quantity
  Future<void> updateStock({
    required String stockId,
    required double newQuantity,
    required StockMovementType movementType,
    String? reason,
    String? reference,
    String? userId,
  }) async {
    try {
      final stockItem = await getStockItem(stockId);
      if (stockItem == null) {
        throw Exception('Stock item not found');
      }

      final quantityChange = newQuantity - stockItem.currentStock;
      final updatedStock = stockItem.updateStock(
        newQuantity,
        movementType,
        reason: reason,
        reference: reference,
        userId: userId,
      );

      await updateStockItem(updatedStock);
      
      await _recordStockMovement(
        stockId: stockId,
        movementType: movementType,
        quantity: quantityChange,
        newStock: newQuantity,
        reason: reason,
        reference: reference,
        userId: userId,
      );

      _notifyStockListeners(stockItem.businessId);
      await _checkAndCreateAlerts(stockItem.businessId, stockId);
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  /// Reduce stock (for sales)
  Future<bool> reduceStock({
    required String businessId,
    required String productId,
    required double quantity,
    String? orderId,
    String? userId,
  }) async {
    try {
      final stockItem = await getStockByProductId(businessId, productId);
      if (stockItem == null) {
        throw Exception('Stock item not found for product: $productId');
      }

      if (stockItem.currentStock < quantity) {
        // Not enough stock
        return false;
      }

      final newQuantity = stockItem.currentStock - quantity;
      await updateStock(
        stockId: stockItem.stockId,
        newQuantity: newQuantity,
        movementType: StockMovementType.sale,
        reason: 'Order sale',
        reference: orderId,
        userId: userId,
      );

      return true;
    } catch (e) {
      throw Exception('Failed to reduce stock: $e');
    }
  }

  /// Add stock (for restocking)
  Future<void> addStock({
    required String stockId,
    required double quantity,
    String? reason,
    String? reference,
    String? userId,
  }) async {
    try {
      final stockItem = await getStockItem(stockId);
      if (stockItem == null) {
        throw Exception('Stock item not found');
      }

      final newQuantity = stockItem.currentStock + quantity;
      await updateStock(
        stockId: stockId,
        newQuantity: newQuantity,
        movementType: StockMovementType.stockIn,
        reason: reason ?? 'Stock replenishment',
        reference: reference,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Failed to add stock: $e');
    }
  }

  /// Delete stock item
  Future<void> deleteStockItem(String stockId) async {
    try {
      final stockItem = await getStockItem(stockId);
      if (stockItem == null) return;

      // Delete movements first
      final movementsSnapshot = await FirebaseFirestore.instance
          .collection(_movementsCollection)
          .where('stockId', isEqualTo: stockId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in movementsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete alerts
      final alertsSnapshot = await FirebaseFirestore.instance
          .collection(_alertsCollection)
          .where('stockId', isEqualTo: stockId)
          .get();

      for (final doc in alertsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete stock item
      batch.delete(FirebaseFirestore.instance.collection(_stockCollection).doc(stockId));

      await batch.commit();
      _notifyStockListeners(stockItem.businessId);
    } catch (e) {
      throw Exception('Failed to delete stock item: $e');
    }
  }

  /// Get stock movements for a stock item
  Future<List<StockMovement>> getStockMovements(String stockId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_movementsCollection)
          .where('stockId', isEqualTo: stockId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StockMovement.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch stock movements: $e');
    }
  }

  /// Get low stock items
  Future<List<StockItem>> getLowStockItems(String businessId) async {
    try {
      final allStock = await getBusinessStock(businessId);
      return allStock.where((item) => item.isLowStock).toList();
    } catch (e) {
      throw Exception('Failed to fetch low stock items: $e');
    }
  }

  /// Get out of stock items
  Future<List<StockItem>> getOutOfStockItems(String businessId) async {
    try {
      final allStock = await getBusinessStock(businessId);
      return allStock.where((item) => item.isOutOfStock).toList();
    } catch (e) {
      throw Exception('Failed to fetch out of stock items: $e');
    }
  }

  /// Get expiring items
  Future<List<StockItem>> getExpiringItems(String businessId, {int daysAhead = 7}) async {
    try {
      final allStock = await getBusinessStock(businessId);
      final cutoffDate = DateTime.now().add(Duration(days: daysAhead));
      
      return allStock.where((item) => 
          item.expiryDate != null && 
          item.expiryDate!.isBefore(cutoffDate) &&
          !item.isExpired
      ).toList();
    } catch (e) {
      throw Exception('Failed to fetch expiring items: $e');
    }
  }

  /// Get expired items
  Future<List<StockItem>> getExpiredItems(String businessId) async {
    try {
      final allStock = await getBusinessStock(businessId);
      return allStock.where((item) => item.isExpired).toList();
    } catch (e) {
      throw Exception('Failed to fetch expired items: $e');
    }
  }

  /// Get stock alerts
  Future<List<StockAlert>> getActiveAlerts(String businessId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_alertsCollection)
          .where('businessId', isEqualTo: businessId)
          .where('isResolved', isEqualTo: false)
          .orderBy('priority')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StockAlert.fromJson({
                ...doc.data(),
                'alertId': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch stock alerts: $e');
    }
  }

  /// Get stock statistics
  Future<Map<String, dynamic>> getStockStatistics(String businessId) async {
    try {
      final allStock = await getBusinessStock(businessId);
      
      final totalItems = allStock.length;
      final lowStockItems = allStock.where((item) => item.isLowStock).length;
      final outOfStockItems = allStock.where((item) => item.isOutOfStock).length;
      final expiringItems = allStock.where((item) => item.isNearExpiry).length;
      final expiredItems = allStock.where((item) => item.isExpired).length;
      
      final totalValue = allStock.fold(0.0, (sum, item) => sum + item.stockValue);
      final averageStockLevel = totalItems > 0 
          ? allStock.fold(0.0, (sum, item) => sum + item.currentStock) / totalItems
          : 0.0;

      return {
        'totalItems': totalItems,
        'lowStockItems': lowStockItems,
        'outOfStockItems': outOfStockItems,
        'expiringItems': expiringItems,
        'expiredItems': expiredItems,
        'totalValue': totalValue,
        'averageStockLevel': averageStockLevel,
        'stockTurnover': 0.0, // TODO: Calculate turnover
        'reorderNeeded': allStock.where((item) => item.needsReorder).length,
      };
    } catch (e) {
      throw Exception('Failed to calculate stock statistics: $e');
    }
  }

  /// Mark alert as read
  Future<void> markAlertAsRead(String alertId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_alertsCollection)
          .doc(alertId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark alert as read: $e');
    }
  }

  /// Mark alert as resolved
  Future<void> markAlertAsResolved(String alertId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_alertsCollection)
          .doc(alertId)
          .update({
        'isResolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark alert as resolved: $e');
    }
  }

  /// Search stock items
  Future<List<StockItem>> searchStock(String businessId, String query) async {
    try {
      final allStock = await getBusinessStock(businessId);
      final lowerQuery = query.toLowerCase();
      
      return allStock.where((item) =>
          item.productName.toLowerCase().contains(lowerQuery) ||
          item.productId.toLowerCase().contains(lowerQuery) ||
          (item.batchNumber?.toLowerCase().contains(lowerQuery) ?? false)
      ).toList();
    } catch (e) {
      throw Exception('Failed to search stock: $e');
    }
  }

  /// Auto-check and create alerts for all stock items
  Future<void> checkAllAlerts(String businessId) async {
    try {
      final allStock = await getBusinessStock(businessId);
      
      for (final stockItem in allStock) {
        await _checkAndCreateAlerts(businessId, stockItem.stockId);
      }
      
      _notifyAlertListeners(businessId);
    } catch (e) {
      throw Exception('Failed to check alerts: $e');
    }
  }

  // Private helper methods

  Future<void> _recordStockMovement({
    required String stockId,
    required StockMovementType movementType,
    required double quantity,
    required double newStock,
    String? reason,
    String? reference,
    String? userId,
  }) async {
    try {
      final movement = StockMovement.create(
        stockId: stockId,
        movementType: movementType,
        quantity: quantity,
        newStock: newStock,
        reason: reason,
        reference: reference,
        userId: userId,
      );

      await FirebaseFirestore.instance
          .collection(_movementsCollection)
          .add(movement.toFirestore());
    } catch (e) {
      throw Exception('Failed to record stock movement: $e');
    }
  }

  Future<void> _checkAndCreateAlerts(String businessId, String stockId) async {
    try {
      final stockItem = await getStockItem(stockId);
      if (stockItem == null) return;

      // Remove existing alerts for this stock item
      final existingAlerts = await FirebaseFirestore.instance
          .collection(_alertsCollection)
          .where('stockId', isEqualTo: stockId)
          .where('isResolved', isEqualTo: false)
          .get();

      for (final doc in existingAlerts.docs) {
        await doc.reference.delete();
      }

      final alerts = <StockAlert>[];

      // Check for out of stock
      if (stockItem.isOutOfStock) {
        alerts.add(StockAlert.outOfStock(
          businessId: businessId,
          stockId: stockId,
          productName: stockItem.productName,
        ));
      }
      // Check for low stock
      else if (stockItem.isLowStock) {
        alerts.add(StockAlert.lowStock(
          businessId: businessId,
          stockId: stockId,
          productName: stockItem.productName,
          currentStock: stockItem.currentStock,
          minimumStock: stockItem.minimumStock,
        ));
      }

      // Check for expiry
      if (stockItem.isExpired) {
        alerts.add(StockAlert.expired(
          businessId: businessId,
          stockId: stockId,
          productName: stockItem.productName,
          expiryDate: stockItem.expiryDate!,
          currentStock: stockItem.currentStock,
        ));
      } else if (stockItem.isNearExpiry) {
        alerts.add(StockAlert.nearExpiry(
          businessId: businessId,
          stockId: stockId,
          productName: stockItem.productName,
          expiryDate: stockItem.expiryDate!,
          currentStock: stockItem.currentStock,
        ));
      }

      // Save alerts
      for (final alert in alerts) {
        final data = alert.toJson();
        data.remove('alertId');
        await FirebaseFirestore.instance
            .collection(_alertsCollection)
            .add(data);
      }

      if (alerts.isNotEmpty) {
        _notifyAlertListeners(businessId);
      }
    } catch (e) {
      throw Exception('Failed to check and create alerts: $e');
    }
  }

  /// Bulk stock update
  Future<void> bulkUpdateStock(List<Map<String, dynamic>> updates) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final update in updates) {
        final stockId = update['stockId'] as String;
        final newQuantity = update['quantity'] as double;
        final movementType = StockMovementType.fromString(update['movementType'] ?? 'adjustment');
        
        final stockRef = FirebaseFirestore.instance.collection(_stockCollection).doc(stockId);
        batch.update(stockRef, {
          'currentStock': newQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Record movement
        final movementData = StockMovement.create(
          stockId: stockId,
          movementType: movementType,
          quantity: newQuantity,
          newStock: newQuantity,
          reason: update['reason'],
        ).toFirestore();
        
        batch.set(FirebaseFirestore.instance.collection(_movementsCollection).doc(), movementData);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk update stock: $e');
    }
  }

  /// Export stock data
  Future<Map<String, dynamic>> exportStockData(String businessId) async {
    try {
      final stocks = await getBusinessStock(businessId);
      final movements = <StockMovement>[];
      
      for (final stock in stocks) {
        final stockMovements = await getStockMovements(stock.stockId);
        movements.addAll(stockMovements);
      }
      
      final alerts = await getActiveAlerts(businessId);
      final stats = await getStockStatistics(businessId);
      
      return {
        'stocks': stocks.map((s) => s.toJson()).toList(),
        'movements': movements.map((m) => m.toJson()).toList(),
        'alerts': alerts.map((a) => a.toJson()).toList(),
        'statistics': stats,
        'exportDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to export stock data: $e');
    }
  }
} 