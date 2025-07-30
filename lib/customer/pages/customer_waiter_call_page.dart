import 'package:flutter/material.dart';
import '../../business/models/staff.dart';
import '../../business/models/waiter_call.dart';
import '../../business/services/waiter_call_service.dart';
import '../../business/services/staff_service.dart';

class CustomerWaiterCallPage extends StatefulWidget {
  final String businessId;
  final String customerId;
  final String customerName;
  final int? tableNumber;
  final String? floorNumber;

  const CustomerWaiterCallPage({
    Key? key,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    this.tableNumber,
    this.floorNumber,
  }) : super(key: key);

  @override
  State<CustomerWaiterCallPage> createState() => _CustomerWaiterCallPageState();
}

class _CustomerWaiterCallPageState extends State<CustomerWaiterCallPage> {
  final WaiterCallService _waiterCallService = WaiterCallService();
  final StaffService _staffService = StaffService();

  List<Staff> _availableWaiters = [];
  bool _isLoading = true;
  String? _error;

  // Form controllers
  final TextEditingController _tableController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Masa ve kat bilgilerini önceden doldur
    if (widget.tableNumber != null) {
      _tableController.text = widget.tableNumber!.toString();
    }
    if (widget.floorNumber != null) {
      _floorController.text = widget.floorNumber!;
    }

    _loadAvailableWaiters();
  }

  @override
  void dispose() {
    _tableController.dispose();
    _floorController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableWaiters() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final waiters = await _waiterCallService
          .getAvailableWaitersForCustomer(widget.businessId);

      setState(() {
        _availableWaiters = waiters;
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
        title: const Text('Garson Çağır'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Müsait garsonlar yükleniyor...'),
          ],
        ),
      );
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
              onPressed: _loadAvailableWaiters,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_availableWaiters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Şu anda müsait garson bulunmuyor',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lütfen daha sonra tekrar deneyin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAvailableWaiters,
              child: const Text('Yenile'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTableInfoCard(),
          _buildWaitersSection(),
        ],
      ),
    );
  }

  Widget _buildTableInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Masa Bilgileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tableController,
                  decoration: const InputDecoration(
                    labelText: 'Masa Numarası *',
                    hintText: 'Örn: 5',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _floorController,
                  decoration: const InputDecoration(
                    labelText: 'Kat (İsteğe bağlı)',
                    hintText: 'Örn: 1',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Özel Mesaj (İsteğe bağlı)',
              hintText: 'Hesap istiyorum, menü istiyorum, vb.',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildWaitersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.people, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Müsait Garsonlar (${_availableWaiters.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _availableWaiters.length,
          itemBuilder: (context, index) {
            final waiter = _availableWaiters[index];
            return _buildWaiterCard(waiter);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWaiterCard(Staff waiter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _callWaiter(waiter),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.orange[100],
                child: waiter.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          waiter.profileImageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              waiter.initials,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        waiter.initials,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      waiter.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      waiter.role.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        waiter.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    Icons.call,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Çağır',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callWaiter(Staff waiter) async {
    // Masa numarası kontrolü
    if (_tableController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen masa numaranızı girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Loading dialog göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Garson çağrılıyor...'),
            ],
          ),
        ),
      );

      // Garson çağrısı oluştur
      await _waiterCallService.callWaiter(
        businessId: widget.businessId,
        customerId: widget.customerId,
        customerName: widget.customerName,
        waiterId: waiter.staffId,
        waiterName: waiter.fullName,
        tableNumber: int.tryParse(_tableController.text.trim()) ?? 0,
        floorNumber: _floorController.text.trim().isNotEmpty
            ? _floorController.text.trim()
            : null,
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      );

      // Loading dialog'ı kapat
      Navigator.pop(context);

      // Başarı dialog'ı göster
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Garson Çağrıldı!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${waiter.fullName} çağrınızı aldı.'),
              const SizedBox(height: 8),
              Text(
                  'Masa: ${_tableController.text}${_floorController.text.isNotEmpty ? ' (${_floorController.text}. Kat)' : ''}'),
              const SizedBox(height: 8),
              const Text(
                'Garsonunuz en kısa sürede sizinle iletişime geçecektir.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog'ı kapat
                Navigator.pop(context); // Bu sayfayı kapat
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Loading dialog'ı kapat
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Garson çağrılırken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
