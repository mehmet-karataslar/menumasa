import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive business analytics data model
class BusinessAnalytics {
  final String businessId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final OrderAnalytics orderAnalytics;
  final ProductAnalytics productAnalytics;
  final CustomerAnalytics customerAnalytics;
  final RevenueAnalytics revenueAnalytics;
  final PerformanceAnalytics performanceAnalytics;
  final PeakHoursAnalytics peakHoursAnalytics;
  final TableAnalytics tableAnalytics;
  final StaffAnalytics staffAnalytics;

  const BusinessAnalytics({
    required this.businessId,
    required this.periodStart,
    required this.periodEnd,
    required this.orderAnalytics,
    required this.productAnalytics,
    required this.customerAnalytics,
    required this.revenueAnalytics,
    required this.performanceAnalytics,
    required this.peakHoursAnalytics,
    required this.tableAnalytics,
    required this.staffAnalytics,
  });

  factory BusinessAnalytics.fromJson(Map<String, dynamic> json) {
    return BusinessAnalytics(
      businessId: json['businessId'] ?? '',
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      orderAnalytics: OrderAnalytics.fromJson(json['orderAnalytics'] ?? {}),
      productAnalytics: ProductAnalytics.fromJson(json['productAnalytics'] ?? {}),
      customerAnalytics: CustomerAnalytics.fromJson(json['customerAnalytics'] ?? {}),
      revenueAnalytics: RevenueAnalytics.fromJson(json['revenueAnalytics'] ?? {}),
      performanceAnalytics: PerformanceAnalytics.fromJson(json['performanceAnalytics'] ?? {}),
      peakHoursAnalytics: PeakHoursAnalytics.fromJson(json['peakHoursAnalytics'] ?? {}),
      tableAnalytics: TableAnalytics.fromJson(json['tableAnalytics'] ?? {}),
      staffAnalytics: StaffAnalytics.fromJson(json['staffAnalytics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'orderAnalytics': orderAnalytics.toJson(),
      'productAnalytics': productAnalytics.toJson(),
      'customerAnalytics': customerAnalytics.toJson(),
      'revenueAnalytics': revenueAnalytics.toJson(),
      'performanceAnalytics': performanceAnalytics.toJson(),
      'peakHoursAnalytics': peakHoursAnalytics.toJson(),
      'tableAnalytics': tableAnalytics.toJson(),
      'staffAnalytics': staffAnalytics.toJson(),
    };
  }
}

/// Order analytics - Sipariş analitikleri
class OrderAnalytics {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int pendingOrders;
  final double averageOrderValue;
  final double averagePreparationTime; // minutes
  final Map<String, int> ordersByHour; // hour -> count
  final Map<String, int> ordersByDay; // date -> count
  final Map<String, int> ordersByStatus; // status -> count
  final List<OrderTimeAnalysis> orderTimeBreakdown;

  const OrderAnalytics({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.pendingOrders,
    required this.averageOrderValue,
    required this.averagePreparationTime,
    required this.ordersByHour,
    required this.ordersByDay,
    required this.ordersByStatus,
    required this.orderTimeBreakdown,
  });

  factory OrderAnalytics.fromJson(Map<String, dynamic> json) {
    return OrderAnalytics(
      totalOrders: json['totalOrders'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      cancelledOrders: json['cancelledOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0.0).toDouble(),
      averagePreparationTime: (json['averagePreparationTime'] ?? 0.0).toDouble(),
      ordersByHour: Map<String, int>.from(json['ordersByHour'] ?? {}),
      ordersByDay: Map<String, int>.from(json['ordersByDay'] ?? {}),
      ordersByStatus: Map<String, int>.from(json['ordersByStatus'] ?? {}),
      orderTimeBreakdown: (json['orderTimeBreakdown'] as List<dynamic>? ?? [])
          .map((item) => OrderTimeAnalysis.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'pendingOrders': pendingOrders,
      'averageOrderValue': averageOrderValue,
      'averagePreparationTime': averagePreparationTime,
      'ordersByHour': ordersByHour,
      'ordersByDay': ordersByDay,
      'ordersByStatus': ordersByStatus,
      'orderTimeBreakdown': orderTimeBreakdown.map((item) => item.toJson()).toList(),
    };
  }

  // Computed properties
  double get completionRate => totalOrders > 0 ? completedOrders / totalOrders : 0.0;
  double get cancellationRate => totalOrders > 0 ? cancelledOrders / totalOrders : 0.0;
  String get peakHour => ordersByHour.entries.isEmpty ? '' : 
      ordersByHour.entries.reduce((a, b) => a.value > b.value ? a : b).key;
}

/// Product analytics - Ürün analitikleri
class ProductAnalytics {
  final int totalProducts;
  final int activeProducts;
  final int outOfStockProducts;
  final Map<String, ProductPerformance> topSellingProducts;
  final Map<String, int> productSales; // productId -> sales count
  final Map<String, double> productRevenue; // productId -> revenue
  final Map<String, int> categorySales; // categoryId -> sales count
  final List<String> lowPerformingProducts;

  const ProductAnalytics({
    required this.totalProducts,
    required this.activeProducts,
    required this.outOfStockProducts,
    required this.topSellingProducts,
    required this.productSales,
    required this.productRevenue,
    required this.categorySales,
    required this.lowPerformingProducts,
  });

  factory ProductAnalytics.fromJson(Map<String, dynamic> json) {
    return ProductAnalytics(
      totalProducts: json['totalProducts'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      outOfStockProducts: json['outOfStockProducts'] ?? 0,
      topSellingProducts: (json['topSellingProducts'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, ProductPerformance.fromJson(value))),
      productSales: Map<String, int>.from(json['productSales'] ?? {}),
      productRevenue: Map<String, double>.from(json['productRevenue'] ?? {}),
      categorySales: Map<String, int>.from(json['categorySales'] ?? {}),
      lowPerformingProducts: List<String>.from(json['lowPerformingProducts'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProducts': totalProducts,
      'activeProducts': activeProducts,
      'outOfStockProducts': outOfStockProducts,
      'topSellingProducts': topSellingProducts.map((key, value) => MapEntry(key, value.toJson())),
      'productSales': productSales,
      'productRevenue': productRevenue,
      'categorySales': categorySales,
      'lowPerformingProducts': lowPerformingProducts,
    };
  }
}

/// Customer analytics - Müşteri analitikleri
class CustomerAnalytics {
  final int totalCustomers;
  final int newCustomers;
  final int returningCustomers;
  final int vipCustomers;
  final double averageCustomerSpending;
  final Map<String, CustomerSegment> customerSegments;
  final Map<String, int> customersByFrequency; // frequency -> count
  final List<CustomerInsight> customerInsights;

  const CustomerAnalytics({
    required this.totalCustomers,
    required this.newCustomers,
    required this.returningCustomers,
    required this.vipCustomers,
    required this.averageCustomerSpending,
    required this.customerSegments,
    required this.customersByFrequency,
    required this.customerInsights,
  });

  factory CustomerAnalytics.fromJson(Map<String, dynamic> json) {
    return CustomerAnalytics(
      totalCustomers: json['totalCustomers'] ?? 0,
      newCustomers: json['newCustomers'] ?? 0,
      returningCustomers: json['returningCustomers'] ?? 0,
      vipCustomers: json['vipCustomers'] ?? 0,
      averageCustomerSpending: (json['averageCustomerSpending'] ?? 0.0).toDouble(),
      customerSegments: (json['customerSegments'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, CustomerSegment.fromJson(value))),
      customersByFrequency: Map<String, int>.from(json['customersByFrequency'] ?? {}),
      customerInsights: (json['customerInsights'] as List<dynamic>? ?? [])
          .map((item) => CustomerInsight.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCustomers': totalCustomers,
      'newCustomers': newCustomers,
      'returningCustomers': returningCustomers,
      'vipCustomers': vipCustomers,
      'averageCustomerSpending': averageCustomerSpending,
      'customerSegments': customerSegments.map((key, value) => MapEntry(key, value.toJson())),
      'customersByFrequency': customersByFrequency,
      'customerInsights': customerInsights.map((item) => item.toJson()).toList(),
    };
  }
}

/// Revenue analytics - Gelir analitikleri
class RevenueAnalytics {
  final double totalRevenue;
  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final Map<String, double> revenueByDay; // date -> revenue
  final Map<String, double> revenueByHour; // hour -> revenue
  final double averageDailyRevenue;
  final double revenueGrowthRate; // percentage
  final List<RevenueBreakdown> revenueBreakdown;

  const RevenueAnalytics({
    required this.totalRevenue,
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.revenueByDay,
    required this.revenueByHour,
    required this.averageDailyRevenue,
    required this.revenueGrowthRate,
    required this.revenueBreakdown,
  });

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) {
    return RevenueAnalytics(
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      todayRevenue: (json['todayRevenue'] ?? 0.0).toDouble(),
      weekRevenue: (json['weekRevenue'] ?? 0.0).toDouble(),
      monthRevenue: (json['monthRevenue'] ?? 0.0).toDouble(),
      revenueByDay: Map<String, double>.from(json['revenueByDay'] ?? {}),
      revenueByHour: Map<String, double>.from(json['revenueByHour'] ?? {}),
      averageDailyRevenue: (json['averageDailyRevenue'] ?? 0.0).toDouble(),
      revenueGrowthRate: (json['revenueGrowthRate'] ?? 0.0).toDouble(),
      revenueBreakdown: (json['revenueBreakdown'] as List<dynamic>? ?? [])
          .map((item) => RevenueBreakdown.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'todayRevenue': todayRevenue,
      'weekRevenue': weekRevenue,
      'monthRevenue': monthRevenue,
      'revenueByDay': revenueByDay,
      'revenueByHour': revenueByHour,
      'averageDailyRevenue': averageDailyRevenue,
      'revenueGrowthRate': revenueGrowthRate,
      'revenueBreakdown': revenueBreakdown.map((item) => item.toJson()).toList(),
    };
  }
}

/// Performance analytics - Performans analitikleri  
class PerformanceAnalytics {
  final double averageServiceTime; // minutes
  final double averageWaitTime; // minutes
  final double customerSatisfactionScore; // 1-5
  final int totalReviews;
  final Map<String, int> ratingDistribution; // rating -> count
  final double orderAccuracy; // percentage
  final List<PerformanceIssue> issues;

  const PerformanceAnalytics({
    required this.averageServiceTime,
    required this.averageWaitTime,
    required this.customerSatisfactionScore,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.orderAccuracy,
    required this.issues,
  });

  factory PerformanceAnalytics.fromJson(Map<String, dynamic> json) {
    return PerformanceAnalytics(
      averageServiceTime: (json['averageServiceTime'] ?? 0.0).toDouble(),
      averageWaitTime: (json['averageWaitTime'] ?? 0.0).toDouble(),
      customerSatisfactionScore: (json['customerSatisfactionScore'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: Map<String, int>.from(json['ratingDistribution'] ?? {}),
      orderAccuracy: (json['orderAccuracy'] ?? 0.0).toDouble(),
      issues: (json['issues'] as List<dynamic>? ?? [])
          .map((item) => PerformanceIssue.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageServiceTime': averageServiceTime,
      'averageWaitTime': averageWaitTime,
      'customerSatisfactionScore': customerSatisfactionScore,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'orderAccuracy': orderAccuracy,
      'issues': issues.map((item) => item.toJson()).toList(),
    };
  }
}

/// Peak hours analytics - Yoğunluk analitikleri
class PeakHoursAnalytics {
  final Map<String, double> hourlyActivity; // hour -> activity score
  final Map<String, HeatMapData> heatMapData; // day_hour -> data
  final String peakHour;
  final String peakDay;
  final String slowestHour;
  final List<PeakPeriod> peakPeriods;

  const PeakHoursAnalytics({
    required this.hourlyActivity,
    required this.heatMapData,
    required this.peakHour,
    required this.peakDay,
    required this.slowestHour,
    required this.peakPeriods,
  });

  factory PeakHoursAnalytics.fromJson(Map<String, dynamic> json) {
    return PeakHoursAnalytics(
      hourlyActivity: Map<String, double>.from(json['hourlyActivity'] ?? {}),
      heatMapData: (json['heatMapData'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, HeatMapData.fromJson(value))),
      peakHour: json['peakHour'] ?? '',
      peakDay: json['peakDay'] ?? '',
      slowestHour: json['slowestHour'] ?? '',
      peakPeriods: (json['peakPeriods'] as List<dynamic>? ?? [])
          .map((item) => PeakPeriod.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hourlyActivity': hourlyActivity,
      'heatMapData': heatMapData.map((key, value) => MapEntry(key, value.toJson())),
      'peakHour': peakHour,
      'peakDay': peakDay,
      'slowestHour': slowestHour,
      'peakPeriods': peakPeriods.map((item) => item.toJson()).toList(),
    };
  }
}

/// Table analytics - Masa analitikleri
class TableAnalytics {
  final Map<String, TablePerformance> tablePerformance; // tableId -> performance
  final Map<String, int> tableUsage; // tableId -> usage count
  final double averageTableTurnover; // times per day
  final String mostPopularTable;
  final String leastUsedTable;

  const TableAnalytics({
    required this.tablePerformance,
    required this.tableUsage,
    required this.averageTableTurnover,
    required this.mostPopularTable,
    required this.leastUsedTable,
  });

  factory TableAnalytics.fromJson(Map<String, dynamic> json) {
    return TableAnalytics(
      tablePerformance: (json['tablePerformance'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, TablePerformance.fromJson(value))),
      tableUsage: Map<String, int>.from(json['tableUsage'] ?? {}),
      averageTableTurnover: (json['averageTableTurnover'] ?? 0.0).toDouble(),
      mostPopularTable: json['mostPopularTable'] ?? '',
      leastUsedTable: json['leastUsedTable'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tablePerformance': tablePerformance.map((key, value) => MapEntry(key, value.toJson())),
      'tableUsage': tableUsage,
      'averageTableTurnover': averageTableTurnover,
      'mostPopularTable': mostPopularTable,
      'leastUsedTable': leastUsedTable,
    };
  }
}

/// Staff analytics - Personel analitikleri
class StaffAnalytics {
  final Map<String, StaffPerformance> staffPerformance; // staffId -> performance
  final double averageOrderProcessingTime;
  final Map<String, int> ordersByStaff; // staffId -> order count
  final Map<String, double> ratingsByStaff; // staffId -> avg rating
  final List<StaffInsight> staffInsights;

  const StaffAnalytics({
    required this.staffPerformance,
    required this.averageOrderProcessingTime,
    required this.ordersByStaff,
    required this.ratingsByStaff,
    required this.staffInsights,
  });

  factory StaffAnalytics.fromJson(Map<String, dynamic> json) {
    return StaffAnalytics(
      staffPerformance: (json['staffPerformance'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, StaffPerformance.fromJson(value))),
      averageOrderProcessingTime: (json['averageOrderProcessingTime'] ?? 0.0).toDouble(),
      ordersByStaff: Map<String, int>.from(json['ordersByStaff'] ?? {}),
      ratingsByStaff: Map<String, double>.from(json['ratingsByStaff'] ?? {}),
      staffInsights: (json['staffInsights'] as List<dynamic>? ?? [])
          .map((item) => StaffInsight.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffPerformance': staffPerformance.map((key, value) => MapEntry(key, value.toJson())),
      'averageOrderProcessingTime': averageOrderProcessingTime,
      'ordersByStaff': ordersByStaff,
      'ratingsByStaff': ratingsByStaff,
      'staffInsights': staffInsights.map((item) => item.toJson()).toList(),
    };
  }
}

// Supporting models

class OrderTimeAnalysis {
  final String timeSlot;
  final int orderCount;
  final double averageValue;
  final double averagePreparationTime;

  const OrderTimeAnalysis({
    required this.timeSlot,
    required this.orderCount,
    required this.averageValue,
    required this.averagePreparationTime,
  });

  factory OrderTimeAnalysis.fromJson(Map<String, dynamic> json) {
    return OrderTimeAnalysis(
      timeSlot: json['timeSlot'] ?? '',
      orderCount: json['orderCount'] ?? 0,
      averageValue: (json['averageValue'] ?? 0.0).toDouble(),
      averagePreparationTime: (json['averagePreparationTime'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeSlot': timeSlot,
      'orderCount': orderCount,
      'averageValue': averageValue,
      'averagePreparationTime': averagePreparationTime,
    };
  }
}

class ProductPerformance {
  final String productId;
  final String productName;
  final int salesCount;
  final double revenue;
  final double rating;
  final int reviewCount;

  const ProductPerformance({
    required this.productId,
    required this.productName,
    required this.salesCount,
    required this.revenue,
    required this.rating,
    required this.reviewCount,
  });

  factory ProductPerformance.fromJson(Map<String, dynamic> json) {
    return ProductPerformance(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      salesCount: json['salesCount'] ?? 0,
      revenue: (json['revenue'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'salesCount': salesCount,
      'revenue': revenue,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}

class CustomerSegment {
  final String segmentName;
  final int customerCount;
  final double averageSpending;
  final double frequency;
  final String characteristics;

  const CustomerSegment({
    required this.segmentName,
    required this.customerCount,
    required this.averageSpending,
    required this.frequency,
    required this.characteristics,
  });

  factory CustomerSegment.fromJson(Map<String, dynamic> json) {
    return CustomerSegment(
      segmentName: json['segmentName'] ?? '',
      customerCount: json['customerCount'] ?? 0,
      averageSpending: (json['averageSpending'] ?? 0.0).toDouble(),
      frequency: (json['frequency'] ?? 0.0).toDouble(),
      characteristics: json['characteristics'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'segmentName': segmentName,
      'customerCount': customerCount,
      'averageSpending': averageSpending,
      'frequency': frequency,
      'characteristics': characteristics,
    };
  }
}

class CustomerInsight {
  final String insightType;
  final String description;
  final double impact;
  final String recommendation;

  const CustomerInsight({
    required this.insightType,
    required this.description,
    required this.impact,
    required this.recommendation,
  });

  factory CustomerInsight.fromJson(Map<String, dynamic> json) {
    return CustomerInsight(
      insightType: json['insightType'] ?? '',
      description: json['description'] ?? '',
      impact: (json['impact'] ?? 0.0).toDouble(),
      recommendation: json['recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'insightType': insightType,
      'description': description,
      'impact': impact,
      'recommendation': recommendation,
    };
  }
}

class RevenueBreakdown {
  final String source;
  final double amount;
  final double percentage;

  const RevenueBreakdown({
    required this.source,
    required this.amount,
    required this.percentage,
  });

  factory RevenueBreakdown.fromJson(Map<String, dynamic> json) {
    return RevenueBreakdown(
      source: json['source'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'amount': amount,
      'percentage': percentage,
    };
  }
}

class PerformanceIssue {
  final String issueType;
  final String description;
  final double severity;
  final String recommendation;
  final DateTime detectedAt;

  const PerformanceIssue({
    required this.issueType,
    required this.description,
    required this.severity,
    required this.recommendation,
    required this.detectedAt,
  });

  factory PerformanceIssue.fromJson(Map<String, dynamic> json) {
    return PerformanceIssue(
      issueType: json['issueType'] ?? '',
      description: json['description'] ?? '',
      severity: (json['severity'] ?? 0.0).toDouble(),
      recommendation: json['recommendation'] ?? '',
      detectedAt: DateTime.parse(json['detectedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'issueType': issueType,
      'description': description,
      'severity': severity,
      'recommendation': recommendation,
      'detectedAt': detectedAt.toIso8601String(),
    };
  }
}

class HeatMapData {
  final double intensity; // 0-1
  final int orderCount;
  final double revenue;
  final String timeSlot;

  const HeatMapData({
    required this.intensity,
    required this.orderCount,
    required this.revenue,
    required this.timeSlot,
  });

  factory HeatMapData.fromJson(Map<String, dynamic> json) {
    return HeatMapData(
      intensity: (json['intensity'] ?? 0.0).toDouble(),
      orderCount: json['orderCount'] ?? 0,
      revenue: (json['revenue'] ?? 0.0).toDouble(),
      timeSlot: json['timeSlot'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intensity': intensity,
      'orderCount': orderCount,
      'revenue': revenue,
      'timeSlot': timeSlot,
    };
  }
}

class PeakPeriod {
  final String timeSlot;
  final String dayOfWeek;
  final double intensity;
  final String description;

  const PeakPeriod({
    required this.timeSlot,
    required this.dayOfWeek,
    required this.intensity,
    required this.description,
  });

  factory PeakPeriod.fromJson(Map<String, dynamic> json) {
    return PeakPeriod(
      timeSlot: json['timeSlot'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      intensity: (json['intensity'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeSlot': timeSlot,
      'dayOfWeek': dayOfWeek,
      'intensity': intensity,
      'description': description,
    };
  }
}

class TablePerformance {
  final String tableId;
  final int usageCount;
  final double averageOrderValue;
  final double averageServiceTime;
  final double customerSatisfaction;

  const TablePerformance({
    required this.tableId,
    required this.usageCount,
    required this.averageOrderValue,
    required this.averageServiceTime,
    required this.customerSatisfaction,
  });

  factory TablePerformance.fromJson(Map<String, dynamic> json) {
    return TablePerformance(
      tableId: json['tableId'] ?? '',
      usageCount: json['usageCount'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0.0).toDouble(),
      averageServiceTime: (json['averageServiceTime'] ?? 0.0).toDouble(),
      customerSatisfaction: (json['customerSatisfaction'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tableId': tableId,
      'usageCount': usageCount,
      'averageOrderValue': averageOrderValue,
      'averageServiceTime': averageServiceTime,
      'customerSatisfaction': customerSatisfaction,
    };
  }
}

class StaffPerformance {
  final String staffId;
  final String staffName;
  final int ordersProcessed;
  final double averageProcessingTime;
  final double customerRating;
  final int customerComplaints;

  const StaffPerformance({
    required this.staffId,
    required this.staffName,
    required this.ordersProcessed,
    required this.averageProcessingTime,
    required this.customerRating,
    required this.customerComplaints,
  });

  factory StaffPerformance.fromJson(Map<String, dynamic> json) {
    return StaffPerformance(
      staffId: json['staffId'] ?? '',
      staffName: json['staffName'] ?? '',
      ordersProcessed: json['ordersProcessed'] ?? 0,
      averageProcessingTime: (json['averageProcessingTime'] ?? 0.0).toDouble(),
      customerRating: (json['customerRating'] ?? 0.0).toDouble(),
      customerComplaints: json['customerComplaints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffId': staffId,
      'staffName': staffName,
      'ordersProcessed': ordersProcessed,
      'averageProcessingTime': averageProcessingTime,
      'customerRating': customerRating,
      'customerComplaints': customerComplaints,
    };
  }
}

class StaffInsight {
  final String staffId;
  final String insightType;
  final String description;
  final double impact;
  final String recommendation;

  const StaffInsight({
    required this.staffId,
    required this.insightType,
    required this.description,
    required this.impact,
    required this.recommendation,
  });

  factory StaffInsight.fromJson(Map<String, dynamic> json) {
    return StaffInsight(
      staffId: json['staffId'] ?? '',
      insightType: json['insightType'] ?? '',
      description: json['description'] ?? '',
      impact: (json['impact'] ?? 0.0).toDouble(),
      recommendation: json['recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffId': staffId,
      'insightType': insightType,
      'description': description,
      'impact': impact,
      'recommendation': recommendation,
    };
  }
} 