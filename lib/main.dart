import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'core/routing/app_router.dart';
import 'presentation/pages/auth/splash_page.dart';
import 'presentation/pages/auth/business_login_page.dart';
import 'presentation/pages/customer/customer_login_page.dart';
import 'presentation/pages/qr/qr_scanner_page.dart';
import 'presentation/pages/qr/qr_menu_page.dart';
import 'presentation/pages/shared/not_found_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i initialize et
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase Crashlytics'i debug modda devre dışı bırak
  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }

  // Flutter Error Handler'ı Firebase Crashlytics'e bağla
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Async Error Handler'ı bağla
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

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
    // Web platformunda direkt müşteri giriş sayfasını aç
    // Mobile'da splash screen göster
    if (kIsWeb) {
      return '/customer-login';
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

      // Web için direkt customer login, mobile için splash
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
      '/login': (context) => const BusinessLoginPage(),
      '/customer-login': (context) => const CustomerLoginPage(),
      '/menu': (context) => const MenuRouterPage(),
      '/qr-scanner': (context) => const QRScannerPage(),
      '/qr-test': (context) => const QRTestRouterPage(),
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

    // Handle QR test page routing
    if (settings.name == '/qr-test') {
      final args = settings.arguments as Map<String, dynamic>?;
      final businessId = args?['businessId'] as String? ?? 'demo-business-001';
      final tableNumber = args?['tableNumber'] as String?;

      return MaterialPageRoute(
        builder: (context) =>
            QRTestPage(businessId: businessId, tableNumber: tableNumber),
        settings: settings,
      );
    }

    // Handle other dynamic routes if needed
    return null;
  }
}

// QR Test router sayfası
class QRTestRouterPage extends StatelessWidget {
  const QRTestRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final tableNumber = args?['tableNumber'] as String?;

    return QRTestPage(businessId: businessId, tableNumber: tableNumber);
  }
}
