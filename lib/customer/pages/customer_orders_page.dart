import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masamenu/customer/services/customer_service.dart';
import '../../data/models/order.dart' as app_order;
import '../../business/models/business.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../services/customer_firestore_service.dart';
import '../models/review_rating.dart';
import '../models/customer_feedback.dart';

class CustomerOrdersPage extends StatefulWidget {
  final String? businessId;
  final String? customerPhone;
  final String? customerId;

  const CustomerOrdersPage({
    Key? key,
    this.businessId,
    this.customerPhone,
    this.customerId,
  }) : super(key: key);

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage>
    with TickerProviderStateMixin {
  final CustomerService _customerService = CustomerService();
  final CustomerFirestoreService _customerFirestoreService = CustomerFirestoreService();

  List<app_order.Order> _orders = [];
  Map<String, Business> _businessCache = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'Tümü';

  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _filterOptions = ['Tümü', 'Bekliyor', 'Hazırlanıyor', 'Tamamlandı', 'İptal Edildi'];

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic));

    _loadOrders();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      List<app_order.Order> orders;
      
      if (widget.customerId != null) {
        // Load orders by customer ID
        orders = await _customerFirestoreService.getOrdersByCustomer(widget.customerId!);
      } else if (widget.businessId != null && widget.customerPhone != null) {
        // Load orders by business and phone
        orders = await _customerFirestoreService.getOrdersByBusinessAndPhone(
          widget.businessId!,
          widget.customerPhone!,
        );
      } else if (widget.businessId != null) {
        // Load orders by business only
        orders = await _customerFirestoreService.getOrdersByBusiness(widget.businessId!);
      } else {
        orders = [];
      }

      // Load business details for each order
      final businessIds = orders.map((o) => o.businessId).toSet();
      for (final businessId in businessIds) {
        if (!_businessCache.containsKey(businessId)) {
          try {
            final business = await _customerFirestoreService.getBusiness(businessId);
            if (business != null) {
              _businessCache[businessId] = business;
            }
          } catch (e) {
            print('Error loading business $businessId: $e');
          }
        }
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      _fadeAnimationController.forward();
      _slideAnimationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Siparişler yüklenirken hata: $e';
        _isLoading = false;
      });
    }
  }

  List<app_order.Order> get _filteredOrders {
    if (_selectedFilter == 'Tümü') {
      return _orders;
    }
    
    final statusFilter = _getOrderStatusFromString(_selectedFilter);
    return _orders.where((order) => order.status == statusFilter).toList();
  }

  app_order.OrderStatus _getOrderStatusFromString(String status) {
    switch (status) {
      case 'Bekliyor':
        return app_order.OrderStatus.pending;
      case 'Hazırlanıyor':
        return app_order.OrderStatus.inProgress;
      case 'Tamamlandı':
        return app_order.OrderStatus.completed;
      case 'İptal Edildi':
        return app_order.OrderStatus.cancelled;
      default:
        return app_order.OrderStatus.pending;
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: LoadingIndicator())
          : _errorMessage != null
          ? Center(child: ErrorMessage(message: _errorMessage!))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildFilterTabs(),
                  Expanded(
                    child: _buildOrdersList(),
                  ),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Siparişlerim',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          if (_orders.isNotEmpty)
            Text(
              '${_filteredOrders.length} sipariş',
              style: AppTypography.caption.copyWith(
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _loadOrders,
          icon: Icon(Icons.refresh_rounded),
          tooltip: 'Yenile',
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: EdgeInsets.all(16),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = filter == _selectedFilter;
          final orderCount = filter == 'Tümü' 
              ? _orders.length 
              : _orders.where((o) => _getOrderStatusText(o.status) == filter).length;

          return Container(
            margin: EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onFilterChanged(filter),
                borderRadius: BorderRadius.circular(25),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.greyLight,
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: AppColors.shadow.withOpacity(0.08),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected ? AppColors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      if (orderCount > 0) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.white.withOpacity(0.2) 
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            orderCount.toString(),
                            style: AppTypography.caption.copyWith(
                              color: isSelected ? AppColors.white : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    final filteredOrders = _filteredOrders;

    if (filteredOrders.isEmpty) {
      return SlideTransition(
        position: _slideAnimation,
        child: _buildEmptyState(),
      );
    }

    return SlideTransition(
      position: _slideAnimation,
      child: RefreshIndicator(
        onRefresh: _loadOrders,
        color: AppColors.primary,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return _buildOrderCard(order, index);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 'Bekliyor':
        title = 'Bekleyen sipariş yok';
        subtitle = 'Şu anda bekleyen siparişiniz bulunmuyor';
        icon = Icons.schedule_rounded;
        break;
      case 'Hazırlanıyor':
        title = 'Hazırlanan sipariş yok';
        subtitle = 'Şu anda hazırlanan siparişiniz bulunmuyor';
        icon = Icons.restaurant_rounded;
        break;
      case 'Tamamlandı':
        title = 'Tamamlanan sipariş yok';
        subtitle = 'Henüz tamamlanmış siparişiniz bulunmuyor';
        icon = Icons.check_circle_rounded;
        break;
      case 'İptal Edildi':
        title = 'İptal edilen sipariş yok';
        subtitle = 'İptal edilmiş siparişiniz bulunmuyor';
        icon = Icons.cancel_rounded;
        break;
      default:
        title = 'Henüz siparişiniz yok';
        subtitle = 'İlk siparişinizi vererek başlayın';
        icon = Icons.receipt_long_rounded;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.greyLighter,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedFilter == 'Tümü') ...[
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.restaurant_menu_rounded),
                label: Text('Sipariş Ver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(app_order.Order order, int index) {
    final business = _businessCache[order.businessId];
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(order, business),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(order, business),
                SizedBox(height: 16),
                _buildOrderItems(order),
                SizedBox(height: 16),
                _buildOrderFooter(order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(app_order.Order order, Business? business) {
    return Row(
      children: [
        // Order icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getOrderStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getOrderStatusIcon(order.status),
            color: _getOrderStatusColor(order.status),
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        // Order info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sipariş #${order.orderId.substring(0, 8)}',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getOrderStatusColor(order.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getOrderStatusText(order.status),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              if (business != null)
                Text(
                  business.businessName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.table_restaurant_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Masa ${order.tableNumber}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatOrderDate(order.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems(app_order.Order order) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greyLighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sipariş Detayları',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: order.items.length > 3 ? 3 : order.items.length,
            separatorBuilder: (context, index) => SizedBox(height: 4),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.productName}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(item.price * item.quantity).toStringAsFixed(2)} ₺',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
          if (order.items.length > 3) ...[
            SizedBox(height: 4),
            Text(
              '+${order.items.length - 3} ürün daha...',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderFooter(app_order.Order order) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 4),
                Text(
                  '${order.items.length} ürün',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              'Toplam: ${order.totalAmount.toStringAsFixed(2)} ₺',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        // Değerlendirme butonu (sadece tamamlanmış siparişler için)
        if (order.status == 'completed' || order.status == 'delivered') ...[
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showReviewDialog(order),
                  icon: Icon(
                    Icons.star_rate_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  label: Text(
                    'Değerlendir',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.warning.withOpacity(0.3)),
                    backgroundColor: AppColors.warning.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFeedbackDialog(order),
                  icon: Icon(
                    Icons.feedback_rounded,
                    size: 16,
                    color: AppColors.info,
                  ),
                  label: Text(
                    'Geri Bildirim',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.info.withOpacity(0.3)),
                    backgroundColor: AppColors.info.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showOrderDetails(app_order.Order order, Business? business) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderDetailsModal(order, business),
    );
  }

  Widget _buildOrderDetailsModal(app_order.Order order, Business? business) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getOrderStatusIcon(order.status),
                    color: _getOrderStatusColor(order.status),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sipariş #${order.orderId.substring(0, 8)}',
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (business != null)
                        Text(
                          business.businessName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(order.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getOrderStatusText(order.status),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.greyLight),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order info
                  _buildDetailSection('Sipariş Bilgileri', [
                    _buildDetailRow('Sipariş No', '#${order.orderId.substring(0, 8)}'),
                    _buildDetailRow('Tarih', _formatOrderDateDetailed(order.createdAt)),
                    _buildDetailRow('Masa', 'Masa ${order.tableNumber}'),
                    _buildDetailRow('Müşteri', order.customerName),
                    if (order.customerPhone != null)
                      _buildDetailRow('Telefon', order.customerPhone!),
                    if (order.notes != null && order.notes!.isNotEmpty)
                      _buildDetailRow('Notlar', order.notes!),
                  ]),

                  SizedBox(height: 24),

                  // Order items
                  _buildDetailSection('Sipariş İçeriği', 
                    order.items.map((item) => 
                      _buildItemRow(item)
                    ).toList(),
                  ),

                  SizedBox(height: 24),

                  // Total
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Toplam Tutar',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${order.totalAmount.toStringAsFixed(2)} ₺',
                          style: AppTypography.h5.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.greyLighter,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': ',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(app_order.OrderItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    'Not: ${item.notes}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.price.toStringAsFixed(2)} ₺',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(item.price * item.quantity).toStringAsFixed(2)} ₺',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getOrderStatusColor(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return AppColors.warning;
      case app_order.OrderStatus.confirmed:
        return AppColors.info;
      case app_order.OrderStatus.preparing:
        return AppColors.warning;
      case app_order.OrderStatus.ready:
        return AppColors.success;
      case app_order.OrderStatus.delivered:
        return AppColors.success;
      case app_order.OrderStatus.inProgress:
        return AppColors.info;
      case app_order.OrderStatus.completed:
        return AppColors.success;
      case app_order.OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getOrderStatusIcon(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return Icons.schedule_rounded;
      case app_order.OrderStatus.confirmed:
        return Icons.check_rounded;
      case app_order.OrderStatus.preparing:
        return Icons.restaurant_rounded;
      case app_order.OrderStatus.ready:
        return Icons.done_all_rounded;
      case app_order.OrderStatus.delivered:
        return Icons.delivery_dining_rounded;
      case app_order.OrderStatus.inProgress:
        return Icons.restaurant_rounded;
      case app_order.OrderStatus.completed:
        return Icons.check_circle_rounded;
      case app_order.OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String _getOrderStatusText(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return 'Bekliyor';
      case app_order.OrderStatus.confirmed:
        return 'Onaylandı';
      case app_order.OrderStatus.preparing:
        return 'Hazırlanıyor';
      case app_order.OrderStatus.ready:
        return 'Hazır';
      case app_order.OrderStatus.delivered:
        return 'Teslim Edildi';
      case app_order.OrderStatus.inProgress:
        return 'Hazırlanıyor';
      case app_order.OrderStatus.completed:
        return 'Tamamlandı';
      case app_order.OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  String _formatOrderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return '${weekdays[date.weekday - 1]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatOrderDateDetailed(DateTime date) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================================
  // REVIEW & FEEDBACK METHODS
  // ============================================================================

  void _showReviewDialog(app_order.Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReviewSheet(order),
    );
  }

  Widget _buildReviewSheet(app_order.Order order) {
    double rating = 5.0;
    final commentController = TextEditingController();
    final business = _businessCache[order.businessId];

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.star_rate_rounded,
                        color: AppColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Değerlendirme Yap',
                            style: AppTypography.h5.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            business?.businessName ?? 'İşletme',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sipariş bilgisi
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.greyLighter,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.greyLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sipariş #${order.orderId.substring(0, 8)}',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${order.items.length} ürün - ${order.totalAmount.toStringAsFixed(2)} ₺',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Puanlama
                      Text(
                        'Genel Memnuniyetiniz',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return GestureDetector(
                                  onTap: () => setState(() => rating = index + 1.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 40,
                                      color: index < rating 
                                          ? AppColors.warning 
                                          : AppColors.greyLight,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getRatingText(rating),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Yorum
                      Text(
                        'Yorumunuz (Opsiyonel)',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Deneyiminizi bizimle paylaşın...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              
              // Submit button
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _submitReview(order, rating, commentController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Değerlendirmeyi Gönder',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFeedbackDialog(app_order.Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFeedbackSheet(order),
    );
  }

  Widget _buildFeedbackSheet(app_order.Order order) {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    FeedbackType selectedType = FeedbackType.general;
    FeedbackCategory selectedCategory = FeedbackCategory.service;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.feedback_rounded,
                        color: AppColors.info,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geri Bildirim',
                            style: AppTypography.h5.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Görüşleriniz bizim için değerli',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Geri bildirim türü
                      Text(
                        'Geri Bildirim Türü',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 8,
                        children: FeedbackType.values.map((type) {
                          final isSelected = selectedType == type;
                          return FilterChip(
                            label: Text(type.displayName),
                            selected: isSelected,
                            onSelected: (selected) => setState(() => selectedType = type),
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Kategori
                      Text(
                        'Kategori',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      DropdownButtonFormField<FeedbackCategory>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: FeedbackCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category.displayName),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => selectedCategory = value!),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Konu
                      Text(
                        'Konu',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: subjectController,
                        decoration: InputDecoration(
                          hintText: 'Geri bildirim konusu...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Mesaj
                      Text(
                        'Mesajınız',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: messageController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Detayları buraya yazın...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              
              // Submit button
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _submitFeedback(
                      order, 
                      selectedType, 
                      selectedCategory, 
                      subjectController.text, 
                      messageController.text,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Geri Bildirimi Gönder',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Çok Kötü';
      case 2:
        return 'Kötü';
      case 3:
        return 'Orta';
      case 4:
        return 'İyi';
      case 5:
        return 'Mükemmel';
      default:
        return 'Mükemmel';
    }
  }

  Future<void> _submitReview(app_order.Order order, double rating, String comment) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LoadingIndicator(),
      );

      final userId = widget.customerPhone ?? 'anonymous';
      final business = _businessCache[order.businessId];

      final review = ReviewRating.create(
        customerId: userId,
        customerName: 'Müşteri', // Gerçek isim alınabilir
        businessId: order.businessId,
        orderId: order.orderId,
        overallRating: rating,
        comment: comment.isNotEmpty ? comment : null,
        isVerified: true, // Sipariş vermiş müşteri
      );

      await _customerFirestoreService.saveReview(review);

      Navigator.pop(context); // Loading kapat
      Navigator.pop(context); // Dialog kapat

      // Başarı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Değerlendirmeniz başarıyla gönderildi!'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Loading kapat

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Değerlendirme gönderilirken hata: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitFeedback(
    app_order.Order order,
    FeedbackType type,
    FeedbackCategory category,
    String subject,
    String message,
  ) async {
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen konu ve mesaj alanlarını doldurun'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LoadingIndicator(),
      );

      final userId = widget.customerPhone ?? 'anonymous';

      final feedback = CustomerFeedback.create(
        customerId: userId,
        customerName: 'Müşteri',
        businessId: order.businessId,
        orderId: order.orderId,
        type: type,
        category: category,
        subject: subject,
        message: message,
      );

      await _customerFirestoreService.saveFeedback(feedback);

      Navigator.pop(context); // Loading kapat
      Navigator.pop(context); // Dialog kapat

      // Başarı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Geri bildiriminiz başarıyla gönderildi!'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Loading kapat

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Geri bildirim gönderilirken hata: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
