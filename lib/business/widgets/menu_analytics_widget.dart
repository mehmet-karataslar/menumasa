import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/business_firestore_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/empty_state.dart';

class MenuAnalyticsWidget extends StatefulWidget {
  final String businessId;
  final List<Category> categories;
  final List<Product> products;

  const MenuAnalyticsWidget({
    super.key,
    required this.businessId,
    required this.categories,
    required this.products,
  });

  @override
  State<MenuAnalyticsWidget> createState() => _MenuAnalyticsWidgetState();
}

class _MenuAnalyticsWidgetState extends State<MenuAnalyticsWidget> {
  final BusinessFirestoreService _businessService = BusinessFirestoreService();

  bool _isLoading = false;
  String _selectedPeriod = '7days'; // 7days, 30days, 90days

  // Analytics data
  Map<String, int> _categoryViews = {};
  Map<String, int> _productViews = {};
  Map<String, double> _categoryRevenue = {};
  List<Map<String, dynamic>> _popularProducts = [];
  List<Map<String, dynamic>> _revenueByDay = [];

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // Simulated analytics data - gerçek uygulamada API'den gelecek
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _categoryViews = {
          for (var category in widget.categories)
            category.name: (100 + (category.name.hashCode % 500)).abs()
        };

        _productViews = {
          for (var product in widget.products)
            product.name: (50 + (product.name.hashCode % 200)).abs()
        };

        _categoryRevenue = {
          for (var category in widget.categories)
            category.name:
                ((category.name.hashCode % 10000) + 1000).abs().toDouble()
        };

        _popularProducts = widget.products
            .map((p) => {
                  'name': p.name,
                  'views': (50 + (p.name.hashCode % 200)).abs(),
                  'revenue': ((p.name.hashCode % 5000) + 500).abs().toDouble(),
                  'price': p.price,
                })
            .toList()
          ..sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));

        _revenueByDay = List.generate(
            7,
            (index) => {
                  'day': DateTime.now().subtract(Duration(days: 6 - index)),
                  'revenue':
                      (500 + (index * 100) + (index.hashCode % 300)).toDouble(),
                });
      });
    } catch (e) {
      print('Analytics yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: LoadingIndicator())
              : _buildAnalyticsContent(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menü Analitikleri',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Menünüzün performans verilerini inceleyin',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Period selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildPeriodButton('7 Gün', '7days'),
                _buildPeriodButton('30 Gün', '30days'),
                _buildPeriodButton('90 Gün', '90days'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String title, String period) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () => setState(() => _selectedPeriod = period),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : null,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    if (widget.products.isEmpty || widget.categories.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.analytics_rounded,
          title: 'Analitik veri yok',
          message: 'Menünüze ürün ekleyerek analitik verilerini görebilirsiniz',
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet kartları
          _buildSummaryCards(),

          const SizedBox(height: 32),

          // Grafik alanı
          if (_isMobile) ..._buildMobileCharts() else _buildDesktopCharts(),

          const SizedBox(height: 32),

          // Popüler ürünler listesi
          _buildPopularProductsList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalViews =
        _productViews.values.fold(0, (sum, views) => sum + views);
    final totalRevenue =
        _categoryRevenue.values.fold(0.0, (sum, revenue) => sum + revenue);
    final avgPrice = widget.products.isNotEmpty
        ? widget.products.map((p) => p.price).reduce((a, b) => a + b) /
            widget.products.length
        : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _isMobile ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: _isMobile ? 1.2 : 1.4,
      children: [
        _buildSummaryCard(
          'Toplam Görüntüleme',
          totalViews.toString(),
          Icons.visibility_rounded,
          AppColors.primary,
          '+12%',
        ),
        _buildSummaryCard(
          'Toplam Gelir',
          '${totalRevenue.toStringAsFixed(0)} ₺',
          Icons.monetization_on_rounded,
          AppColors.success,
          '+8%',
        ),
        _buildSummaryCard(
          'Ortalama Fiyat',
          '${avgPrice.toStringAsFixed(0)} ₺',
          Icons.payments_rounded,
          AppColors.info,
          '+5%',
        ),
        _buildSummaryCard(
          'Aktif Ürün',
          widget.products.where((p) => p.isAvailable).length.toString(),
          Icons.restaurant_menu_rounded,
          AppColors.warning,
          '+2%',
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMobileCharts() {
    return [
      _buildCategoryChart(),
      const SizedBox(height: 32),
      _buildRevenueChart(),
    ];
  }

  Widget _buildDesktopCharts() {
    return Row(
      children: [
        Expanded(child: _buildCategoryChart()),
        const SizedBox(width: 32),
        Expanded(child: _buildRevenueChart()),
      ],
    );
  }

  Widget _buildCategoryChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Performansı',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(),
                centerSpaceRadius: 60,
                sectionsSpace: 2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: widget.categories.take(5).map((category) {
              final index = widget.categories.indexOf(category);
              final colors = [
                AppColors.primary,
                AppColors.secondary,
                AppColors.success,
                AppColors.warning,
                AppColors.info,
              ];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];

    final totalViews =
        _categoryViews.values.fold(0, (sum, views) => sum + views);

    return widget.categories.take(5).map((category) {
      final index = widget.categories.indexOf(category);
      final views = _categoryViews[category.name] ?? 0;
      final percentage = totalViews > 0 ? (views / totalViews * 100) : 0;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: views.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günlük Gelir Trendi',
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}₺',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _revenueByDay.length) {
                          final day = _revenueByDay[index]['day'] as DateTime;
                          return Text(
                            '${day.day}/${day.month}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _revenueByDay.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['revenue'],
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
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
    );
  }

  Widget _buildPopularProductsList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                'En Popüler Ürünler',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _popularProducts.take(5).length,
            itemBuilder: (context, index) {
              final product = _popularProducts[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Ranking
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: index < 3
                            ? [
                                AppColors.warning,
                                AppColors.textSecondary,
                                AppColors.warning.withOpacity(0.7)
                              ][index]
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AppTypography.bodyMedium.copyWith(
                            color:
                                index < 3 ? AppColors.white : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product['views']} görüntüleme',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Revenue
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(product['revenue'] as double).toStringAsFixed(0)} ₺',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(product['price'] as double).toStringAsFixed(0)} ₺/adet',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
