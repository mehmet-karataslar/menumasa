import 'package:cloud_firestore/cloud_firestore.dart';

/// Stock management models for inventory tracking
class StockItem {
  final String stockId;
  final String businessId;
  final String productId;
  final String productName;
  final String unit; // adet, kg, lt, etc.
  final double currentStock;
  final double minimumStock;
  final double maximumStock;
  final double reorderLevel;
  final double unitCost;
  final String? supplierId;
  final String? supplierName;
  final DateTime lastRestocked;
  final DateTime? expiryDate;
  final String? batchNumber;
  final StockStatus status;
  final List<StockMovement> movements;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StockItem({
    required this.stockId,
    required this.businessId,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumStock,
    required this.reorderLevel,
    required this.unitCost,
    this.supplierId,
    this.supplierName,
    required this.lastRestocked,
    this.expiryDate,
    this.batchNumber,
    required this.status,
    this.movements = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory StockItem.create({
    required String businessId,
    required String productId,
    required String productName,
    required String unit,
    required double currentStock,
    required double minimumStock,
    required double maximumStock,
    required double unitCost,
    String? supplierId,
    String? supplierName,
    DateTime? expiryDate,
    String? batchNumber,
  }) {
    final now = DateTime.now();
    return StockItem(
      stockId: 'stock_${now.millisecondsSinceEpoch}',
      businessId: businessId,
      productId: productId,
      productName: productName,
      unit: unit,
      currentStock: currentStock,
      minimumStock: minimumStock,
      maximumStock: maximumStock,
      reorderLevel: minimumStock * 1.5, // Auto-calculate reorder level
      unitCost: unitCost,
      supplierId: supplierId,
      supplierName: supplierName,
      lastRestocked: now,
      expiryDate: expiryDate,
      batchNumber: batchNumber,
      status: _calculateStatus(currentStock, minimumStock, expiryDate),
      createdAt: now,
      updatedAt: now,
    );
  }

  static StockStatus _calculateStatus(double currentStock, double minimumStock, DateTime? expiryDate) {
    // Check expiry first
    if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
      return StockStatus.expired;
    }
    
    // Check expiry warning (7 days)
    if (expiryDate != null && expiryDate.isBefore(DateTime.now().add(const Duration(days: 7)))) {
      return StockStatus.nearExpiry;
    }

    // Check stock levels
    if (currentStock <= 0) {
      return StockStatus.outOfStock;
    } else if (currentStock <= minimumStock) {
      return StockStatus.lowStock;
    } else {
      return StockStatus.inStock;
    }
  }

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      stockId: json['stockId'] ?? '',
      businessId: json['businessId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      unit: json['unit'] ?? 'adet',
      currentStock: (json['currentStock'] ?? 0.0).toDouble(),
      minimumStock: (json['minimumStock'] ?? 0.0).toDouble(),
      maximumStock: (json['maximumStock'] ?? 0.0).toDouble(),
      reorderLevel: (json['reorderLevel'] ?? 0.0).toDouble(),
      unitCost: (json['unitCost'] ?? 0.0).toDouble(),
      supplierId: json['supplierId'],
      supplierName: json['supplierName'],
      lastRestocked: _parseDateTime(json['lastRestocked']),
      expiryDate: json['expiryDate'] != null ? _parseDateTime(json['expiryDate']) : null,
      batchNumber: json['batchNumber'],
      status: StockStatus.fromString(json['status'] ?? 'in_stock'),
      movements: (json['movements'] as List<dynamic>? ?? [])
          .map((movement) => StockMovement.fromJson(movement))
          .toList(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockId': stockId,
      'businessId': businessId,
      'productId': productId,
      'productName': productName,
      'unit': unit,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'reorderLevel': reorderLevel,
      'unitCost': unitCost,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'lastRestocked': lastRestocked.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'batchNumber': batchNumber,
      'status': status.value,
      'movements': movements.map((movement) => movement.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data['lastRestocked'] = Timestamp.fromDate(lastRestocked);
    data['createdAt'] = Timestamp.fromDate(createdAt);
    data['updatedAt'] = Timestamp.fromDate(updatedAt);
    if (expiryDate != null) {
      data['expiryDate'] = Timestamp.fromDate(expiryDate!);
    }
    return data;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    
    return DateTime.now();
  }

  // Business logic methods
  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;
  bool get needsReorder => currentStock <= reorderLevel;
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isNearExpiry => expiryDate != null && 
      expiryDate!.isBefore(DateTime.now().add(const Duration(days: 7)));

  double get stockValue => currentStock * unitCost;
  double get daysUntilExpiry => expiryDate != null 
      ? expiryDate!.difference(DateTime.now()).inDays.toDouble()
      : double.infinity;

  StockItem updateStock(double newStock, StockMovementType movementType, {
    String? reason,
    String? reference,
    String? userId,
  }) {
    final movement = StockMovement.create(
      stockId: stockId,
      movementType: movementType,
      quantity: newStock - currentStock,
      newStock: newStock,
      reason: reason,
      reference: reference,
      userId: userId,
    );

    final updatedMovements = [...movements, movement];
    final newStatus = _calculateStatus(newStock, minimumStock, expiryDate);

    return copyWith(
      currentStock: newStock,
      status: newStatus,
      movements: updatedMovements,
      updatedAt: DateTime.now(),
      lastRestocked: movementType == StockMovementType.stockIn ? DateTime.now() : lastRestocked,
    );
  }

  StockItem copyWith({
    String? stockId,
    String? businessId,
    String? productId,
    String? productName,
    String? unit,
    double? currentStock,
    double? minimumStock,
    double? maximumStock,
    double? reorderLevel,
    double? unitCost,
    String? supplierId,
    String? supplierName,
    DateTime? lastRestocked,
    DateTime? expiryDate,
    String? batchNumber,
    StockStatus? status,
    List<StockMovement>? movements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockItem(
      stockId: stockId ?? this.stockId,
      businessId: businessId ?? this.businessId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      unitCost: unitCost ?? this.unitCost,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      status: status ?? this.status,
      movements: movements ?? this.movements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'StockItem(stockId: $stockId, productName: $productName, currentStock: $currentStock, status: ${status.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockItem && other.stockId == stockId;
  }

  @override
  int get hashCode => stockId.hashCode;
}

/// Stock movement tracking for audit trail
class StockMovement {
  final String movementId;
  final String stockId;
  final StockMovementType movementType;
  final double quantity; // Positive for in, negative for out
  final double previousStock;
  final double newStock;
  final String? reason;
  final String? reference; // Order ID, purchase ID, etc.
  final String? userId;
  final String? userName;
  final DateTime timestamp;

  const StockMovement({
    required this.movementId,
    required this.stockId,
    required this.movementType,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.reason,
    this.reference,
    this.userId,
    this.userName,
    required this.timestamp,
  });

  factory StockMovement.create({
    required String stockId,
    required StockMovementType movementType,
    required double quantity,
    required double newStock,
    String? reason,
    String? reference,
    String? userId,
    String? userName,
  }) {
    final now = DateTime.now();
    return StockMovement(
      movementId: 'movement_${now.millisecondsSinceEpoch}',
      stockId: stockId,
      movementType: movementType,
      quantity: quantity,
      previousStock: newStock - quantity,
      newStock: newStock,
      reason: reason,
      reference: reference,
      userId: userId,
      userName: userName,
      timestamp: now,
    );
  }

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      movementId: json['movementId'] ?? '',
      stockId: json['stockId'] ?? '',
      movementType: StockMovementType.fromString(json['movementType'] ?? 'adjustment'),
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      previousStock: (json['previousStock'] ?? 0.0).toDouble(),
      newStock: (json['newStock'] ?? 0.0).toDouble(),
      reason: json['reason'],
      reference: json['reference'],
      userId: json['userId'],
      userName: json['userName'],
      timestamp: StockItem._parseDateTime(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movementId': movementId,
      'stockId': stockId,
      'movementType': movementType.value,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'reason': reason,
      'reference': reference,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data['timestamp'] = Timestamp.fromDate(timestamp);
    return data;
  }

  @override
  String toString() {
    return 'StockMovement(${movementType.displayName}: ${quantity > 0 ? '+' : ''}$quantity)';
  }
}

/// Stock alert for notifications
class StockAlert {
  final String alertId;
  final String businessId;
  final String stockId;
  final String productName;
  final StockAlertType alertType;
  final String message;
  final double currentStock;
  final double? threshold;
  final DateTime? expiryDate;
  final AlertPriority priority;
  final bool isRead;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const StockAlert({
    required this.alertId,
    required this.businessId,
    required this.stockId,
    required this.productName,
    required this.alertType,
    required this.message,
    required this.currentStock,
    this.threshold,
    this.expiryDate,
    required this.priority,
    this.isRead = false,
    this.isResolved = false,
    required this.createdAt,
    this.resolvedAt,
  });

  factory StockAlert.lowStock({
    required String businessId,
    required String stockId,
    required String productName,
    required double currentStock,
    required double minimumStock,
  }) {
    return StockAlert(
      alertId: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      stockId: stockId,
      productName: productName,
      alertType: StockAlertType.lowStock,
      message: '$productName stok seviyesi düşük (${currentStock.toStringAsFixed(1)})',
      currentStock: currentStock,
      threshold: minimumStock,
      priority: AlertPriority.medium,
      createdAt: DateTime.now(),
    );
  }

  factory StockAlert.outOfStock({
    required String businessId,
    required String stockId,
    required String productName,
  }) {
    return StockAlert(
      alertId: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      stockId: stockId,
      productName: productName,
      alertType: StockAlertType.outOfStock,
      message: '$productName stokta yok!',
      currentStock: 0,
      priority: AlertPriority.high,
      createdAt: DateTime.now(),
    );
  }

  factory StockAlert.nearExpiry({
    required String businessId,
    required String stockId,
    required String productName,
    required DateTime expiryDate,
    required double currentStock,
  }) {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    return StockAlert(
      alertId: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      stockId: stockId,
      productName: productName,
      alertType: StockAlertType.nearExpiry,
      message: '$productName $daysUntilExpiry gün içinde son kullanma tarihi dolacak',
      currentStock: currentStock,
      expiryDate: expiryDate,
      priority: AlertPriority.medium,
      createdAt: DateTime.now(),
    );
  }

  factory StockAlert.expired({
    required String businessId,
    required String stockId,
    required String productName,
    required DateTime expiryDate,
    required double currentStock,
  }) {
    return StockAlert(
      alertId: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      stockId: stockId,
      productName: productName,
      alertType: StockAlertType.expired,
      message: '$productName son kullanma tarihi geçmiş!',
      currentStock: currentStock,
      expiryDate: expiryDate,
      priority: AlertPriority.high,
      createdAt: DateTime.now(),
    );
  }

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      alertId: json['alertId'] ?? '',
      businessId: json['businessId'] ?? '',
      stockId: json['stockId'] ?? '',
      productName: json['productName'] ?? '',
      alertType: StockAlertType.fromString(json['alertType'] ?? 'low_stock'),
      message: json['message'] ?? '',
      currentStock: (json['currentStock'] ?? 0.0).toDouble(),
      threshold: json['threshold'] != null ? (json['threshold'] as num).toDouble() : null,
      expiryDate: json['expiryDate'] != null ? StockItem._parseDateTime(json['expiryDate']) : null,
      priority: AlertPriority.fromString(json['priority'] ?? 'medium'),
      isRead: json['isRead'] ?? false,
      isResolved: json['isResolved'] ?? false,
      createdAt: StockItem._parseDateTime(json['createdAt']),
      resolvedAt: json['resolvedAt'] != null ? StockItem._parseDateTime(json['resolvedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'businessId': businessId,
      'stockId': stockId,
      'productName': productName,
      'alertType': alertType.value,
      'message': message,
      'currentStock': currentStock,
      'threshold': threshold,
      'expiryDate': expiryDate?.toIso8601String(),
      'priority': priority.value,
      'isRead': isRead,
      'isResolved': isResolved,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  StockAlert markAsRead() => copyWith(isRead: true);
  StockAlert markAsResolved() => copyWith(isResolved: true, resolvedAt: DateTime.now());

  StockAlert copyWith({
    String? alertId,
    String? businessId,
    String? stockId,
    String? productName,
    StockAlertType? alertType,
    String? message,
    double? currentStock,
    double? threshold,
    DateTime? expiryDate,
    AlertPriority? priority,
    bool? isRead,
    bool? isResolved,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return StockAlert(
      alertId: alertId ?? this.alertId,
      businessId: businessId ?? this.businessId,
      stockId: stockId ?? this.stockId,
      productName: productName ?? this.productName,
      alertType: alertType ?? this.alertType,
      message: message ?? this.message,
      currentStock: currentStock ?? this.currentStock,
      threshold: threshold ?? this.threshold,
      expiryDate: expiryDate ?? this.expiryDate,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

// Enums

enum StockStatus {
  inStock('in_stock', 'Stokta Var'),
  lowStock('low_stock', 'Düşük Stok'),
  outOfStock('out_of_stock', 'Stokta Yok'),
  nearExpiry('near_expiry', 'Son Kullanma Tarihi Yaklaşıyor'),
  expired('expired', 'Son Kullanma Tarihi Geçmiş');

  const StockStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static StockStatus fromString(String value) {
    return StockStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StockStatus.inStock,
    );
  }
}

enum StockMovementType {
  stockIn('stock_in', 'Stok Girişi'),
  stockOut('stock_out', 'Stok Çıkışı'),
  sale('sale', 'Satış'),
  waste('waste', 'Fire'),
  adjustment('adjustment', 'Düzeltme'),
  transfer('transfer', 'Transfer'),
  return_('return', 'İade');

  const StockMovementType(this.value, this.displayName);
  final String value;
  final String displayName;

  static StockMovementType fromString(String value) {
    return StockMovementType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => StockMovementType.adjustment,
    );
  }
}

enum StockAlertType {
  lowStock('low_stock', 'Düşük Stok'),
  outOfStock('out_of_stock', 'Stokta Yok'),
  nearExpiry('near_expiry', 'Son Kullanma Tarihi Yaklaşıyor'),
  expired('expired', 'Süresi Geçmiş'),
  reorderNeeded('reorder_needed', 'Sipariş Gerekli');

  const StockAlertType(this.value, this.displayName);
  final String value;
  final String displayName;

  static StockAlertType fromString(String value) {
    return StockAlertType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => StockAlertType.lowStock,
    );
  }
}

enum AlertPriority {
  low('low', 'Düşük'),
  medium('medium', 'Orta'),
  high('high', 'Yüksek'),
  critical('critical', 'Kritik');

  const AlertPriority(this.value, this.displayName);
  final String value;
  final String displayName;

  static AlertPriority fromString(String value) {
    return AlertPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => AlertPriority.medium,
    );
  }
} 