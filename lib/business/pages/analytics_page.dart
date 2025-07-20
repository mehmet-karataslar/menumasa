import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../services/analytics_service.dart';
import '../models/analytics_models.dart';
import '../services/business_service.dart';
import '../../../presentation/widgets/shared/loading_indicator.dart';
import '../../../presentation/widgets/shared/error_message.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with TickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  final BusinessService _businessService = BusinessService();

  late TabController _tabController;
  
  BusinessAnalytics? _analytics;
  Map<String, dynamic>? _dashboardData;
  Map<String, HeatMapData>? _heatMapData;
  bool _isLoading = true;
  String? _errorMessage;
  
  String _selectedPeriod = 'today';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initializeDates();
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeDates() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = _startDate.add(const Duration(days: 1));
        break;
      case 'week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final business = _businessService.currentBusiness;
      if (business == null) {
        throw Exception('İşletme bilgisi bulunamadı');
      }

      // Load all analytics data in parallel
      final futures = await Future.wait([
        _analyticsService.getBusinessAnalytics(
          businessId: business.businessId,
          startDate: _startDate,
          endDate: _endDate,
        ),
        _analyticsService.getDashboardData(business.businessId),
        _analyticsService.getHeatMapData(
          businessId: business.businessId,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ]);

      setState(() {
        _analytics = futures[0] as BusinessAnalytics;
        _dashboardData = futures[1] as Map<String, dynamic>;
        _heatMapData = futures[2] as Map<String, HeatMapData>;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Analytics yüklenirken hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Tabs
          _buildTabBar(),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingIndicator())
                : _errorMessage != null
                    ? Center(child: ErrorMessage(message: _errorMessage!))
                    : _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İşletme Analitikleri',
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _loadAnalytics,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yenile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Quick stats
          if (_dashboardData != null) _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          items: const [
            DropdownMenuItem(value: 'today', child: Text('Bugün')),
            DropdownMenuItem(value: 'week', child: Text('Bu Hafta')),
            DropdownMenuItem(value: 'month', child: Text('Bu Ay')),
            DropdownMenuItem(value: 'year', child: Text('Bu Yıl')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPeriod = value;
                _initializeDates();
              });
              _loadAnalytics();
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Toplam Sipariş',
            _dashboardData!['todayOrders'].toString(),
            Icons.shopping_cart,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Aktif Sipariş',
            _dashboardData!['activeOrders'].toString(),
            Icons.hourglass_empty,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Gelir',
            '₺${_dashboardData!['todayRevenue'].toStringAsFixed(2)}',
            Icons.monetization_on,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Ort. Sipariş',
            '₺${_dashboardData!['averageOrderValue'].toStringAsFixed(2)}',
            Icons.analytics,
            AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textLight,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'Genel Bakış'),
          Tab(text: 'Siparişler'),
          Tab(text: 'Ürünler'),
          Tab(text: 'Müşteriler'),
          Tab(text: 'Performans'),
          Tab(text: 'Isı Haritası'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_analytics == null) {
      return const Center(child: Text('Analytics verisi yüklenemedi'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildOrdersTab(),
        _buildProductsTab(),
        _buildCustomersTab(),
        _buildPerformanceTab(),
        _buildHeatMapTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue chart
          _buildRevenueChart(),
          
          const SizedBox(height: 32),
          
          Row(
            children: [
              // Order status pie chart
              Expanded(
                child: _buildOrderStatusChart(),
              ),
              
              const SizedBox(width: 24),
              
              // Peak hours chart
              Expanded(
                child: _buildPeakHoursChart(),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Top products table
          _buildTopProductsTable(),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gelir Trendi',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 60),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getRevenueSpots(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getRevenueSpots() {
    if (_analytics?.revenueAnalytics.revenueByDay.isEmpty ?? true) {
      return [const FlSpot(0, 0)];
    }

    final revenueData = _analytics!.revenueAnalytics.revenueByDay;
    final sortedEntries = revenueData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  Widget _buildOrderStatusChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sipariş Durumları',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _getOrderStatusSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getOrderStatusSections() {
    final orderAnalytics = _analytics?.orderAnalytics;
    if (orderAnalytics == null) return [];

    return [
      PieChartSectionData(
        value: orderAnalytics.completedOrders.toDouble(),
        title: '${orderAnalytics.completedOrders}',
        color: AppColors.success,
        radius: 60,
      ),
      PieChartSectionData(
        value: orderAnalytics.pendingOrders.toDouble(),
        title: '${orderAnalytics.pendingOrders}',
        color: AppColors.warning,
        radius: 60,
      ),
      PieChartSectionData(
        value: orderAnalytics.cancelledOrders.toDouble(),
        title: '${orderAnalytics.cancelledOrders}',
        color: AppColors.error,
        radius: 60,
      ),
    ];
  }

  Widget _buildPeakHoursChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saatlik Yoğunluk',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _getPeakHoursBarGroups(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _getPeakHoursBarGroups() {
    final peakData = _analytics?.peakHoursAnalytics.hourlyActivity ?? {};
    
    return peakData.entries.take(12).toList().asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value,
            color: AppColors.primary,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildTopProductsTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En Çok Satan Ürünler',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            DataTable(
              columns: const [
                DataColumn(label: Text('Ürün Adı')),
                DataColumn(label: Text('Satış')),
                DataColumn(label: Text('Gelir')),
                DataColumn(label: Text('Değerlendirme')),
              ],
              rows: _analytics!.productAnalytics.topSellingProducts.values.take(5).map((product) {
                return DataRow(
                  cells: [
                    DataCell(Text(product.productName)),
                    DataCell(Text(product.salesCount.toString())),
                    DataCell(Text('₺${product.revenue.toStringAsFixed(2)}')),
                    DataCell(Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(product.rating.toStringAsFixed(1)),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Order analytics cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Toplam Sipariş',
                  _analytics!.orderAnalytics.totalOrders.toString(),
                  Icons.shopping_cart,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Tamamlanan',
                  _analytics!.orderAnalytics.completedOrders.toString(),
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'İptal Edilen',
                  _analytics!.orderAnalytics.cancelledOrders.toString(),
                  Icons.cancel,
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Ort. Tutar',
                  '₺${_analytics!.orderAnalytics.averageOrderValue.toStringAsFixed(2)}',
                  Icons.monetization_on,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Order completion rate
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sipariş Tamamlanma Oranı',
                    style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _analytics!.orderAnalytics.completionRate,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '%${(_analytics!.orderAnalytics.completionRate * 100).toStringAsFixed(1)}',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Product analytics cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Toplam Ürün',
                  _analytics!.productAnalytics.totalProducts.toString(),
                  Icons.inventory,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Aktif Ürün',
                  _analytics!.productAnalytics.activeProducts.toString(),
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Stokta Yok',
                  _analytics!.productAnalytics.outOfStockProducts.toString(),
                  Icons.warning,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Düşük Performans',
                  _analytics!.productAnalytics.lowPerformingProducts.length.toString(),
                  Icons.trending_down,
                  AppColors.error,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Top selling products chart
          _buildTopProductsChart(),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Customer analytics cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Toplam Müşteri',
                  _analytics!.customerAnalytics.totalCustomers.toString(),
                  Icons.people,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Yeni Müşteri',
                  _analytics!.customerAnalytics.newCustomers.toString(),
                  Icons.person_add,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Dönen Müşteri',
                  _analytics!.customerAnalytics.returningCustomers.toString(),
                  Icons.repeat,
                  AppColors.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'VIP Müşteri',
                  _analytics!.customerAnalytics.vipCustomers.toString(),
                  Icons.star,
                  AppColors.warning,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Customer frequency chart
          _buildCustomerFrequencyChart(),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Performance metrics
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Ort. Servis Süresi',
                  '${_analytics!.performanceAnalytics.averageServiceTime.toStringAsFixed(1)} dk',
                  Icons.timer,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Müşteri Memnuniyeti',
                  _analytics!.performanceAnalytics.customerSatisfactionScore.toStringAsFixed(1),
                  Icons.sentiment_satisfied,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Sipariş Doğruluğu',
                  '%${_analytics!.performanceAnalytics.orderAccuracy.toStringAsFixed(1)}',
                  Icons.check_circle,
                  AppColors.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Toplam Değerlendirme',
                  _analytics!.performanceAnalytics.totalReviews.toString(),
                  Icons.rate_review,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatMapTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktivite Isı Haritası',
                style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _buildHeatMap(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatMap() {
    if (_heatMapData == null || _heatMapData!.isEmpty) {
      return const Center(
        child: Text('Isı haritası verisi bulunamadı'),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 24, // 24 hours
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 7 * 24, // 7 days * 24 hours
      itemBuilder: (context, index) {
        final day = index ~/ 24 + 1;
        final hour = index % 24;
        final key = '${day}_$hour';
        final data = _heatMapData![key];
        
        return Container(
          decoration: BoxDecoration(
            color: data != null 
                ? AppColors.primary.withOpacity(data.intensity)
                : AppColors.borderLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Tooltip(
            message: data != null 
                ? 'Gün: $day, Saat: $hour\nSipariş: ${data.orderCount}\nGelir: ₺${data.revenue.toStringAsFixed(2)}'
                : 'Veri yok',
            child: Container(),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En Çok Satan Ürünler',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 60),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _getTopProductsBarGroups(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _getTopProductsBarGroups() {
    final topProducts = _analytics!.productAnalytics.topSellingProducts.values.take(10).toList();
    
    return topProducts.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.salesCount.toDouble(),
            color: AppColors.primary,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildCustomerFrequencyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Müşteri Sıklık Dağılımı',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _getCustomerFrequencySections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getCustomerFrequencySections() {
    final frequencyData = _analytics!.customerAnalytics.customersByFrequency;
    final colors = [AppColors.primary, AppColors.success, AppColors.warning, AppColors.error];
    
    return frequencyData.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final frequency = entry.value;
      
      return PieChartSectionData(
        value: frequency.value.toDouble(),
        title: '${frequency.value}',
        color: colors[index % colors.length],
        radius: 60,
      );
    }).toList();
  }
} 