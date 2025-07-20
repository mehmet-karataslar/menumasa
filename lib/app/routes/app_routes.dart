import 'package:flutter/material.dart';

import '../../main.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/business_register_page.dart';
import '../../presentation/pages/auth/router_page.dart';
import '../../business/pages/business_login_page.dart';
import '../../presentation/pages/customer/menu_page.dart';
import '../../presentation/pages/customer/product_detail_page.dart';
import '../../presentation/pages/customer/customer_orders_page.dart';
import '../../presentation/pages/customer/customer_home_page.dart';
import '../../presentation/pages/customer/customer_dashboard_page.dart';
import '../../presentation/pages/customer/business_detail_page.dart';
import '../../presentation/pages/customer/search_page.dart';
import '../../presentation/pages/business/business_home_page.dart';
import '../../data/models/category.dart' as app_category;
import '../../data/models/business.dart';
import '../../admin/admin.dart';
import '../../admin/admin_routes.dart';
import '../../business/pages/business_dashboard_page.dart';

class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String businessLogin = '/business/login';
  static const String register = '/register';
  static const String businessRegister = '/business-register';
  static const String router = '/router';
  static const String menu = '/menu';
  static const String productDetail = '/product-detail';
  static const String customerOrders = '/customer/orders';
  static const String customerHome = '/customer/home';
  static const String customerDashboard = '/customer/dashboard';
  static const String businessDetail = '/business/detail';
  static const String search = '/search';
  static const String businessHome = '/business/home';

  // Business management routes with tab support
  static const String businessDashboard = '/business/dashboard';
  static const String businessManagement = '/business';

  // Valid business tabs
  static const List<String> validBusinessTabs = [
    'genel-bakis',
    'siparisler',
    'kategoriler',
    'urunler',
    'indirimler',
    'qr-kodlar',
    'ayarlar',
  ];

  // Route map
  static Map<String, WidgetBuilder> get routes => {
    '/': (context) => const RouterPage(),
    login: (context) => const LoginPage(userType: 'customer'),
    businessLogin: (context) => const BusinessLoginPage(),
    register: (context) => const RegisterPage(userType: 'customer'),
    businessRegister: (context) => const BusinessRegisterPage(),
    router: (context) => const RouterPage(),
    menu: (context) => const MenuRouterPage(),
    productDetail: (context) => const ProductDetailRouterPage(),
    customerOrders: (context) => const CustomerOrdersRouterPage(),
    customerHome: (context) => const CustomerHomeRouterPage(),
    customerDashboard: (context) => const CustomerDashboardRouterPage(),
    businessDetail: (context) => const BusinessDetailRouterPage(),
    search: (context) => const SearchRouterPage(),
    businessHome: (context) => const BusinessHomeRouterPage(),
    businessDashboard: (context) => const BusinessDashboardRouterPage(),
  };

  // Custom route generator for dynamic URLs
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

    // Handle admin routes
    if (AdminModule.isAdminRoute(settings.name ?? '')) {
      return AdminRoutes.generateRoute(settings);
    }

    // Handle login and register routes with userType parameter
    if (settings.name == login) {
      final args = settings.arguments as Map<String, dynamic>?;
      final userType = args?['userType'] ?? 'business';
      return MaterialPageRoute(
        builder: (context) => LoginPage(userType: userType),
        settings: settings,
      );
    }

    if (settings.name == register) {
      final args = settings.arguments as Map<String, dynamic>?;
      final userType = args?['userType'] ?? 'business';
      return MaterialPageRoute(
        builder: (context) => RegisterPage(userType: userType),
        settings: settings,
      );
    }

    // Handle dynamic menu URLs: /menu/businessId?table=tableNumber
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'menu') {
      final businessId = uri.pathSegments[1];
      final tableNumber = uri.queryParameters['table'];

      return MaterialPageRoute(
        builder: (context) => MenuPage(businessId: businessId),
        settings: settings,
      );
    }

    // Handle business management URLs: /business/businessId/tab
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'business') {
      final businessId = uri.pathSegments[1];
      
      // Check if there's a tab specified
      String? tab;
      if (uri.pathSegments.length >= 3) {
        final potentialTab = uri.pathSegments[2];
        if (validBusinessTabs.contains(potentialTab)) {
          tab = potentialTab;
        }
      }

      return MaterialPageRoute(
        builder: (context) => BusinessHomePage(
          businessId: businessId,
          initialTab: tab ?? 'genel-bakis', // Default to overview
        ),
        settings: settings,
      );
    }

    // Handle legacy business dashboard route
    if (settings.name == businessDashboard) {
      return MaterialPageRoute(
        builder: (context) => const BusinessDashboardRouterPage(),
        settings: settings,
      );
    }

    return null;
  }

  // Unknown route handler
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(builder: (context) => const RouterPage());
  }
}

// Router widget classes for parameter handling
class MenuRouterPage extends StatelessWidget {
  const MenuRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;
    final tableNumber = args?['tableNumber'] as String?;

    // Auth kontrolü - eğer businessId yoksa router'a yönlendir
    if (businessId == null || businessId.isEmpty) {
      return const RouterPage();
    }

    return MenuPage(businessId: businessId);
  }
}

class ProductDetailRouterPage extends StatelessWidget {
  const ProductDetailRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final product = args?['product'];
    final business = args?['business'];

    // Gerekli parametreler yoksa router'a yönlendir
    if (product == null || business == null) {
      return const RouterPage();
    }

    return ProductDetailPage(product: product, business: business);
  }
}

class CustomerOrdersRouterPage extends StatelessWidget {
  const CustomerOrdersRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;
    final customerPhone = args?['customerPhone'] as String?;

    // businessId yoksa router'a yönlendir
    if (businessId == null || businessId.isEmpty) {
      return const RouterPage();
    }

    return CustomerOrdersPage(
      businessId: businessId,
      customerPhone: customerPhone,
    );
  }
}

class BusinessDashboardRouterPage extends StatelessWidget {
  const BusinessDashboardRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BusinessDashboardPage();
  }
}

class CustomerHomeRouterPage extends StatelessWidget {
  const CustomerHomeRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    if (userId == null || userId.isEmpty) {
      return const RouterPage();
    }

    return CustomerHomePage(userId: userId);
  }
}

class CustomerDashboardRouterPage extends StatelessWidget {
  const CustomerDashboardRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    if (userId == null || userId.isEmpty) {
      return const RouterPage();
    }

    return CustomerDashboardPage(userId: userId);
  }
}

class BusinessDetailRouterPage extends StatelessWidget {
  const BusinessDetailRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final business = args?['business'];
    final customerData = args?['customerData'];

    if (business == null) {
      return const RouterPage();
    }

    return BusinessDetailPage(
      business: business,
      customerData: customerData,
    );
  }
}

class SearchRouterPage extends StatelessWidget {
  const SearchRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businesses = args?['businesses'] as List<dynamic>?;
    final categories = args?['categories'] as List<dynamic>?;

    if (businesses == null || categories == null) {
      return const RouterPage();
    }

    return SearchPage(
      businesses: businesses.cast<Business>(),
      categories: categories.cast<app_category.Category>(),
    );
  }
}

class BusinessHomeRouterPage extends StatelessWidget {
  const BusinessHomeRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Business home route should redirect to business dashboard
    // Check if user is authenticated business user
    return const BusinessDashboardPage();
  }
}
