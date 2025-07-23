import 'package:flutter/material.dart';

/// Base Route Handler Interface
/// Her modül kendi route handler'ını bu interface'i implement ederek oluşturur
abstract class BaseRouteHandler {
  /// Modül adı
  String get moduleName;
  
  /// Bu handler'ın işleyebileceği route prefix'i
  String get routePrefix;
  
  /// Bu handler'ın işleyebileceği route'lar
  List<String> get supportedRoutes;
  
  /// Route'u handle edebilir mi kontrol eder
  bool canHandle(String routeName);
  
  /// Route'u handle eder ve MaterialPageRoute döner
  Route<dynamic>? handleRoute(RouteSettings settings);
  
  /// Statik route'ları döner (MaterialApp.routes için)
  Map<String, WidgetBuilder> get staticRoutes;
}

/// Route Result - Route handling sonuçları için
class RouteResult {
  final Route<dynamic>? route;
  final bool handled;
  final String? errorMessage;
  
  const RouteResult({
    this.route,
    required this.handled,
    this.errorMessage,
  });
  
  factory RouteResult.success(Route<dynamic> route) {
    return RouteResult(
      route: route,
      handled: true,
    );
  }
  
  factory RouteResult.notHandled() {
    return const RouteResult(handled: false);
  }
  
  factory RouteResult.error(String message) {
    return RouteResult(
      handled: false,
      errorMessage: message,
    );
  }
}

/// Route Utils - Ortak route yardımcı fonksiyonları
class RouteUtils {
  RouteUtils._();
  
  /// URL'den path segment'lerini çıkarır
  static List<String> getPathSegments(String routeName) {
    final uri = Uri.parse(routeName);
    return uri.pathSegments;
  }
  
  /// URL'den query parametrelerini çıkarır
  static Map<String, String> getQueryParameters(String routeName) {
    final uri = Uri.parse(routeName);
    return uri.queryParameters;
  }
  
  /// Route arguments'ları safely çıkarır
  static T? getArgument<T>(RouteSettings settings, String key) {
    final args = settings.arguments as Map<String, dynamic>?;
    return args?[key] as T?;
  }
  
  /// Route arguments'ları safely çıkarır (required)
  static T getRequiredArgument<T>(RouteSettings settings, String key) {
    final value = getArgument<T>(settings, key);
    if (value == null) {
      throw ArgumentError('Required argument "$key" not found in route settings');
    }
    return value;
  }
  
  /// Debug route bilgilerini print eder
  static void debugRoute(String routeName, RouteSettings settings) {
    print('🔗 Route Debug: $routeName');
    print('   📂 Path segments: ${getPathSegments(routeName)}');
    print('   🔍 Query params: ${getQueryParameters(routeName)}');
    print('   📋 Arguments: ${settings.arguments}');
  }
  
  /// Safe MaterialPageRoute oluşturur
  static MaterialPageRoute<T> createRoute<T extends Object?>(
    Widget Function(BuildContext) builder,
    RouteSettings settings, {
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute<T>(
      builder: builder,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }
}

/// Route Guard Interface - Route koruma için
abstract class RouteGuard {
  /// Route'a erişim kontrolü yapar
  Future<bool> canAccess(RouteSettings settings);
  
  /// Erişim reddedildiğinde yönlendirme route'u
  String get redirectRoute;
  
  /// Guard adı (debug için)
  String get guardName;
}

/// Auth Guard - Authentication kontrolü
class AuthGuard implements RouteGuard {
  @override
  String get guardName => 'AuthGuard';
  
  @override
  String get redirectRoute => '/login';
  
  @override
  Future<bool> canAccess(RouteSettings settings) async {
    // TODO: AuthService ile authentication kontrolü yap
    return true; // Şimdilik herkesi geçir
  }
}

/// Business Guard - Business user kontrolü
class BusinessGuard implements RouteGuard {
  @override
  String get guardName => 'BusinessGuard';
  
  @override
  String get redirectRoute => '/business/login';
  
  @override
  Future<bool> canAccess(RouteSettings settings) async {
    // TODO: Business user kontrolü yap
    return true; // Şimdilik herkesi geçir
  }
}

/// Admin Guard - Admin user kontrolü
class AdminGuard implements RouteGuard {
  @override
  String get guardName => 'AdminGuard';
  
  @override
  String get redirectRoute => '/admin/login';
  
  @override
  Future<bool> canAccess(RouteSettings settings) async {
    // TODO: Admin user kontrolü yap
    return true; // Şimdilik herkesi geçir
  }
} 