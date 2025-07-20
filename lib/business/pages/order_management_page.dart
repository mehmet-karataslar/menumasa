import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/order.dart';
import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/order_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../services/business_firestore_service.dart';

class OrderManagementPage extends StatefulWidget {
  final String businessId;

  const OrderManagementPage({Key? key, required this.businessId}) : super(key: key);

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> with TickerProviderStateMixin {
  final BusinessFirestoreService _businessFirestoreService = BusinessFirestoreService();

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
    _businessFirestoreService.startOrderListener(widget.businessId, _onOrdersChanged);
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
    _pendingCount = _orders.where((o) => o.status == OrderStatus.pending).length;
    _inProgressCount = _orders.where((o) => o.status == OrderStatus.inProgress).length;
    _completedCount = _orders.where((o) => o.status == OrderStatus.completed).length;
    
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

      // Load business info
      final business = await _businessFirestoreService.getBusiness(widget.businessId);

      // Load initial orders
      final orders = await _businessFirestoreService.getOrdersByBusiness(widget.businessId);

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
            content: Text('Siparişler yüklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _buildBody(),
      floatingActionButton: _pendingCount > 0 ? _buildPendingOrdersFAB() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    return Column(
      children: [
        // Header with statistics
        _buildHeader(),
        
        // Filter tabs
        _buildFilterTabs(),
        
        // Orders list
        Expanded(child: _buildOrdersList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterOrders();
                });
              },
              decoration: InputDecoration(
                hintText: 'Sipariş ara (müşteri adı, masa no, sipariş no)...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Statistics cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Bekleyen',
                  _pendingCount.toString(),
                  AppColors.warning,
                  Icons.schedule,
                  _pendingCount > 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Hazırlanan',
                  _inProgressCount.toString(),
                  AppColors.info,
                  Icons.restaurant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Tamamlanan',
                  _completedCount.toString(),
                  AppColors.success,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Bugün',
                  _todayOrderCount.toString(),
                  AppColors.primary,
                  Icons.today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon, [bool isUrgent = false]) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Icon(icon, color: color, size: 20),
              if (isUrgent)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h6.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildFilterChip('all', 'Tümü', _orders.length),
            const SizedBox(width: 8),
            _buildFilterChip('pending', 'Bekleyen', _pendingCount),
            const SizedBox(width: 8),
            _buildFilterChip('inProgress', 'Hazırlanan', _inProgressCount),
            const SizedBox(width: 8),
            _buildFilterChip('completed', 'Tamamlanan', _completedCount),
            const SizedBox(width: 8),
            _buildFilterChip('today', 'Bugün', _todayOrderCount),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, int count) {
    final isSelected = _selectedStatus == filter;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = filter;
          _filterOrders();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.white : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_filteredOrders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long,
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
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    final timeAgo = _getTimeAgo(order.createdAt);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Order status indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Order info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Masa ${order.tableNumber}',
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                order.status.displayName,
                                style: AppTypography.caption.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          order.customerName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Time and amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeAgo,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      Text(
                        '${order.totalAmount.toStringAsFixed(2)} TL',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Order items preview
              Text(
                'Ürünler (${order.items.length})',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.items.take(3).map((item) => 
                  '${item.quantity}x ${item.productName}'
                ).join(', ') + (order.items.length > 3 ? '...' : ''),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (order.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.notes!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  if (order.status == OrderStatus.pending) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateOrderStatus(order, OrderStatus.inProgress),
                        icon: const Icon(Icons.restaurant, size: 16),
                        label: const Text('Hazırla'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.info,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateOrderStatus(order, OrderStatus.cancelled),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('İptal'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                  ] else if (order.status == OrderStatus.inProgress) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateOrderStatus(order, OrderStatus.completed),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Tamamla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      order.status == OrderStatus.completed
                          ? 'Sipariş tamamlandı'
                          : 'Sipariş iptal edildi',
                      style: AppTypography.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.preparing:
        return AppColors.warning;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.inProgress:
        return AppColors.info;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}dk';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s';
    } else {
      return '${difference.inDays}g';
    }
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      await _businessFirestoreService.updateOrderStatus(order.id, newStatus);
      
      HapticFeedback.lightImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sipariş ${newStatus.displayName.toLowerCase()} olarak işaretlendi',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş güncellenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: _getStatusColor(order.status),
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
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Masa ${order.tableNumber} - ${order.customerName}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Order items
            Text(
              'Sipariş Detayları',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        item.quantity.toString(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.productName,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  Text(
                    '${item.totalPrice.toStringAsFixed(2)} TL',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )).toList(),
            
            const Divider(height: 24),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Toplam',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${order.totalAmount.toStringAsFixed(2)} TL',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status actions
            if (order.status == OrderStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateOrderStatus(order, OrderStatus.inProgress);
                      },
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Hazırla'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateOrderStatus(order, OrderStatus.cancelled);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('İptal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
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
                  icon: const Icon(Icons.check),
                  label: const Text('Tamamla'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
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
    return FloatingActionButton.extended(
      onPressed: () {
        setState(() {
          _selectedStatus = 'pending';
          _filterOrders();
        });
      },
      backgroundColor: AppColors.warning,
      foregroundColor: AppColors.white,
      icon: Stack(
        children: [
          const Icon(Icons.schedule),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _pendingCount.toString(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      label: Text('$_pendingCount Bekleyen'),
    );
  }
}
 