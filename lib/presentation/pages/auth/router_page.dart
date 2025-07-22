import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/url_service.dart';
import '../../../data/models/user.dart' hide UserType;
import '../../../core/enums/user_type.dart';
import 'login_page.dart';
import 'business_register_page.dart';
import 'register_page.dart';
import '../../../business/pages/business_login_page.dart';
import '../../../customer/pages/qr_menu_page.dart';
import '../../../shared/pages/universal_qr_menu_page.dart';

class RouterPage extends StatefulWidget {
  const RouterPage({super.key});

  @override
  State<RouterPage> createState() => _RouterPageState();
}

class _RouterPageState extends State<RouterPage> {
  final AuthService _authService = AuthService();
  final UrlService _urlService = UrlService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationState();
    
    // URL güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlService.updateUrl('/', customTitle: 'MasaMenu - Dijital Menü Çözümü');
    });
  }

  Future<void> _checkAuthenticationState() async {
    try {
      final currentUser = _authService.currentUser;
      

      
      // Sadece auth durumunu kontrol et, otomatik yönlendirme yapma
      if (currentUser != null) {
        print('User authenticated: ${currentUser.uid}');
        // User authenticated but don't auto-redirect
        // Let them choose what to do from the main page
      }
    } catch (e) {
      // Continue to show router page if there's an error
      print('Auth check error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        _urlService.updateUrl('/', customTitle: 'MasaMenu - Dijital Menü Çözümü');
        // Reload the router page to show welcome screen
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çıkış yapıldı'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // URL'den QR menü kontrolü
    final routeName = ModalRoute.of(context)?.settings.name;
    print('🔍 RouterPage - Route name: $routeName');
    print('🔍 RouterPage - Current URL: ${UrlService().getCurrentPath()}');
    
    if (routeName != null && (routeName.startsWith('/qr-menu/') || routeName.startsWith('/menu/') || routeName == '/qr')) {
      print('✅ RouterPage - QR menu URL detected, redirecting...');
      // QR menü URL'si tespit edildi, direkt QR menü sayfasına yönlendir
      return _buildQRMenuRedirect(routeName);
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Yükleniyor...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildWelcomePage();
  }

  Widget _buildWelcomePage() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: 60),
              
              // Main action buttons
              _buildMainActions(),
              
              const SizedBox(height: 40),
              
              // Feature highlights
              _buildFeatureHighlights(),
              
              const SizedBox(height: 40),
              
              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.restaurant_menu,
            size: 64,
            color: AppColors.white,
          ),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          'MasaMenu',
          style: AppTypography.h1.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Dijital Menü Çözümü',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            fontSize: 18,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'QR kod ile kolay menü erişimi, sipariş yönetimi ve müşteri deneyimi',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainActions() {
    return Column(
      children: [
        // Check if user is authenticated and show logout option
        FutureBuilder<bool>(
          future: _checkIfUserAuthenticated(),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.greyLighter,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Oturum açık',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final userData = await _authService.getCurrentUserData();
                              print('Router - User data: ${userData?.toJson()}'); // Debug log
                              print('Router - User type: ${userData?.userType}'); // Debug log
                              
                              if (userData?.userType.value == 'business') {
                                Navigator.pushNamed(context, '/business/dashboard');
                              } else if (userData?.userType.value == 'customer') {
                                Navigator.pushNamed(context, '/customer/dashboard', 
                                  arguments: {'userId': userData!.id});
                              } else {
                                print('Router - Unknown user type: ${userData?.userType}');
                                // Fallback: Go to appropriate login
                                Navigator.pushNamed(context, '/login');
                              }
                            },
                            icon: const Icon(Icons.dashboard, size: 18),
                            label: const Text('Panel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Çıkış'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Customer access button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _urlService.updateUrl('/login', customTitle: 'Müşteri Girişi | MasaMenu');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(userType: 'customer'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.person, size: 24),
            label: Text(
              'Müşteri Girişi',
              style: AppTypography.buttonLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Business access button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _urlService.updateUrl('/business/login', customTitle: 'İşletme Girişi | MasaMenu');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusinessLoginPage(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.business, size: 24),
            label: Text(
              'İşletme Girişi',
              style: AppTypography.buttonLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Quick registration links
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                _urlService.updateUrl('/register', customTitle: 'Müşteri Kaydı | MasaMenu');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterPage(userType: 'customer'),
                  ),
                );
              },
              child: Text(
                'Müşteri Kaydı',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const Text(' | '),
            
            TextButton(
              onPressed: () {
                _urlService.updateUrl('/business-register', customTitle: 'İşletme Kaydı | MasaMenu');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BusinessRegisterPage(),
                  ),
                );
              },
              child: Text(
                'İşletme Kaydı',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<bool> _checkIfUserAuthenticated() async {
    final currentUser = _authService.currentUser;
    return currentUser != null;
  }

  Widget _buildQRMenuRedirect(String routeName) {
    print('🔄 _buildQRMenuRedirect called with: $routeName');
    
    // URL'i parse et
    final uri = Uri.parse(routeName);
    final pathSegments = uri.pathSegments;
    final currentUrl = _urlService.getCurrentPath();
    final currentParams = _urlService.getCurrentParams();
    
    print('🔍 Current URL path: $currentUrl');
    print('🔍 Current URL params: $currentParams');
    print('🔍 Parsed URI: $uri');
    print('🔍 Path segments: $pathSegments');
    
    // Yeni evrensel QR format kontrol et (/qr?business=X&table=Y)
    if (routeName == '/qr' || routeName.startsWith('/qr?')) {
      print('✅ Redirecting to UniversalQRMenuPage');
      // Evrensel QR menü sayfasını döndür
      return const UniversalQRMenuPage();
    }
    
    // Eski format kontrol et (/menu/businessId veya /qr-menu/businessId)
    if (pathSegments.length >= 2) {
      final businessId = pathSegments[1];
      final tableNumber = uri.queryParameters['table'] != null 
          ? int.tryParse(uri.queryParameters['table']!) 
          : null;
      
      // Direkt QRMenuPage widget'ını döndür (eski format uyumluluğu için)
      return QRMenuPage(
        businessId: businessId,
        qrCode: routeName,
        tableNumber: tableNumber,
      );
    }
    
    // Geçersiz URL ise normal router'ı göster
    return _buildWelcomePage();
  }

  Widget _buildFeatureHighlights() {
    return Column(
      children: [
        Text(
          'Özellikler',
          style: AppTypography.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.qr_code,
                title: 'QR Menü',
                description: 'QR kod ile hızlı menü erişimi',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.shopping_cart,
                title: 'Sipariş Yönetimi',
                description: 'Kolay sipariş alma sistemi',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.analytics,
                title: 'Analitik',
                description: 'Satış raporları ve istatistikler',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.mobile_friendly,
                title: 'Mobil Uyumlu',
                description: 'Tüm cihazlarda çalışır',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Divider(
          color: AppColors.grey.withOpacity(0.3),
          thickness: 1,
        ),
        
        const SizedBox(height: 16),
        
        Text(
          '© 2024 MasaMenu. Tüm hakları saklıdır.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textLight,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Dijital menü çözümünüz',
          style: AppTypography.caption.copyWith(
            color: AppColors.textLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

