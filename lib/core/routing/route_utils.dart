import 'package:flutter/material.dart';

/// Route yardımcı metodları ve utilities
class RouteUtils {
  RouteUtils._();

  /// Route oluşturma helper'ı
  static Route<dynamic> createRoute(WidgetBuilder builder, RouteSettings settings) {
    return MaterialPageRoute(
      builder: builder,
      settings: settings,
    );
  }

  /// Path segment'lerini döner
  static List<String> getPathSegments(String routeName) {
    return routeName.split('/').where((segment) => segment.isNotEmpty).toList();
  }

  /// Route argument'ini type-safe bir şekilde alır
  static T? getArgument<T>(RouteSettings settings, String key) {
    final args = settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey(key)) {
      return args[key] as T?;
    }
    return null;
  }

  /// Route debug bilgisi yazdırır
  static void debugRoute(String routeName, RouteSettings settings) {
    print('🔗 [RouteUtils] Route: $routeName');
    if (settings.arguments != null) {
      print('   Arguments: ${settings.arguments}');
    }
  }

  /// Modern Customer Dashboard'a git
  static void navigateToModernCustomerDashboard(
    BuildContext context,
    String userId, {
    String tabId = 'home',
    bool replace = false,
  }) {
    final route = '/customer/$userId/$tabId';
    
    if (replace) {
      Navigator.pushReplacementNamed(
        context,
        route,
        arguments: {
          'userId': userId,
          'tabId': tabId,
        },
      );
    } else {
      Navigator.pushNamed(
        context,
        route,
        arguments: {
          'userId': userId,
          'tabId': tabId,
        },
      );
    }
  }

  /// Modern Business Dashboard'a git
  static void navigateToModernBusinessDashboard(
    BuildContext context,
    String businessId, {
    String tabId = 'dashboard',
    bool replace = false,
  }) {
    final route = '/business/$businessId/$tabId';
    
    if (replace) {
      Navigator.pushReplacementNamed(
        context,
        route,
        arguments: {
          'businessId': businessId,
          'tabId': tabId,
        },
      );
    } else {
      Navigator.pushNamed(
        context,
        route,
        arguments: {
          'businessId': businessId,
          'tabId': tabId,
        },
      );
    }
  }

  /// Customer dashboard sekmesine git
  static void navigateToCustomerTab(
    BuildContext context,
    String userId,
    String tabId,
  ) {
    navigateToModernCustomerDashboard(context, userId, tabId: tabId);
  }

  /// Business dashboard sekmesine git
  static void navigateToBusinessTab(
    BuildContext context,
    String businessId,
    String tabId,
  ) {
    navigateToModernBusinessDashboard(context, businessId, tabId: tabId);
  }

  /// URL'den parametreleri çıkar
  static Map<String, String> extractParameters(String url) {
    final uri = Uri.parse(url);
    final params = <String, String>{};
    
    // Query parameters
    params.addAll(uri.queryParameters);
    
    // Path segments (businessId, userId gibi)
    final pathSegments = uri.pathSegments;
    if (pathSegments.length >= 2) {
      params['entityId'] = pathSegments[1]; // businessId veya userId
    }
    if (pathSegments.length >= 3) {
      params['tabId'] = pathSegments[2]; // tab identifier
    }
    
    return params;
  }

  /// Route validation
  static bool isValidCustomerRoute(String route) {
    final segments = getPathSegments(route);
    if (segments.length < 2) return false;
    if (segments[0] != 'customer') return false;
    
    const validTabs = ['home', 'orders', 'favorites', 'services', 'profile'];
    if (segments.length >= 3) {
      return validTabs.contains(segments[2]);
    }
    
    return true;
  }

  /// Route validation
  static bool isValidBusinessRoute(String route) {
    final segments = getPathSegments(route);
    if (segments.length < 2) return false;
    if (segments[0] != 'business') return false;
    
    const validTabs = [
      'dashboard', 'orders', 'menu', 'qr', 'analytics', 
      'stock', 'staff', 'features', 'profile'
    ];
    if (segments.length >= 3) {
      return validTabs.contains(segments[2]);
    }
    
    return true;
  }
}

/// Navigation helper extension'ları
extension NavigationHelpers on BuildContext {
  /// Customer dashboard'a git
  void goToCustomerDashboard(String userId, {String tab = 'home'}) {
    RouteUtils.navigateToModernCustomerDashboard(this, userId, tabId: tab);
  }

  /// Business dashboard'a git
  void goToBusinessDashboard(String businessId, {String tab = 'dashboard'}) {
    RouteUtils.navigateToModernBusinessDashboard(this, businessId, tabId: tab);
  }

  /// Customer sekmesine git
  void goToCustomerTab(String userId, String tab) {
    RouteUtils.navigateToCustomerTab(this, userId, tab);
  }

  /// Business sekmesine git
  void goToBusinessTab(String businessId, String tab) {
    RouteUtils.navigateToBusinessTab(this, businessId, tab);
  }
} 