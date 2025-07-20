import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/firestore_service.dart';
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
  final FirestoreService _firestoreService = FirestoreService();

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

      final business = await _firestoreService.getBusiness(widget.businessId);
      List<Order> orders = [];

      // Load orders for business
      final allOrders = await _firestoreService.getOrders(businessId: widget.businessId);
      
      if (widget.customerPhone != null) {
        // Filter orders for specific customer
        orders = allOrders.where((order) => order.customerPhone == widget.customerPhone).toList();
      } else {
        // Load all orders for business (fallback)
        orders = allOrders;
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

    final status = OrderStatus.values.firstWhere(
      (s) => s.name == _selectedStatus,
      orElse: () => OrderStatus.pending,
    );

    return _orders.where((order) => order.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişlerim'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading ? const LoadingIndicator() : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long,
        title: 'Henüz Sipariş Yok',
        message:
            'Henüz hiç sipariş vermediniz. Menüden ürün seçerek sipariş verebilirsiniz.',
        actionText: 'Menüye Git',
        onActionPressed: () => Navigator.pop(context),
      );
    }

    return Column(
      children: [
        // Business info header
        if (_business != null) _buildBusinessHeader(),

        // Status filter
        _buildStatusFilter(),

        // Orders list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _buildOrdersList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.white,
            ),
            child: const Icon(
              Icons.restaurant,
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
                  _business!.businessName,
                  style: AppTypography.h5.copyWith(color: AppColors.white),
                ),
                Text(
                  'Sipariş Takip',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Tümü', _orders.length),
            const SizedBox(width: 8),
            _buildFilterChip(
              'pending',
              'Bekliyor',
              _orders.where((o) => o.status == OrderStatus.pending).length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'inProgress',
              'Hazırlanıyor',
              _orders.where((o) => o.status == OrderStatus.inProgress).length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'completed',
              'Tamamlandı',
              _orders.where((o) => o.status == OrderStatus.completed).length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'cancelled',
              'İptal',
              _orders.where((o) => o.status == OrderStatus.cancelled).length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildOrdersList() {
    final filteredOrders = _filteredOrders;

    if (filteredOrders.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list,
        title: 'Sipariş Bulunamadı',
        message: 'Seçilen durumda sipariş bulunmuyor.',
        actionText: 'Filtreyi Temizle',
        onActionPressed: () {
          setState(() {
            _selectedStatus = 'all';
          });
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
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
                          'Sipariş #${order.orderId.substring(0, 8)}',
                          style: AppTypography.h6.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          order.formattedTableNumber,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
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
              Text(
                order.orderSummary,
                style: AppTypography.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Progress indicator
              _buildProgressIndicator(order.status),

              const SizedBox(height: 12),

              // Order total and details button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Toplam: ${order.formattedTotalAmount}',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showOrderDetails(order),
                    child: const Text('Detaylar'),
                  ),
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
    String label;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = AppColors.warning;
        textColor = Colors.white;
        label = 'Bekliyor';
        break;
      case OrderStatus.inProgress:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        label = 'Hazırlanıyor';
        break;
      case OrderStatus.completed:
        backgroundColor = AppColors.success;
        textColor = Colors.white;
        label = 'Tamamlandı';
        break;
      case OrderStatus.cancelled:
        backgroundColor = AppColors.error;
        textColor = Colors.white;
        label = 'İptal Edildi';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(OrderStatus status) {
    final steps = [
      {'label': 'Sipariş Alındı', 'status': OrderStatus.pending},
      {'label': 'Hazırlanıyor', 'status': OrderStatus.inProgress},
      {'label': 'Tamamlandı', 'status': OrderStatus.completed},
    ];

    if (status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: AppColors.error, size: 16),
            const SizedBox(width: 8),
            Text(
              'Sipariş iptal edildi',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final stepStatus = step['status'] as OrderStatus;
        final isActive = _getStatusIndex(status) >= index;
        final isCompleted = _getStatusIndex(status) > index;

        return Expanded(
          child: Row(
            children: [
              // Step indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success
                      : isActive
                      ? AppColors.primary
                      : AppColors.greyLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  color: Colors.white,
                  size: 12,
                ),
              ),

              // Step label
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step['label'] as String,
                  style: AppTypography.bodySmall.copyWith(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Connector line (except for last step)
              if (index < steps.length - 1)
                Container(
                  height: 2,
                  width: 20,
                  color: isCompleted ? AppColors.success : AppColors.greyLight,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  int _getStatusIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.inProgress:
        return 1;
      case OrderStatus.completed:
        return 2;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderDetailsSheet(order),
    );
  }

  Widget _buildOrderDetailsSheet(Order order) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sipariş Detayları', style: AppTypography.h4),
                      Text(
                        'Sipariş #${order.orderId.substring(0, 8)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order info
                  _buildDetailRow('Masa Numarası', order.formattedTableNumber),
                  _buildDetailRow('Sipariş Zamanı', order.orderTimeDisplay),
                  _buildDetailRow('Müşteri', order.customerName),
                  if (order.customerPhone?.isNotEmpty == true)
                    _buildDetailRow('Telefon', order.customerPhone!),

                  const SizedBox(height: 16),

                  // Order items
                  Text('Sipariş İçeriği', style: AppTypography.h5),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => _buildOrderItem(item)),

                  const SizedBox(height: 16),

                  // Notes
                  if (order.notes?.isNotEmpty == true) ...[
                    Text('Notlar', style: AppTypography.h5),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.notes!,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Toplam Tutar',
                          style: AppTypography.h5.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          order.formattedTotalAmount,
                          style: AppTypography.h4.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
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
                if (item.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Not: ${item.notes!}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${item.quantity}x',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.formattedTotalPrice} ₺',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
