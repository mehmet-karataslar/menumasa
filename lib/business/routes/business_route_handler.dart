import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/routing/base_route_handler.dart';
import '../../core/routing/route_constants.dart';
import '../../core/routing/route_utils.dart' as route_utils;
import '../../core/services/auth_service.dart';
import '../../presentation/pages/auth/router_page.dart';
import '../pages/business_login_page.dart';
import '../pages/business_dashboard_page.dart';


/// Business Route Handler - Business modülü route'larını yönetir
class BusinessRouteHandler implements BaseRouteHandler {
  static final BusinessRouteHandler _instance = BusinessRouteHandler._internal();
  factory BusinessRouteHandler() => _instance;
  BusinessRouteHandler._internal();

  @override
  String get moduleName => 'Business';

  @override
  String get routePrefix => AppRouteConstants.businessPrefix;

  @override
  List<String> get supportedRoutes => [
    AppRouteConstants.businessLogin,
    AppRouteConstants.businessDashboard,
    AppRouteConstants.businessHome,
    AppRouteConstants.businessOverview,
    AppRouteConstants.businessOrders,
    AppRouteConstants.businessMenu,
    AppRouteConstants.businessWaiters,
    AppRouteConstants.businessDiscounts,
    AppRouteConstants.businessQR,
    AppRouteConstants.businessTableManagement,
    AppRouteConstants.businessKitchenIntegration,
    AppRouteConstants.businessDeliveryManagement,
    AppRouteConstants.businessPaymentManagement,
    AppRouteConstants.businessStaffTracking,
    AppRouteConstants.businessCRMManagement,
    AppRouteConstants.businessHardwareIntegration,
    AppRouteConstants.businessMultiBranch,
    AppRouteConstants.businessRemoteAccess,
    AppRouteConstants.businessLegalCompliance,
    AppRouteConstants.businessCostControl,
    AppRouteConstants.businessAIPrediction,
    AppRouteConstants.businessDigitalMarketing,
    AppRouteConstants.businessDataSecurity,
    AppRouteConstants.businessAnalytics,
    AppRouteConstants.businessStockManagement,
    AppRouteConstants.businessSettings,
  ];

  @override
  Map<String, WidgetBuilder> get staticRoutes => {
    AppRouteConstants.businessLogin: (context) => const BusinessLoginPage(),
    AppRouteConstants.businessDashboard: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessHome: (context) => const BusinessHomeRouterPage(),
    AppRouteConstants.businessOverview: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessOrders: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessMenu: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessWaiters: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessDiscounts: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessQR: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessTableManagement: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessKitchenIntegration: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessDeliveryManagement: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessPaymentManagement: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessStaffTracking: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessCRMManagement: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessHardwareIntegration: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessMultiBranch: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessRemoteAccess: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessLegalCompliance: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessCostControl: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessAIPrediction: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessDigitalMarketing: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessDataSecurity: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessAnalytics: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessStockManagement: (context) => const BusinessDashboardRouterPage(),
    AppRouteConstants.businessSettings: (context) => const BusinessDashboardRouterPage(),
  };

  @override
  bool canHandle(String routeName) {
    return AppRouteConstants.isBusinessRoute(routeName);
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

    // Dinamik route'ları handle et
    return _handleDynamicRoute(settings);
  }

  /// Dinamik business route'larını handle eder
  Route<dynamic>? _handleDynamicRoute(RouteSettings settings) {
    final routeName = settings.name!;
    final pathSegments = RouteUtils.getPathSegments(routeName);
    
    // /business/{businessId}/{tabId} format için
    if (pathSegments.length >= 3) {
      final businessId = pathSegments[1];
      final tabId = pathSegments[2];
      
      // dashboard tab route'ları
      if (_isModernDashboardTab(tabId)) {
        return RouteUtils.createRoute(
          (context) => BusinessDashboard(
            businessId: businessId,
            initialTab: tabId, // tabId zaten string olarak geliyor
          ),
          RouteSettings(
            name: routeName,
            arguments: {
              'businessId': businessId,
              'tabId': tabId,
              ...?settings.arguments as Map<String, dynamic>?,
            },
          ),
        );
      }
      
      // Legacy dashboard tab route'ları
      if (_isDashboardTab(tabId)) {
        return RouteUtils.createRoute(
          (context) => const BusinessDashboardRouterPage(),
          RouteSettings(
            name: routeName,
            arguments: {
              'businessId': businessId,
              'initialTab': tabId,
              ...?settings.arguments as Map<String, dynamic>?,
            },
          ),
        );
      }
    }
    
    // /business/{businessId} format için (legacy support)
    if (pathSegments.length >= 2) {
      final segment = pathSegments[1];
      
      // Dashboard tab route'ları
      if (_isDashboardTab(segment)) {
        return RouteUtils.createRoute(
          (context) => const BusinessDashboardRouterPage(),
          RouteSettings(
            name: routeName,
            arguments: {
              'initialTab': segment,
              ...?settings.arguments as Map<String, dynamic>?,
            },
          ),
        );
      }
    }

    return null;
  }

  /// Modern dashboard tab'ı mı kontrol eder (şimdi kullanmıyoruz ama ileride gerekebilir)
  bool _isModernDashboardTab(String tabId) {
    // Modern dashboard devre dışı, her zaman false döner
    return false;
  }

  /// Tab ID'den tab index'i döner (modern dashboard için - kullanılmıyor)
  int _getTabIndex(String tabId) {
    // Modern dashboard devre dışı
    return 0;
  }

  /// Legacy dashboard tab'ı mı kontrol eder
  bool _isDashboardTab(String segment) {
    const dashboardTabs = [
      'genel-bakis',
      'siparisler',
      'menu-yonetimi',
      'garsonlar',
      'indirimler',
      'qr-kodlar',
      'masa-yonetimi',
      'mutfak-entegrasyonu',
      'teslimat-yonetimi',
      'odeme-yonetimi',
      'personel-takibi',
      'crm-yonetimi',
      'donanim-entegrasyonu',
      'sube-yonetimi',
      'uzaktan-erisim',
      'yasal-uyumluluk',
      'maliyet-kontrolu',
      'ai-tahminleme',
      'dijital-pazarlama',
      'veri-guvenligi',
      'analitikler',
      'stok-yonetimi',
      'ayarlar',
    ];
    return dashboardTabs.contains(segment);
  }
}

/// Business Dashboard Router Page - Authentication ve business ID yönetimi
class BusinessDashboardRouterPage extends StatefulWidget {
  const BusinessDashboardRouterPage({super.key});

  @override
  State<BusinessDashboardRouterPage> createState() => _BusinessDashboardRouterPageState();
}

class _BusinessDashboardRouterPageState extends State<BusinessDashboardRouterPage> {
  final AuthService _authService = AuthService();
  String? _businessId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  Future<void> _loadBusinessId() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      print('BusinessDashboard - Current user: ${user?.uid}');
      
      if (user != null) {
        // Get user data to check if it's a business user
        final userData = await _authService.getCurrentUserData();
        print('BusinessDashboard - User data: ${userData?.toJson()}');
        print('BusinessDashboard - User type: ${userData?.userType}');
        
        if (userData != null && userData.userType.value == 'business') {
          // Get business ID from business_users collection
          final businessUserDoc = await FirebaseFirestore.instance
              .collection('business_users')
              .doc(user.uid)
              .get();
          
          print('BusinessDashboard - Business user doc exists: ${businessUserDoc.exists}');
          
          if (businessUserDoc.exists) {
            final businessData = businessUserDoc.data()!;
            print('BusinessDashboard - Business data: $businessData');
            setState(() {
              _businessId = businessData['businessId'] ?? user.uid;
              _isLoading = false;
            });
          } else {
            // Fallback: use user ID as business ID
            print('BusinessDashboard - Using fallback business ID: ${user.uid}');
            setState(() {
              _businessId = user.uid;
              _isLoading = false;
            });
          }
        } else {
          print('BusinessDashboard - User is not business type: ${userData?.userType}');
          setState(() {
            _error = 'Bu kullanıcı işletme hesabı değil. User type: ${userData?.userType}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Kullanıcı oturum açmamış';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('BusinessDashboard - Error: $e');
      setState(() {
        _error = 'Business bilgileri yüklenirken hata: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRouteConstants.businessRegister);
                },
                child: const Text('İşletme Kaydı Yap'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_businessId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // URL'den hangi sekmenin açılacağını belirle
    final routeName = ModalRoute.of(context)?.settings.name;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    String? initialTab = args?['initialTab'];
    
    if (initialTab == null && routeName != null) {
      final uri = Uri.parse(routeName);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        initialTab = pathSegments[1];
      }
    }
    
    return BusinessDashboard(
      businessId: _businessId!,
      initialTab: initialTab,
    );
  }

  int _getTabIndexFromName(String? tabName) {
    if (tabName == null) return 0;
    
    const tabMap = {
      'genel-bakis': 0,
      'dashboard': 0,
      'siparisler': 1,
      'orders': 1,
      'menu-yonetimi': 2,
      'menu': 2,
      'garsonlar': 3,
      'staff': 3,
      'indirimler': 4,
      'discounts': 4,
      'qr-kodlar': 5,
      'qr': 5,
      'masa-yonetimi': 6,
      'table-management': 6,
      'mutfak-entegrasyonu': 7,
      'kitchen-integration': 7,
      'teslimat-yonetimi': 8,
      'delivery-management': 8,
      'odeme-yonetimi': 9,
      'payment-management': 9,
      'personel-takibi': 10,
      'staff-tracking': 10,
      'crm-yonetimi': 11,
      'crm-management': 11,
      'donanim-entegrasyonu': 12,
      'hardware-integration': 12,
      'sube-yonetimi': 13,
      'multi-branch': 13,
      'uzaktan-erisim': 14,
      'remote-access': 14,
      'yasal-uyumluluk': 15,
      'legal-compliance': 15,
      'maliyet-kontrolu': 16,
      'cost-control': 16,
      'ai-tahminleme': 17,
      'ai-prediction': 17,
      'dijital-pazarlama': 18,
      'digital-marketing': 18,
      'veri-guvenligi': 19,
      'data-security': 19,
      'analitikler': 20,
      'analytics': 20,
      'stok-yonetimi': 21,
      'stock-management': 21,
      'ayarlar': 22,
      'settings': 22,
      'profile': 22,
    };
    
    return tabMap[tabName] ?? 0;
  }
}

/// Business Home Router Page - Business dashboard'a yönlendirir
class BusinessHomeRouterPage extends StatefulWidget {
  const BusinessHomeRouterPage({super.key});

  @override
  State<BusinessHomeRouterPage> createState() => _BusinessHomeRouterPageState();
}

class _BusinessHomeRouterPageState extends State<BusinessHomeRouterPage> {
  final AuthService _authService = AuthService();
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  Future<void> _loadBusinessId() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _businessId = user.uid; // Use user uid as business ID
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_businessId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Business home route should redirect to business dashboard
    return BusinessDashboard(businessId: _businessId!);
  }
} 