import 'package:flutter/material.dart';

import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/business_register_page.dart';
import '../../presentation/pages/auth/router_page.dart';
import '../../business/pages/business_login_page.dart';
import '../../customer/pages/menu_page.dart';
import '../../customer/pages/product_detail_page.dart';
import '../../customer/pages/customer_orders_page.dart';
import '../../customer/pages/customer_home_page.dart';
import '../../customer/pages/customer_dashboard_page.dart';
import '../../customer/pages/business_detail_page.dart';
import '../../customer/pages/search_page.dart';
import '../../business/pages/business_home_page.dart';
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
  static const String customerHome = '/customer/home';
  static const String customerDashboard = '/customer/dashboard';
  static const String customerOrders = '/customer/orders';
  static const String menu = '/menu';
  static const String productDetail = '/product-detail';
  static const String businessDetail = '/business/detail';
  static const String search = '/search';

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
    customerHome: (context) => const CustomerHomeRouterPage(),
    customerDashboard: (context) => const CustomerDashboardRouterPage(),
    customerOrders: (context) => const CustomerOrdersRouterPage(),
    menu: (context) => const MenuRouterPage(),
    productDetail: (context) => const ProductDetailRouterPage(),
    businessDetail: (context) => const BusinessDetailRouterPage(),
    search: (context) => const SearchRouterPage(),

    // Business route'ları
    businessHome: (context) => const BusinessHomeRouterPage(),
    businessDashboard: (context) => const BusinessDashboardRouterPage(),
  };

  // =============================================================================
  // DYNAMIC ROUTE GENERATOR - Dinamik Route Yönetimi
  // =============================================================================
  
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

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
        case 'home':
          final args = settings.arguments as Map<String, dynamic>?;
          final userId = args?['userId'] ?? 'guest';
          return MaterialPageRoute(
            builder: (context) => CustomerHomePage(userId: userId),
            settings: settings,
          );

        case 'dashboard':
          final args = settings.arguments as Map<String, dynamic>?;
          final userId = args?['userId'] ?? 'guest';
          return MaterialPageRoute(
            builder: (context) => CustomerDashboardPage(userId: userId),
            settings: settings,
          );

        case 'orders':
          final args = settings.arguments as Map<String, dynamic>?;
          final userId = args?['userId'] ?? 'guest';
          return MaterialPageRoute(
            builder: (context) => CustomerOrdersPage(userId: userId, businessId: '',),
            settings: settings,
          );
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

    if (pathSegments.length >= 2) {
      final businessId = pathSegments[1];
      return MaterialPageRoute(
        builder: (context) => MenuPage(businessId: businessId),
        settings: settings,
      );
    }

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
      customerPhone: customerPhone, userId: null,
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
    
    return ResponsiveAdminDashboard(businessId: _businessId!);
  }
}

class CustomerHomeRouterPage extends StatelessWidget {
  const CustomerHomeRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String?;

    if (userId == null || userId.isEmpty) {
      return const RouterPage();
    }

    return CustomerHomePage(userId: userId);
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
    return ResponsiveAdminDashboard(businessId: _businessId!);
  }
}
