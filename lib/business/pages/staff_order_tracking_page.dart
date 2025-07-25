import 'package:flutter/material.dart';
import '../models/staff.dart';
import '../../data/models/order.dart';
import '../../core/services/order_service.dart';

class StaffOrderTrackingPage extends StatefulWidget {
  final Staff currentStaff;
  
  const StaffOrderTrackingPage({
    Key? key,
    required this.currentStaff,
  }) : super(key: key);

  @override
  State<StaffOrderTrackingPage> createState() => _StaffOrderTrackingPageState();
}

class _StaffOrderTrackingPageState extends State<StaffOrderTrackingPage> {
  final OrderService _orderService = OrderService();
  
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;
  OrderStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    
    // Periyodik yenileme (30 saniyede bir)
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadOrders();
      }
    });
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // İşletme siparişlerini yükle
      final orders = await _orderService.getOrdersByBusinessId(widget.currentStaff.businessId);
      
      // Bugünün siparişlerini filtrele
      final today = DateTime.now();
      final todayOrders = orders.where((order) {
        return order.createdAt.year == today.year &&
               order.createdAt.month == today.month &&
               order.createdAt.day == today.day;
      }).toList();

      // Sıralama: En yeni siparişler önce
      todayOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _orders = todayOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipariş Takibi'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Yenile',
          ),
          PopupMenuButton<OrderStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrele',
            onSelected: (status) {
              setState(() {
                _filterStatus = status;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Tümü'),
              ),
              ...OrderStatus.values.map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(status.displayName),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadOrders,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.refresh, color: Colors.white),
        tooltip: 'Siparişleri Yenile',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Hata: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    final filteredOrders = _filterStatus != null
        ? _orders.where((order) => order.status == _filterStatus).toList()
        : _orders;

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _filterStatus != null
                  ? '${_filterStatus!.displayName} durumunda sipariş bulunamadı'
                  : 'Bugün henüz sipariş yok',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildOrderStats(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return _buildOrderCard(order);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStats() {
    final pendingCount = _orders.where((o) => o.status == OrderStatus.pending).length;
    final inProgressCount = _orders.where((o) => o.status == OrderStatus.inProgress).length;
    final completedCount = _orders.where((o) => o.status == OrderStatus.completed).length;
    final totalRevenue = _orders
        .where((o) => o.status == OrderStatus.completed)
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            title: 'Bekleyen',
            value: '$pendingCount',
            color: Colors.orange,
            icon: Icons.pending,
          ),
          _buildStatItem(
            title: 'Hazırlanıyor',
            value: '$inProgressCount',
            color: Colors.blue,
            icon: Icons.restaurant,
          ),
          _buildStatItem(
            title: 'Tamamlanan',
            value: '$completedCount',
            color: Colors.green,
            icon: Icons.check_circle,
          ),
          _buildStatItem(
            title: 'Gelir',
            value: '₺${totalRevenue.toStringAsFixed(0)}',
            color: Colors.purple,
            icon: Icons.monetization_on,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.customerName} - Masa ${order.tableNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sipariş #${order.orderId.substring(order.orderId.length - 6)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(order.status)),
                        ),
                        child: Text(
                          order.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.orderTimeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} ürün',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₺${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Text(
                    order.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              ],
              if (_canUpdateOrderStatus(order)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (order.status == OrderStatus.pending)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateOrderStatus(order, OrderStatus.inProgress),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Hazırlanıyor'),
                        ),
                      ),
                    if (order.status == OrderStatus.inProgress) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateOrderStatus(order, OrderStatus.completed),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Tamamlandı'),
                        ),
                      ),
                    ],
                    if (order.status == OrderStatus.pending || order.status == OrderStatus.inProgress) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _updateOrderStatus(order, OrderStatus.cancelled),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('İptal'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _canUpdateOrderStatus(Order order) {
    // Müdür her durumu değiştirebilir
    if (widget.currentStaff.role == StaffRole.manager) {
      return order.status != OrderStatus.completed && order.status != OrderStatus.cancelled;
    }

    // Mutfak personeli sipariş durumunu güncelleyebilir
    if (widget.currentStaff.role == StaffRole.kitchen) {
      return order.status == OrderStatus.pending || order.status == OrderStatus.inProgress;
    }

    // Garson ve kasiyer sadece pending siparişleri başlatabilir
    if (widget.currentStaff.role == StaffRole.waiter || widget.currentStaff.role == StaffRole.cashier) {
      return order.status == OrderStatus.pending;
    }

    return false;
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      Order updatedOrder;
      
      switch (newStatus) {
        case OrderStatus.inProgress:
          updatedOrder = order.markAsInProgress();
          break;
        case OrderStatus.completed:
          updatedOrder = order.markAsCompleted();
          break;
        case OrderStatus.cancelled:
          updatedOrder = order.markAsCancelled();
          break;
        default:
          return;
      }

      await _orderService.saveOrder(updatedOrder);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş durumu güncellendi: ${newStatus.displayName}'),
          backgroundColor: Colors.green,
        ),
      );

      // Siparişleri yenile
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sipariş Detayları',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Müşteri: ${order.customerName}'),
                    Text('Masa: ${order.tableNumber}'),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Sipariş Zamanı: ${_formatDateTime(order.createdAt)}'),
                const SizedBox(height: 16),
                Text(
                  'Ürünler:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: order.items.length,
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text('${item.quantity}'),
                        ),
                        title: Text(item.productName),
                        subtitle: Text('₺${item.productPrice.toStringAsFixed(2)}'),
                        trailing: Text(
                          '₺${(item.productPrice * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Toplam:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₺${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue[300]!;
      case OrderStatus.preparing:
        return Colors.cyan;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green[300]!;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.'
           '${dateTime.month.toString().padLeft(2, '0')}.'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 