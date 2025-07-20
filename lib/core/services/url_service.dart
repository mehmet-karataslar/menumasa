import 'dart:html' as html;
import 'package:flutter/material.dart';

class UrlService {
  static final UrlService _instance = UrlService._internal();
  factory UrlService() => _instance;
  UrlService._internal();

  // Route definitions for different modules
  static const Map<String, String> routeTitles = {
    // Root routes
    '/': 'Ana Sayfa | MasaMenu',
    '/login': 'Giriş | MasaMenu',
    '/register': 'Kayıt Ol | MasaMenu',
    '/business-register': 'İşletme Kaydı | MasaMenu',
    
    // Business routes
    '/business/login': 'İşletme Girişi | MasaMenu',
    '/business/dashboard': 'İşletme Paneli | MasaMenu',
    
    // Admin routes
    '/admin/login': 'Admin Girişi | MasaMenu',
    '/admin/dashboard': 'Admin Paneli | MasaMenu',
    '/admin/businesses': 'İşletme Yönetimi | MasaMenu',
    '/admin/customers': 'Müşteri Yönetimi | MasaMenu',
    '/admin/admins': 'Admin Yönetimi | MasaMenu',
    '/admin/analytics': 'Analitikler | MasaMenu',
    '/admin/settings': 'Sistem Ayarları | MasaMenu',
    '/admin/logs': 'Aktivite Logları | MasaMenu',
    
    // Customer routes
    '/customer/home': 'Müşteri Ana Sayfa | MasaMenu',
    '/customer/dashboard': 'Müşteri Paneli | MasaMenu',
    '/customer/orders': 'Siparişlerim | MasaMenu',
    '/search': 'İşletme Ara | MasaMenu',
  };

  // Business tab route mappings
  static const Map<String, String> businessTabTitles = {
    'genel-bakis': 'Genel Bakış',
    'siparisler': 'Siparişler',
    'kategoriler': 'Kategoriler',
    'urunler': 'Ürünler',
    'indirimler': 'İndirimler',
    'qr-kodlar': 'QR Kodlar',
    'ayarlar': 'Ayarlar',
  };

  /// Updates the browser URL and page title
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

  /// Replaces the current URL without adding to history
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

  /// Updates URL for business pages with tab support
  void updateBusinessUrl(String businessId, String tab, {String? businessName}) {
    final route = '/business/$businessId/$tab';
    final tabTitle = businessTabTitles[tab] ?? tab;
    final title = businessName != null 
        ? '$businessName - $tabTitle | MasaMenu'
        : '$tabTitle | MasaMenu';
    
    updateUrl(route, customTitle: title);
  }

  /// Updates URL for menu pages
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

  /// Updates URL for customer pages
  void updateCustomerUrl(String userId, String page, {String? customTitle}) {
    final route = '/customer/$page';
    final title = customTitle ?? _getPageTitle(route);
    
    updateUrl(route, customTitle: title, params: {'userId': userId});
  }

  /// Updates URL for admin pages
  void updateAdminUrl(String page, {String? customTitle}) {
    final route = '/admin/$page';
    final title = customTitle ?? _getPageTitle(route);
    
    updateUrl(route, customTitle: title);
  }

  /// Gets the current URL path
  String getCurrentPath() {
    return html.window.location.pathname ?? '/';
  }

  /// Gets the current URL parameters
  Map<String, String> getCurrentParams() {
    final uri = Uri.parse(html.window.location.href);
    return uri.queryParameters;
  }

  /// Parses business URL to extract businessId and tab
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

  /// Parses menu URL to extract businessId and table number
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

  /// Sets up URL listener for back/forward button support
  void setupUrlListener(Function(String) onUrlChange) {
    html.window.addEventListener('popstate', (event) {
      final newPath = getCurrentPath();
      onUrlChange(newPath);
    });
  }

  /// Private method to get page title from route
  String _getPageTitle(String route) {
    // Check exact match first
    if (routeTitles.containsKey(route)) {
      return routeTitles[route]!;
    }
    
    // Handle dynamic routes
    final segments = route.split('/').where((s) => s.isNotEmpty).toList();
    
    if (segments.isEmpty) {
      return routeTitles['/']!;
    }
    
    // Business routes
    if (segments.length >= 2 && segments[0] == 'business') {
      if (segments.length >= 3) {
        final tab = segments[2];
        final tabTitle = businessTabTitles[tab] ?? tab;
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
      return routeTitles[adminRoute] ?? 'Admin Paneli | MasaMenu';
    }
    
    // Customer routes
    if (segments.length >= 2 && segments[0] == 'customer') {
      final customerRoute = '/customer/${segments[1]}';
      return routeTitles[customerRoute] ?? 'Müşteri Paneli | MasaMenu';
    }
    
    // Default fallback
    return 'MasaMenu - Dijital Menü Çözümü';
  }

  /// Helper method for navigation with URL update
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
} 