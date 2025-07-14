import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/order.dart';
import '../../../data/models/business.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/data_service.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import '../../widgets/shared/empty_state.dart';

class OrderManagementPage extends StatefulWidget {
  final String businessId;

  const OrderManagementPage({Key? key, required this.businessId}) : super(key: key);

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> with TickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final DataService _dataService = DataService();

  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  Business? _business;
  bool _isLoading = true;
  String _searchQuery = '';
  OrderStatus? _selectedStatus;
  int? _selectedTableNumber;

  late TabController _tabController;

  // Filter options
  final List<OrderStatus> _statusFilters = [
    OrderStatus.pending,
    OrderStatus.inProgress,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _orderService.addOrderListener(_onOrdersChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderService.removeOrderListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged(List<Order> orders) {
    if (mounted) {
      setState(() {
        _orders = orders;
        _filterOrders();
      });
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _orderService.initialize();
      await _dataService.initialize();

      final orders = await _orderService.getOrdersByBusinessId(
        widget.businessId,
      );
      final business = await _dataService.getBusiness(widget.businessId);

      setState(() {
        _orders = orders;
        _business = business;
        _isLoading = false;
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
      if (_selectedStatus != null && order.status != _selectedStatus) {
        return false;
      }

      // Table filter
      if (_selectedTableNumber != null &&
          order.tableNumber != _selectedTableNumber) {
        return false;
      }

      return true;
    }).toList();

    // Sort by creation date (newest first)
    _filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sipariş durumu güncellendi: ${newStatus.displayName}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş durumu güncellenirken hata oluştu: $e'),
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
      builder: (context) => _buildOrderDetailSheet(order),
    );
  }

  Widget _buildOrderDetailSheet(Order order) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Order details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sipariş #${order.orderId}',
                              style: AppTypography.h4,
                            ),
                            Text(
                              order.formattedTableNumber,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(order.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Customer info
                  _buildDetailRow('Müşteri', order.customerName),
                  if (order.customerPhone != null)
                    _buildDetailRow('Telefon', order.customerPhone!),
                  _buildDetailRow('Sipariş Zamanı', order.orderTimeDisplay),
                  _buildDetailRow('Toplam Tutar', order.formattedTotalAmount),
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _buildDetailRow('Notlar', order.notes!),
                  const SizedBox(height: 24),
                  // Order items
                  Text('Sipariş Detayları', style: AppTypography.h5),
                  const SizedBox(height: 12),
                  ...order.items.map((item) => _buildOrderItemCard(item)),
                ],
              ),
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (order.status == OrderStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateOrderStatus(
                          order.orderId,
                          OrderStatus.inProgress,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Hazırlanıyor'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateOrderStatus(
                          order.orderId,
                          OrderStatus.cancelled,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('İptal Et'),
                    ),
                  ),
                ],
                if (order.status == OrderStatus.inProgress) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateOrderStatus(
                          order.orderId,
                          OrderStatus.completed,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Tamamlandı'),
                    ),
                  ),
                ],
                if (order.status == OrderStatus.completed ||
                    order.status == OrderStatus.cancelled) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Kapat'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(8),
                image: item.productImage != null
                    ? DecorationImage(
                        image: NetworkImage(item.productImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.productImage == null
                  ? const Icon(Icons.restaurant, color: AppColors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${item.quantity}x ${item.formattedUnitPrice}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Text(
                      'Not: ${item.notes}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            // Total price
            Text(
              item.formattedTotalPrice,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişler'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            setState(() {
              _selectedStatus = index == 0 ? null : _statusFilters[index - 1];
              _filterOrders();
            });
          },
          tabs: [
            Tab(text: 'Tümü (${_orders.length})'),
            Tab(
              text:
                  'Bekleyen (${_orders.where((o) => o.status == OrderStatus.pending).length})',
            ),
            Tab(
              text:
                  'Hazırlanan (${_orders.where((o) => o.status == OrderStatus.inProgress).length})',
            ),
            Tab(
              text:
                  'Tamamlanan (${_orders.where((o) => o.status == OrderStatus.completed).length})',
            ),
          ],
        ),
      ),
      body: _isLoading ? const LoadingIndicator() : _buildOrdersList(),
    );
  }

  Widget _buildOrdersList() {
    if (_filteredOrders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long,
        title: 'Sipariş Bulunamadı',
        message: _searchQuery.isNotEmpty || _selectedStatus != null
            ? 'Arama kriterlerinize uygun sipariş bulunamadı.'
            : 'Henüz sipariş bulunmamaktadır.',
        actionText: _searchQuery.isNotEmpty || _selectedStatus != null
            ? 'Filtreleri Temizle'
            : null,
        onActionPressed: _searchQuery.isNotEmpty || _selectedStatus != null
            ? () {
                setState(() {
                  _searchQuery = '';
                  _selectedStatus = null;
                  _selectedTableNumber = null;
                  _tabController.index = 0;
                  _filterOrders();
                });
              }
            : null,
      );
    }

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Sipariş ara...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterOrders();
              });
            },
          ),
        ),
        // Orders list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredOrders.length,
              itemBuilder: (context, index) {
                final order = _filteredOrders[index];
                return _buildOrderCard(order);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.formattedTableNumber,
                          style: AppTypography.h5.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          order.customerName,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(order.status),
                      const SizedBox(height: 4),
                      Text(
                        order.orderTimeDisplay,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Order summary
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderSummary,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.formattedTotalAmount,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quick actions
              Row(
                children: [
                  if (order.status == OrderStatus.pending) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus(
                          order.orderId,
                          OrderStatus.inProgress,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Hazırlanıyor'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus(
                          order.orderId,
                          OrderStatus.cancelled,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('İptal'),
                      ),
                    ),
                  ],
                  if (order.status == OrderStatus.inProgress) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus(
                          order.orderId,
                          OrderStatus.completed,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Tamamlandı'),
                      ),
                    ),
                  ],
                  if (order.status == OrderStatus.completed ||
                      order.status == OrderStatus.cancelled) ...[
                    Expanded(
                      child: Text(
                        order.status == OrderStatus.completed
                            ? 'Tamamlandı'
                            : 'İptal Edildi',
                        style: AppTypography.bodyMedium.copyWith(
                          color: order.status == OrderStatus.completed
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = AppColors.warning;
        textColor = Colors.white;
        break;
      case OrderStatus.inProgress:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        break;
      case OrderStatus.completed:
        backgroundColor = AppColors.success;
        textColor = Colors.white;
        break;
      case OrderStatus.cancelled:
        backgroundColor = AppColors.error;
        textColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: AppTypography.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrele'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status filter
            DropdownButtonFormField<OrderStatus?>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Durum'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tümü')),
                ..._statusFilters.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Table filter
            TextFormField(
              decoration: const InputDecoration(labelText: 'Masa Numarası'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _selectedTableNumber = int.tryParse(value);
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedTableNumber = null;
                _filterOrders();
              });
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          TextButton(
            onPressed: () {
              _filterOrders();
              Navigator.pop(context);
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }
}
 