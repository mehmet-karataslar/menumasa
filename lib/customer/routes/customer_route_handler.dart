import 'package:flutter/material.dart';
import '../../core/routing/base_route_handler.dart';
import '../../core/routing/route_constants.dart';
import '../../core/routing/route_utils.dart' as route_utils;
import '../../presentation/pages/auth/router_page.dart';
import '../pages/customer_dashboard_page.dart';
import '../pages/customer_orders_page.dart';
import '../pages/customer_profile_page.dart';
import '../pages/cart_page.dart';
import '../pages/menu_page.dart';
import '../pages/business_detail_page.dart';
import '../pages/search_page.dart';
import '../pages/qr_scanner_page.dart';
import '../../business/models/business.dart';
import '../../business/models/category.dart' as app_category;

/// Customer Route Handler - Customer modülü route'larını yönetir
class CustomerRouteHandler implements BaseRouteHandler {
  static final CustomerRouteHandler _instance = CustomerRouteHandler._internal();
  factory CustomerRouteHandler() => _instance;
  CustomerRouteHandler._internal();

  @override
  String get moduleName => 'Customer';

  @override
  String get routePrefix => AppRouteConstants.customerPrefix;

  @override
  List<String> get supportedRoutes => [
    AppRouteConstants.customerDashboard,
    AppRouteConstants.customerOrders,
    AppRouteConstants.customerProfile,
    AppRouteConstants.customerCart,
    AppRouteConstants.customerSearch,
    AppRouteConstants.customerQRScanner,
  ];

  @override
  Map<String, WidgetBuilder> get staticRoutes => {
    AppRouteConstants.customerDashboard: (context) => const CustomerDashboardRouterPage(),
    AppRouteConstants.customerOrders: (context) => const CustomerOrdersRouterPage(),
    AppRouteConstants.customerProfile: (context) => const CustomerProfileRouterPage(),
    AppRouteConstants.customerCart: (context) => const CustomerCartRouterPage(),
    AppRouteConstants.customerSearch: (context) => const SearchRouterPage(),
    AppRouteConstants.customerQRScanner: (context) => const QRScannerRouterPage(),
  };

  @override
  bool canHandle(String routeName) {
    return AppRouteConstants.isCustomerRoute(routeName);
  }

  @override
  Route<dynamic>? handleRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null || !canHandle(routeName)) {
      return null;
    }

    RouteUtils.debugRoute(routeName, settings);

    // Statik route'ları kontrol et
    final staticBuilder = staticRoutes[routeName];
    if (staticBuilder != null) {
      return RouteUtils.createRoute(staticBuilder, settings);
    }

    // Dinamik route'ları handle et
    return _handleDynamicRoute(settings);
  }

  /// Dinamik customer route'larını handle eder
  Route<dynamic>? _handleDynamicRoute(RouteSettings settings) {
    final routeName = settings.name!;
    final pathSegments = RouteUtils.getPathSegments(routeName);

    if (pathSegments.length >= 2) {
      switch (pathSegments[1]) {
        case 'dashboard':
          final args = RouteUtils.getArgument<Map<String, dynamic>>(settings, 'args') ?? {};
          final userId = args['userId'] as String? ?? 'guest';
          return RouteUtils.createRoute(
            (context) => CustomerDashboardPage(userId: userId),
            settings,
          );

        case 'orders':
          final args = RouteUtils.getArgument<Map<String, dynamic>>(settings, 'args') ?? {};
          return RouteUtils.createRoute(
            (context) => CustomerOrdersPage(
              businessId: args['businessId'] as String?,
              customerPhone: args['customerPhone'] as String?,
              customerId: args['customerId'] as String?,
            ),
            settings,
          );

        case 'profile':
          return RouteUtils.createRoute(
            (context) => const CustomerProfilePage(),
            settings,
          );

        case 'cart':
          final args = RouteUtils.getArgument<Map<String, dynamic>>(settings, 'args') ?? {};
          final businessId = args['businessId'] as String?;
          if (businessId == null) return null;
          return RouteUtils.createRoute(
            (context) => CartPage(businessId: businessId),
            settings,
          );

        // Handle dynamic routes like /customer/{userId}/business/{businessId}
        default:
          if (pathSegments.length >= 3) {
            final userId = pathSegments[1];
            final actionType = pathSegments[2];

            // Modern dashboard tab routes: /customer/{userId}/{tabId}
            if (_isModernDashboardTab(actionType)) {
              final tabIndex = _getTabIndex(actionType);
              return RouteUtils.createRoute(
                (context) => CustomerDashboardPage(
                  userId: userId,
                  initialTabIndex: tabIndex,
                ),
                RouteSettings(
                  name: routeName,
                  arguments: {
                    'userId': userId,
                    'tabId': actionType,
                    'tabIndex': tabIndex,
                    ...?settings.arguments as Map<String, dynamic>?,
                  },
                ),
              );
            }

            // Multi-segment routes
            if (pathSegments.length >= 4) {
              final targetId = pathSegments[3];

              switch (actionType) {
                case 'business':
                  final args = RouteUtils.getArgument<Map<String, dynamic>>(settings, 'args') ?? {};
                  final business = args['business'];
                  final customerData = args['customerData'];
                  if (business == null) return null;
                  return RouteUtils.createRoute(
                    (context) => BusinessDetailPage(
                      business: business,
                      customerData: customerData,
                    ),
                    settings,
                  );

                case 'menu':
                  return RouteUtils.createRoute(
                    (context) => MenuPage(businessId: targetId),
                    settings,
                  );

                case 'cart':
                  return RouteUtils.createRoute(
                    (context) => CartPage(businessId: targetId),
                    settings,
                  );

                case 'orders':
                  return RouteUtils.createRoute(
                    (context) => CustomerOrdersPage(
                      businessId: targetId,
                      customerId: userId,
                    ),
                    settings,
                  );
              }
            }
            
            // Single segment routes
            switch (actionType) {
              case 'qr-scanner':
                return RouteUtils.createRoute(
                  (context) => QRScannerPage(userId: userId),
                  settings,
                );

              case 'search':
                final args = RouteUtils.getArgument<Map<String, dynamic>>(settings, 'args') ?? {};
                final businesses = args['businesses'] as List<dynamic>? ?? [];
                final categories = args['categories'] as List<dynamic>? ?? [];
                return RouteUtils.createRoute(
                  (context) => SearchPage(
                    businesses: businesses.cast<Business>(),
                    categories: categories.cast<app_category.Category>(),
                  ),
                  settings,
                );

              case 'profile':
                return RouteUtils.createRoute(
                  (context) => const CustomerProfilePage(),
                  settings,
                );
            }
          }
          break;
      }
    }

    return null;
  }

  /// Modern dashboard tab'ı mı kontrol eder
  bool _isModernDashboardTab(String tabId) {
    const modernTabs = ['home', 'orders', 'favorites', 'services', 'profile'];
    return modernTabs.contains(tabId);
  }

  /// Tab ID'den tab index'i döner
  int _getTabIndex(String tabId) {
    const tabMap = {
      'home': 0,
      'orders': 1,
      'favorites': 2,
      'services': 3,
      'profile': 4,
    };
    return tabMap[tabId] ?? 0;
  }
}

/// Router Page Classes - Parameter handling için
class CustomerDashboardRouterPage extends StatelessWidget {
  const CustomerDashboardRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String? ?? 'guest';
    final tabIndex = args?['tabIndex'] as int? ?? 0;

    return CustomerDashboardPage(
      userId: userId,
      initialTabIndex: tabIndex,
    );
  }
}

class CustomerOrdersRouterPage extends StatelessWidget {
  const CustomerOrdersRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;
    final customerPhone = args?['customerPhone'] as String?;
    final customerId = args?['customerId'] as String?;

    // businessId yoksa router'a yönlendir
    if (businessId == null || businessId.isEmpty) {
      return const RouterPage();
    }

    return CustomerOrdersPage(
      businessId: businessId,
      customerPhone: customerPhone,
      customerId: customerId,
    );
  }
}

class CustomerProfileRouterPage extends StatelessWidget {
  const CustomerProfileRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerProfilePage();
  }
}

class CustomerCartRouterPage extends StatelessWidget {
  const CustomerCartRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    if (businessId == null || businessId.isEmpty) {
      return const RouterPage();
    }

    return CartPage(businessId: businessId);
  }
}

class SearchRouterPage extends StatelessWidget {
  const SearchRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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

class QRScannerRouterPage extends StatelessWidget {
  const QRScannerRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    return QRScannerPage(userId: userId);
  }
} 