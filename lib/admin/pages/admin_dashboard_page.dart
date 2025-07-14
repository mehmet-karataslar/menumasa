import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../admin/models/admin_user.dart';
import '../../admin/services/admin_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminService _adminService = AdminService();
  AdminUser? _currentAdmin;
  bool _isLoading = true;
  int _selectedIndex = 0;
  Map<String, dynamic> _systemStats = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentAdmin();
    _loadSystemStats();
  }

  Future<void> _loadCurrentAdmin() async {
    try {
      final admin = await _adminService.getCurrentAdmin();
      setState(() {
        _currentAdmin = admin;
      });
    } catch (e) {
      print('Admin yüklenirken hata: $e');
    }
  }

  Future<void> _loadSystemStats() async {
    try {
      final stats = await _adminService.getSystemStats();
      setState(() {
        _systemStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Sistem istatistikleri yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _adminService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/admin/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yapılırken hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on web or desktop
    final isWebOrDesktop = kIsWeb || MediaQuery.of(context).size.width > 768;
    
    if (isWebOrDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Color(0xFF2a2a2a),
              border: Border(
                right: BorderSide(color: Color(0xFF404040), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentAdmin?.name ?? 'Admin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currentAdmin?.role.value ?? 'Admin',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Navigation Menu
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildMenuItem(
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      _buildMenuItem(
                        icon: Icons.business,
                        title: 'İşletmeler',
                        isSelected: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                      _buildMenuItem(
                        icon: Icons.people,
                        title: 'Müşteriler',
                        isSelected: _selectedIndex == 2,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                      _buildMenuItem(
                        icon: Icons.admin_panel_settings,
                        title: 'Adminler',
                        isSelected: _selectedIndex == 3,
                        onTap: () => setState(() => _selectedIndex = 3),
                      ),
                      _buildMenuItem(
                        icon: Icons.analytics,
                        title: 'Analitik',
                        isSelected: _selectedIndex == 4,
                        onTap: () => setState(() => _selectedIndex = 4),
                      ),
                      _buildMenuItem(
                        icon: Icons.settings,
                        title: 'Sistem Ayarları',
                        isSelected: _selectedIndex == 5,
                        onTap: () => setState(() => _selectedIndex = 5),
                      ),
                      _buildMenuItem(
                        icon: Icons.history,
                        title: 'Aktivite Logları',
                        isSelected: _selectedIndex == 6,
                        onTap: () => setState(() => _selectedIndex = 6),
                      ),
                    ],
                  ),
                ),
                
                // Logout Button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Çıkış Yap'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD32F2F),
                    ),
                  )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF2a2a2a),
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentAdmin?.name ?? 'Admin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _currentAdmin?.role.value ?? 'Admin',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Navigation Menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildMenuItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    isSelected: _selectedIndex == 0,
                    onTap: () {
                      setState(() => _selectedIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.business,
                    title: 'İşletmeler',
                    isSelected: _selectedIndex == 1,
                    onTap: () {
                      setState(() => _selectedIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.people,
                    title: 'Müşteriler',
                    isSelected: _selectedIndex == 2,
                    onTap: () {
                      setState(() => _selectedIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Adminler',
                    isSelected: _selectedIndex == 3,
                    onTap: () {
                      setState(() => _selectedIndex = 3);
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.analytics,
                    title: 'Analitik',
                    isSelected: _selectedIndex == 4,
                    onTap: () {
                      setState(() => _selectedIndex = 4);
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: 'Sistem Ayarları',
                    isSelected: _selectedIndex == 5,
                    onTap: () {
                      setState(() => _selectedIndex = 5);
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Aktivite Logları',
                    isSelected: _selectedIndex == 6,
                    onTap: () {
                      setState(() => _selectedIndex = 6);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            
            // Logout Button
            Container(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Çıkış Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD32F2F),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFD32F2F) : Colors.grey[400],
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD32F2F) : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFFD32F2F).withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildBusinessesContent();
      case 2:
        return _buildCustomersContent();
      case 3:
        return _buildAdminsContent();
      case 4:
        return _buildAnalyticsContent();
      case 5:
        return _buildSettingsContent();
      case 6:
        return _buildActivityLogsContent();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldin, ${_currentAdmin?.name ?? 'Admin'}!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sistem yönetim paneline hoş geldiniz',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: isMobile ? 16 : 24),
          
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: isMobile ? 12 : 16,
            mainAxisSpacing: isMobile ? 12 : 16,
            childAspectRatio: isMobile ? 1.1 : 1.2,
            children: [
              _buildStatCard(
                title: 'Toplam İşletme',
                value: '${_systemStats['businesses']?['totalBusinesses'] ?? 0}',
                icon: Icons.business,
                color: const Color(0xFF1976D2),
              ),
              _buildStatCard(
                title: 'Toplam Müşteri',
                value: '${_systemStats['customers']?['totalCustomers'] ?? 0}',
                icon: Icons.people,
                color: const Color(0xFF388E3C),
              ),
              _buildStatCard(
                title: 'Toplam Sipariş',
                value: '${_systemStats['orders']?['totalOrders'] ?? 0}',
                icon: Icons.shopping_cart,
                color: const Color(0xFFFF9800),
              ),
              _buildStatCard(
                title: 'Aktif Admin',
                value: '${_systemStats['admins']?['activeAdmins'] ?? 1}',
                icon: Icons.admin_panel_settings,
                color: const Color(0xFFD32F2F),
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 16 : 24),
          
          // Recent Activities
          _buildRecentActivities(isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildBusinessesContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'İşletme Yönetimi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin/businesses');
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni İşletme'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.business,
                  color: Color(0xFFD32F2F),
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'İşletme Yönetimi Sayfası',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bu sayfada işletmeleri yönetebilir, yeni işletme ekleyebilir ve mevcut işletmeleri düzenleyebilirsiniz.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Müşteri Yönetimi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin/customers');
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Müşteri'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.people,
                  color: Color(0xFFD32F2F),
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Müşteri Yönetimi Sayfası',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bu sayfada müşterileri yönetebilir, müşteri istatistiklerini görüntüleyebilir ve müşteri aktivitelerini takip edebilirsiniz.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Admin Yönetimi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin/admins');
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFFD32F2F),
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Admin Yönetimi Sayfası',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bu sayfada admin kullanıcılarını yönetebilir, yeni admin ekleyebilir ve admin yetkilerini düzenleyebilirsiniz.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sistem Analitikleri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.analytics,
                  color: Color(0xFFD32F2F),
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Analitik Sayfası',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bu sayfada sistem genelinde analitikleri görüntüleyebilir, performans metriklerini takip edebilir ve raporları inceleyebilirsiniz.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sistem Ayarları',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.settings,
                  color: Color(0xFFD32F2F),
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Sistem Ayarları Sayfası',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bu sayfada sistem ayarlarını yapılandırabilir, güvenlik ayarlarını düzenleyebilir ve sistem parametrelerini değiştirebilirsiniz.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivite Logları',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.history,
                  color: Color(0xFFD32F2F),
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Aktivite Logları Sayfası',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bu sayfada sistem aktivitelerini görüntüleyebilir, kullanıcı işlemlerini takip edebilir ve güvenlik loglarını inceleyebilirsiniz.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildRecentActivities({bool isMobile = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Son Aktiviteler',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: const Color(0xFF2a2a2a),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.login,
                title: 'Admin girişi yapıldı',
                subtitle: '${_currentAdmin?.name ?? 'Admin'} sisteme giriş yaptı',
                time: 'Az önce',
                isMobile: isMobile,
              ),
              Divider(color: Colors.grey, height: isMobile ? 24 : 32),
              _buildActivityItem(
                icon: Icons.admin_panel_settings,
                title: 'Admin modülü başlatıldı',
                subtitle: 'Sistem yönetim modülü aktif edildi',
                time: 'Az önce',
                isMobile: isMobile,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    bool isMobile = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFD32F2F), size: isMobile ? 16 : 20),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: isMobile ? 10 : 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: isMobile ? 10 : 12,
          ),
        ),
      ],
    );
  }
}
