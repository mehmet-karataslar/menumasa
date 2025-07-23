// =============================================================================
// DEPRECATED: Bu dosya artık kullanılmamaktadır
// Yeni routing sistemi için lib/core/routing/app_router.dart kullanın
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/routing/app_router.dart';
import '../../core/routing/route_constants.dart';

/// DEPRECATED: Yeni AppRouter kullanın
@Deprecated('Use AppRouter from lib/core/routing/app_router.dart instead')
class AppRoutes {
  AppRoutes._();

  // Legacy compatibility - Yeni router'a yönlendirme
  static final AppRouter _router = AppRouter();

  /// DEPRECATED: AppRouter.staticRoutes kullanın
  @Deprecated('Use AppRouter().staticRoutes instead')
  static Map<String, WidgetBuilder> get routes => _router.staticRoutes;

  /// DEPRECATED: AppRouter.onGenerateRoute kullanın
  @Deprecated('Use AppRouter().onGenerateRoute instead')
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return _router.onGenerateRoute(settings);
  }

  /// DEPRECATED: AppRouter.onUnknownRoute kullanın
  @Deprecated('Use AppRouter().onUnknownRoute instead')
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return _router.onUnknownRoute(settings);
  }

  // DEPRECATED Route constants - AppRouteConstants kullanın
  @Deprecated('Use AppRouteConstants.root instead')
  static const String home = AppRouteConstants.root;
  
  @Deprecated('Use AppRouteConstants.router instead')
  static const String router = AppRouteConstants.router;
  
  @Deprecated('Use AppRouteConstants.login instead')
  static const String login = AppRouteConstants.login;
  
  @Deprecated('Use AppRouteConstants.register instead')
  static const String register = AppRouteConstants.register;
  
  @Deprecated('Use AppRouteConstants.businessLogin instead')
  static const String businessLogin = AppRouteConstants.businessLogin;
  
  @Deprecated('Use AppRouteConstants.businessRegister instead')
  static const String businessRegister = AppRouteConstants.businessRegister;
  
  @Deprecated('Use AppRouteConstants.customerDashboard instead')
  static const String customerDashboard = AppRouteConstants.customerDashboard;
  
  @Deprecated('Use AppRouteConstants.customerOrders instead')
  static const String customerOrders = AppRouteConstants.customerOrders;
  
  @Deprecated('Use AppRouteConstants.customerProfile instead')
  static const String customerProfile = AppRouteConstants.customerProfile;
  
  @Deprecated('Use AppRouteConstants.customerCart instead')
  static const String customerCart = AppRouteConstants.customerCart;
  
  @Deprecated('Use AppRouteConstants.menu instead')
  static const String menu = AppRouteConstants.menu;
  
  @Deprecated('Use AppRouteConstants.qrMenu instead')
  static const String qrMenu = AppRouteConstants.qrMenu;
  
  @Deprecated('Use AppRouteConstants.qrScanner instead')  
  static const String qrScanner = AppRouteConstants.qrScanner;
  
  @Deprecated('Use AppRouteConstants.productDetail instead')
  static const String productDetail = AppRouteConstants.productDetail;
  
  @Deprecated('Use AppRouteConstants.businessDetail instead')
  static const String businessDetail = AppRouteConstants.businessDetail;
  
  @Deprecated('Use AppRouteConstants.search instead')
  static const String search = AppRouteConstants.search;
  
  @Deprecated('Use AppRouteConstants.businessDashboard instead')
  static const String businessDashboard = AppRouteConstants.businessDashboard;
  
  @Deprecated('Use AppRouteConstants.adminLogin instead')
  static const String adminLogin = AppRouteConstants.adminLogin;
  
  @Deprecated('Use AppRouteConstants.adminRegister instead')
  static const String adminRegister = AppRouteConstants.adminRegister;
  
  @Deprecated('Use AppRouteConstants.adminDashboard instead')
  static const String adminDashboard = AppRouteConstants.adminDashboard;
  
  @Deprecated('Use AppRouteConstants.universalQR instead')
  static const String universalQR = AppRouteConstants.universalQR;

  // Legacy helper methods
  @Deprecated('Use AppRouter.pushNamed instead')
  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return AppRouter.pushNamed<T>(context, routeName, arguments: arguments);
  }

  @Deprecated('Use AppRouter.pushReplacementNamed instead')
  static Future<T?> replaceWith<T>(BuildContext context, String routeName, {Object? arguments}) {
    return AppRouter.pushReplacementNamed<T>(context, routeName, arguments: arguments);
  }

  @Deprecated('Use AppRouter.pushNamedAndClearStack instead')
  static Future<T?> clearAndNavigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return AppRouter.pushNamedAndClearStack<T>(context, routeName, arguments: arguments);
  }

  @Deprecated('Use AppRouter.pop instead')
  static void goBack<T>(BuildContext context, [T? result]) {
    AppRouter.pop<T>(context, result);
  }
}
