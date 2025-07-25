import 'package:flutter/material.dart';
import '../models/staff.dart';
import '../models/waiter_call.dart';
import '../services/waiter_call_service.dart';

class StaffCallManagementPage extends StatefulWidget {
  final Staff currentStaff;
  
  const StaffCallManagementPage({
    Key? key,
    required this.currentStaff,
  }) : super(key: key);

  @override
  State<StaffCallManagementPage> createState() => _StaffCallManagementPageState();
}

class _StaffCallManagementPageState extends State<StaffCallManagementPage> {
  final WaiterCallService _waiterCallService = WaiterCallService();
  
  List<WaiterCall> _activeCalls = [];
  List<WaiterCall> _allCalls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCalls();
    
    // Periyodik yenileme (15 saniyede bir)
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        _loadCalls();
      }
    });
  }

  Future<void> _loadCalls() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Garsonun aktif çağrılarını yükle
      final activeCalls = await _waiterCallService.getActiveCallsForWaiter(widget.currentStaff.staffId);
      
      // Garsonun tüm çağrılarını yükle (son 24 saat)
      final allCalls = await _waiterCallService.getWaiterCallsByWaiterId(widget.currentStaff.staffId);
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      final recentCalls = allCalls.where((call) => call.createdAt.isAfter(yesterday)).toList();

      setState(() {
        _activeCalls = activeCalls;
        _allCalls = recentCalls;
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
        title: const Text('Garson Çağrıları'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCalls,
            tooltip: 'Yenile',
          ),
          if (_activeCalls.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_activeCalls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _activeCalls.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _loadCalls,
              backgroundColor: Colors.green[700],
              icon: const Icon(Icons.notifications_active, color: Colors.white),
              label: Text(
                '${_activeCalls.length} Aktif Çağrı',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
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
              onPressed: _loadCalls,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.green[700],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.green[700],
            tabs: [
              Tab(
                text: 'Aktif Çağrılar (${_activeCalls.length})',
                icon: const Icon(Icons.notification_important),
              ),
              Tab(
                text: 'Geçmiş (${_allCalls.length})',
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildActiveCallsTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCallsTab() {
    if (_activeCalls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              'Aktif çağrınız yok!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Müşteri çağrılarına hazırsınız',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCalls,
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

  Widget _buildHistoryTab() {
    final todayCalls = _allCalls.where((call) {
      final today = DateTime.now();
      return call.createdAt.year == today.year &&
             call.createdAt.month == today.month &&
             call.createdAt.day == today.day;
    }).toList();

    if (todayCalls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Bugün henüz çağrı yok',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCalls,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: todayCalls.length,
        itemBuilder: (context, index) {
          final call = todayCalls[index];
          return _buildHistoryCallCard(call);
        },
      ),
    );
  }

  Widget _buildActiveCallCard(WaiterCall call) {
    final isPending = call.status == WaiterCallStatus.pending;
    final isResponded = call.status == WaiterCallStatus.responded;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPending ? Colors.red : Colors.blue,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isPending ? Icons.priority_high : Icons.schedule,
                    color: isPending ? Colors.red : Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      call.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.red[100] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      call.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isPending ? Colors.red[700] : Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.table_restaurant, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    call.tableInfo,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _getTimeAgo(call.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (call.message != null && call.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.message, color: Colors.amber[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          call.message!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (isPending) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _respondToCall(call),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Kabul Et'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _cancelCall(call),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('Reddet'),
                    ),
                  ],
                  if (isResponded) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _completeCall(call),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.done_all, size: 20),
                        label: const Text('Tamamlandı'),
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

  Widget _buildHistoryCallCard(WaiterCall call) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(call.status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(call.status),
            color: _getStatusColor(call.status),
            size: 20,
          ),
        ),
        title: Text(call.customerName),
        subtitle: Text('${call.tableInfo} • ${_formatTime(call.createdAt)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              call.status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(call.status),
              ),
            ),
            if (call.responseTimeMinutes != null)
              Text(
                '${call.responseTimeMinutes!.toStringAsFixed(0)} dk',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        onTap: () => _showCallDetails(call),
      ),
    );
  }

  Future<void> _respondToCall(WaiterCall call) async {
    try {
      await _waiterCallService.respondToCall(call.callId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çağrı kabul edildi! Müşteriye bildirim gönderildi.'),
          backgroundColor: Colors.green,
        ),
      );

      _loadCalls();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeCall(WaiterCall call) async {
    try {
      await _waiterCallService.completeCall(call.callId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çağrı tamamlandı!'),
          backgroundColor: Colors.green,
        ),
      );

      _loadCalls();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelCall(WaiterCall call) async {
    try {
      await _waiterCallService.cancelCall(call.callId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çağrı reddedildi.'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadCalls();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCallDetails(WaiterCall call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çağrı Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Müşteri: ${call.customerName}'),
            const SizedBox(height: 8),
            Text('Masa: ${call.tableInfo}'),
            const SizedBox(height: 8),
            Text('Durum: ${call.status.displayName}'),
            const SizedBox(height: 8),
            Text('Çağrı Zamanı: ${_formatDateTime(call.createdAt)}'),
            if (call.respondedAt != null) ...[
              const SizedBox(height: 8),
              Text('Kabul Zamanı: ${_formatDateTime(call.respondedAt!)}'),
            ],
            if (call.completedAt != null) ...[
              const SizedBox(height: 8),
              Text('Tamamlanma Zamanı: ${_formatDateTime(call.completedAt!)}'),
            ],
            if (call.message != null && call.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Mesaj:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(call.message!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(WaiterCallStatus status) {
    switch (status) {
      case WaiterCallStatus.pending:
        return Colors.orange;
      case WaiterCallStatus.responded:
        return Colors.blue;
      case WaiterCallStatus.completed:
        return Colors.green;
      case WaiterCallStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(WaiterCallStatus status) {
    switch (status) {
      case WaiterCallStatus.pending:
        return Icons.pending;
      case WaiterCallStatus.responded:
        return Icons.schedule;
      case WaiterCallStatus.completed:
        return Icons.check_circle;
      case WaiterCallStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.'
           '${dateTime.month.toString().padLeft(2, '0')}.'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 