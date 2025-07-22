import 'package:flutter/material.dart';

import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/business_register_page.dart';
import '../../presentation/pages/auth/router_page.dart';
import '../../business/pages/business_login_page.dart';
import '../../customer/pages/menu_page.dart';
import '../../customer/pages/product_detail_page.dart';
import '../../customer/pages/customer_orders_page.dart';
import '../../customer/pages/customer_dashboard_page.dart';
import '../../customer/pages/customer_profile_page.dart';
import '../../customer/pages/cart_page.dart';
import '../../customer/pages/business_detail_page.dart';
import '../../customer/pages/search_page.dart';
import '../../customer/pages/qr_scanner_page.dart';
import '../../customer/pages/qr_menu_page.dart';
import '../../business/pages/business_dashboard_page.dart';
import '../../business/models/category.dart' as app_category;
import '../../business/models/business.dart';
import '../../admin/admin.dart';
import '../../core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/user_type.dart';

/// Merkezi Route Yönetimi - Tüm route'lar burada tanımlanır
class AppRoutes {
  AppRoutes._();

  // =============================================================================
  // ROUTE NAMES - Tüm Route Sabitleri
  // =============================================================================
  
  // Ana route'lar
  static const String home = '/';
  static const String router = '/router';

  // Auth route'ları
  static const String login = '/login';
  static const String register = '/register';
  static const String businessLogin = '/business/login';
  static const String businessRegister = '/business-register';

  // Customer route'ları
  static const String customerDashboard = '/customer/dashboard';
  static const String customerOrders = '/customer/orders';
  static const String customerProfile = '/customer/profile';
  static const String customerCart = '/customer/cart';
  static const String menu = '/menu';
  static const String productDetail = '/product-detail';
  static const String businessDetail = '/business/detail';
  static const String search = '/search';
  static const String qrScanner = '/qr-scanner';
  static const String qrMenu = '/qr-menu';

  // Business route'ları
  static const String businessHome = '/business/home';
  static const String businessDashboard = '/business/dashboard';
  static const String businessManagement = '/business/management';
  static const String businessAnalytics = '/business/analytics';
  static const String businessSettings = '/business/settings';

  // Admin route'ları (AdminModule üzerinden yönetiliyor)
  // /admin/* route'ları AdminRoutes tarafından handle ediliyor

  // =============================================================================
  // ROUTE MAP - Statik Route Tanımları
  // =============================================================================
  
  static Map<String, WidgetBuilder> get routes => {
    // Ana route'lar
    home: (context) => const RouterPage(),
    router: (context) => const RouterPage(),

    // Auth route'ları
    login: (context) => const LoginPage(userType: 'customer'),
    register: (context) => const RegisterPage(userType: 'customer'),
    businessLogin: (context) => const BusinessLoginPage(),
    businessRegister: (context) => const BusinessRegisterPage(),

    // Customer route'ları
    customerDashboard: (context) => const CustomerDashboardRouterPage(),
    customerOrders: (context) => const CustomerOrdersRouterPage(),
    customerProfile: (context) => const CustomerProfileRouterPage(),
    customerCart: (context) => const CustomerCartRouterPage(),
    menu: (context) => const MenuRouterPage(),
    productDetail: (context) => const ProductDetailRouterPage(),
    businessDetail: (context) => const BusinessDetailRouterPage(),
    search: (context) => const SearchRouterPage(),
    qrScanner: (context) => const QRScannerRouterPage(),
    qrMenu: (context) => const QRMenuRouterPage(),

    // Business route'ları
    businessHome: (context) => const BusinessHomeRouterPage(),
    businessDashboard: (context) => const BusinessDashboardRouterPage(),
  };

  // =============================================================================
  // DYNAMIC ROUTE GENERATOR - Dinamik Route Yönetimi
  // =============================================================================
  
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');
    
    // Debug: URL routing'i logla
    print('🔗 Route Debug: ${settings.name}');
    print('🔗 URI path: ${uri.path}');
    print('🔗 URI query: ${uri.query}');

    // Admin route'ları - AdminModule'a yönlendir
    if (AdminModule.isAdminRoute(settings.name ?? '')) {
      return AdminRoutes.generateRoute(settings);
    }

    // Login route - userType parametresi ile
    if (settings.name == login) {
      final args = settings.arguments as Map<String, dynamic>?;
      final userType = args?['userType'] ?? 'customer';
      return MaterialPageRoute(
        builder: (context) => LoginPage(userType: userType),
        settings: settings,
      );
    }

    // Register route - userType parametresi ile
    if (settings.name == register) {
      final args = settings.arguments as Map<String, dynamic>?;
      final userType = args?['userType'] ?? 'customer';
      return MaterialPageRoute(
        builder: (context) => RegisterPage(userType: userType),
        settings: settings,
      );
    }

    // Customer dinamik route'ları
    if (settings.name?.startsWith('/customer/') == true) {
      return _handleCustomerRoutes(settings);
    }

    // Business dinamik route'ları
    if (settings.name?.startsWith('/business/') == true) {
      return _handleBusinessRoutes(settings);
    }

    // Menu route'ları (businessId parametresi ile)
    if (settings.name?.startsWith('/menu/') == true) {
      return _handleMenuRoutes(settings);
    }

    // QR Menü route'ları
    if (settings.name?.startsWith('/qr-menu/') == true) {
      print('🎯 QR Menu route tespit edildi: ${settings.name}');
      return _handleMenuRoutes(settings);
    }

    // Genel QR scanner route'u
    if (settings.name == qrScanner) {
      final args = settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId'] as String?;
      return MaterialPageRoute(
        builder: (context) => QRScannerPage(userId: userId),
        settings: settings,
      );
    }

    return null;
  }

  // =============================================================================
  // CUSTOMER ROUTE HANDLER
  // =============================================================================
  
  static Route<dynamic>? _handleCustomerRoutes(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');
    final pathSegments = uri.pathSegments;

    if (pathSegments.length >= 2) {
      switch (pathSegments[1]) {


        case 'dashboard':
          final args = settings.arguments as Map<String, dynamic>?;
          final userId = args?['userId'] as String? ?? 'guest';
          return MaterialPageRoute(
            builder: (context) => CustomerDashboardPage(userId: userId),
            settings: settings,
          );

        case 'orders':
          final args = settings.arguments as Map<String, dynamic>?;
          final businessId = args?['businessId'] as String?;
          final customerPhone = args?['customerPhone'] as String?;
          final customerId = args?['customerId'] as String?;
          return MaterialPageRoute(
            builder: (context) => CustomerOrdersPage(
              businessId: businessId,
              customerPhone: customerPhone,
              customerId: customerId,
            ),
            settings: settings,
          );

        case 'profile':
          final args = settings.arguments as Map<String, dynamic>?;
          final customerData = args?['customerData'];
          final userId = args?['userId'] as String?;
          return MaterialPageRoute(
            builder: (context) => const CustomerProfilePage(),
            settings: settings,
          );

        case 'cart':
          final args = settings.arguments as Map<String, dynamic>?;
          final businessId = args?['businessId'] as String?;
          final userId = args?['userId'] as String?;
          if (businessId == null) return null;
          return MaterialPageRoute(
            builder: (context) => CartPage(businessId: businessId),
            settings: settings,
          );

        // Handle dynamic routes like /customer/{userId}/business/{businessId}
        default:
          if (pathSegments.length >= 4) {
            final userId = pathSegments[1];
            final actionType = pathSegments[2];
            final targetId = pathSegments[3];

            switch (actionType) {
              case 'business':
                final args = settings.arguments as Map<String, dynamic>?;
                final business = args?['business'];
                final customerData = args?['customerData'];
                if (business == null) return null;
                return MaterialPageRoute(
                  builder: (context) => BusinessDetailPage(
                    business: business,
                    customerData: customerData,
                  ),
                  settings: settings,
                );

              case 'menu':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => MenuPage(businessId: targetId),
                  settings: settings,
                );

              case 'cart':
                return MaterialPageRoute(
                  builder: (context) => CartPage(businessId: targetId),
                  settings: settings,
                );

              case 'orders':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => CustomerOrdersPage(
                    businessId: targetId,
                    customerId: userId,
                  ),
                  settings: settings,
                );
            }
          }
          
          // Handle /customer/{userId}/search and /customer/{userId}/profile
          if (pathSegments.length >= 3) {
            final userId = pathSegments[1];
            final actionType = pathSegments[2];

            switch (actionType) {
              case 'qr-scanner':
                return MaterialPageRoute(
                  builder: (context) => QRScannerPage(userId: userId),
                  settings: settings,
                );

              case 'search':
                final args = settings.arguments as Map<String, dynamic>?;
                final businesses = args?['businesses'] as List<dynamic>? ?? [];
                final categories = args?['categories'] as List<dynamic>? ?? [];
                return MaterialPageRoute(
                  builder: (context) => SearchPage(
                    businesses: businesses.cast<Business>(),
                    categories: categories.cast<app_category.Category>(),
                  ),
                  settings: settings,
                );
              case 'search':
                final args = settings.arguments as Map<String, dynamic>?;
                final businesses = args?['businesses'] as List<dynamic>? ?? [];
                final categories = args?['categories'] as List<dynamic>? ?? [];
                return MaterialPageRoute(
                  builder: (context) => SearchPage(
                    businesses: businesses.cast<Business>(),
                    categories: categories.cast<app_category.Category>(),
                  ),
                  settings: settings,
                );

              case 'profile':
                return MaterialPageRoute(
                  builder: (context) => const CustomerProfilePage(),
                  settings: settings,
                );
            }
          }
          break;
      }
    }

    return null;
  }

  // =============================================================================
  // BUSINESS ROUTE HANDLER
  // =============================================================================
  
  static Route<dynamic>? _handleBusinessRoutes(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');
    final pathSegments = uri.pathSegments;

    if (pathSegments.length >= 2) {
      switch (pathSegments[1]) {
        case 'dashboard':
          return MaterialPageRoute(
            builder: (context) => const BusinessDashboardRouterPage(),
            settings: settings,
          );

        case 'home':
          return MaterialPageRoute(
            builder: (context) => const BusinessHomeRouterPage(),
            settings: settings,
          );

        case 'login':
          return MaterialPageRoute(
            builder: (context) => const BusinessLoginPage(),
            settings: settings,
          );
      }
    }

    return null;
  }

  // =============================================================================
  // MENU ROUTE HANDLER
  // =============================================================================
  
  static Route<dynamic>? _handleMenuRoutes(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');
    final pathSegments = uri.pathSegments;
    
    print('🍽️ Menu Routes Handler:');
    print('   🔗 URL: ${settings.name}');
    print('   📂 Path segments: $pathSegments');
    print('   🔍 Query params: ${uri.queryParameters}');

    if (pathSegments.length >= 2) {
      final businessId = pathSegments[1];
      final isQRMenu = pathSegments[0] == 'qr-menu';
      
      print('   🏢 Business ID: $businessId');
      print('   📱 Is QR Menu: $isQRMenu');
      
      if (isQRMenu) {
        // QR Menü route'u için QRMenuPage'e yönlendir
        final tableNumber = uri.queryParameters['table'] != null 
            ? int.tryParse(uri.queryParameters['table']!) 
            : null;
        
        print('   🪑 Table number: $tableNumber');
        print('   ✅ Yönlendiriliyor QRMenuPage\'e');
        
        return MaterialPageRoute(
          builder: (context) => QRMenuPage(
            businessId: businessId,
            qrCode: settings.name,
            tableNumber: tableNumber,
          ),
          settings: settings,
        );
      } else {
        // Normal menü route'u için MenuPage'e yönlendir
        print('   ✅ Yönlendiriliyor MenuPage\'e');
        return MaterialPageRoute(
          builder: (context) => MenuPage(businessId: businessId),
          settings: settings,
        );
      }
    }

    print('   ❌ Route handle edilemedi');
    return null;
  }

  // =============================================================================
  // ERROR ROUTE HANDLER
  // =============================================================================
  
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => const RouterPage(),
      settings: settings,
    );
  }
}

// Router widget classes for parameter handling
class MenuRouterPage extends StatelessWidget {
  const MenuRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;
    final tableNumber = args?['tableNumber'] as String?;

    // Auth kontrolü - eğer businessId yoksa router'a yönlendir
    if (businessId == null || businessId.isEmpty) {
      return const RouterPage();
    }
    return MenuPage(businessId: businessId);
  }
}

class ProductDetailRouterPage extends StatelessWidget {
  const ProductDetailRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final product = args?['product'];
    final business = args?['business'];

    // Gerekli parametreler yoksa router'a yönlendir
    if (product == null || business == null) {
      return const RouterPage();
    }

    return ProductDetailPage(product: product, business: business);
  }
}

class CustomerOrdersRouterPage extends StatelessWidget {
  const CustomerOrdersRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;
    final customerPhone = args?['customerPhone'] as String?;

    // businessId yoksa router'a yönlendir
    if (businessId == null || businessId.isEmpty) {
      return const RouterPage();
    }

    return CustomerOrdersPage(
      businessId: businessId,
      customerPhone: customerPhone,
    );
  }
}

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
      print('BusinessDashboard - Current user: ${user?.uid}'); // Debug log
      
      if (user != null) {
        // Get user data to check if it's a business user
        final userData = await _authService.getCurrentUserData();
        print('BusinessDashboard - User data: ${userData?.toJson()}'); // Debug log
        print('BusinessDashboard - User type: ${userData?.userType}'); // Debug log
        
        if (userData != null && userData.userType.value == 'business') {
          // Get business ID from business_users collection
          final businessUserDoc = await FirebaseFirestore.instance
              .collection('business_users')
              .doc(user.uid)
              .get();
          
          print('BusinessDashboard - Business user doc exists: ${businessUserDoc.exists}'); // Debug log
          
          if (businessUserDoc.exists) {
            final businessData = businessUserDoc.data()!;
            print('BusinessDashboard - Business data: $businessData'); // Debug log
            setState(() {
              _businessId = businessData['businessId'] ?? user.uid;
              _isLoading = false;
            });
          } else {
            // Fallback: use user ID as business ID
            print('BusinessDashboard - Using fallback business ID: ${user.uid}'); // Debug log
            setState(() {
              _businessId = user.uid;
              _isLoading = false;
            });
          }
        } else {
          print('BusinessDashboard - User is not business type: ${userData?.userType}'); // Debug log
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
      print('BusinessDashboard - Error: $e'); // Debug log
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
                  Navigator.pushReplacementNamed(context, '/business-register');
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
    
    return BusinessDashboard(businessId: _businessId!);
  }
}



class CustomerDashboardRouterPage extends StatelessWidget {
  const CustomerDashboardRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    if (userId == null || userId.isEmpty) {
      return const RouterPage();
    }

    return CustomerDashboardPage(userId: userId);
  }
}

class CustomerProfileRouterPage extends StatelessWidget {
  const CustomerProfileRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerProfilePage();
  }
}

class CustomerCartRouterPage extends StatelessWidget {
  const CustomerCartRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String?;

    if (businessId == null || businessId.isEmpty) {
      return const RouterPage();
    }

    return CartPage(businessId: businessId);
  }
}

class BusinessDetailRouterPage extends StatelessWidget {
  const BusinessDetailRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final business = args?['business'];
    final customerData = args?['customerData'];

    if (business == null) {
      return const RouterPage();
    }

    return BusinessDetailPage(
      business: business,
      customerData: customerData,
    );
  }

  // =============================================================================
  // QR MENU ROUTE HANDLER
  // =============================================================================
  
  static Route<dynamic>? _handleQRMenuRoutes(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');
    final pathSegments = uri.pathSegments;

    // /qr-menu/{businessId} pattern'ı
    if (pathSegments.length >= 2) {
      final businessId = pathSegments[1];
      final args = settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId'] as String?;
      final qrCode = args?['qrCode'] as String?;

      return MaterialPageRoute(
        builder: (context) => QRMenuPage(
          businessId: businessId,
          userId: userId,
          qrCode: qrCode,
        ),
        settings: settings,
      );
    }

    return null;
  }
}

class SearchRouterPage extends StatelessWidget {
  const SearchRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businesses = args?['businesses'] as List<dynamic>?;
    final categories = args?['categories'] as List<dynamic>?;

    if (businesses == null || categories == null) {
      return const RouterPage();
    }

    return SearchPage(
      businesses: businesses.cast<Business>(),
      categories: categories.cast<app_category.Category>(),
    );
  }
}

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
    // Check if user is authenticated business user
    return BusinessDashboard(businessId: _businessId!);
  }
}

class QRScannerRouterPage extends StatelessWidget {
  const QRScannerRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    return QRScannerPage(userId: userId);
  }
}

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
