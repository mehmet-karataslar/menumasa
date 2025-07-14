import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';
import '../models/admin_user.dart';

class BusinessManagementPage extends StatefulWidget {
  const BusinessManagementPage({Key? key}) : super(key: key);

  @override
  State<BusinessManagementPage> createState() => _BusinessManagementPageState();
}

class _BusinessManagementPageState extends State<BusinessManagementPage> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _businesses = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final businesses = await _adminService.getAllBusinesses();
      final stats = await _adminService.getBusinessStats();

      setState(() {
        _businesses = businesses;
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

  Future<void> _updateBusinessStatus(String businessId, bool isApproved) async {
    try {
      await _adminService.updateBusinessStatus(
        businessId: businessId,
        isApproved: isApproved,
        status: isApproved ? 'approved' : 'pending',
      );
      
      // Refresh the list
      await _loadBusinesses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşletme durumu güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleBusinessActive(String businessId, bool isActive) async {
    try {
      await _adminService.toggleBusinessActive(
        businessId: businessId,
        isActive: !isActive,
      );
      
      // Refresh the list
      await _loadBusinesses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşletme durumu değiştirildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text(
          'İşletme Yönetimi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBusinesses,
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
                        onPressed: _loadBusinesses,
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
                      
                      // Businesses List
                      _buildBusinessesList(),
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
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.2 : 1.5,
      children: [
        _buildStatCard(
          title: 'Toplam İşletme',
          value: '${_stats['totalBusinesses'] ?? 0}',
          icon: Icons.business,
          color: const Color(0xFF1976D2),
        ),
        _buildStatCard(
          title: 'Aktif İşletme',
          value: '${_stats['activeBusinesses'] ?? 0}',
          icon: Icons.check_circle,
          color: const Color(0xFF388E3C),
        ),
        _buildStatCard(
          title: 'Onaylı İşletme',
          value: '${_stats['approvedBusinesses'] ?? 0}',
          icon: Icons.verified,
          color: const Color(0xFFFF9800),
        ),
        _buildStatCard(
          title: 'Bekleyen İşletme',
          value: '${_stats['pendingBusinesses'] ?? 0}',
          icon: Icons.pending,
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
    return Container(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'İşletmeler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_businesses.length} işletme',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_businesses.isEmpty)
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
                  Icons.business_outlined,
                  color: Colors.grey,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz işletme bulunmuyor',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sisteme kayıt olan işletmeler burada görünecek',
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
            itemCount: _businesses.length,
            itemBuilder: (context, index) {
              final business = _businesses[index];
              return _buildBusinessCard(business);
            },
          ),
      ],
    );
  }

  Widget _buildBusinessCard(Map<String, dynamic> business) {
    final isActive = business['isActive'] ?? false;
    final isApproved = business['isApproved'] ?? false;
    final status = business['status'] ?? 'pending';
    
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
              // Business Logo or Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: business['logoUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          business['logoUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.business,
                              color: Color(0xFFD32F2F),
                              size: 30,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.business,
                        color: Color(0xFFD32F2F),
                        size: 30,
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Business Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business['businessName'] ?? 'İsimsiz İşletme',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business['businessType'] ?? 'Bilinmeyen Tip',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business['businessAddress'] ?? 'Adres bilgisi yok',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Indicators
              Column(
                children: [
                  // Active Status
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
                  const SizedBox(height: 4),
                  // Approval Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isApproved ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isApproved ? 'Onaylı' : 'Beklemede',
                      style: TextStyle(
                        color: isApproved ? Colors.blue : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Business Description
          if (business['businessDescription'] != null && business['businessDescription'].isNotEmpty)
            Text(
              business['businessDescription'],
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              // Approve/Reject Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateBusinessStatus(
                    business['id'],
                    !isApproved,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApproved ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isApproved ? 'Onayı Kaldır' : 'Onayla'),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Toggle Active Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _toggleBusinessActive(
                    business['id'],
                    isActive,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isActive ? 'Pasif Yap' : 'Aktif Yap'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 