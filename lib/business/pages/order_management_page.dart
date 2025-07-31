import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/order.dart';
import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../services/business_firestore_service.dart';
import '../../core/utils/date_utils.dart' as date_utils;

class OrderManagementPage extends StatefulWidget {
  final String businessId;

  const OrderManagementPage({Key? key, required this.businessId})
      : super(key: key);

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage>
    with TickerProviderStateMixin {
  final BusinessFirestoreService _businessFirestoreService =
      BusinessFirestoreService();

  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  Business? _business;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  int? _selectedTableNumber;

  late TabController _tabController;

  // Statistics
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;
  int _todayOrderCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    _setupOrderListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _businessFirestoreService.stopOrderListener(widget.businessId);
    super.dispose();
  }

  void _setupOrderListener() {
    _businessFirestoreService.startOrderListener(
        widget.businessId, _onOrdersChanged);
  }

  void _onOrdersChanged(List<Order> orders) {
    if (mounted) {
      setState(() {
        _orders = orders;
        _updateStatistics();
        _filterOrders();
      });
    }
  }

  void _updateStatistics() {
    _pendingCount =
        _orders.where((o) => o.status == OrderStatus.pending).length;
    _inProgressCount =
        _orders.where((o) => o.status == OrderStatus.inProgress).length;
    _completedCount =
        _orders.where((o) => o.status == OrderStatus.completed).length;

    final today = DateTime.now();
    _todayOrderCount = _orders.where((order) {
      final orderDate = order.createdAt;
      return orderDate.year == today.year &&
          orderDate.month == today.month &&
          orderDate.day == today.day;
    }).length;
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final business =
          await _businessFirestoreService.getBusiness(widget.businessId);

      final orders = await _businessFirestoreService
          .getOrdersByBusiness(widget.businessId);

      setState(() {
        _business = business;
        _orders = orders;
        _isLoading = false;
        _updateStatistics();
        _filterOrders();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Siparişler yüklenirken hata oluştu: $e'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _filterOrders() {
    _filteredOrders = _orders.where((order) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!order.customerName.toLowerCase().contains(query) &&
            !order.orderId.toLowerCase().contains(query) &&
            !order.tableNumber.toString().contains(query)) {
          return false;
        }
      }

      // Status filter
      switch (_selectedStatus) {
        case 'pending':
          if (order.status != OrderStatus.pending) return false;
          break;
        case 'inProgress':
          if (order.status != OrderStatus.inProgress) return false;
          break;
        case 'completed':
          if (order.status != OrderStatus.completed) return false;
          break;
        case 'cancelled':
          if (order.status != OrderStatus.cancelled) return false;
          break;
        case 'today':
          final today = DateTime.now();
          final orderDate = order.createdAt;
          if (!(orderDate.year == today.year &&
              orderDate.month == today.month &&
              orderDate.day == today.day)) return false;
          break;
      }

      // Table filter
      if (_selectedTableNumber != null &&
          order.tableNumber != _selectedTableNumber) {
        return false;
      }

      return true;
    }).toList();

    // Sort by creation date (newest first for most, oldest first for pending)
    if (_selectedStatus == 'pending') {
      _filteredOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      _filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(isWeb, isTablet),
          Expanded(child: _buildBody(isWeb, isTablet)),
        ],
      ),
      floatingActionButton: _pendingCount > 0 ? _buildPendingOrdersFAB() : null,
    );
  }

  Widget _buildHeader(bool isWeb, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withBlue(200),
            AppColors.primary.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 32 : 20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.receipt_long_rounded,
                        color: AppColors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sipariş Yönetimi',
                          style: AppTypography.h5.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Siparişleri yönetin ve takip edin',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.white.withOpacity(0.9),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isWeb)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Canlı Takip',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: isWeb ? 32 : 24),
              _buildSearchBar(isWeb),
              SizedBox(height: isWeb ? 24 : 20),
              _buildStatsCards(isWeb, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterOrders();
          });
        },
        style: AppTypography.bodyMedium.copyWith(letterSpacing: 0.2),
        decoration: InputDecoration(
          hintText: 'Sipariş ara (müşteri, masa, sipariş no)...',
          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon:
                      Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _filterOrders();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isWeb ? 20 : 16,
            vertical: isWeb ? 20 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(bool isWeb, bool isTablet) {
    final stats = [
      {
        'label': 'Bekleyen',
        'count': _pendingCount,
        'color': const Color(0xFFF59E0B),
        'icon': Icons.schedule_rounded,
        'isUrgent': _pendingCount > 0,
      },
      {
        'label': 'Hazırlanıyor',
        'count': _inProgressCount,
        'color': const Color(0xFF3B82F6),
        'icon': Icons.restaurant_rounded,
        'isUrgent': false,
      },
      {
        'label': 'Tamamlanan',
        'count': _completedCount,
        'color': const Color(0xFF10B981),
        'icon': Icons.check_circle_rounded,
        'isUrgent': false,
      },
      {
        'label': 'Bugün',
        'count': _todayOrderCount,
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.today_rounded,
        'isUrgent': false,
      },
    ];

    if (isWeb || isTablet) {
      return Row(
        children: stats
            .map((stat) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildStatCard(
                      stat['label'] as String,
                      stat['count'] as int,
                      stat['color'] as Color,
                      stat['icon'] as IconData,
                      stat['isUrgent'] as bool,
                      isWeb,
                    ),
                  ),
                ))
            .toList(),
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      stats[0]['label'] as String,
                      stats[0]['count'] as int,
                      stats[0]['color'] as Color,
                      stats[0]['icon'] as IconData,
                      stats[0]['isUrgent'] as bool,
                      isWeb)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildStatCard(
                      stats[1]['label'] as String,
                      stats[1]['count'] as int,
                      stats[1]['color'] as Color,
                      stats[1]['icon'] as IconData,
                      stats[1]['isUrgent'] as bool,
                      isWeb)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      stats[2]['label'] as String,
                      stats[2]['count'] as int,
                      stats[2]['color'] as Color,
                      stats[2]['icon'] as IconData,
                      stats[2]['isUrgent'] as bool,
                      isWeb)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildStatCard(
                      stats[3]['label'] as String,
                      stats[3]['count'] as int,
                      stats[3]['color'] as Color,
                      stats[3]['icon'] as IconData,
                      stats[3]['isUrgent'] as bool,
                      isWeb)),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon,
      bool isUrgent, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: isWeb ? 15 : 8,
            offset: Offset(0, isWeb ? 6 : 3),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(isWeb ? 12 : 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(isWeb ? 12 : 8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: isWeb ? 8 : 4,
                      offset: Offset(0, isWeb ? 4 : 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: isWeb ? 24 : 16),
              ),
              if (isUrgent)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: isWeb ? 12 : 10,
                    height: isWeb ? 12 : 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(isWeb ? 6 : 5),
                      border: Border.all(
                          color: Colors.white, width: isWeb ? 2 : 1.5),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isWeb ? 12 : 6),
          Text(
            count.toString(),
            style: (isWeb ? AppTypography.h5 : AppTypography.h6).copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: isWeb ? 4 : 2),
          Text(
            label,
            style: (isWeb ? AppTypography.bodySmall : AppTypography.caption)
                .copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isWeb, bool isTablet) {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    return Container(
      constraints: BoxConstraints(maxWidth: isWeb ? 1400 : double.infinity),
      margin: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 0),
      child: Column(
        children: [
          _buildFilterTabs(isWeb, isTablet),
          Expanded(child: _buildOrdersList(isWeb, isTablet)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isWeb, bool isTablet) {
    final filters = [
      {
        'key': 'all',
        'label': 'Tümü',
        'count': _orders.length,
        'color': const Color(0xFF6B7280)
      },
      {
        'key': 'pending',
        'label': 'Bekleyen',
        'count': _pendingCount,
        'color': const Color(0xFFF59E0B)
      },
      {
        'key': 'inProgress',
        'label': 'Hazırlanıyor',
        'count': _inProgressCount,
        'color': const Color(0xFF3B82F6)
      },
      {
        'key': 'completed',
        'label': 'Tamamlanan',
        'count': _completedCount,
        'color': const Color(0xFF10B981)
      },
      {
        'key': 'today',
        'label': 'Bugün',
        'count': _todayOrderCount,
        'color': const Color(0xFF8B5CF6)
      },
    ];

    return Container(
      margin: EdgeInsets.all(isWeb ? 24 : 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters
              .map((filter) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildFilterChip(
                      filter['key'] as String,
                      filter['label'] as String,
                      filter['count'] as int,
                      filter['color'] as Color,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, int count, Color color) {
    final isSelected = _selectedStatus == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = filter;
          _filterOrders();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withOpacity(0.8)])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 15 : 8,
              offset: Offset(0, isSelected ? 6 : 2),
            ),
          ],
          border: Border.all(
            color: isSelected ? Colors.transparent : color.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(bool isWeb, bool isTablet) {
    if (_filteredOrders.isEmpty) {
      return Container(
        margin: EdgeInsets.all(isWeb ? 24 : 16),
        child: EmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'Sipariş Bulunamadı',
          message: _searchQuery.isNotEmpty || _selectedStatus != 'all'
              ? 'Arama kriterlerinize uygun sipariş bulunamadı.'
              : 'Henüz sipariş bulunmamaktadır.',
          actionText: _searchQuery.isNotEmpty || _selectedStatus != 'all'
              ? 'Filtreleri Temizle'
              : null,
          onActionPressed: _searchQuery.isNotEmpty || _selectedStatus != 'all'
              ? () {
                  setState(() {
                    _searchQuery = '';
                    _selectedStatus = 'all';
                    _selectedTableNumber = null;
                    _filterOrders();
                  });
                }
              : null,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: Container(
        margin: EdgeInsets.all(isWeb ? 24 : 16),
        child: isWeb && MediaQuery.of(context).size.width > 1200
            ? _buildOrdersGrid()
            : _buildOrdersListView(),
      ),
    );
  }

  Widget _buildOrdersGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.3,
      ),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order, true);
      },
    );
  }

  Widget _buildOrdersListView() {
    return ListView.builder(
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildOrderCard(order, false),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order, bool isGrid) {
    final statusColor = _getStatusColor(order.status);
    final timeAgo = date_utils.DateUtils.formatTimeAgo(order.createdAt);
    final orderDate =
        date_utils.DateUtils.formatBusinessDateTime(order.createdAt);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showOrderDetails(order),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isWeb ? 24 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withOpacity(0.8)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          AppColors.primary.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.table_restaurant_rounded,
                                        color: AppColors.primary, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Masa ${order.tableNumber}',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  order.status.displayName,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order.customerName,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeAgo,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.8)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            '${order.totalAmount.toStringAsFixed(2)} TL',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Order items preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.borderColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu_rounded,
                              color: AppColors.textSecondary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Ürünler (${order.items.length})',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.items
                                .take(3)
                                .map((item) =>
                                    '${item.quantity}x ${item.productName}')
                                .join(', ') +
                            (order.items.length > 3 ? '...' : ''),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                if (order.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note_rounded,
                            size: 16, color: const Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.notes!,
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFFA16207),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons
                _buildOrderActions(order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderActions(Order order) {
    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _updateOrderStatus(order, OrderStatus.inProgress),
              icon: const Icon(Icons.restaurant_rounded, size: 16),
              label: const Text('Hazırla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateOrderStatus(order, OrderStatus.cancelled),
              icon: const Icon(Icons.cancel_rounded, size: 16),
              label: const Text('İptal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side:
                    BorderSide(color: const Color(0xFFEF4444).withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else if (order.status == OrderStatus.inProgress) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(order, OrderStatus.completed),
          icon: const Icon(Icons.check_circle_rounded, size: 16),
          label: const Text('Tamamla'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _getStatusColor(order.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: _getStatusColor(order.status).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              order.status == OrderStatus.completed
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: _getStatusColor(order.status),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              order.status == OrderStatus.completed
                  ? 'Sipariş Tamamlandı'
                  : 'Sipariş İptal Edildi',
              style: TextStyle(
                color: _getStatusColor(order.status),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.confirmed:
        return const Color(0xFF3B82F6);
      case OrderStatus.preparing:
        return const Color(0xFFF59E0B);
      case OrderStatus.ready:
        return const Color(0xFF10B981);
      case OrderStatus.delivered:
        return const Color(0xFF10B981);
      case OrderStatus.inProgress:
        return const Color(0xFF3B82F6);
      case OrderStatus.completed:
        return const Color(0xFF10B981);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      await _businessFirestoreService.updateOrderStatus(order.id, newStatus);

      if (mounted) {
        setState(() {
          final index = _orders.indexWhere((o) => o.id == order.id);
          if (index != -1) {
            _orders[index] = _orders[index].copyWith(
              status: newStatus,
              updatedAt: DateTime.now(),
            );
            _updateStatistics();
            _filterOrders();
          }
        });
      }

      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                    'Sipariş ${newStatus.displayName.toLowerCase()} olarak işaretlendi'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Sipariş güncellenirken hata oluştu: $e'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showOrderDetails(Order order) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(isWeb ? 32 : 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: isWeb ? 600 : double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(order.status),
                        _getStatusColor(order.status).withOpacity(0.8)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(order.status).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sipariş #${order.orderId.substring(order.orderId.length - 8)}',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.table_restaurant_rounded,
                                    color: AppColors.primary, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'Masa ${order.tableNumber}',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            order.customerName,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Order items
            Row(
              children: [
                Icon(Icons.restaurant_menu_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Sipariş Detayları',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.borderColor.withOpacity(0.3)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: order.items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.8)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              item.quantity.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              if (item.notes?.isNotEmpty == true) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.notes!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${item.totalPrice.toStringAsFixed(2)} TL',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Total
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Toplam Tutar',
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      '${order.totalAmount.toStringAsFixed(2)} TL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status actions
            if (order.status == OrderStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateOrderStatus(order, OrderStatus.inProgress);
                      },
                      icon: const Icon(Icons.restaurant_rounded),
                      label: const Text('Hazırlamaya Başla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateOrderStatus(order, OrderStatus.cancelled);
                      },
                      icon: const Icon(Icons.cancel_rounded),
                      label: const Text('İptal Et'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: BorderSide(
                            color: const Color(0xFFEF4444).withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (order.status == OrderStatus.inProgress) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateOrderStatus(order, OrderStatus.completed);
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Siparişi Tamamla'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingOrdersFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _selectedStatus = 'pending';
            _filterOrders();
          });
        },
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Stack(
          children: [
            const Icon(Icons.schedule_rounded),
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  _pendingCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        label: Text(
          '$_pendingCount Bekleyen Sipariş',
          style:
              const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
    );
  }
}
