import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../data/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/order_service.dart';
import '../../core/services/data_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';

class CustomerOrdersPage extends StatefulWidget {
  final String businessId;
  final String? customerPhone;

  const CustomerOrdersPage({
    Key? key,
    required this.businessId,
    this.customerPhone,
  }) : super(key: key);

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  final OrderService _orderService = OrderService();
  final DataService _dataService = DataService();

  List<Order> _orders = [];
  Business? _business;
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
    // Refresh orders every 30 seconds for real-time updates
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadData();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _orderService.initialize();
      await _dataService.initialize();

      final business = await _dataService.getBusiness(widget.businessId);
      List<Order> orders = [];

      if (widget.customerPhone != null) {
        // Load orders for specific customer
        orders = await _orderService.getOrdersByCustomerPhone(
          widget.customerPhone!,
          widget.businessId,
        );
      } else {
        // Load all orders for business (fallback)
        orders = await _orderService.getOrdersByBusinessId(widget.businessId);
      }

      // Sort orders by date (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _business = business;
        _orders = orders;
        _isLoading = false;
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

  List<Order> get _filteredOrders {
    if (_selectedStatus == 'all') {
      return _orders;
    }
    return _orders.where((order) => order.status == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? const LoadingIndicator() : _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Siparişlerim',
        style: AppTypography.h3.copyWith(color: AppColors.white),
      ),
      backgroundColor: AppColors.primary,
      elevation: 0,
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Business info header
        if (_business != null) _buildBusinessHeader(),
        
        // Status filter
        _buildStatusFilter(),
        
        // Orders list
        Expanded(
          child: _filteredOrders.isEmpty
              ? _buildEmptyState()
              : _buildOrdersList(),
        ),
      ],
    );
  }

  Widget _buildBusinessHeader() {
    return Container(
      padding: AppDimensions.paddingL,
      color: AppColors.white,
      child: Row(
        children: [
          if (_business!.logoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _business!.logoUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.greyLighter,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: AppColors.greyLight,
                      size: 30,
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.greyLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.store,
                color: AppColors.greyLight,
                size: 30,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _business!.businessName,
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _business!.businessType,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (widget.customerPhone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Müşteri: ${widget.customerPhone}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = [
      {'key': 'all', 'label': 'Tümü'},
      {'key': 'pending', 'label': 'Beklemede'},
      {'key': 'confirmed', 'label': 'Onaylandı'},
      {'key': 'preparing', 'label': 'Hazırlanıyor'},
      {'key': 'ready', 'label': 'Hazır'},
      {'key': 'delivered', 'label': 'Teslim Edildi'},
      {'key': 'cancelled', 'label': 'İptal Edildi'},
    ];

    return Container(
      height: 50,
      color: AppColors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppDimensions.paddingM,
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status['key'];

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStatus = status['key']!;
                  });
                }
              },
              backgroundColor: AppColors.greyLighter,
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    if (_orders.isEmpty) {
      message = widget.customerPhone != null
          ? 'Bu müşterinin henüz siparişi yok'
          : 'Henüz sipariş yok';
      icon = Icons.receipt_long;
    } else {
      message = 'Bu durumda sipariş bulunamadı';
      icon = Icons.filter_list;
    }

    return EmptyState(
      icon: icon,
      title: 'Sipariş Bulunamadı',
      message: message,
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: AppDimensions.paddingM,
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(_filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sipariş #${order.id.substring(0, 8)}',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildStatusBadge(order.status.toString().split('.').last),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Order info
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(order.createdAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (order.tableNumber != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.table_restaurant,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Masa ${order.tableNumber}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Order items
            Column(
              children: order.items.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.productName}',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      Text(
                        '${(item.price * item.quantity).toStringAsFixed(2)} ₺',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            if (order.items.length > 3) ...[
              const SizedBox(height: 4),
              Text(
                '+${order.items.length - 3} ürün daha',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Order total and customer info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.customerName != null) ...[
                      Text(
                        'Müşteri: ${order.customerName}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (order.customerPhone != null) ...[
                      Text(
                        'Tel: ${order.customerPhone}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Toplam',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${order.totalAmount.toStringAsFixed(2)} ₺',
                      style: AppTypography.h5.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Notes
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.greyLighter,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'pending':
        color = AppColors.warning;
        text = 'Beklemede';
        break;
      case 'confirmed':
        color = AppColors.info;
        text = 'Onaylandı';
        break;
      case 'preparing':
        color = AppColors.primary;
        text = 'Hazırlanıyor';
        break;
      case 'ready':
        color = AppColors.success;
        text = 'Hazır';
        break;
      case 'delivered':
        color = AppColors.success;
        text = 'Teslim Edildi';
        break;
      case 'cancelled':
        color = AppColors.error;
        text = 'İptal Edildi';
        break;
      default:
        color = AppColors.textSecondary;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }
} 