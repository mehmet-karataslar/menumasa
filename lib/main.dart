import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masa Menü',
      debugShowCheckedModeBanner: false,

      // Tema ayarları
      theme: _buildTheme(),

      // Başlangıç rotası
      initialRoute: '/',

      // Rota yapılandırması
      routes: _buildRoutes(),

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
    };
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
    // Simulate business verification
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _businessExists = widget.businessId.isNotEmpty;
      _isLoading = false;
    });

    if (_businessExists) {
      // Show welcome message for QR scanned users
      _showQRWelcomeMessage();
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

    return AdminDashboardPage(businessId: businessId);
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

    return CategoryManagementPage(businessId: businessId);
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

    return ProductManagementPage(businessId: businessId);
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

    return BusinessInfoPage(businessId: businessId);
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

    return MenuSettingsPage(businessId: businessId);
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
                      arguments: {'businessId': 'demo-business'},
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
  final TextEditingController _urlController = TextEditingController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod Tarayıcı'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Icon
            Icon(
              Icons.qr_code_scanner,
              size: 120,
              color: AppColors.primary.withOpacity(0.7),
            ),

            const SizedBox(height: 32),

            // Title
            const Text(
              'QR Kod ile Menüye Erişin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            const Text(
              'QR kod URL\'ini girin veya demo menüyü görüntüleyin',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // URL Input
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'QR Kod URL\'i',
                hintText: 'https://masamenu.app/menu/...',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.greyLight,
              ),
            ),

            const SizedBox(height: 24),

            // Process Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processQRCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : const Text(
                        'Menüyü Aç',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            const Divider(),

            const SizedBox(height: 16),

            // Demo Button
            const Text(
              'veya',
              style: TextStyle(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 16),

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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Help Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(height: 8),
                  const Text(
                    'QR Kod Nasıl Taranır?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Telefon kameranızı QR koda doğrultun\n'
                    '2. Açılan linke dokunun\n'
                    '3. Veya linki kopyalayıp buraya yapıştırın',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processQRCode() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen QR kod URL\'ini girin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Parse QR URL to extract business ID
      final uri = Uri.parse(url);

      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'menu') {
        final businessId = uri.pathSegments[1];
        final tableNumber = uri.queryParameters['table'];

        // Navigate to menu
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/menu',
            arguments: {'businessId': businessId, 'tableNumber': tableNumber},
          );
        }
      } else {
        throw Exception('Geçersiz QR kod URL\'i');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR kod işlenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _openDemoMenu() {
    Navigator.pushNamed(
      context,
      '/menu',
      arguments: {'businessId': 'demo-business-001'},
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
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

    return QRCodeManagementPage(businessId: businessId);
  }
}
