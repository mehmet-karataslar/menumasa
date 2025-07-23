import 'package:flutter/material.dart';
import '../../core/routing/base_route_handler.dart';
import '../../core/routing/route_constants.dart';
import '../pages/admin_login_page.dart';
import '../pages/admin_register_page.dart';
import '../pages/admin_dashboard_page.dart';
import '../pages/admin_management_page.dart';
import '../pages/business_management_page.dart';
import '../pages/customer_management_page.dart';
import '../pages/analytics_page.dart';
import '../pages/system_settings_page.dart';
import '../pages/activity_logs_page.dart';

/// Admin Route Handler - Admin modülü route'larını yönetir
class AdminRouteHandler implements BaseRouteHandler {
  static final AdminRouteHandler _instance = AdminRouteHandler._internal();
  factory AdminRouteHandler() => _instance;
  AdminRouteHandler._internal();

  @override
  String get moduleName => 'Admin';

  @override
  String get routePrefix => AppRouteConstants.adminPrefix;

  @override
  List<String> get supportedRoutes => [
    AppRouteConstants.adminLogin,
    AppRouteConstants.adminRegister,
    AppRouteConstants.adminDashboard,
    AppRouteConstants.adminBusinesses,
    AppRouteConstants.adminCustomers,
    AppRouteConstants.adminAdmins,
    AppRouteConstants.adminAnalytics,
    AppRouteConstants.adminSettings,
    AppRouteConstants.adminLogs,
  ];

  @override
  Map<String, WidgetBuilder> get staticRoutes => {
    AppRouteConstants.adminLogin: (context) => const AdminLoginPage(),
    AppRouteConstants.adminRegister: (context) => const AdminRegisterPage(),
    AppRouteConstants.adminDashboard: (context) => const AdminDashboardPage(),
    AppRouteConstants.adminBusinesses: (context) => const BusinessManagementPage(),
    AppRouteConstants.adminCustomers: (context) => const CustomerManagementPage(),
    AppRouteConstants.adminAdmins: (context) => const AdminManagementPage(),
    AppRouteConstants.adminAnalytics: (context) => const AnalyticsPage(),
    AppRouteConstants.adminSettings: (context) => const SystemSettingsPage(),
    AppRouteConstants.adminLogs: (context) => const ActivityLogsPage(),
  };

  @override
  bool canHandle(String routeName) {
    return AppRouteConstants.isAdminRoute(routeName);
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

  /// Dinamik admin route'larını handle eder
  Route<dynamic>? _handleDynamicRoute(RouteSettings settings) {
    final routeName = settings.name!;
    final pathSegments = RouteUtils.getPathSegments(routeName);
    
    // /admin/dashboard/{section} format için
    if (pathSegments.length >= 3 && pathSegments[1] == 'dashboard') {
      final section = pathSegments[2];
      return RouteUtils.createRoute(
        (context) => const AdminDashboardPage(),
        RouteSettings(
          name: routeName,
          arguments: {
            'initialSection': section,
            ...?settings.arguments as Map<String, dynamic>?,
          },
        ),
      );
    }

    // /admin/businesses/{businessId} format için
    if (pathSegments.length >= 3 && pathSegments[1] == 'businesses') {
      final businessId = pathSegments[2];
      return RouteUtils.createRoute(
        (context) => const BusinessManagementPage(),
        RouteSettings(
          name: routeName,
          arguments: {
            'selectedBusinessId': businessId,
            ...?settings.arguments as Map<String, dynamic>?,
          },
        ),
      );
    }

    // /admin/customers/{customerId} format için
    if (pathSegments.length >= 3 && pathSegments[1] == 'customers') {
      final customerId = pathSegments[2];
      return RouteUtils.createRoute(
        (context) => const CustomerManagementPage(),
        RouteSettings(
          name: routeName,
          arguments: {
            'selectedCustomerId': customerId,
            ...?settings.arguments as Map<String, dynamic>?,
          },
        ),
      );
    }

    // /admin/admins/{adminId} format için
    if (pathSegments.length >= 3 && pathSegments[1] == 'admins') {
      final adminId = pathSegments[2];
      return RouteUtils.createRoute(
        (context) => const AdminManagementPage(),
        RouteSettings(
          name: routeName,
          arguments: {
            'selectedAdminId': adminId,
            ...?settings.arguments as Map<String, dynamic>?,
          },
        ),
      );
    }

    return null;
  }
} 