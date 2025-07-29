import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../models/waiter_call.dart';
import '../models/staff.dart';
import '../services/waiter_call_service.dart';
import '../services/staff_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../../core/utils/date_utils.dart' as date_utils;

class StaffCallManagementPage extends StatefulWidget {
  final String businessId;

  const StaffCallManagementPage({super.key, required this.businessId});

  @override
  State<StaffCallManagementPage> createState() =>
      _StaffCallManagementPageState();
}

class _StaffCallManagementPageState extends State<StaffCallManagementPage>
    with TickerProviderStateMixin {
  final WaiterCallService _waiterCallService = WaiterCallService();
  final StaffService _staffService = StaffService();

  List<WaiterCall> _allCalls = [];
  List<WaiterCall> _activeCalls = [];
  List<WaiterCall> _completedCalls = [];
  List<Staff> _staff = [];

  bool _isLoading = true;
  String? _errorMessage;

  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadData();
    _startRealTimeUpdates();
    _startPulseAnimation();
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  void _startRealTimeUpdates() {
    // Update every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadData();
        _startRealTimeUpdates();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final calls =
          await _waiterCallService.getWaiterCallsByBusiness(widget.businessId);
      final staff = await _staffService.getStaffByBusiness(widget.businessId);

      setState(() {
        _allCalls = calls;
        _activeCalls = calls
            .where((call) =>
                call.status == WaiterCallStatus.pending ||
                call.status == WaiterCallStatus.responded)
            .toList();
        _completedCalls = calls
            .where((call) =>
                call.status == WaiterCallStatus.completed ||
                call.status == WaiterCallStatus.cancelled)
            .toList();
        _staff = staff;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Veriler yüklenirken hata: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCallStatus(
      WaiterCall call, WaiterCallStatus newStatus) async {
    try {
      await _waiterCallService.updateWaiterCall(
        call.copyWith(
          status: newStatus,
          respondedAt: newStatus == WaiterCallStatus.responded
              ? DateTime.now()
              : call.respondedAt,
          completedAt: newStatus == WaiterCallStatus.completed
              ? DateTime.now()
              : call.completedAt,
        ),
      );

      HapticFeedback.mediumImpact();
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.white),
              const SizedBox(width: 12),
              Text('Çağrı durumu güncellendi'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Geri',
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.room_service_rounded, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garson Çağrıları',
                  style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Gerçek zamanlı takip',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _activeCalls.isNotEmpty
                            ? _pulseAnimation.value
                            : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _activeCalls.isNotEmpty
                                ? AppColors.warning
                                : AppColors.greyLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.priority_high_rounded,
                            size: 16,
                            color: AppColors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text('Aktif (${_activeCalls.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text('Tamamlanan (${_completedCalls.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text('İstatistikler'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
              ? Center(child: ErrorMessage(message: _errorMessage!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveCallsTab(),
                    _buildCompletedCallsTab(),
                    _buildStatisticsTab(),
                  ],
                ),
    );
  }

  Widget _buildActiveCallsTab() {
    if (_activeCalls.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.room_service_outlined,
          title: 'Aktif Çağrı Yok',
          message: 'Şu anda bekleyen garson çağrısı bulunmuyor.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeCalls.length,
        itemBuilder: (context, index) {
          final call = _activeCalls[index];
          return _buildActiveCallCard(call);
        },
      ),
    );
  }

  Widget _buildActiveCallCard(WaiterCall call) {
    final staff = _staff.firstWhere(
      (s) => s.staffId == call.waiterId,
      orElse: () => Staff.create(
        businessId: widget.businessId,
        firstName: 'Bilinmeyen',
        lastName: 'Garson',
        email: '',
        phone: '',
        password: '',
      ),
    );

    final isUrgent = DateTime.now().difference(call.createdAt).inMinutes > 5;
    final responseTime = call.respondedAt != null
        ? call.respondedAt!.difference(call.createdAt).inMinutes
        : DateTime.now().difference(call.createdAt).inMinutes;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isUrgent ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isUrgent
                ? AppColors.error
                : AppColors.greyLight.withOpacity(0.5),
            width: isUrgent ? 2 : 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isUrgent
                ? LinearGradient(
                    colors: [
                      AppColors.error.withOpacity(0.05),
                      AppColors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Table Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.table_restaurant_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'MASA ${call.tableNumber}',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(call.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(call.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(call.status),
                            style: AppTypography.caption.copyWith(
                              color: _getStatusColor(call.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isUrgent) ...[
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_rounded,
                                size: 12,
                                color: AppColors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Customer Info
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.customerName,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Müşteri',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Message
                if (call.message != null && call.message!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 16,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            call.message!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.info,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Time Info
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${DateTime.now().difference(call.createdAt).inMinutes} dk önce',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color:
                          isUrgent ? AppColors.error : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$responseTime dakika',
                      style: AppTypography.caption.copyWith(
                        color: isUrgent
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontWeight:
                            isUrgent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    if (call.status == WaiterCallStatus.pending) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateCallStatus(
                              call, WaiterCallStatus.responded),
                          icon: Icon(Icons.check_rounded, size: 18),
                          label: Text('Yanıtla'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateCallStatus(call, WaiterCallStatus.completed),
                        icon: Icon(Icons.done_all_rounded, size: 18),
                        label: Text('Tamamla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.error.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () =>
                            _updateCallStatus(call, WaiterCallStatus.cancelled),
                        icon: Icon(Icons.close_rounded, color: AppColors.error),
                        tooltip: 'İptal Et',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCallsTab() {
    if (_completedCalls.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.history_rounded,
          title: 'Tamamlanan Çağrı Yok',
          message: 'Henüz tamamlanan garson çağrısı bulunmuyor.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedCalls.length,
      itemBuilder: (context, index) {
        final call = _completedCalls[index];
        return _buildCompletedCallCard(call);
      },
    );
  }

  Widget _buildCompletedCallCard(WaiterCall call) {
    final responseTime = call.respondedAt != null
        ? call.respondedAt!.difference(call.createdAt).inMinutes
        : null;

    final completionTime = call.completedAt != null
        ? call.completedAt!.difference(call.createdAt).inMinutes
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'MASA ${call.tableNumber}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(call.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(call.status),
                      style: AppTypography.caption.copyWith(
                        color: _getStatusColor(call.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                call.customerName,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${call.createdAt.day}.${call.createdAt.month}.${call.createdAt.year} ${call.createdAt.hour}:${call.createdAt.minute.toString().padLeft(2, '0')}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  if (completionTime != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.timer_outlined,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '${completionTime}dk',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final totalCalls = _allCalls.length;
    final avgResponseTime = _calculateAverageResponseTime();
    final todaysCalls = _allCalls
        .where((call) => call.createdAt
            .isAfter(DateTime.now().subtract(const Duration(days: 1))))
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                title: 'Toplam Çağrı',
                value: totalCalls.toString(),
                icon: Icons.room_service_rounded,
                color: AppColors.primary,
              ),
              _buildStatCard(
                title: 'Bugünkü Çağrılar',
                value: todaysCalls.toString(),
                icon: Icons.today_rounded,
                color: AppColors.info,
              ),
              _buildStatCard(
                title: 'Ort. Yanıt Süresi',
                value: '${avgResponseTime.toStringAsFixed(1)} dk',
                icon: Icons.timer_outlined,
                color: AppColors.warning,
              ),
              _buildStatCard(
                title: 'Aktif Çağrılar',
                value: _activeCalls.length.toString(),
                icon: Icons.priority_high_rounded,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.05), AppColors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(WaiterCallStatus status) {
    switch (status) {
      case WaiterCallStatus.pending:
        return AppColors.warning;
      case WaiterCallStatus.responded:
        return AppColors.info;
      case WaiterCallStatus.completed:
        return AppColors.success;
      case WaiterCallStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getStatusText(WaiterCallStatus status) {
    switch (status) {
      case WaiterCallStatus.pending:
        return 'Bekliyor';
      case WaiterCallStatus.responded:
        return 'Yanıtlandı';
      case WaiterCallStatus.completed:
        return 'Tamamlandı';
      case WaiterCallStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  double _calculateAverageResponseTime() {
    if (_allCalls.isEmpty) return 0.0;

    final responseTimes = _allCalls
        .where((call) => call.respondedAt != null)
        .map((call) =>
            call.respondedAt!.difference(call.createdAt).inMinutes.toDouble())
        .toList();

    if (responseTimes.isEmpty) return 0.0;

    return responseTimes.reduce((a, b) => a + b) / responseTimes.length;
  }
}
