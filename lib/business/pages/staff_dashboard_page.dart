import 'package:flutter/material.dart';
import '../models/staff.dart';
import '../services/staff_service.dart';
import '../../core/services/auth_service.dart';
import 'staff_menu_page.dart';
import 'staff_order_tracking_page.dart';
import 'staff_call_management_page.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({Key? key}) : super(key: key);

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  final StaffService _staffService = StaffService();
  final AuthService _authService = AuthService();

  Staff? _currentStaff;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentStaff();
  }

  Future<void> _loadCurrentStaff() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Auth service'den user bilgilerini al
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      // Staff bilgilerini al (eğer staff ise)
      // Burada normalde user'dan staff ID'sini alacağız
      // Şimdilik mock data kullanıyoruz

      setState(() {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Geri',
        ),
        title: Text(_getPageTitle()),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Hata oluştu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentStaff,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    // Demo amaçlı - farklı rolleri göster
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildRoleFeatures(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Personel', // _currentStaff?.fullName ?? 'Personel'
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Garson', // _currentStaff?.role.displayName ?? 'Rol'
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Müsait', // _currentStaff?.status.displayName ?? 'Durum'
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFeatures() {
    // Demo amaçlı - garson rolü için özellikler göster
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mevcut Özellikler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        _buildWaiterFeatures(),
      ],
    );
  }

  Widget _buildWaiterFeatures() {
    return Column(
      children: [
        _buildFeatureCard(
          title: 'Sipariş Verme',
          description: 'Müşteri siparişlerini sisteme gir',
          icon: Icons.restaurant_menu,
          color: Colors.orange,
          onTap: () {
            // Demo Staff objesi oluştur ve menü sayfasına git
            final demoStaff = Staff.create(
              businessId: 'demo_business_id',
              firstName: 'Demo',
              lastName: 'Garson',
              email: 'demo@garson.com',
              phone: '5555555555',
              password: 'demo123',
              role: StaffRole.waiter,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StaffMenuPage(currentStaff: demoStaff),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          title: 'Sipariş Takibi',
          description: 'Mevcut siparişleri takip et',
          icon: Icons.track_changes,
          color: Colors.blue,
          onTap: () {
            // Demo Staff objesi oluştur ve sipariş takip sayfasına git
            final demoStaff = Staff.create(
              businessId: 'demo_business_id',
              firstName: 'Demo',
              lastName: 'Garson',
              email: 'demo@garson.com',
              phone: '5555555555',
              password: 'demo123',
              role: StaffRole.waiter,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    StaffOrderTrackingPage(currentStaff: demoStaff),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          title: 'Garson Çağırma',
          description: 'Müşteri çağrılarına cevap ver',
          icon: Icons.support_agent,
          color: Colors.green,
          onTap: () {
            // Demo Staff objesi oluştur ve çağrı yönetim sayfasına git
            final demoStaff = Staff.create(
              businessId: 'demo_business_id',
              firstName: 'Demo',
              lastName: 'Garson',
              email: 'demo@garson.com',
              phone: '5555555555',
              password: 'demo123',
              role: StaffRole.waiter,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StaffCallManagementPage(
                  businessId: 'demo_business_id',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildManagerFeatures() {
    return Column(
      children: [
        _buildFeatureCard(
          title: 'Personel Yönetimi',
          description: 'Personelleri yönet ve izle',
          icon: Icons.people,
          color: Colors.purple,
          onTap: () {
            // Personel yönetim sayfasına git
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          title: 'Analitikler',
          description: 'İşletme analitiklerini görüntüle',
          icon: Icons.analytics,
          color: Colors.teal,
          onTap: () {
            // Analitik sayfasına git
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          title: 'Ayarlar',
          description: 'Sistem ayarlarını düzenle',
          icon: Icons.settings,
          color: Colors.grey,
          onTap: () {
            // Ayarlar sayfasına git
          },
        ),
      ],
    );
  }

  Widget _buildKitchenFeatures() {
    return Column(
      children: [
        _buildFeatureCard(
          title: 'Sipariş Alma',
          description: 'Gelen siparişleri al ve işle',
          icon: Icons.kitchen,
          color: Colors.red,
          onTap: () {
            // Mutfak siparişleri sayfasına git
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          title: 'Sipariş Durumu',
          description: 'Sipariş durumlarını güncelle',
          icon: Icons.update,
          color: Colors.amber,
          onTap: () {
            // Sipariş durum sayfasına git
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          title: 'Çağrılara Cevap',
          description: 'Garson çağrılarına cevap ver',
          icon: Icons.phone_callback,
          color: Colors.green,
          onTap: () {
            // Çağrı cevap sayfasına git
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPageTitle() {
    // Demo amaçlı
    return 'Garson Paneli';

    // Gerçek implementation:
    // if (_currentStaff == null) return 'Personel Paneli';
    //
    // switch (_currentStaff!.role) {
    //   case StaffRole.manager:
    //     return 'Müdür Paneli';
    //   case StaffRole.waiter:
    //     return 'Garson Paneli';
    //   case StaffRole.kitchen:
    //     return 'Mutfak Paneli';
    //   case StaffRole.cashier:
    //     return 'Kasiyer Paneli';
    // }
  }
}
