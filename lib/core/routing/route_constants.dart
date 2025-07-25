/// Merkezi Route Constants - Tüm route path'leri burada tanımlanır
class AppRouteConstants {
  AppRouteConstants._();

  // =============================================================================
  // ROOT ROUTES
  // =============================================================================
  static const String root = '/';
  static const String router = '/router';

  // =============================================================================
  // AUTH ROUTES  
  // =============================================================================
  static const String login = '/login';
  static const String register = '/register';
  
  // =============================================================================
  // ADMIN ROUTES (Prefix: /admin)
  // =============================================================================
  static const String adminPrefix = '/admin';
  static const String adminLogin = '/admin/login';
  static const String adminRegister = '/admin/register';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminBusinesses = '/admin/businesses';
  static const String adminCustomers = '/admin/customers';
  static const String adminAdmins = '/admin/admins';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminSettings = '/admin/settings';
  static const String adminLogs = '/admin/logs';

  // =============================================================================
  // BUSINESS ROUTES (Prefix: /business)
  // =============================================================================
  static const String businessPrefix = '/business';
  static const String businessLogin = '/business/login';
  static const String businessRegister = '/business-register';
  static const String businessDashboard = '/business/dashboard';
  static const String businessHome = '/business/home';
  
  // Business Dashboard Tabs (Legacy + New Features)
  static const String businessOverview = '/business/genel-bakis';
  static const String businessOrders = '/business/siparisler';
  static const String businessMenu = '/business/menu-yonetimi';
  static const String businessWaiters = '/business/garsonlar';
  static const String businessDiscounts = '/business/indirimler';
  static const String businessQR = '/business/qr-kodlar';
  static const String businessTableManagement = '/business/masa-yonetimi';
  static const String businessKitchenIntegration = '/business/mutfak-entegrasyonu';
  static const String businessDeliveryManagement = '/business/teslimat-yonetimi';
  static const String businessPaymentManagement = '/business/odeme-yonetimi';
  static const String businessStaffTracking = '/business/personel-takibi';
  static const String businessCRMManagement = '/business/crm-yonetimi';
  static const String businessHardwareIntegration = '/business/donanim-entegrasyonu';
  static const String businessMultiBranch = '/business/sube-yonetimi';
  static const String businessRemoteAccess = '/business/uzaktan-erisim';
  static const String businessLegalCompliance = '/business/yasal-uyumluluk';
  static const String businessCostControl = '/business/maliyet-kontrolu';
  static const String businessAIPrediction = '/business/ai-tahminleme';
  static const String businessDigitalMarketing = '/business/dijital-pazarlama';
  static const String businessDataSecurity = '/business/veri-guvenligi';
  static const String businessAnalytics = '/business/analitikler';
  static const String businessStockManagement = '/business/stok-yonetimi';
  static const String businessSettings = '/business/ayarlar';

  // Modern Business Dashboard Tabs
  static const String businessModernDashboard = '/business/:businessId/dashboard';
  static const String businessModernOrders = '/business/:businessId/orders';
  static const String businessModernMenu = '/business/:businessId/menu';
  static const String businessModernQRCodes = '/business/:businessId/qr';
  static const String businessModernAnalytics = '/business/:businessId/analytics';
  static const String businessModernStock = '/business/:businessId/stock';
  static const String businessModernStaff = '/business/:businessId/staff';
  static const String businessModernFeatures = '/business/:businessId/features';
  static const String businessModernProfile = '/business/:businessId/profile';

  // =============================================================================
  // CUSTOMER ROUTES (Prefix: /customer)
  // =============================================================================
  static const String customerPrefix = '/customer';
  static const String customerDashboard = '/customer/dashboard';
  static const String customerOrders = '/customer/orders';
  static const String customerProfile = '/customer/profile';
  static const String customerCart = '/customer/cart';
  static const String customerSearch = '/customer/search';
  static const String customerQRScanner = '/customer/qr-scanner';

  // Modern Customer Dashboard Tabs
  static const String customerModernHome = '/customer/:userId/home';
  static const String customerModernOrders = '/customer/:userId/orders';
  static const String customerModernFavorites = '/customer/:userId/favorites';
  static const String customerModernServices = '/customer/:userId/services';
  static const String customerModernProfile = '/customer/:userId/profile';

  // =============================================================================
  // PUBLIC ROUTES
  // =============================================================================
  static const String menu = '/menu';
  static const String qrMenu = '/qr-menu';
  static const String qrScanner = '/qr-scanner';
  static const String productDetail = '/product-detail';
  static const String businessDetail = '/business/detail';
  static const String search = '/search';
  
  // Universal QR Route
  static const String universalQR = '/qr';

  // =============================================================================
  // DYNAMIC ROUTE PATTERNS
  // =============================================================================
  static const String menuWithBusinessId = '/menu/:businessId';
  static const String qrMenuWithBusinessId = '/qr-menu/:businessId';
  static const String customerWithUserId = '/customer/:userId';
  static const String businessDetailWithId = '/business/:businessId/detail';

  // =============================================================================
  // ROUTE CHECKING HELPERS
  // =============================================================================
  
  /// Admin route mu kontrol eder
  static bool isAdminRoute(String routeName) {
    return routeName.startsWith(adminPrefix);
  }
  
  /// Business route mu kontrol eder
  static bool isBusinessRoute(String routeName) {
    return routeName.startsWith(businessPrefix);
  }
  
  /// Customer route mu kontrol eder
  static bool isCustomerRoute(String routeName) {
    return routeName.startsWith(customerPrefix);
  }
  
  /// QR route mu kontrol eder
  static bool isQRRoute(String routeName) {
    return routeName == universalQR || 
           routeName.startsWith('/qr?') ||
           routeName.startsWith('/qr-menu/') ||
           routeName.contains('business=') ||
           routeName.contains('table=');
  }

  /// Auth route mu kontrol eder
  static bool isAuthRoute(String routeName) {
    return routeName == login || 
           routeName == register ||
           routeName == businessLogin ||
           routeName == businessRegister ||
           routeName == adminLogin ||
           routeName == adminRegister;
  }
}

/// Route parametrelerini tiplendirir
class RouteParams {
  // URL Parameters
  static const String businessId = 'businessId';
  static const String userId = 'userId';
  static const String productId = 'productId';
  static const String orderId = 'orderId';
  static const String categoryId = 'categoryId';
  
  // Query Parameters
  static const String table = 'table';
  static const String tableNumber = 'tableNumber';
  static const String userType = 'userType';
  static const String returnUrl = 'returnUrl';
  static const String business = 'business';
}

/// Route argument tipleri
class RouteArgs {
  // Customer Arguments
  static const String customerData = 'customerData';
  static const String businesses = 'businesses';
  static const String categories = 'categories';
  
  // Business Arguments
  static const String businessData = 'businessData';
  static const String product = 'product';
  static const String business = 'business';
  
  // Admin Arguments
  static const String adminData = 'adminData';
  
  // QR Arguments
  static const String qrCode = 'qrCode';
  static const String isQRRoute = 'isQRRoute';
  static const String originalUrl = 'originalUrl';
  static const String routeError = 'routeError';
} 