import 'package:flutter/material.dart';
import 'url_service.dart';

/// Creates a platform-specific URL service implementation
UrlServiceBase createUrlService() {
  return UrlServiceStub();
}

/// Stub implementation for non-web platforms
class UrlServiceStub extends UrlServiceBase {
  @override
  void updateUrl(String route, {String? customTitle, Map<String, String>? params}) {
    // No-op on non-web platforms
    if (customTitle != null) {
      print('Would set title to: $customTitle');
    }
    print('Would update URL to: $route');
  }

  @override
  void replaceUrl(String route, {String? customTitle, Map<String, String>? params}) {
    // No-op on non-web platforms
    if (customTitle != null) {
      print('Would set title to: $customTitle');
    }
    print('Would replace URL with: $route');
  }

  @override
  void updateBusinessUrl(String businessId, String tab, {String? businessName}) {
    final route = '/business/$tab'; // Business ID'yi URL'den kaldırdık
    final tabTitle = UrlService.businessTabTitles[tab] ?? tab;
    final title = businessName != null 
        ? '$businessName - $tabTitle | MasaMenu'
        : '$tabTitle | MasaMenu';
    
    updateUrl(route, customTitle: title);
  }

  @override
  void updateMenuUrl(String businessId, {int? tableNumber, String? businessName}) {
    String route = '/menu/$businessId';
    Map<String, String>? params;
    
    if (tableNumber != null) {
      params = {'table': tableNumber.toString()};
    }
    
    final title = businessName != null 
        ? '$businessName - Menü | MasaMenu'
        : 'Menü | MasaMenu';
    
    updateUrl(route, customTitle: title, params: params);
  }

  @override
  void updateCustomerUrl(String userId, String page, {String? customTitle}) {
    final route = '/customer/$page';
    final title = customTitle ?? _getPageTitle(route);
    
    updateUrl(route, customTitle: title, params: {'userId': userId});
  }

  @override
  void updateAdminUrl(String page, {String? customTitle}) {
    final route = '/admin/$page';
    final title = customTitle ?? _getPageTitle(route);
    
    updateUrl(route, customTitle: title);
  }

  @override
  String getCurrentPath() {
    // Return default path for non-web platforms
    return '/';
  }

  @override
  String getCurrentBaseUrl() {
    return 'https://your-app.com'; // Stub implementation
  }

  @override
  Map<String, String> getCurrentParams() {
    // Return empty params for non-web platforms
    return {};
  }

  @override
  Map<String, String?> parseBusinessUrl() {
    // Return default values for non-web platforms
    return {'businessId': null, 'tab': 'genel-bakis'};
  }

  @override
  Map<String, String?> parseMenuUrl() {
    // Return default values for non-web platforms
    return {'businessId': null, 'tableNumber': null};
  }

  @override
  void setupUrlListener(Function(String) onUrlChange) {
    // No-op on non-web platforms
    print('URL listener setup not supported on this platform');
  }

  @override
  void navigateWithUrl(BuildContext context, String route, {
    Object? arguments,
    String? customTitle,
    Map<String, String>? params,
    bool replace = false,
  }) {
    // Update URL first (no-op on non-web)
    if (replace) {
      replaceUrl(route, customTitle: customTitle, params: params);
    } else {
      updateUrl(route, customTitle: customTitle, params: params);
    }
    
    // Then navigate normally
    if (replace) {
      Navigator.pushReplacementNamed(context, route, arguments: arguments);
    } else {
      Navigator.pushNamed(context, route, arguments: arguments);
    }
  }

  /// Private method to get page title from route
  String _getPageTitle(String route) {
    // Check exact match first
    if (UrlService.routeTitles.containsKey(route)) {
      return UrlService.routeTitles[route]!;
    }
    
    // Handle dynamic routes
    final segments = route.split('/').where((s) => s.isNotEmpty).toList();
    
    if (segments.isEmpty) {
      return UrlService.routeTitles['/']!;
    }
    
    // Business routes
    if (segments.length >= 2 && segments[0] == 'business') {
      if (segments.length >= 3) {
        final tab = segments[2];
        final tabTitle = UrlService.businessTabTitles[tab] ?? tab;
        return '$tabTitle | MasaMenu';
      }
      return 'İşletme Paneli | MasaMenu';
    }
    
    // Menu routes
    if (segments.length >= 2 && segments[0] == 'menu') {
      return 'Menü | MasaMenu';
    }
    
    // Admin routes
    if (segments.length >= 2 && segments[0] == 'admin') {
      final adminRoute = '/admin/${segments[1]}';
      return UrlService.routeTitles[adminRoute] ?? 'Admin Paneli | MasaMenu';
    }
    
    // Customer routes
    if (segments.length >= 2 && segments[0] == 'customer') {
      final customerRoute = '/customer/${segments[1]}';
      return UrlService.routeTitles[customerRoute] ?? 'Müşteri Paneli | MasaMenu';
    }
    
    // Default fallback
    return 'MasaMenu - Dijital Menü Çözümü';
  }
} 