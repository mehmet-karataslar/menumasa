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

// Core services
import 'core/services/data_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/cart_service.dart';
import 'core/services/order_service.dart';
import 'core/services/qr_service.dart';

// Global Firebase availability flag
bool isFirebaseAvailable = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is supported on this platform
  bool firebaseSupported = _isFirebaseSupported();

  if (firebaseSupported) {
    try {
      // Firebase initialization
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Firebase Crashlytics setup
      if (!kDebugMode) {
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      isFirebaseAvailable = true;
      print('🔥 Firebase initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Firebase initialization error: $e');
      print('Stack trace: $stackTrace');
      isFirebaseAvailable = false;
    }
  } else {
    print('⚠️ Firebase not supported on this platform, using local storage');
    isFirebaseAvailable = false;
  }

  try {
    // Initialize services (they will handle Firebase availability internally)
    await DataService().initialize();
    await CartService().initialize();
    await OrderService().initialize();

    print('📱 Services initialized successfully');

    // Create sample data if needed
    await DataService().initializeSampleData();
    print('📊 Sample data check completed');
  } catch (e, stackTrace) {
    print('❌ Service initialization error: $e');
    print('Stack trace: $stackTrace');
  }

  runApp(const MasamenuApp());
}

bool _isFirebaseSupported() {
  // Firebase is supported on mobile platforms and web
  // Desktop platforms have limited support
  if (kIsWeb) {
    return true;
  }

  // For mobile platforms
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return true;
  }

  // For desktop platforms, Firebase support is limited
  return false;
}

class MasamenuApp extends StatelessWidget {
  const MasamenuApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masa Menü - Dijital Menü Çözümü',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: AppTypography.fontFamily,
        textTheme: AppTypography.textTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
      // Remove deprecated textScaleFactor
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
      home: const SplashPage(),
      // Routes tanımlamaları
      routes: {
        '/login': (context) => const BusinessLoginPage(),
        '/customer-login': (context) => const CustomerLoginPage(),
        '/qr-scanner': (context) => const QRScannerPage(),
        '/not-found': (context) => const NotFoundPage(),
      },
      // Route generator for dynamic routes with arguments
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/admin':
            // Admin Dashboard route
            final businessId =
                args?['businessId'] as String? ?? 'demo-business-001';
            return MaterialPageRoute(
              builder: (context) => AdminDashboardRouterPage(),
              settings: RouteSettings(name: '/admin', arguments: args),
            );

          case '/menu':
            // Customer Menu route
            final businessId =
                args?['businessId'] as String? ?? 'demo-business-001';
            final customerPhone = args?['customerPhone'] as String?;
            return MaterialPageRoute(
              builder: (context) => MenuRouterPage(),
              settings: RouteSettings(name: '/menu', arguments: args),
            );

          case '/product-detail':
            // Product Detail route
            return MaterialPageRoute(
              builder: (context) => ProductDetailRouterPage(),
              settings: RouteSettings(name: '/product-detail', arguments: args),
            );

          case '/admin/categories':
            // Category Management route
            return MaterialPageRoute(
              builder: (context) => CategoryManagementRouterPage(),
              settings: RouteSettings(
                name: '/admin/categories',
                arguments: args,
              ),
            );

          case '/admin/products':
            // Product Management route
            return MaterialPageRoute(
              builder: (context) => ProductManagementRouterPage(),
              settings: RouteSettings(name: '/admin/products', arguments: args),
            );

          case '/admin/qr-codes':
            // QR Code Management route
            return MaterialPageRoute(
              builder: (context) => QRCodeManagementRouterPage(),
              settings: RouteSettings(name: '/admin/qr-codes', arguments: args),
            );

          case '/admin/business-info':
            // Business Info route
            return MaterialPageRoute(
              builder: (context) => BusinessInfoRouterPage(),
              settings: RouteSettings(
                name: '/admin/business-info',
                arguments: args,
              ),
            );

          case '/admin/menu-settings':
            // Menu Settings route
            return MaterialPageRoute(
              builder: (context) => MenuSettingsRouterPage(),
              settings: RouteSettings(
                name: '/admin/menu-settings',
                arguments: args,
              ),
            );

          case '/admin/discounts':
            // Discount Management route
            return MaterialPageRoute(
              builder: (context) => DiscountManagementRouterPage(),
              settings: RouteSettings(
                name: '/admin/discounts',
                arguments: args,
              ),
            );

          case '/admin/orders':
            // Orders route
            return MaterialPageRoute(
              builder: (context) => OrdersRouterPage(),
              settings: RouteSettings(name: '/admin/orders', arguments: args),
            );

          case '/customer-orders':
            // Customer Orders route
            return MaterialPageRoute(
              builder: (context) => CustomerOrdersRouterPage(),
              settings: RouteSettings(
                name: '/customer-orders',
                arguments: args,
              ),
            );

          default:
            // Unknown route
            return MaterialPageRoute(
              builder: (context) => const NotFoundPage(),
            );
        }
      },
      // Unknown route handler
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const NotFoundPage());
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Debug widget to show Firebase connection status
class FirebaseStatusWidget extends StatefulWidget {
  const FirebaseStatusWidget({Key? key}) : super(key: key);

  @override
  State<FirebaseStatusWidget> createState() => _FirebaseStatusWidgetState();
}

class _FirebaseStatusWidgetState extends State<FirebaseStatusWidget> {
  String _status = 'Checking Firebase...';

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  Future<void> _checkFirebaseStatus() async {
    try {
      final dataService = DataService();
      final businesses = await dataService.getBusinesses();

      setState(() {
        _status = '✅ Firebase OK - ${businesses.length} business found';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Firebase Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Text(_status, style: const TextStyle(fontSize: 12)),
    );
  }
}
