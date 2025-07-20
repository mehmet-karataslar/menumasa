import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Conditional imports for platform-specific functionality
import 'url_service_stub.dart'
    if (dart.library.html) 'url_service_web.dart'
    if (dart.library.io) 'url_service_io.dart';

abstract class UrlServiceBase {
  /// Updates the browser URL and page title
  void updateUrl(String route, {String? customTitle, Map<String, String>? params});

  /// Replaces the current URL without adding to history
  void replaceUrl(String route, {String? customTitle, Map<String, String>? params});

  /// Updates URL for business pages with tab support
  void updateBusinessUrl(String businessId, String tab, {String? businessName});

  /// Updates URL for menu pages
  void updateMenuUrl(String businessId, {int? tableNumber, String? businessName});

  /// Updates URL for customer pages
  void updateCustomerUrl(String userId, String page, {String? customTitle});

  /// Updates URL for admin pages
  void updateAdminUrl(String page, {String? customTitle});

  /// Gets the current URL path
  String getCurrentPath();

  /// Gets the current URL parameters
  Map<String, String> getCurrentParams();

  /// Parses business URL to extract businessId and tab
  Map<String, String?> parseBusinessUrl();

  /// Parses menu URL to extract businessId and table number
  Map<String, String?> parseMenuUrl();

  /// Sets up URL listener for back/forward button support
  void setupUrlListener(Function(String) onUrlChange);

  /// Helper method for navigation with URL update
  void navigateWithUrl(BuildContext context, String route, {
    Object? arguments,
    String? customTitle,
    Map<String, String>? params,
    bool replace = false,
  });
}

class UrlService extends UrlServiceBase {
  static final UrlService _instance = UrlService._internal();
  factory UrlService() => _instance;
  UrlService._internal();

  // Platform-specific implementation
  late final UrlServiceBase _implementation = createUrlService();

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
    '/customer/dashboard': 'Müşteri Dashboard | MasaMenu',
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

  @override
  void updateUrl(String route, {String? customTitle, Map<String, String>? params}) {
    _implementation.updateUrl(route, customTitle: customTitle, params: params);
  }

  @override
  void replaceUrl(String route, {String? customTitle, Map<String, String>? params}) {
    _implementation.replaceUrl(route, customTitle: customTitle, params: params);
  }

  @override
  void updateBusinessUrl(String businessId, String tab, {String? businessName}) {
    _implementation.updateBusinessUrl(businessId, tab, businessName: businessName);
  }

  @override
  void updateMenuUrl(String businessId, {int? tableNumber, String? businessName}) {
    _implementation.updateMenuUrl(businessId, tableNumber: tableNumber, businessName: businessName);
  }

  @override
  void updateCustomerUrl(String userId, String page, {String? customTitle}) {
    _implementation.updateCustomerUrl(userId, page, customTitle: customTitle);
  }

  @override
  void updateAdminUrl(String page, {String? customTitle}) {
    _implementation.updateAdminUrl(page, customTitle: customTitle);
  }

  @override
  String getCurrentPath() {
    return _implementation.getCurrentPath();
  }

  @override
  Map<String, String> getCurrentParams() {
    return _implementation.getCurrentParams();
  }

  @override
  Map<String, String?> parseBusinessUrl() {
    return _implementation.parseBusinessUrl();
  }

  @override
  Map<String, String?> parseMenuUrl() {
    return _implementation.parseMenuUrl();
  }

  @override
  void setupUrlListener(Function(String) onUrlChange) {
    _implementation.setupUrlListener(onUrlChange);
  }

  @override
  void navigateWithUrl(BuildContext context, String route, {
    Object? arguments,
    String? customTitle,
    Map<String, String>? params,
    bool replace = false,
  }) {
    _implementation.navigateWithUrl(
      context,
      route,
      arguments: arguments,
      customTitle: customTitle,
      params: params,
      replace: replace,
    );
  }
} 