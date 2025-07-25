import 'package:flutter/material.dart';
import 'base_route_handler.dart';
import 'route_constants.dart';
import '../../shared/pages/universal_qr_menu_page.dart';
import '../../customer/pages/qr_menu_page.dart';
import '../../customer/pages/menu_page.dart';
import '../../customer/pages/product_detail_page.dart';
import '../../customer/pages/qr_scanner_page.dart';
import '../../presentation/pages/auth/router_page.dart';

/// QR Route Handler - QR menü ve evrensel QR route'larını yönetir
class QRRouteHandler implements BaseRouteHandler {
  static final QRRouteHandler _instance = QRRouteHandler._internal();
  factory QRRouteHandler() => _instance;
  QRRouteHandler._internal();

  @override
  String get moduleName => 'QR';

  @override
  String get routePrefix => '/qr';

  @override
  List<String> get supportedRoutes => [
    AppRouteConstants.universalQR,
    AppRouteConstants.qrMenu,
    AppRouteConstants.menu,
    AppRouteConstants.qrScanner,
    AppRouteConstants.productDetail,
  ];

  @override
  Map<String, WidgetBuilder> get staticRoutes => {
    AppRouteConstants.universalQR: (context) => const UniversalQRMenuPage(),
    AppRouteConstants.qrScanner: (context) => const QRScannerRouterPage(),
  };

  @override
  bool canHandle(String routeName) {
    return AppRouteConstants.isQRRoute(routeName) ||
           routeName.startsWith('/menu/') ||
           routeName.startsWith('/qr-menu/') ||
           routeName == AppRouteConstants.qrScanner ||
           routeName == AppRouteConstants.productDetail;
  }

  @override
  Route<dynamic>? handleRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null || !canHandle(routeName)) {
      return null;
    }

    RouteUtils.debugRoute(routeName, settings);

    // Statik route'ları kontrol et
    final staticBuilder = staticRoutes[routeName];
    if (staticBuilder != null) {
      return RouteUtils.createRoute(staticBuilder, settings);
    }

    // QR menü route'larını özel handle et
    if (_isQRMenuRoute(routeName)) {
      return _handleQRMenuRoute(settings);
    }

    // Diğer dinamik route'ları handle et
    return _handleDynamicRoute(settings);
  }

  /// QR menü route'u mu kontrol eder
  bool _isQRMenuRoute(String routeName) {
    try {
      print('🔍 QR Route Detection: Checking route: $routeName');
      
      final uri = Uri.parse(routeName);
      
      // 1. Direct QR routes
      if (routeName == AppRouteConstants.universalQR || routeName == '/qr') {
        print('✅ Direct QR route detected');
        return true;
      }
      
      // 2. QR with query parameters: /qr?business=...
      if (routeName.startsWith('/qr?')) {
        print('✅ QR query route detected');
        return true;
      }
      
      // 3. QR menu paths: /qr-menu/{businessId}
      if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'qr-menu') {
        print('✅ QR menu path detected');
        return true;
      }
      
      // 4. Legacy menu paths: /menu/{businessId} with query params
      if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'menu' && 
          uri.queryParameters.isNotEmpty) {
        print('✅ Legacy menu route detected');
        return true;
      }
      
      // 5. Query parametrelerinde business var mı?
      if (uri.queryParameters.containsKey('business') || 
          uri.queryParameters.containsKey('businessId')) {
        print('✅ Business parameter route detected');
        return true;
      }
      
      // 6. Complex QR URL formats (external camera scanning)
      if (_isExternalQRUrl(routeName)) {
        print('✅ External QR URL detected');
        return true;
      }
      
      print('❌ Not a QR route');
      return false;
      
    } catch (e) {
      print('❌ QR route detection error: $e');
      // If parsing fails, assume it's not a QR route
      return false;
    }
  }

  /// External QR URL detection (from camera scanning)
  bool _isExternalQRUrl(String routeName) {
    try {
      // Check if URL contains typical QR patterns
      if (routeName.contains('business=') || 
          routeName.contains('businessId=') ||
          routeName.contains('table=') ||
          routeName.contains('tableNumber=')) {
        return true;
      }
      
      // Check if URL has QR-like structure
      if (routeName.contains('/menu/') && routeName.contains('?')) {
        return true;
      }
      
      // Check for base64 or encoded QR data
      if (routeName.contains('%') && routeName.length > 20) {
        try {
          final decoded = Uri.decodeFull(routeName);
          return decoded.contains('business') || decoded.contains('menu');
        } catch (e) {
          return false;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// QR menü route'unu handle eder
  Route<dynamic> _handleQRMenuRoute(RouteSettings settings) {
    final routeName = settings.name!;
    print('🔗 QR Menu Route Handler - Processing: $routeName');
    
    try {
      // Enhanced URL parsing with fallback mechanisms
      final parsedData = _parseQRUrl(routeName);
      final businessId = parsedData['businessId'];
      final tableNumber = parsedData['tableNumber'];
      
      print('✅ QR Parameters extracted - Business: $businessId, Table: $tableNumber');
      
      // Create enhanced arguments
      final enhancedArguments = <String, dynamic>{
        'businessId': businessId,
        'tableNumber': tableNumber,
        'isQRRoute': true,
        'originalUrl': routeName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'source': 'qr_route_handler',
        // Merge existing arguments if any
        ...?settings.arguments as Map<String, dynamic>?,
      };
      
      // Always route to UniversalQRMenuPage for consistency
      // It can handle both specific business and general QR cases
      return RouteUtils.createRoute(
        (context) => const UniversalQRMenuPage(),
        RouteSettings(
          name: routeName,
          arguments: enhancedArguments,
        ),
      );
      
    } catch (e) {
      print('❌ QR Menu Route Error: $e');
      
      // Fallback: Always route to UniversalQRMenuPage with error info
      return RouteUtils.createRoute(
        (context) => const UniversalQRMenuPage(),
        RouteSettings(
          name: routeName,
          arguments: {
            'routeError': e.toString(),
            'originalUrl': routeName,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'source': 'qr_route_handler_error',
            ...?settings.arguments as Map<String, dynamic>?,
          },
        ),
      );
    }
  }

  /// Enhanced QR URL parsing with multiple fallback mechanisms
  Map<String, dynamic> _parseQRUrl(String routeName) {
    String? businessId;
    int? tableNumber;
    
    try {
      print('🔍 Parsing QR URL: $routeName');
      
      // Decode URL if needed
      String decodedUrl = routeName;
      if (routeName.contains('%')) {
        try {
          decodedUrl = Uri.decodeFull(routeName);
          print('🔄 Decoded URL: $decodedUrl');
        } catch (e) {
          print('⚠️ URL decode failed, using original: $e');
        }
      }
      
      final uri = Uri.parse(decodedUrl);
      
      // Method 1: Query parameters (most reliable)
      businessId = uri.queryParameters['business'] ?? 
                  uri.queryParameters['businessId'] ?? 
                  uri.queryParameters['business_id'];
                  
      final tableString = uri.queryParameters['table'] ?? 
                         uri.queryParameters['tableNumber'] ?? 
                         uri.queryParameters['table_number'];
      if (tableString != null) {
        tableNumber = int.tryParse(tableString);
      }
      
      print('📋 Method 1 - Query params: business=$businessId, table=$tableNumber');
      
      // Method 2: Path segments
      if (businessId == null && uri.pathSegments.isNotEmpty) {
        // /qr-menu/{businessId} format
        if (uri.pathSegments.contains('qr-menu')) {
          final index = uri.pathSegments.indexOf('qr-menu');
          if (index + 1 < uri.pathSegments.length) {
            businessId = uri.pathSegments[index + 1];
            print('📋 Method 2a - QR menu path: $businessId');
          }
        }
        
        // /menu/{businessId} format
        if (businessId == null && uri.pathSegments.contains('menu')) {
          final index = uri.pathSegments.indexOf('menu');
          if (index + 1 < uri.pathSegments.length) {
            businessId = uri.pathSegments[index + 1];
            print('📋 Method 2b - Menu path: $businessId');
          }
        }
        
        // Direct path format /{businessId}
        if (businessId == null && uri.pathSegments.length == 1) {
          final potentialBusinessId = uri.pathSegments[0];
          // Validate it looks like a business ID (not a common route)
          if (!_isCommonRoute(potentialBusinessId)) {
            businessId = potentialBusinessId;
            print('📋 Method 2c - Direct path: $businessId');
          }
        }
      }
      
      // Method 3: Fragment/hash parsing (fallback)
      if (businessId == null && uri.fragment.isNotEmpty) {
        try {
          final fragmentUri = Uri.parse(uri.fragment);
          businessId = fragmentUri.queryParameters['business'] ?? 
                      fragmentUri.queryParameters['businessId'];
          print('📋 Method 3 - Fragment: $businessId');
        } catch (e) {
          print('⚠️ Fragment parsing failed: $e');
        }
      }
      
      // Method 4: String pattern matching (last resort)
      if (businessId == null) {
        businessId = _extractBusinessIdFromString(decodedUrl);
        if (businessId != null) {
          print('📋 Method 4 - Pattern matching: $businessId');
        }
      }
      
    } catch (e) {
      print('❌ QR URL parsing error: $e');
    }
    
    final result = {
      'businessId': businessId,
      'tableNumber': tableNumber,
    };
    
    print('🎯 Final parsing result: $result');
    return result;
  }

  /// Check if a path segment is a common route (not a business ID)
  bool _isCommonRoute(String path) {
    const commonRoutes = [
      'login', 'register', 'admin', 'business', 'customer', 
      'qr', 'menu', 'search', 'cart', 'profile', 'settings',
      'about', 'contact', 'help', 'terms', 'privacy'
    ];
    return commonRoutes.contains(path.toLowerCase());
  }

  /// Extract business ID using string pattern matching
  String? _extractBusinessIdFromString(String url) {
    try {
      // Pattern 1: business=VALUE
      RegExp businessPattern = RegExp(r'business[=:]([^&?#]+)', caseSensitive: false);
      var match = businessPattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
      
      // Pattern 2: businessId=VALUE
      RegExp businessIdPattern = RegExp(r'businessId[=:]([^&?#]+)', caseSensitive: false);
      match = businessIdPattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
      
      // Pattern 3: /menu/BUSINESS_ID or /qr-menu/BUSINESS_ID
      RegExp menuPattern = RegExp(r'/(?:qr-)?menu/([^/?#]+)', caseSensitive: false);
      match = menuPattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
      
      return null;
    } catch (e) {
      print('❌ Pattern matching error: $e');
      return null;
    }
  }

  /// Diğer dinamik route'ları handle eder
  Route<dynamic>? _handleDynamicRoute(RouteSettings settings) {
    final routeName = settings.name!;
    final pathSegments = RouteUtils.getPathSegments(routeName);
    
    // /menu/{businessId} format için
    if (pathSegments.length >= 2 && pathSegments[0] == 'menu') {
      final businessId = pathSegments[1];
      return RouteUtils.createRoute(
        (context) => MenuPage(businessId: businessId),
        settings,
      );
    }

    // /product-detail handling
    if (routeName == AppRouteConstants.productDetail) {
      return RouteUtils.createRoute(
        (context) => const ProductDetailRouterPage(),
        settings,
      );
    }

    return null;
  }
}

/// Product Detail Router Page
class ProductDetailRouterPage extends StatelessWidget {
  const ProductDetailRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final product = args?['product'];
    final business = args?['business'];

    // Gerekli parametreler yoksa router'a yönlendir
    if (product == null || business == null) {
      return const RouterPage();
    }

    return ProductDetailPage(product: product, business: business);
  }
}

/// QR Scanner Router Page
class QRScannerRouterPage extends StatelessWidget {
  const QRScannerRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    return QRScannerPage(userId: userId);
  }
}

/// QR Menu Router Page
class QRMenuRouterPage extends StatelessWidget {
  const QRMenuRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;
    final userId = args?['userId'] as String?;
    final qrCode = args?['qrCode'] as String?;
    final tableNumber = args?['tableNumber'] as int?;

    if (businessId == null) {
      return const RouterPage();
    }

    return QRMenuPage(
      businessId: businessId,
      userId: userId,
      qrCode: qrCode,
      tableNumber: tableNumber,
    );
  }
} 