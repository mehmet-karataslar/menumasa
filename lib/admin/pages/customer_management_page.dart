import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';

class CustomerManagementPage extends StatefulWidget {
  const CustomerManagementPage({Key? key}) : super(key: key);

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final customers = await _adminService.getAllCustomers();
      final stats = await _adminService.getCustomerStats();

      setState(() {
        _customers = customers;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text(
          'Müşteri Yönetimi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD32F2F),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hata: $_errorMessage',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCustomers,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Cards
                      _buildStatsCards(),
                      
                      const SizedBox(height: 24),
                      
                      // Customers List
                      _buildCustomersList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsCards() {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.2 : 1.5,
      children: [
        _buildStatCard(
          title: 'Toplam Müşteri',
          value: '${_stats['totalCustomers'] ?? 0}',
          icon: Icons.people,
          color: const Color(0xFF1976D2),
        ),
        _buildStatCard(
          title: 'Aktif Müşteri',
          value: '${_stats['activeCustomers'] ?? 0}',
          icon: Icons.check_circle,
          color: const Color(0xFF388E3C),
        ),
        _buildStatCard(
          title: 'Pasif Müşteri',
          value: '${_stats['inactiveCustomers'] ?? 0}',
          icon: Icons.cancel,
          color: const Color(0xFFD32F2F),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isMobile ? 20 : 24),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: isMobile ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Müşteriler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_customers.length} müşteri',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_customers.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.people_outline,
                  color: Colors.grey,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz müşteri bulunmuyor',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sisteme kayıt olan müşteriler burada görünecek',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _customers.length,
            itemBuilder: (context, index) {
              final customer = _customers[index];
              return _buildCustomerCard(customer);
            },
          ),
      ],
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final isActive = customer['isActive'] ?? false;
    final createdAt = customer['createdAt'] != null 
        ? DateTime.tryParse(customer['createdAt']) 
        : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Customer Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: customer['profileImageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          customer['profileImageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: Color(0xFFD32F2F),
                              size: 30,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Color(0xFFD32F2F),
                        size: 30,
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer['fullName'] ?? customer['name'] ?? 'İsimsiz Müşteri',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer['email'] ?? 'E-posta yok',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer['phone'] ?? 'Telefon yok',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Pasif',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Customer Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kayıt Tarihi:',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      createdAt != null 
                          ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                          : 'Bilinmiyor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Son Giriş:',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      customer['lastLoginAt'] != null 
                          ? '${DateTime.tryParse(customer['lastLoginAt'])?.day}/${DateTime.tryParse(customer['lastLoginAt'])?.month}/${DateTime.tryParse(customer['lastLoginAt'])?.year}'
                          : 'Hiç giriş yapmamış',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 