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
    final uri = Uri.parse(routeName);
    
    // 1. /qr ile başlayan route'lar (evrensel QR)
    if (routeName == AppRouteConstants.universalQR || routeName.startsWith('/qr?')) {
      return true;
    }
    
    // 2. /qr-menu/{businessId} formatı
    if (routeName.startsWith('/qr-menu/')) {
      return true;
    }
    
    // 3. Query parametrelerinde business var mı?
    if (uri.queryParameters.containsKey('business') || 
        uri.queryParameters.containsKey('businessId')) {
      return true;
    }
    
    // 4. Eski format desteği: /menu/ içeren URL'ler
    if (routeName.contains('/menu/') && uri.queryParameters.isNotEmpty) {
      return true;
    }
    
    return false;
  }

  /// QR menü route'unu handle eder
  Route<dynamic> _handleQRMenuRoute(RouteSettings settings) {
    final routeName = settings.name!;
    print('🔗 QR Menu Route Handler - Processing: $routeName');
    
    try {
      final uri = Uri.parse(routeName);
      String? businessId;
      int? tableNumber;
      
      // Business ID ve table number çıkar
      businessId = uri.queryParameters['business'] ?? 
                  uri.queryParameters['businessId'];
      final tableString = uri.queryParameters['table'] ?? 
                         uri.queryParameters['tableNumber'];
      if (tableString != null) {
        tableNumber = int.tryParse(tableString);
      }
      
      // Path'den çıkar (/qr-menu/{businessId} formatı)
      if (businessId == null && uri.pathSegments.isNotEmpty) {
        if (uri.pathSegments.contains('qr-menu') && uri.pathSegments.length > 1) {
          final index = uri.pathSegments.indexOf('qr-menu');
          if (index + 1 < uri.pathSegments.length) {
            businessId = uri.pathSegments[index + 1];
          }
        } else if (uri.pathSegments.contains('menu') && uri.pathSegments.length > 1) {
          final index = uri.pathSegments.indexOf('menu');
          if (index + 1 < uri.pathSegments.length) {
            businessId = uri.pathSegments[index + 1];
          }
        }
      }
      
      print('✅ QR Parameters extracted - Business: $businessId, Table: $tableNumber');
      
      // Eğer belirli bir business ID varsa QRMenuPage'e yönlendir
      if (businessId != null && businessId.isNotEmpty) {
        return RouteUtils.createRoute(
          (context) => QRMenuPage(
            businessId: businessId!,
            qrCode: routeName,
            tableNumber: tableNumber,
          ),
          RouteSettings(
            name: routeName,
            arguments: {
              'businessId': businessId,
              'tableNumber': tableNumber,
              'isQRRoute': true,
              'originalUrl': routeName,
              ...?settings.arguments as Map<String, dynamic>?,
            },
          ),
        );
      }
      
      // Genel QR sayfasına yönlendir
      return RouteUtils.createRoute(
        (context) => const UniversalQRMenuPage(),
        RouteSettings(
          name: routeName,
          arguments: {
            'businessId': businessId,
            'tableNumber': tableNumber,
            'isQRRoute': true,
            'originalUrl': routeName,
            ...?settings.arguments as Map<String, dynamic>?,
          },
        ),
      );
      
    } catch (e) {
      print('❌ QR Menu Route Error: $e');
      
      // Hata durumunda da UniversalQRMenuPage'e git
      return RouteUtils.createRoute(
        (context) => const UniversalQRMenuPage(),
        RouteSettings(
          name: routeName,
          arguments: {
            'routeError': e.toString(),
            'originalUrl': routeName,
            ...?settings.arguments as Map<String, dynamic>?,
          },
        ),
      );
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