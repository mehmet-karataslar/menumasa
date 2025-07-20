import 'package:flutter/material.dart';
import 'pages/business_login_page.dart';
import 'pages/business_dashboard_page.dart';
import 'pages/business_management_page.dart';
import 'pages/customer_management_page.dart';
import 'pages/analytics_page.dart';
import 'pages/stock_management_page.dart';
import 'pages/system_settings_page.dart';
import 'pages/activity_logs_page.dart';

class BusinessRoutes {
  static const String login = '/business/login';
  static const String dashboard = '/business/dashboard';
  static const String management = '/business/management';
  static const String customers = '/business/customers';
  static const String analytics = '/business/analytics';
  static const String stock = '/business/stock';
  static const String settings = '/business/settings';
  static const String logs = '/business/logs';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const BusinessLoginPage(),
      dashboard: (context) => ResponsiveAdminDashboard(businessId: 'demo'), // TODO: Get from auth
      management: (context) => const BusinessManagementPage(),
      customers: (context) => const CustomerManagementPage(),
      analytics: (context) => const AnalyticsPage(),
      stock: (context) => const StockManagementPage(),
      settings: (context) => const SystemSettingsPage(),
      logs: (context) => const ActivityLogsPage(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/business/login':
        return MaterialPageRoute(
          builder: (context) => const BusinessLoginPage(),
        );
      case '/business/dashboard':
        return MaterialPageRoute(
          builder: (context) => ResponsiveAdminDashboard(businessId: 'demo'), // TODO: Get from auth
        );
      case '/business/management':
        return MaterialPageRoute(
          builder: (context) => const BusinessManagementPage(),
        );
      case '/business/customers':
        return MaterialPageRoute(
          builder: (context) => const CustomerManagementPage(),
        );
      case '/business/analytics':
        return MaterialPageRoute(
          builder: (context) => const AnalyticsPage(),
        );
      case '/business/stock':
        return MaterialPageRoute(
          builder: (context) => const StockManagementPage(),
        );
      case '/business/settings':
        return MaterialPageRoute(
          builder: (context) => const SystemSettingsPage(),
        );
      case '/business/logs':
        return MaterialPageRoute(
          builder: (context) => const ActivityLogsPage(),
        );
      default:
        return null;
    }
  }
} 