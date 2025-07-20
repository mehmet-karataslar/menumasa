import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../services/stock_service.dart';
import '../services/business_service.dart';
import '../models/stock_models.dart';
import '../../../presentation/widgets/shared/loading_indicator.dart';
import '../../../presentation/widgets/shared/error_message.dart';
import '../../../presentation/widgets/shared/empty_state.dart';

class StockManagementPage extends StatefulWidget {
  const StockManagementPage({super.key});

  @override
  State<StockManagementPage> createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage> with TickerProviderStateMixin {
  final StockService _stockService = StockService();
  final BusinessService _businessService = BusinessService();

  late TabController _tabController;
  
  List<StockItem> _allStock = [];
  List<StockAlert> _alerts = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadStockData();
    _setupListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stockService.removeStockListener(_onStockUpdate);
    _stockService.removeAlertListener(_onAlertUpdate);
    super.dispose();
  }

  void _setupListeners() {
    _stockService.addStockListener(_onStockUpdate);
    _stockService.addAlertListener(_onAlertUpdate);
  }

  void _onStockUpdate(List<StockItem> stocks) {
    if (mounted) {
      setState(() {
        _allStock = stocks;
      });
    }
  }

  void _onAlertUpdate(List<StockAlert> alerts) {
    if (mounted) {
      setState(() {
        _alerts = alerts;
      });
    }
  }

  Future<void> _loadStockData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final business = _businessService.currentBusiness;
      if (business == null) {
        throw Exception('İşletme bilgisi bulunamadı');
      }

      final futures = await Future.wait([
        _stockService.getBusinessStock(business.businessId),
        _stockService.getActiveAlerts(business.businessId),
        _stockService.getStockStatistics(business.businessId),
      ]);

      setState(() {
        _allStock = futures[0] as List<StockItem>;
        _alerts = futures[1] as List<StockAlert>;
        _statistics = futures[2] as Map<String, dynamic>;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Stok verileri yüklenirken hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Alerts banner
          if (_alerts.isNotEmpty) _buildAlertsBanner(),
          
          // Statistics cards
          if (_statistics != null) _buildStatisticsCards(),
          
          // Tabs
          _buildTabBar(),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingIndicator())
                : _errorMessage != null
                    ? Center(child: ErrorMessage(message: _errorMessage!))
                    : _buildTabContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStockDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Stok Ekle'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                'Stok Yönetimi',
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _exportStock,
                    icon: const Icon(Icons.download),
                    tooltip: 'Stok Dışa Aktar',
                  ),
                  IconButton(
                    onPressed: _checkAlerts,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Kontrol Et',
                  ),
                  IconButton(
                    onPressed: _showBulkUpdateDialog,
                    icon: const Icon(Icons.edit_note),
                    tooltip: 'Toplu Güncelleme',
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsBanner() {
    final highPriorityAlerts = _alerts.where((alert) => 
        alert.priority == AlertPriority.high || alert.priority == AlertPriority.critical
    ).toList();

    if (highPriorityAlerts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dikkat: ${highPriorityAlerts.length} Kritik Uyarı',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  highPriorityAlerts.map((a) => a.message).join(', '),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _tabController.animateTo(4), // Alerts tab
            child: const Text('Görüntüle'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Toplam Ürün',
              _statistics!['totalItems'].toString(),
              Icons.inventory,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Düşük Stok',
              _statistics!['lowStockItems'].toString(),
              Icons.warning,
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Stokta Yok',
              _statistics!['outOfStockItems'].toString(),
              Icons.error,
              AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Toplam Değer',
              '₺${_statistics!['totalValue'].toStringAsFixed(2)}',
              Icons.monetization_on,
              AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textLight,
        indicatorColor: AppColors.primary,
        tabs: [
          Tab(text: 'Tüm Stok (${_allStock.length})'),
          Tab(text: 'Düşük Stok (${_allStock.where((s) => s.isLowStock).length})'),
          Tab(text: 'Stokta Yok (${_allStock.where((s) => s.isOutOfStock).length})'),
          Tab(text: 'Son Kullanma (${_allStock.where((s) => s.isNearExpiry || s.isExpired).length})'),
          Tab(text: 'Uyarılar (${_alerts.length})'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllStockTab(),
        _buildLowStockTab(),
        _buildOutOfStockTab(),
        _buildExpiryTab(),
        _buildAlertsTab(),
      ],
    );
  }

  Widget _buildAllStockTab() {
    final filteredStock = _getFilteredStock(_allStock);
    
    if (filteredStock.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory,
        title: 'Henüz stok yok',
        message: 'İlk stok kaydınızı oluşturun',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStock.length,
      itemBuilder: (context, index) {
        return _buildStockCard(filteredStock[index]);
      },
    );
  }

  Widget _buildLowStockTab() {
    final lowStockItems = _getFilteredStock(_allStock.where((s) => s.isLowStock).toList());
    
    if (lowStockItems.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle,
        title: 'Harika!',
        message: 'Düşük stok bulunamadı',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lowStockItems.length,
      itemBuilder: (context, index) {
        return _buildStockCard(lowStockItems[index]);
      },
    );
  }

  Widget _buildOutOfStockTab() {
    final outOfStockItems = _getFilteredStock(_allStock.where((s) => s.isOutOfStock).toList());
    
    if (outOfStockItems.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle,
        title: 'Harika!',
        message: 'Stokta olmayan ürün yok',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: outOfStockItems.length,
      itemBuilder: (context, index) {
        return _buildStockCard(outOfStockItems[index]);
      },
    );
  }

  Widget _buildExpiryTab() {
    final expiringItems = _getFilteredStock(_allStock.where((s) => s.isNearExpiry || s.isExpired).toList());
    
    if (expiringItems.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle,
        title: 'Harika!',
        message: 'Yakında süresi dolacak ürün yok',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expiringItems.length,
      itemBuilder: (context, index) {
        return _buildStockCard(expiringItems[index]);
      },
    );
  }

  Widget _buildAlertsTab() {
    if (_alerts.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_off,
        title: 'Uyarı yok',
        message: 'Şu anda aktif uyarı bulunmuyor',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        return _buildAlertCard(_alerts[index]);
      },
    );
  }

  Widget _buildStockCard(StockItem stock) {
    Color statusColor;
    IconData statusIcon;
    
    switch (stock.status) {
      case StockStatus.inStock:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case StockStatus.lowStock:
        statusColor = AppColors.warning;
        statusIcon = Icons.warning;
        break;
      case StockStatus.outOfStock:
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        break;
      case StockStatus.nearExpiry:
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule;
        break;
      case StockStatus.expired:
        statusColor = AppColors.error;
        statusIcon = Icons.dangerous;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.productName,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            stock.status.displayName,
                            style: AppTypography.bodySmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleStockAction(action, stock),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                    const PopupMenuItem(value: 'add', child: Text('Stok Ekle')),
                    const PopupMenuItem(value: 'reduce', child: Text('Stok Azalt')),
                    const PopupMenuItem(value: 'movements', child: Text('Hareketleri Görüntüle')),
                    const PopupMenuItem(value: 'delete', child: Text('Sil')),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Mevcut Stok',
                    '${stock.currentStock.toStringAsFixed(1)} ${stock.unit}',
                    Icons.inventory,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Min. Stok',
                    '${stock.minimumStock.toStringAsFixed(1)} ${stock.unit}',
                    Icons.warning,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Birim Fiyat',
                    '₺${stock.unitCost.toStringAsFixed(2)}',
                    Icons.monetization_on,
                  ),
                ),
              ],
            ),
            
            if (stock.expiryDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    'Son Kullanma: ${_formatDate(stock.expiryDate!)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Toplam Değer: ₺${stock.stockValue.toStringAsFixed(2)}',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(StockAlert alert) {
    Color priorityColor;
    IconData priorityIcon;
    
    switch (alert.priority) {
      case AlertPriority.low:
        priorityColor = AppColors.success;
        priorityIcon = Icons.info;
        break;
      case AlertPriority.medium:
        priorityColor = AppColors.warning;
        priorityIcon = Icons.warning;
        break;
      case AlertPriority.high:
        priorityColor = AppColors.error;
        priorityIcon = Icons.error;
        break;
      case AlertPriority.critical:
        priorityColor = AppColors.error;
        priorityIcon = Icons.dangerous;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(priorityIcon, color: priorityColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.alertType.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    alert.priority.displayName,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  backgroundColor: priorityColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              alert.message,
              style: AppTypography.bodyMedium,
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateTime(alert.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                Row(
                  children: [
                    if (!alert.isRead)
                      TextButton(
                        onPressed: () => _markAlertAsRead(alert.alertId),
                        child: const Text('Okundu İşaretle'),
                      ),
                    TextButton(
                      onPressed: () => _markAlertAsResolved(alert.alertId),
                      child: const Text('Çözüldü'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<StockItem> _getFilteredStock(List<StockItem> stock) {
    if (_searchQuery.isEmpty) return stock;
    
    return stock.where((item) =>
        item.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.productId.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _handleStockAction(String action, StockItem stock) {
    switch (action) {
      case 'edit':
        _showEditStockDialog(stock);
        break;
      case 'add':
        _showAddStockQuantityDialog(stock);
        break;
      case 'reduce':
        _showReduceStockDialog(stock);
        break;
      case 'movements':
        _showMovementsDialog(stock);
        break;
      case 'delete':
        _showDeleteConfirmation(stock);
        break;
    }
  }

  void _showAddStockDialog() {
    // TODO: Implement add stock dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stok ekleme özelliği yakında eklenecek')),
    );
  }

  void _showEditStockDialog(StockItem stock) {
    // TODO: Implement edit stock dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${stock.productName} düzenleme özelliği yakında eklenecek')),
    );
  }

  void _showAddStockQuantityDialog(StockItem stock) {
    // TODO: Implement add stock quantity dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${stock.productName} stok ekleme özelliği yakında eklenecek')),
    );
  }

  void _showReduceStockDialog(StockItem stock) {
    // TODO: Implement reduce stock dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${stock.productName} stok azaltma özelliği yakında eklenecek')),
    );
  }

  void _showMovementsDialog(StockItem stock) {
    // TODO: Implement movements dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${stock.productName} hareketleri görüntüleme özelliği yakında eklenecek')),
    );
  }

  void _showDeleteConfirmation(StockItem stock) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stok Silme Onayı'),
        content: Text('${stock.productName} ürününün stok kaydını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStock(stock);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showBulkUpdateDialog() {
    // TODO: Implement bulk update dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toplu güncelleme özelliği yakında eklenecek')),
    );
  }

  Future<void> _deleteStock(StockItem stock) async {
    try {
      await _stockService.deleteStockItem(stock.stockId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${stock.productName} stok kaydı silindi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok silme hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _markAlertAsRead(String alertId) async {
    try {
      await _stockService.markAlertAsRead(alertId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uyarı güncelleme hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _markAlertAsResolved(String alertId) async {
    try {
      await _stockService.markAlertAsResolved(alertId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uyarı çözüldü olarak işaretlendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uyarı güncelleme hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _checkAlerts() async {
    try {
      final business = _businessService.currentBusiness;
      if (business != null) {
        await _stockService.checkAllAlerts(business.businessId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok kontrolleri tamamlandı')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kontrol hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _exportStock() async {
    try {
      final business = _businessService.currentBusiness;
      if (business != null) {
        final data = await _stockService.exportStockData(business.businessId);
        // TODO: Implement actual export (save to file or share)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok verileri dışa aktarıldı')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dışa aktarma hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
} 