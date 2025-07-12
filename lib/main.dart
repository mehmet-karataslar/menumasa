import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'presentation/pages/customer/menu_page.dart';
import 'presentation/pages/customer/product_detail_page.dart';
import 'presentation/pages/admin/admin_dashboard_page.dart';
import 'presentation/pages/admin/category_management_page.dart';
import 'presentation/pages/admin/product_management_page.dart';
import 'presentation/pages/admin/qr_code_management_page.dart';
import 'presentation/pages/admin/business_info_page.dart';
import 'presentation/pages/admin/menu_settings_page.dart';
import 'presentation/pages/admin/discount_management_page.dart';
import 'presentation/pages/admin/orders_page.dart';
import 'presentation/pages/customer/customer_orders_page.dart';
import 'presentation/pages/admin/responsive_admin_dashboard.dart';
import 'core/services/data_service.dart';
import 'core/services/qr_service.dart';
import 'data/models/product.dart';
import 'data/models/business.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Sistem UI yapılandırması
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MasaMenuApp());
}

class MasaMenuApp extends StatelessWidget {
  const MasaMenuApp({Key? key}) : super(key: key);

  String _getInitialRoute() {
    // Web platformunda direkt welcome sayfasını aç
    // Mobile'da splash screen göster
    if (kIsWeb) {
      return '/welcome';
    }
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masa Menü - Dijital Menü Çözümü',
      debugShowCheckedModeBanner: false,

      // Tema ayarları
      theme: _buildTheme(),

      // Web için direkt welcome sayfası, mobile için splash
      initialRoute: _getInitialRoute(),

      // Rota yapılandırması
      routes: _buildRoutes(),

      // Dinamik rota üretici - QR kod URL'leri için
      onGenerateRoute: _generateRoute,

      // Bilinmeyen rota işleyicisi
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const NotFoundPage());
      },

      // Uygulama başlığı
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor:
                1.0, // Kullanıcı font boyutu değişikliklerini sınırla
          ),
          child: child!,
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorScheme.lightScheme,
      textTheme: AppTypography.textTheme,
      fontFamily: AppTypography.fontFamily,

      // AppBar teması
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Buton temaları
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Input teması
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Card teması
      cardTheme: CardThemeData(
        color: AppColors.white,
        shadowColor: AppColors.shadow,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Divider teması
      dividerTheme: const DividerThemeData(
        color: AppColors.greyLight,
        thickness: 1,
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => const SplashPage(),
      '/welcome': (context) => const WelcomePage(),
      '/login': (context) => const LoginPage(),
      '/menu': (context) => const MenuRouterPage(),
      '/qr-scanner': (context) => const QRScannerPage(),
      '/product-detail': (context) => const ProductDetailRouterPage(),
      '/admin': (context) => const AdminDashboardRouterPage(),
      '/admin/dashboard': (context) => const AdminDashboardRouterPage(),
      '/admin/categories': (context) => const CategoryManagementRouterPage(),
      '/admin/products': (context) => const ProductManagementRouterPage(),
      '/admin/business-info': (context) => const BusinessInfoRouterPage(),
      '/admin/menu-settings': (context) => const MenuSettingsRouterPage(),
      '/admin/qr-codes': (context) => const QRCodeManagementRouterPage(),
      '/admin/discounts': (context) => const DiscountManagementRouterPage(),
      '/admin/orders': (context) => const OrdersRouterPage(),
      '/customer/orders': (context) => const CustomerOrdersRouterPage(),
    };
  }

  // Custom route generator for dynamic QR code URLs
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

    // Handle QR code menu URLs: /menu/businessId?table=tableNumber
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'menu') {
      final businessId = uri.pathSegments[1];
      final tableNumber = uri.queryParameters['table'];

      return MaterialPageRoute(
        builder: (context) =>
            QRMenuPage(businessId: businessId, tableNumber: tableNumber),
        settings: settings,
      );
    }

    // Handle other dynamic routes if needed
    return null;
  }
}

// Menü router sayfası - businessId ve tableNumber parametrelerini alır
class MenuRouterPage extends StatelessWidget {
  const MenuRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final tableNumber = args?['tableNumber'] as String?;

    return QRMenuPage(businessId: businessId, tableNumber: tableNumber);
  }
}

// QR Menü sayfası - QR kod taramasından gelen kullanıcılar için özel sayfa
class QRMenuPage extends StatefulWidget {
  final String businessId;
  final String? tableNumber;

  const QRMenuPage({Key? key, required this.businessId, this.tableNumber})
    : super(key: key);

  @override
  State<QRMenuPage> createState() => _QRMenuPageState();
}

class _QRMenuPageState extends State<QRMenuPage> {
  bool _isLoading = true;
  bool _businessExists = false;

  @override
  void initState() {
    super.initState();
    _verifyBusiness();
  }

  Future<void> _verifyBusiness() async {
    // Real business verification using DataService
    try {
      final dataService = DataService();
      await dataService.initialize();
      await dataService.initializeSampleData();

      final business = await dataService.getBusiness(widget.businessId);

      setState(() {
        _businessExists = business != null && business.isActive;
        _isLoading = false;
      });

      if (_businessExists) {
        // Show welcome message for QR scanned users
        _showQRWelcomeMessage();
      }
    } catch (e) {
      setState(() {
        _businessExists = false;
        _isLoading = false;
      });
    }
  }

  void _showQRWelcomeMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final message = widget.tableNumber != null
            ? 'Masa ${widget.tableNumber} menüsüne hoş geldiniz!'
            : 'Dijital menümüze hoş geldiniz!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.qr_code, color: AppColors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Menü yükleniyor...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_businessExists) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Hata'),
          backgroundColor: AppColors.error,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: AppColors.error),
                const SizedBox(height: 24),
                Text(
                  'İşletme Bulunamadı',
                  style: AppTypography.h3.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Taradığınız QR kod geçersiz veya işletme artık aktif değil.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/qr-scanner'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Tekrar QR Tara'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/welcome'),
                  child: const Text('Ana Sayfaya Dön'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show the actual menu page
    return MenuPage(businessId: widget.businessId);
  }
}

// Ürün detay router sayfası - product ve business parametrelerini alır
class ProductDetailRouterPage extends StatelessWidget {
  const ProductDetailRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return const NotFoundPage();
    }

    final product = args['product'] as Product?;
    final business = args['business'] as Business?;

    if (product == null || business == null) {
      return const NotFoundPage();
    }

    return ProductDetailPage(product: product, business: business);
  }
}

// Admin Dashboard router sayfası
class AdminDashboardRouterPage extends StatelessWidget {
  const AdminDashboardRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';

    // Get current route to determine which page to show
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, card layout for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return AdminDashboardPage(businessId: businessId);
    }
  }
}

// Category Management router sayfası
class CategoryManagementRouterPage extends StatelessWidget {
  const CategoryManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return CategoryManagementPage(businessId: businessId);
    }
  }
}

// Product Management router sayfası
class ProductManagementRouterPage extends StatelessWidget {
  const ProductManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return ProductManagementPage(businessId: businessId);
    }
  }
}

// Business Info router sayfası
class BusinessInfoRouterPage extends StatelessWidget {
  const BusinessInfoRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return BusinessInfoPage(businessId: businessId);
    }
  }
}

// Menu Settings router sayfası
class MenuSettingsRouterPage extends StatelessWidget {
  const MenuSettingsRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return MenuSettingsPage(businessId: businessId);
    }
  }
}

// 404 sayfa
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sayfa Bulunamadı')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            SizedBox(height: 16),
            Text(
              'Sayfa Bulunamadı',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Aradığınız sayfa mevcut değil.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// Splash page placeholder
class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToMenu();
  }

  void _navigateToMenu() {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 64,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 32),

            // Uygulama adı
            const Text(
              'Masa Menü',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Slogan
            const Text(
              'Dijital Menü Çözümü',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.white,
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Welcome page - demo için seçim sayfası
class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.2),
                      blurRadius: 16,
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

              const SizedBox(height: 32),

              // Başlık
              const Text(
                'Masa Menü',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Dijital Menü Çözümü',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 48),

              // Müşteri menüsü butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/menu',
                      arguments: {'businessId': 'demo-business-001'},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, color: AppColors.white),
                      SizedBox(width: 8),
                      Text(
                        'Müşteri Menüsü',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // QR Scanner butonu
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/qr-scanner');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.success, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: AppColors.success),
                      SizedBox(width: 8),
                      Text(
                        'QR Kod Tara',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Admin paneli butonu
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/admin',
                      arguments: {'businessId': 'demo-business-001'},
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'İşletme Yönetimi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Bilgi metni
              const Text(
                'Demo sürümü - Gerçek veriler kullanılmaktadır',
                style: TextStyle(fontSize: 14, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder sayfalar
class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: const Center(child: Text('Giriş sayfası geliştiriliyor...')),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yönetim Paneli')),
      body: const Center(child: Text('Yönetim paneli geliştiriliyor...')),
    );
  }
}

// QR Scanner sayfası
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final QRService _qrService = QRService();
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _flashEnabled = false;
  bool _hasScanned = false;
  String _scanStatusText = 'QR kod taramak için kamerayı QR koda doğrultun';

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
      autoStart: true,
    );

    setState(() {
      _isScanning = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('QR Kod Tarayıcı'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          // Flash Toggle
          IconButton(
            icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          // Manual URL Input
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showManualInputDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Scanner
          if (_isScanning && _scannerController != null)
            MobileScanner(
              controller: _scannerController!,
              onDetect: _onQRCodeDetected,
            ),

          // Scanning Overlay
          _buildScanningOverlay(),

          // Bottom Info Panel
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      decoration: BoxDecoration(color: AppColors.black.withOpacity(0.5)),
      child: Stack(
        children: [
          // Scanning Frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hasScanned ? AppColors.success : AppColors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  ...List.generate(4, (index) {
                    final isTop = index < 2;
                    final isLeft = index % 2 == 0;
                    return Positioned(
                      top: isTop ? 0 : null,
                      bottom: isTop ? null : 0,
                      left: isLeft ? 0 : null,
                      right: isLeft ? null : 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _hasScanned
                              ? AppColors.success
                              : AppColors.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isTop && isLeft ? 10 : 0),
                            topRight: Radius.circular(
                              isTop && !isLeft ? 10 : 0,
                            ),
                            bottomLeft: Radius.circular(
                              !isTop && isLeft ? 10 : 0,
                            ),
                            bottomRight: Radius.circular(
                              !isTop && !isLeft ? 10 : 0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Success Icon
                  if (_hasScanned)
                    const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 50,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Status Text
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _scanStatusText,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Demo Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openDemoMenu,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Demo Menüyü Görüntüle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Help Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'QR kodu taramak için kamerayı QR koda doğrultun',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null) return;

    setState(() {
      _hasScanned = true;
      _scanStatusText = 'QR kod başarıyla tarandı!';
    });

    // Vibration feedback
    HapticFeedback.lightImpact();

    // Process QR code
    _processQRCode(qrData);
  }

  Future<void> _processQRCode(String qrData) async {
    try {
      // Parse QR code using QR service
      final scanResult = _qrService.parseQRCode(qrData);

      if (scanResult != null) {
        // Navigate to menu
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/menu',
            arguments: {
              'businessId': scanResult.businessId,
              'tableNumber': scanResult.tableNumber,
            },
          );
        }
      } else {
        // Try to parse as regular URL
        final uri = Uri.tryParse(qrData);
        if (uri != null &&
            uri.pathSegments.length >= 2 &&
            uri.pathSegments[0] == 'menu') {
          final businessId = uri.pathSegments[1];
          final tableNumber = uri.queryParameters['table'];

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/menu',
              arguments: {'businessId': businessId, 'tableNumber': tableNumber},
            );
          }
        } else {
          throw Exception('Bu QR kod desteklenmiyor');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasScanned = false;
          _scanStatusText = 'QR kod okunamadı. Tekrar deneyin.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR kod hatası: $e'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Tekrar Dene',
              onPressed: () {
                setState(() {
                  _hasScanned = false;
                  _scanStatusText =
                      'QR kod taramak için kamerayı QR koda doğrultun';
                });
              },
            ),
          ),
        );
      }
    }
  }

  void _toggleFlash() {
    if (_scannerController != null) {
      _scannerController!.toggleTorch();
      setState(() {
        _flashEnabled = !_flashEnabled;
      });
    }
  }

  void _showManualInputDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Kod URL\'i Girin'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'QR Kod URL\'i',
            hintText: 'https://masamenu.app/menu/...',
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (urlController.text.isNotEmpty) {
                _processQRCode(urlController.text.trim());
              }
            },
            child: const Text('Menüyü Aç'),
          ),
        ],
      ),
    );
  }

  void _openDemoMenu() {
    Navigator.pushReplacementNamed(
      context,
      '/menu',
      arguments: {'businessId': 'demo-business-001'},
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }
}

// QR Code Management router sayfası
class QRCodeManagementRouterPage extends StatelessWidget {
  const QRCodeManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return QRCodeManagementPage(businessId: businessId);
    }
  }
}

// Discount Management router sayfası
class DiscountManagementRouterPage extends StatelessWidget {
  const DiscountManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return DiscountManagementPage(businessId: businessId);
    }
  }
}

// Orders router sayfası
class OrdersRouterPage extends StatelessWidget {
  const OrdersRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return OrdersPage(businessId: businessId);
    }
  }
}

// Customer Orders router sayfası
class CustomerOrdersRouterPage extends StatelessWidget {
  const CustomerOrdersRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final customerPhone = args?['customerPhone'] as String?;

    return CustomerOrdersPage(
      businessId: businessId,
      customerPhone: customerPhone,
    );
  }
}
