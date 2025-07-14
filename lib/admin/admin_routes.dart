import 'package:flutter/material.dart';
import 'pages/admin_login_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/business_management_page.dart';
import 'pages/customer_management_page.dart';
import 'pages/admin_management_page.dart';
import 'pages/analytics_page.dart';
import 'pages/system_settings_page.dart';
import 'pages/activity_logs_page.dart';

class AdminRoutes {
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String businessManagement = '/admin/businesses';
  static const String customerManagement = '/admin/customers';
  static const String adminManagement = '/admin/admins';
  static const String analytics = '/admin/analytics';
  static const String systemSettings = '/admin/settings';
  static const String activityLogs = '/admin/logs';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case adminLogin:
        return MaterialPageRoute(
          builder: (_) => const AdminLoginPage(),
          settings: settings,
        );

      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardPage(),
          settings: settings,
        );

      case businessManagement:
        return MaterialPageRoute(
          builder: (_) => const BusinessManagementPage(),
          settings: settings,
        );

      case customerManagement:
        return MaterialPageRoute(
          builder: (_) => const CustomerManagementPage(),
          settings: settings,
        );

      case adminManagement:
        return MaterialPageRoute(
          builder: (_) => const AdminManagementPage(),
          settings: settings,
        );

      case analytics:
        return MaterialPageRoute(
          builder: (_) => const AnalyticsPage(),
          settings: settings,
        );

      case systemSettings:
        return MaterialPageRoute(
          builder: (_) => const SystemSettingsPage(),
          settings: settings,
        );

      case activityLogs:
        return MaterialPageRoute(
          builder: (_) => const ActivityLogsPage(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const AdminLoginPage(),
          settings: settings,
        );
    }
  }

  // Admin route'larının tam listesi
  static List<String> get allRoutes => [
    adminLogin,
    adminDashboard,
    businessManagement,
    customerManagement,
    adminManagement,
    analytics,
    systemSettings,
    activityLogs,
  ];

  // Admin route'larının prefix'i
  static const String adminPrefix = '/admin';

  // Bir route'un admin route'u olup olmadığını kontrol et
  static bool isAdminRoute(String route) {
    return route.startsWith(adminPrefix);
  }

  // Admin route'larını ana route'lardan ayır
  static String getAdminRoute(String fullRoute) {
    if (fullRoute.startsWith(adminPrefix)) {
      return fullRoute;
    }
    return adminLogin;
  }
} 