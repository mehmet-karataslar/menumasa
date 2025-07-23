import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/qr_validation_service.dart';

/// QR Kod Analitik Widget'ı - İşletme paneli için
class QRAnalyticsWidget extends StatefulWidget {
  final String businessId;
  final String businessName;

  const QRAnalyticsWidget({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<QRAnalyticsWidget> createState() => _QRAnalyticsWidgetState();
}

class _QRAnalyticsWidgetState extends State<QRAnalyticsWidget> {
  final QRValidationService _validationService = QRValidationService();
  
  QRCodeAnalytics? _analytics;
  bool _isLoading = true;
  String? _errorMessage;
  
  int _selectedDays = 7; // Varsayılan 7 gün

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: _selectedDays));
      
      final analytics = await _validationService.getQRCodeAnalytics(
        widget.businessId,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Analitik verileri yüklenirken hata: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Kod Analitikleri',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Son $_selectedDays gün',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Zaman aralığı seçici
                _buildTimeRangeSelector(),
              ],
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              _buildLoadingState()
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_analytics != null)
              _buildAnalyticsContent()
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return PopupMenuButton<int>(
      initialValue: _selectedDays,
      onSelected: (days) {
        setState(() {
          _selectedDays = days;
        });
        _loadAnalytics();
      },
      icon: Icon(Icons.date_range_rounded, color: AppColors.primary),
      itemBuilder: (context) => [
        PopupMenuItem(value: 1, child: Text('Son 1 gün')),
        PopupMenuItem(value: 7, child: Text('Son 7 gün')),
        PopupMenuItem(value: 30, child: Text('Son 30 gün')),
        PopupMenuItem(value: 90, child: Text('Son 90 gün')),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Analitik verileri yükleniyor...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
          const SizedBox(height: 12),
          Text(
            'Hata',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAnalytics,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_rounded,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz QR Kod Taranmamış',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'QR kodlarınız tarandığında analitikler burada görünecek.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return Column(
      children: [
        // Özet kartları
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Toplam Tarama',
                _analytics!.totalScans.toString(),
                Icons.qr_code_scanner_rounded,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Günlük Ortalama',
                _analytics!.averageDailyScans.toStringAsFixed(1),
                Icons.trending_up_rounded,
                AppColors.secondary,
              ),
            ),
          ],
        ),

        if (_analytics!.mostUsedTable != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'En Popüler Masa',
                  'Masa ${_analytics!.mostUsedTable}',
                  Icons.table_restaurant_rounded,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Masa Sayısı',
                  _analytics!.tableScans.length.toString(),
                  Icons.restaurant_rounded,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // Günlük grafik
        if (_analytics!.dailyScans.isNotEmpty) ...[
          Text(
            'Günlük QR Kod Tarama Sayısı',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildDailyChart(),
          ),
          const SizedBox(height: 24),
        ],

        // Masa bazında grafik
        if (_analytics!.tableScans.isNotEmpty) ...[
          Text(
            'Masa Bazında Tarama Sayısı',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildTableChart(),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart() {
    final data = _analytics!.dailyScans.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (data.isEmpty) return Container();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final dateStr = data[index].key;
                  final parts = dateStr.split('-');
                  if (parts.length >= 3) {
                    return Text(
                      '${parts[2]}/${parts[1]}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  }
                }
                return Container();
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((entry) => FlSpot(
                      entry.key.toDouble(),
                      entry.value.value.toDouble(),
                    ))
                .toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primary,
                  strokeColor: AppColors.white,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableChart() {
    final sortedTables = _analytics!.tableScans.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxCount = sortedTables.isNotEmpty ? sortedTables.first.value : 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCount.toDouble() * 1.2,
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedTables.length) {
                  return Text(
                    'M${sortedTables[index].key}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedTables
            .asMap()
            .entries
            .map((entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: AppColors.secondary,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }
} 