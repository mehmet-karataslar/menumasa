import 'package:flutter/material.dart';

import '../../main.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/business_register_page.dart';
import '../../presentation/pages/auth/router_page.dart';
import '../../presentation/pages/customer/menu_page.dart';
import '../../presentation/pages/customer/product_detail_page.dart';
import '../../presentation/pages/customer/customer_orders_page.dart';
import '../../presentation/pages/customer/customer_home_page.dart';
import '../../presentation/pages/customer/customer_dashboard_page.dart';
import '../../presentation/pages/customer/business_detail_page.dart';
import '../../presentation/pages/customer/search_page.dart';
import '../../presentation/pages/admin/admin_dashboard_page.dart';
import '../../presentation/pages/admin/responsive_admin_dashboard.dart';
import '../../presentation/pages/admin/category_management_page.dart';
import '../../presentation/pages/admin/product_management_page.dart';
import '../../presentation/pages/admin/business_info_page.dart';
import '../../presentation/pages/admin/menu_settings_page.dart';
import '../../presentation/pages/admin/discount_management_page.dart';
import '../../presentation/pages/admin/orders_page.dart';

class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
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

  // Admin routes
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminCategories = '/admin/categories';
  static const String adminProducts = '/admin/products';
  static const String adminBusinessInfo = '/admin/business-info';
  static const String adminMenuSettings = '/admin/menu-settings';
  static const String adminDiscounts = '/admin/discounts';
  static const String adminOrders = '/admin/orders';
  static const String responsiveAdmin = '/admin/responsive';

  // Route map
  static Map<String, WidgetBuilder> get routes => {
    '/': (context) => const RouterPage(),
    login: (context) => const LoginPage(userType: 'business'),
    register: (context) => const RegisterPage(userType: 'business'),
    businessRegister: (context) => const BusinessRegisterPage(),
    router: (context) => const RouterPage(),
    menu: (context) => const MenuRouterPage(),
    productDetail: (context) => const ProductDetailRouterPage(),
    customerOrders: (context) => const CustomerOrdersRouterPage(),
    customerHome: (context) => const CustomerHomeRouterPage(),
    customerDashboard: (context) => const CustomerDashboardRouterPage(),
    businessDetail: (context) => const BusinessDetailRouterPage(),
    search: (context) => const SearchRouterPage(),
    admin: (context) => const ResponsiveAdminRouterPage(),
    adminDashboard: (context) => const ResponsiveAdminRouterPage(),
    adminCategories: (context) => const ResponsiveAdminRouterPage(),
    adminProducts: (context) => const ResponsiveAdminRouterPage(),
    adminBusinessInfo: (context) => const ResponsiveAdminRouterPage(),
    adminMenuSettings: (context) => const ResponsiveAdminRouterPage(),
    adminDiscounts: (context) => const ResponsiveAdminRouterPage(),
    adminOrders: (context) => const ResponsiveAdminRouterPage(),
    responsiveAdmin: (context) => const ResponsiveAdminRouterPage(),
  };

  // Custom route generator for dynamic URLs
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

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

class ResponsiveAdminRouterPage extends StatelessWidget {
  const ResponsiveAdminRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    // businessId yoksa router'a yönlendir
    if (businessId == null || businessId.isEmpty) {
      return const RouterPage();
    }

    return ResponsiveAdminDashboard(businessId: businessId);
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
      businesses: businesses.cast<dynamic>(),
      categories: categories.cast<dynamic>(),
    );
  }
}
