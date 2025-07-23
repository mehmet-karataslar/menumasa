import 'package:flutter/material.dart';
import 'base_route_handler.dart';
import 'route_constants.dart';
import 'qr_route_handler.dart';
import '../../admin/routes/admin_route_handler.dart';
import '../../business/routes/business_route_handler.dart';
import '../../customer/routes/customer_route_handler.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/business_register_page.dart';
import '../../presentation/pages/auth/router_page.dart';
import '../../business/pages/business_login_page.dart';

/// Ana Router Manager - Tüm modül route handler'larını koordine eder
class AppRouter {
  static final AppRouter _instance = AppRouter._internal();
  factory AppRouter() => _instance;
  AppRouter._internal() {
    _initializeHandlers();
  }

  // Route Handler'lar
  late final List<BaseRouteHandler> _handlers;
  
  // Route Guards
  final List<RouteGuard> _globalGuards = [];

  /// Route handler'ları başlat
  void _initializeHandlers() {
    _handlers = [
      QRRouteHandler(),
      AdminRouteHandler(),
      BusinessRouteHandler(),
      CustomerRouteHandler(),
    ];
    
    print('🔗 AppRouter initialized with ${_handlers.length} handlers:');
    for (final handler in _handlers) {
      print('   📁 ${handler.moduleName} (${handler.routePrefix})');
    }
  }

  /// Global route guard ekle
  void addGlobalGuard(RouteGuard guard) {
    _globalGuards.add(guard);
    print('🛡️ Added global guard: ${guard.guardName}');
  }

  /// Statik route'ları döner (MaterialApp.routes için)
  Map<String, WidgetBuilder> get staticRoutes {
    final routes = <String, WidgetBuilder>{
      // Core routes
      AppRouteConstants.root: (context) => const RouterPage(),
      AppRouteConstants.router: (context) => const RouterPage(),
      
      // Auth routes
      AppRouteConstants.login: (context) => const LoginPage(userType: 'customer'),
      AppRouteConstants.register: (context) => const RegisterPage(userType: 'customer'),
      AppRouteConstants.businessLogin: (context) => const BusinessLoginPage(),
      AppRouteConstants.businessRegister: (context) => const BusinessRegisterPage(),
    };

    // Tüm handler'lardan statik route'ları al
    for (final handler in _handlers) {
      routes.addAll(handler.staticRoutes);
    }

    print('🗺️ Static routes registered: ${routes.length}');
    return routes;
  }

  /// Dinamik route generation - MaterialApp.onGenerateRoute için
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';
    
    print('🔗 AppRouter: Handling route "$routeName"');
    
    // Debug route info
    RouteUtils.debugRoute(routeName, settings);

    // Global guard'ları kontrol et
    for (final guard in _globalGuards) {
      // TODO: Guard implementation
    }

    // Auth route'ları özel handle et
    if (AppRouteConstants.isAuthRoute(routeName)) {
      return _handleAuthRoutes(settings);
    }

    // Her handler'ı sırayla dene
    for (final handler in _handlers) {
      if (handler.canHandle(routeName)) {
        print('   ✅ Handled by ${handler.moduleName}');
        final route = handler.handleRoute(settings);
        if (route != null) {
          return route;
        }
      }
    }

    print('   ❌ No handler found for route "$routeName"');
    return null;
  }

  /// Unknown route handler - MaterialApp.onUnknownRoute için
  Route<dynamic> onUnknownRoute(RouteSettings settings) {
    print('❓ Unknown route: ${settings.name}');
    return MaterialPageRoute(
      builder: (context) => const RouterPage(),
      settings: RouteSettings(
        name: AppRouteConstants.router,
        arguments: {
          'unknownRoute': settings.name,
          'originalArguments': settings.arguments,
        },
      ),
    );
  }

  /// Auth route'larını handle eder
  Route<dynamic>? _handleAuthRoutes(RouteSettings settings) {
    final routeName = settings.name!;
    
    switch (routeName) {
      case AppRouteConstants.login:
        final args = RouteUtils.getArgument<Map<String, dynamic>>(settings, 'args') ?? {};
        final userType = args['userType'] ?? 'customer';
        return RouteUtils.createRoute(
          (context) => LoginPage(userType: userType),
          settings,
        );

      case AppRouteConstants.register:
        final args = RouteUtils.getArgument<Map<String, dynamic>>(settings, 'args') ?? {};
        final userType = args['userType'] ?? 'customer';
        return RouteUtils.createRoute(
          (context) => RegisterPage(userType: userType),
          settings,
        );

      case AppRouteConstants.businessLogin:
        return RouteUtils.createRoute(
          (context) => const BusinessLoginPage(),
          settings,
        );

      case AppRouteConstants.businessRegister:
        return RouteUtils.createRoute(
          (context) => const BusinessRegisterPage(),
          settings,
        );

      default:
        return null;
    }
  }

  /// Route'a programmatik olarak git
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Route'a git ve stack'i temizle
  static Future<T?> pushNamedAndClearStack<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Route'ı replace et
  static Future<T?> pushReplacementNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, Object?>(
      routeName,
      arguments: arguments,
    );
  }

  /// Geri git
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  /// Belirli route'a kadar geri git
  static void popUntil(BuildContext context, String routeName) {
    Navigator.of(context).popUntil(ModalRoute.withName(routeName));
  }

  /// Current route name'i al
  static String? getCurrentRouteName(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }

  /// Route can pop kontrolü
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }
}

/// Type-safe route navigation extension'ları
extension TypeSafeRouting on BuildContext {
  // Admin routes
  Future<void> pushAdminDashboard() => AppRouter.pushNamed(this, AppRouteConstants.adminDashboard);
  Future<void> pushAdminLogin() => AppRouter.pushNamed(this, AppRouteConstants.adminLogin);
  
  // Business routes
  Future<void> pushBusinessDashboard() => AppRouter.pushNamed(this, AppRouteConstants.businessDashboard);
  Future<void> pushBusinessLogin() => AppRouter.pushNamed(this, AppRouteConstants.businessLogin);
  
  // Customer routes
  Future<void> pushCustomerDashboard([String? userId]) => AppRouter.pushNamed(
    this, 
    AppRouteConstants.customerDashboard,
    arguments: {'userId': userId ?? 'guest'},
  );
  
  // QR routes
  Future<void> pushQRScanner([String? userId]) => AppRouter.pushNamed(
    this,
    AppRouteConstants.qrScanner,
    arguments: {'userId': userId},
  );
  
  Future<void> pushQRMenu(String businessId, {int? tableNumber}) => AppRouter.pushNamed(
    this,
    '${AppRouteConstants.qrMenu}/$businessId',
    arguments: {'tableNumber': tableNumber},
  );

  // Auth routes
  Future<void> pushLogin([String userType = 'customer']) => AppRouter.pushNamed(
    this,
    AppRouteConstants.login,
    arguments: {'userType': userType},
  );
  
  Future<void> pushRegister([String userType = 'customer']) => AppRouter.pushNamed(
    this,
    AppRouteConstants.register,
    arguments: {'userType': userType},
  );
}

/// Route debugging utilities
class RouteDebugger {
  static bool _debugEnabled = true;
  
  static void enable() => _debugEnabled = true;
  static void disable() => _debugEnabled = false;
  
  static void logRoute(String message) {
    if (_debugEnabled) {
      print('🔗 [RouteDebugger] $message');
    }
  }
  
  static void logHandlers(List<BaseRouteHandler> handlers) {
    if (!_debugEnabled) return;
    
    print('🔗 [RouteDebugger] Active handlers:');
    for (int i = 0; i < handlers.length; i++) {
      final handler = handlers[i];
      print('   ${i + 1}. ${handler.moduleName} (${handler.routePrefix})');
      print('      Supported routes: ${handler.supportedRoutes.length}');
    }
  }
} 