import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'url_service.dart';

/// Creates a platform-specific URL service implementation
UrlServiceBase createUrlService() {
  return UrlServiceWeb();
}

/// Web implementation with full browser URL management
class UrlServiceWeb extends UrlServiceBase {
  @override
  void updateUrl(String route, {String? customTitle, Map<String, String>? params}) {
    try {
      // Construct the final URL with parameters
      String finalUrl = route;
      if (params != null && params.isNotEmpty) {
        final queryParams = params.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        finalUrl += '?$queryParams';
      }

      // Update browser URL without page reload
      html.window.history.pushState(null, customTitle ?? _getPageTitle(route), finalUrl);
      
      // Update page title
      html.document.title = customTitle ?? _getPageTitle(route);
      
      print('URL updated to: $finalUrl with title: ${html.document.title}');
    } catch (e) {
      print('Error updating URL: $e');
    }
  }

  @override
  void replaceUrl(String route, {String? customTitle, Map<String, String>? params}) {
    try {
      // Construct the final URL with parameters
      String finalUrl = route;
      if (params != null && params.isNotEmpty) {
        final queryParams = params.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        finalUrl += '?$queryParams';
      }

      // Replace current URL without page reload
      html.window.history.replaceState(null, customTitle ?? _getPageTitle(route), finalUrl);
      
      // Update page title
      html.document.title = customTitle ?? _getPageTitle(route);
      
      print('URL replaced to: $finalUrl with title: ${html.document.title}');
    } catch (e) {
      print('Error replacing URL: $e');
    }
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
    return html.window.location.pathname ?? '/';
  }

  /// Gets the current base URL (protocol + host)
  @override
  String getCurrentBaseUrl() {
    try {
      final protocol = html.window.location.protocol;
      final host = html.window.location.host;
      final baseUrl = '$protocol//$host';
      print('🌐 Web Base URL: $baseUrl');
      return baseUrl;
    } catch (e) {
      print('❌ Web Base URL error: $e');
      // Fallback
      return 'https://menumebak.web.app';
    }
  }

  @override
  Map<String, String> getCurrentParams() {
    final uri = Uri.parse(html.window.location.href);
    return uri.queryParameters;
  }

  @override
  Map<String, String?> parseBusinessUrl() {
    final path = getCurrentPath();
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    
    if (segments.length >= 2 && segments[0] == 'business') {
      return {
        'businessId': segments[1],
        'tab': segments.length >= 3 ? segments[2] : 'genel-bakis',
      };
    }
    
    return {'businessId': null, 'tab': null};
  }

  @override
  Map<String, String?> parseMenuUrl() {
    final path = getCurrentPath();
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final params = getCurrentParams();
    
    if (segments.length >= 2 && segments[0] == 'menu') {
      return {
        'businessId': segments[1],
        'tableNumber': params['table'],
      };
    }
    
    return {'businessId': null, 'tableNumber': null};
  }

  @override
  void setupUrlListener(Function(String) onUrlChange) {
    html.window.addEventListener('popstate', (event) {
      final newPath = getCurrentPath();
      onUrlChange(newPath);
    });
  }

  @override
  void navigateWithUrl(BuildContext context, String route, {
    Object? arguments,
    String? customTitle,
    Map<String, String>? params,
    bool replace = false,
  }) {
    // Update URL first
    if (replace) {
      replaceUrl(route, customTitle: customTitle, params: params);
    } else {
      updateUrl(route, customTitle: customTitle, params: params);
    }
    
    // Then navigate
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