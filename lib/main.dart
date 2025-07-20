import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'core/services/firestore_service.dart';
import 'presentation/pages/customer/menu_page.dart';
import 'presentation/pages/customer/product_detail_page.dart';
import 'admin/admin.dart';
import 'business/pages/category_management_page.dart';
import 'business/pages/product_management_page.dart';
import 'business/pages/qr_management_page.dart';
import 'business/pages/business_profile_page.dart';
import 'business/pages/menu_settings_page.dart';
import 'business/pages/discount_management_page.dart';
import 'business/pages/order_management_page.dart';
import 'presentation/pages/customer/customer_orders_page.dart';
import 'business/pages/business_dashboard_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/register_page.dart';
import 'presentation/pages/auth/business_register_page.dart';
import 'presentation/pages/auth/router_page.dart';
import 'core/services/data_service.dart';
import 'core/services/auth_service.dart';
import 'data/models/product.dart';
import 'data/models/business.dart';
import 'app/routes/app_routes.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Configure Firebase Auth for development
    if (kIsWeb) {
      // Disable reCAPTCHA for development
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
    }
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue anyway, Firebase might already be initialized
  }

  // App Check is disabled for now to avoid hot restart issues
  // Firebase will work without App Check in development

  // Initialize Firestore database
  final firestoreService = FirestoreService();
  await firestoreService.initializeDatabase();

  // Initialize Admin Module
  await AdminModule.initialize();

  // System UI configuration
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Run the app
  runApp(const MasaMenuApp());
}

class MasaMenuApp extends StatelessWidget {
  const MasaMenuApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masa Menü - Dijital Menü Çözümü',
      debugShowCheckedModeBanner: false,

      // Theme settings
      theme: _buildTheme(),

      // Direct auth router page
      initialRoute: '/',

      // Route configuration
      routes: AppRoutes.routes,

      // Dynamic route generator
      onGenerateRoute: AppRoutes.onGenerateRoute,

      // Unknown route handler
      onUnknownRoute: AppRoutes.onUnknownRoute,

      // App title
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0, // Limit user font size changes
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

      // AppBar theme
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

      // Button themes
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

      // Input theme
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

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.white,
        shadowColor: AppColors.shadow,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.greyLight,
        thickness: 1,
      ),
    );
  }




}



// Menu router page - takes businessId parameter
class MenuRouterPage extends StatelessWidget {
  const MenuRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    if (businessId == null) {
      return const NotFoundPage();
    }

    return MenuPage(businessId: businessId);
  }
}

// Product detail router page - takes product and business parameters
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

// Admin Dashboard router page
class AdminDashboardRouterPage extends StatelessWidget {
  const AdminDashboardRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    if (businessId == null) {
      return const NotFoundPage();
    }

    return ResponsiveAdminDashboard(businessId: businessId);
  }
}

// Category Management router page
class CategoryManagementRouterPage extends StatelessWidget {
  const CategoryManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    if (businessId == null) {
      return const NotFoundPage();
    }

    return CategoryManagementPage(businessId: businessId);
  }
}

// Product Management router page
class ProductManagementRouterPage extends StatelessWidget {
  const ProductManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    if (businessId == null) {
      return const NotFoundPage();
    }

    return ProductManagementPage(businessId: businessId);
  }
}

// Business Profile router page
class BusinessProfileRouterPage extends StatelessWidget {
  const BusinessProfileRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    if (businessId == null) {
      return const NotFoundPage();
    }

    return BusinessProfilePage(businessId: businessId);
  }
}

// Menu Settings router page
class MenuSettingsRouterPage extends StatelessWidget {
  const MenuSettingsRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    if (businessId == null) {
      return const NotFoundPage();
    }

    return MenuSettingsPage(businessId: businessId);
  }
}

// QR Management router page
class QRManagementRouterPage extends StatelessWidget {
  const QRManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    if (businessId == null) {
      return const NotFoundPage();
    }

    return QRManagementPage(businessId: businessId);
  }
}

// Discount Management router page
class DiscountManagementRouterPage extends StatelessWidget {
  const DiscountManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    if (businessId ==null) {
      return const NotFoundPage();
    }

    return DiscountManagementPage(businessId: businessId);
  }
}

// Order Management router page
class OrderManagementRouterPage extends StatelessWidget {
  const OrderManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    if (businessId == null) {
      return const NotFoundPage();
    }

    return OrderManagementPage(businessId: businessId);
  }
}

// NotFound page for invalid routes
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sayfa Bulunamadı')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Aradığınız sayfa bulunamadı', style: AppTypography.h3),
            const SizedBox(height: 8),
            Text(
              'İstediğiniz sayfa mevcut değil veya kaldırılmış',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    );
  }
}
