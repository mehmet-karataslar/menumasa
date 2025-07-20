import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_models.dart';
import '../../data/models/order.dart' as app_order;
import '../../data/models/product.dart';
import '../../data/models/business.dart';
import '../../core/services/firestore_service.dart';

/// Business analytics service for comprehensive data analysis
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  /// Get comprehensive business analytics for a given period
  Future<BusinessAnalytics> getBusinessAnalytics({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch all necessary data
      final orders = await _getOrdersInPeriod(businessId, startDate, endDate);
      final products = await _firestoreService.getBusinessProducts(businessId);
      final business = await _firestoreService.getBusiness(businessId);

      // Calculate analytics
      final orderAnalytics = _calculateOrderAnalytics(orders, startDate, endDate);
      final productAnalytics = _calculateProductAnalytics(products, orders);
      final customerAnalytics = _calculateCustomerAnalytics(orders);
      final revenueAnalytics = _calculateRevenueAnalytics(orders, startDate, endDate);
      final performanceAnalytics = _calculatePerformanceAnalytics(orders);
      final peakHoursAnalytics = _calculatePeakHoursAnalytics(orders);
      final tableAnalytics = _calculateTableAnalytics(orders);
      final staffAnalytics = _calculateStaffAnalytics(orders);

      return BusinessAnalytics(
        businessId: businessId,
        periodStart: startDate,
        periodEnd: endDate,
        orderAnalytics: orderAnalytics,
        productAnalytics: productAnalytics,
        customerAnalytics: customerAnalytics,
        revenueAnalytics: revenueAnalytics,
        performanceAnalytics: performanceAnalytics,
        peakHoursAnalytics: peakHoursAnalytics,
        tableAnalytics: tableAnalytics,
        staffAnalytics: staffAnalytics,
      );
    } catch (e) {
      throw Exception('Business analytics calculation failed: $e');
    }
  }

  /// Get real-time dashboard data
  Future<Map<String, dynamic>> getDashboardData(String businessId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todayOrders = await _getOrdersInPeriod(businessId, startOfDay, endOfDay);
      final activeOrders = todayOrders.where((o) => o.status != app_order.OrderStatus.completed && o.status != app_order.OrderStatus.cancelled).toList();
      
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekOrders = await _getOrdersInPeriod(businessId, weekStart, today);
      
      final monthStart = DateTime(today.year, today.month, 1);
      final monthOrders = await _getOrdersInPeriod(businessId, monthStart, today);

      final todayRevenue = todayOrders
          .where((o) => o.status == app_order.OrderStatus.completed)
          .fold(0.0, (sum, order) => sum + order.totalAmount);

      final weekRevenue = weekOrders
          .where((o) => o.status == app_order.OrderStatus.completed)
          .fold(0.0, (sum, order) => sum + order.totalAmount);

      final monthRevenue = monthOrders
          .where((o) => o.status == app_order.OrderStatus.completed)
          .fold(0.0, (sum, order) => sum + order.totalAmount);

      return {
        'todayOrders': todayOrders.length,
        'activeOrders': activeOrders.length,
        'todayRevenue': todayRevenue,
        'weekRevenue': weekRevenue,
        'monthRevenue': monthRevenue,
        'averageOrderValue': todayOrders.isNotEmpty ? todayRevenue / todayOrders.length : 0.0,
        'completionRate': todayOrders.isNotEmpty 
            ? todayOrders.where((o) => o.status == app_order.OrderStatus.completed).length / todayOrders.length 
            : 0.0,
        'peakHour': _findPeakHour(todayOrders),
        'topProducts': await _getTopProducts(businessId, startOfDay, endOfDay),
      };
    } catch (e) {
      throw Exception('Dashboard data calculation failed: $e');
    }
  }

  /// Get heat map data for activity visualization
  Future<Map<String, HeatMapData>> getHeatMapData({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final orders = await _getOrdersInPeriod(businessId, startDate, endDate);
      final heatMapData = <String, HeatMapData>{};

      // Group orders by day and hour
      for (final order in orders) {
        final hour = order.createdAt.hour;
        final day = order.createdAt.weekday;
        final key = '${day}_$hour';

        if (heatMapData.containsKey(key)) {
          final existing = heatMapData[key]!;
          heatMapData[key] = HeatMapData(
            intensity: existing.intensity,
            orderCount: existing.orderCount + 1,
            revenue: existing.revenue + order.totalAmount,
            timeSlot: existing.timeSlot,
          );
        } else {
          heatMapData[key] = HeatMapData(
            intensity: 0.1,
            orderCount: 1,
            revenue: order.totalAmount,
            timeSlot: '${day}_$hour',
          );
        }
      }

      // Calculate intensity based on maximum order count
      final maxOrderCount = heatMapData.values.isEmpty 
          ? 1 
          : heatMapData.values.map((data) => data.orderCount).reduce((a, b) => a > b ? a : b);

      return heatMapData.map((key, data) => MapEntry(
        key,
        HeatMapData(
          intensity: data.orderCount / maxOrderCount,
          orderCount: data.orderCount,
          revenue: data.revenue,
          timeSlot: data.timeSlot,
        ),
      ));
    } catch (e) {
      throw Exception('Heat map data calculation failed: $e');
    }
  }

  /// Get product performance analytics
  Future<List<ProductPerformance>> getProductPerformanceAnalytics({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final orders = await _getOrdersInPeriod(businessId, startDate, endDate);
      final products = await _firestoreService.getBusinessProducts(businessId);
      
      final productStats = <String, Map<String, dynamic>>{};

      // Calculate stats for each product
      for (final order in orders) {
        for (final item in order.items) {
          final productId = item.productId;
          
          if (productStats.containsKey(productId)) {
            productStats[productId]!['salesCount'] += item.quantity;
            productStats[productId]!['revenue'] += item.totalPrice;
          } else {
            final product = products.firstWhere(
              (p) => p.productId == productId,
              orElse: () => Product(
                productId: productId,
                businessId: businessId,
                categoryId: '',
                name: item.productName,
                description: '',
                detailedDescription: '',
                price: item.price,
                currentPrice: item.price,
                currency: 'TRY',
                images: [],
                allergens: [],
                tags: [],
                isActive: true,
                isAvailable: true,
                sortOrder: 0,
                timeRules: [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            productStats[productId] = {
              'productName': product.name,
              'salesCount': item.quantity,
              'revenue': item.totalPrice,
              'rating': 4.0, // TODO: Get from reviews
              'reviewCount': 0, // TODO: Get from reviews
            };
          }
        }
      }

      // Convert to ProductPerformance objects and sort by sales
      final performances = productStats.entries
          .map((entry) => ProductPerformance(
                productId: entry.key,
                productName: entry.value['productName'],
                salesCount: entry.value['salesCount'],
                revenue: entry.value['revenue'],
                rating: entry.value['rating'],
                reviewCount: entry.value['reviewCount'],
              ))
          .toList()
        ..sort((a, b) => b.salesCount.compareTo(a.salesCount));

      return performances.take(limit).toList();
    } catch (e) {
      throw Exception('Product performance calculation failed: $e');
    }
  }

  /// Get customer insights and segmentation
  Future<Map<String, CustomerSegment>> getCustomerSegmentation({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final orders = await _getOrdersInPeriod(businessId, startDate, endDate);
      
      // Group customers by their characteristics
      final customerGroups = <String, List<String>>{
        'Yeni Müşteriler': [],
        'Düzenli Müşteriler': [],
        'VIP Müşteriler': [],
        'Değerli Müşteriler': [],
      };

      final customerStats = <String, Map<String, dynamic>>{};

      for (final order in orders) {
        final customerId = order.customerPhone ?? order.customerName;
        
        if (customerStats.containsKey(customerId)) {
          customerStats[customerId]!['orderCount']++;
          customerStats[customerId]!['totalSpent'] += order.totalAmount;
        } else {
          customerStats[customerId] = {
            'orderCount': 1,
            'totalSpent': order.totalAmount,
            'firstOrderDate': order.createdAt,
            'lastOrderDate': order.createdAt,
          };
        }
      }

      // Categorize customers
      for (final entry in customerStats.entries) {
        final customerId = entry.key;
        final stats = entry.value;
        final orderCount = stats['orderCount'] as int;
        final totalSpent = stats['totalSpent'] as double;

        if (orderCount >= 10 && totalSpent >= 1000) {
          customerGroups['VIP Müşteriler']!.add(customerId);
        } else if (orderCount >= 5 && totalSpent >= 500) {
          customerGroups['Değerli Müşteriler']!.add(customerId);
        } else if (orderCount >= 3) {
          customerGroups['Düzenli Müşteriler']!.add(customerId);
        } else {
          customerGroups['Yeni Müşteriler']!.add(customerId);
        }
      }

      // Create customer segments
      final segments = <String, CustomerSegment>{};
      
      for (final entry in customerGroups.entries) {
        final segmentName = entry.key;
        final customerIds = entry.value;
        
        if (customerIds.isNotEmpty) {
          final segmentStats = customerIds.map((id) => customerStats[id]!).toList();
          final avgSpending = segmentStats.fold(0.0, (sum, stats) => sum + stats['totalSpent']) / customerIds.length;
          final avgFrequency = segmentStats.fold(0.0, (sum, stats) => sum + stats['orderCount']) / customerIds.length;

          segments[segmentName] = CustomerSegment(
            segmentName: segmentName,
            customerCount: customerIds.length,
            averageSpending: avgSpending,
            frequency: avgFrequency,
            characteristics: _getSegmentCharacteristics(segmentName),
          );
        }
      }

      return segments;
    } catch (e) {
      throw Exception('Customer segmentation calculation failed: $e');
    }
  }

  // Private helper methods

  Future<List<app_order.Order>> _getOrdersInPeriod(String businessId, DateTime start, DateTime end) async {
    try {
      // TODO: Implement Firestore query with date range
      final orders = await _firestoreService.getBusinessOrders(businessId, limit: 1000);
      return orders.where((order) => 
          order.createdAt.isAfter(start) && order.createdAt.isBefore(end)
      ).toList();
    } catch (e) {
      // Fallback to empty list if no orders found
      return [];
    }
  }

  OrderAnalytics _calculateOrderAnalytics(List<app_order.Order> orders, DateTime start, DateTime end) {
    final totalOrders = orders.length;
    final completedOrders = orders.where((o) => o.status == app_order.OrderStatus.completed).length;
    final cancelledOrders = orders.where((o) => o.status == app_order.OrderStatus.cancelled).length;
    final pendingOrders = orders.where((o) => o.status == app_order.OrderStatus.pending).length;

    final completedOrdersList = orders.where((o) => o.status == app_order.OrderStatus.completed).toList();
    final averageOrderValue = completedOrdersList.isNotEmpty
        ? completedOrdersList.fold(0.0, (sum, order) => sum + order.totalAmount) / completedOrdersList.length
        : 0.0;

    final averagePreparationTime = completedOrdersList.isNotEmpty
        ? completedOrdersList
            .where((order) => order.completedAt != null)
            .fold(0.0, (sum, order) => sum + order.completedAt!.difference(order.createdAt).inMinutes) 
            / completedOrdersList.length
        : 0.0;

    // Group orders by hour
    final ordersByHour = <String, int>{};
    for (final order in orders) {
      final hour = order.createdAt.hour.toString().padLeft(2, '0');
      ordersByHour[hour] = (ordersByHour[hour] ?? 0) + 1;
    }

    // Group orders by day
    final ordersByDay = <String, int>{};
    for (final order in orders) {
      final day = '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')}';
      ordersByDay[day] = (ordersByDay[day] ?? 0) + 1;
    }

    final ordersByStatus = <String, int>{
      'pending': pendingOrders,
      'completed': completedOrders,
      'cancelled': cancelledOrders,
      'in_progress': orders.where((o) => o.status == app_order.OrderStatus.inProgress).length,
    };

    return OrderAnalytics(
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      cancelledOrders: cancelledOrders,
      pendingOrders: pendingOrders,
      averageOrderValue: averageOrderValue,
      averagePreparationTime: averagePreparationTime,
      ordersByHour: ordersByHour,
      ordersByDay: ordersByDay,
      ordersByStatus: ordersByStatus,
      orderTimeBreakdown: [], // TODO: Implement detailed time breakdown
    );
  }

  ProductAnalytics _calculateProductAnalytics(List<Product> products, List<app_order.Order> orders) {
    final totalProducts = products.length;
    final activeProducts = products.where((p) => p.isActive && p.isAvailable).length;
    final outOfStockProducts = products.where((p) => !p.isAvailable).length;

    // Calculate product sales from orders
    final productSales = <String, int>{};
    final productRevenue = <String, double>{};
    final categorySales = <String, int>{};

    for (final order in orders) {
      for (final item in order.items) {
        productSales[item.productId] = (productSales[item.productId] ?? 0) + item.quantity;
        productRevenue[item.productId] = (productRevenue[item.productId] ?? 0.0) + item.totalPrice;
        
        // Find category for this product
        final product = products.firstWhere(
          (p) => p.productId == item.productId,
          orElse: () => products.first,
        );
        categorySales[product.categoryId] = (categorySales[product.categoryId] ?? 0) + item.quantity;
      }
    }

    // Get top selling products
    final topSellingProducts = <String, ProductPerformance>{};
    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedProducts.take(10)) {
      final product = products.firstWhere(
        (p) => p.productId == entry.key,
        orElse: () => products.first,
      );
      
      topSellingProducts[entry.key] = ProductPerformance(
        productId: entry.key,
        productName: product.name,
        salesCount: entry.value,
        revenue: productRevenue[entry.key] ?? 0.0,
        rating: 4.0, // TODO: Get from reviews
        reviewCount: 0, // TODO: Get from reviews
      );
    }

    // Get low performing products (bottom 20% by sales)
    final lowPerformingProducts = productSales.entries
        .where((entry) => entry.value < (productSales.values.isEmpty ? 0 : productSales.values.reduce((a, b) => a + b) * 0.1))
        .map((entry) => entry.key)
        .toList();

    return ProductAnalytics(
      totalProducts: totalProducts,
      activeProducts: activeProducts,
      outOfStockProducts: outOfStockProducts,
      topSellingProducts: topSellingProducts,
      productSales: productSales,
      productRevenue: productRevenue,
      categorySales: categorySales,
      lowPerformingProducts: lowPerformingProducts,
    );
  }

  CustomerAnalytics _calculateCustomerAnalytics(List<app_order.Order> orders) {
    final customerOrders = <String, List<app_order.Order>>{};
    
    for (final order in orders) {
      final customerId = order.customerPhone ?? order.customerName;
      customerOrders[customerId] = (customerOrders[customerId] ?? [])..add(order);
    }

    final totalCustomers = customerOrders.length;
    final newCustomers = customerOrders.values.where((orders) => orders.length == 1).length;
    final returningCustomers = customerOrders.values.where((orders) => orders.length > 1).length;
    final vipCustomers = customerOrders.values.where((orders) => 
        orders.length >= 10 && orders.fold(0.0, (sum, order) => sum + order.totalAmount) >= 1000
    ).length;

    final totalSpending = orders.fold(0.0, (sum, order) => sum + order.totalAmount);
    final averageCustomerSpending = totalCustomers > 0 ? totalSpending / totalCustomers : 0.0;

    // Customer frequency analysis
    final customersByFrequency = <String, int>{
      '1': customerOrders.values.where((orders) => orders.length == 1).length,
      '2-5': customerOrders.values.where((orders) => orders.length >= 2 && orders.length <= 5).length,
      '6-10': customerOrders.values.where((orders) => orders.length >= 6 && orders.length <= 10).length,
      '10+': customerOrders.values.where((orders) => orders.length > 10).length,
    };

    return CustomerAnalytics(
      totalCustomers: totalCustomers,
      newCustomers: newCustomers,
      returningCustomers: returningCustomers,
      vipCustomers: vipCustomers,
      averageCustomerSpending: averageCustomerSpending,
      customerSegments: {}, // Will be calculated separately
      customersByFrequency: customersByFrequency,
      customerInsights: [], // TODO: Implement customer insights
    );
  }

  RevenueAnalytics _calculateRevenueAnalytics(List<app_order.Order> orders, DateTime start, DateTime end) {
    final completedOrders = orders.where((o) => o.status == app_order.OrderStatus.completed).toList();
    final totalRevenue = completedOrders.fold(0.0, (sum, order) => sum + order.totalAmount);

    final today = DateTime.now();
    final todayOrders = completedOrders.where((o) => 
        o.createdAt.year == today.year && 
        o.createdAt.month == today.month && 
        o.createdAt.day == today.day
    ).toList();
    final todayRevenue = todayOrders.fold(0.0, (sum, order) => sum + order.totalAmount);

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekOrders = completedOrders.where((o) => o.createdAt.isAfter(weekStart)).toList();
    final weekRevenue = weekOrders.fold(0.0, (sum, order) => sum + order.totalAmount);

    final monthStart = DateTime(today.year, today.month, 1);
    final monthOrders = completedOrders.where((o) => o.createdAt.isAfter(monthStart)).toList();
    final monthRevenue = monthOrders.fold(0.0, (sum, order) => sum + order.totalAmount);

    // Revenue by day
    final revenueByDay = <String, double>{};
    for (final order in completedOrders) {
      final day = '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')}';
      revenueByDay[day] = (revenueByDay[day] ?? 0.0) + order.totalAmount;
    }

    // Revenue by hour
    final revenueByHour = <String, double>{};
    for (final order in completedOrders) {
      final hour = order.createdAt.hour.toString().padLeft(2, '0');
      revenueByHour[hour] = (revenueByHour[hour] ?? 0.0) + order.totalAmount;
    }

    final averageDailyRevenue = revenueByDay.isNotEmpty 
        ? revenueByDay.values.fold(0.0, (sum, value) => sum + value) / revenueByDay.length 
        : 0.0;

    // Simple growth rate calculation (month over month)
    final revenueGrowthRate = 0.0; // TODO: Implement proper growth rate calculation

    return RevenueAnalytics(
      totalRevenue: totalRevenue,
      todayRevenue: todayRevenue,
      weekRevenue: weekRevenue,
      monthRevenue: monthRevenue,
      revenueByDay: revenueByDay,
      revenueByHour: revenueByHour,
      averageDailyRevenue: averageDailyRevenue,
      revenueGrowthRate: revenueGrowthRate,
      revenueBreakdown: [], // TODO: Implement revenue breakdown
    );
  }

  PerformanceAnalytics _calculatePerformanceAnalytics(List<app_order.Order> orders) {
    final completedOrders = orders.where((o) => o.status == app_order.OrderStatus.completed && o.completedAt != null).toList();
    
    final averageServiceTime = completedOrders.isNotEmpty
        ? completedOrders.fold(0.0, (sum, order) => sum + order.completedAt!.difference(order.createdAt).inMinutes) / completedOrders.length
        : 0.0;

    // TODO: Calculate wait time (would need order acceptance time)
    final averageWaitTime = 0.0;

    // TODO: Get from reviews/ratings system
    final customerSatisfactionScore = 4.2;
    final totalReviews = 0;
    final ratingDistribution = <String, int>{
      '1': 0, '2': 0, '3': 0, '4': 0, '5': 0,
    };

    final orderAccuracy = orders.isNotEmpty 
        ? (orders.length - orders.where((o) => o.status == app_order.OrderStatus.cancelled).length) / orders.length * 100
        : 100.0;

    return PerformanceAnalytics(
      averageServiceTime: averageServiceTime,
      averageWaitTime: averageWaitTime,
      customerSatisfactionScore: customerSatisfactionScore,
      totalReviews: totalReviews,
      ratingDistribution: ratingDistribution,
      orderAccuracy: orderAccuracy,
      issues: [], // TODO: Implement issue detection
    );
  }

  PeakHoursAnalytics _calculatePeakHoursAnalytics(List<app_order.Order> orders) {
    final hourlyActivity = <String, double>{};
    
    // Calculate activity score for each hour
    for (int hour = 0; hour < 24; hour++) {
      final hourOrders = orders.where((o) => o.createdAt.hour == hour).length;
      hourlyActivity[hour.toString().padLeft(2, '0')] = hourOrders.toDouble();
    }

    final maxActivity = hourlyActivity.values.isEmpty ? 1.0 : hourlyActivity.values.reduce((a, b) => a > b ? a : b);
    
    // Normalize activity scores
    final normalizedActivity = hourlyActivity.map((key, value) => MapEntry(key, value / maxActivity));

    final peakHour = normalizedActivity.entries.isEmpty ? '12' : 
        normalizedActivity.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Find peak day
    final dayOrders = <String, int>{};
    for (final order in orders) {
      final dayName = _getDayName(order.createdAt.weekday);
      dayOrders[dayName] = (dayOrders[dayName] ?? 0) + 1;
    }
    
    final peakDay = dayOrders.entries.isEmpty ? 'Monday' :
        dayOrders.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final slowestHour = normalizedActivity.entries.isEmpty ? '03' :
        normalizedActivity.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    return PeakHoursAnalytics(
      hourlyActivity: normalizedActivity,
      heatMapData: {}, // Will be calculated separately
      peakHour: peakHour,
      peakDay: peakDay,
      slowestHour: slowestHour,
      peakPeriods: [], // TODO: Implement peak period detection
    );
  }

  TableAnalytics _calculateTableAnalytics(List<app_order.Order> orders) {
    final tableUsage = <String, int>{};
    final tableOrderValues = <String, List<double>>{};
    final tableServiceTimes = <String, List<double>>{};

    for (final order in orders) {
      final tableId = order.tableNumber.toString();
      tableUsage[tableId] = (tableUsage[tableId] ?? 0) + 1;
      
      tableOrderValues[tableId] = (tableOrderValues[tableId] ?? [])..add(order.totalAmount);
      
      if (order.status == app_order.OrderStatus.completed && order.completedAt != null) {
        final serviceTime = order.completedAt!.difference(order.createdAt).inMinutes.toDouble();
        tableServiceTimes[tableId] = (tableServiceTimes[tableId] ?? [])..add(serviceTime);
      }
    }

    final tablePerformance = <String, TablePerformance>{};
    for (final tableId in tableUsage.keys) {
      final usage = tableUsage[tableId]!;
      final orderValues = tableOrderValues[tableId] ?? [];
      final serviceTimes = tableServiceTimes[tableId] ?? [];
      
      final avgOrderValue = orderValues.isNotEmpty ? orderValues.reduce((a, b) => a + b) / orderValues.length : 0.0;
      final avgServiceTime = serviceTimes.isNotEmpty ? serviceTimes.reduce((a, b) => a + b) / serviceTimes.length : 0.0;

      tablePerformance[tableId] = TablePerformance(
        tableId: tableId,
        usageCount: usage,
        averageOrderValue: avgOrderValue,
        averageServiceTime: avgServiceTime,
        customerSatisfaction: 4.0, // TODO: Get from reviews
      );
    }

    final mostPopularTable = tableUsage.entries.isEmpty ? '' :
        tableUsage.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    final leastUsedTable = tableUsage.entries.isEmpty ? '' :
        tableUsage.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    final averageTableTurnover = tableUsage.values.isEmpty ? 0.0 :
        tableUsage.values.reduce((a, b) => a + b) / tableUsage.length;

    return TableAnalytics(
      tablePerformance: tablePerformance,
      tableUsage: tableUsage,
      averageTableTurnover: averageTableTurnover,
      mostPopularTable: mostPopularTable,
      leastUsedTable: leastUsedTable,
    );
  }

  StaffAnalytics _calculateStaffAnalytics(List<app_order.Order> orders) {
    // TODO: Implement staff analytics when staff assignment is available
    return StaffAnalytics(
      staffPerformance: {},
      averageOrderProcessingTime: 0.0,
      ordersByStaff: {},
      ratingsByStaff: {},
      staffInsights: [],
    );
  }

  String _findPeakHour(List<app_order.Order> orders) {
    final hourCounts = <int, int>{};
    for (final order in orders) {
      hourCounts[order.createdAt.hour] = (hourCounts[order.createdAt.hour] ?? 0) + 1;
    }
    
    if (hourCounts.isEmpty) return '12';
    
    final peakHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return peakHour.toString().padLeft(2, '0');
  }

  Future<List<Map<String, dynamic>>> _getTopProducts(String businessId, DateTime start, DateTime end) async {
    try {
      final orders = await _getOrdersInPeriod(businessId, start, end);
      final productSales = <String, int>{};
      final productNames = <String, String>{};

      for (final order in orders) {
        for (final item in order.items) {
          productSales[item.productId] = (productSales[item.productId] ?? 0) + item.quantity;
          productNames[item.productId] = item.productName;
        }
      }

      final sortedProducts = productSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedProducts.take(5).map((entry) => {
        'productId': entry.key,
        'productName': productNames[entry.key] ?? 'Unknown',
        'salesCount': entry.value,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  String _getDayName(int weekday) {
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayNames[weekday - 1];
  }

  String _getSegmentCharacteristics(String segmentName) {
    switch (segmentName) {
      case 'Yeni Müşteriler':
        return 'İlk kez sipariş veren, potansiyel müşteriler';
      case 'Düzenli Müşteriler':
        return 'Düzenli olarak sipariş veren, sadık müşteriler';
      case 'VIP Müşteriler':
        return 'Yüksek harcama yapan, en değerli müşteriler';
      case 'Değerli Müşteriler':
        return 'Orta seviye harcama yapan, potansiyel VIP müşteriler';
      default:
        return 'Genel müşteri segmenti';
    }
  }
} 