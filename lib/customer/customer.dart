// Customer Module Export
// Ana customer modülü - tüm customer bileşenlerini export eder

// Models
export 'models/customer_user.dart';
export 'models/customer_session.dart';
export 'models/customer_activity_log.dart';
export 'models/customer_preferences.dart';
// CustomerStats is already exported via customer_user.dart

// Services
export 'services/customer_service.dart';

// Pages
export 'pages/customer_home_page.dart';
export 'pages/business_detail_page.dart';
export 'pages/menu_page.dart';
export 'pages/cart_page.dart';
export 'pages/customer_orders_page.dart';
export 'pages/search_page.dart';

// Widgets
export 'widgets/business_header.dart';
export 'widgets/category_list.dart';
export 'widgets/product_grid.dart';
export 'widgets/search_bar.dart';
export 'widgets/filter_bottom_sheet.dart';



// Customer Module Configuration
class CustomerModule {
  static const String moduleName = 'Customer';
  static const String version = '1.0.0';
  
  // Module initialization
  static void initialize() {
    // Customer module initialization logic
    print('$moduleName Module v$version initialized');
  }
  
  // Module configuration
  static Map<String, dynamic> get config => {
    'name': moduleName,
    'version': version,
    'features': [
      'QR Code Scanning',
      'Business Discovery',
      'Menu Browsing',
      'Cart Management',
      'Order Placement',
      'Order Tracking',
      'Favorites Management',
      'Search & Filter',
    ],
    'pages': [
      'Customer Home',
      'Business Detail',
      'Menu',
      'Cart',
      'Orders',
      'Search',
    ],
    'services': [
      'Customer Service',
    ],
  };
}

// Customer Module Constants
class CustomerConstants {
  // Customer UI Constants
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  
  // Customer Colors (uses main app colors)
  static const String primaryColorName = 'primary';
  static const String secondaryColorName = 'secondary';
  static const String accentColorName = 'accent';
  
  // Customer Text Styles
  static const String customerFontFamily = 'Poppins';
  static const double customerFontSize = 14.0;
  static const double customerHeaderFontSize = 18.0;
  
  // Customer Spacing
  static const double customerPadding = 16.0;
  static const double customerMargin = 8.0;
  static const double customerSpacing = 12.0;
  
  // Customer Animation
  static const Duration customerAnimationDuration = Duration(milliseconds: 300);
  
  // Order Status
  static const List<String> orderStatuses = [
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'delivered',
    'cancelled'
  ];
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'cash',
    'credit_card',
    'debit_card',
    'mobile_payment',
    'online_payment'
  ];
}

// Customer Module Utils
class CustomerUtils {
  /// Order status'ü Türkçe'ye çevir
  static String getOrderStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Beklemede';
      case 'confirmed':
        return 'Onaylandı';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'ready':
        return 'Hazır';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Bilinmeyen';
    }
  }
  
  /// Payment method'u Türkçe'ye çevir
  static String getPaymentMethodText(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Nakit';
      case 'credit_card':
        return 'Kredi Kartı';
      case 'debit_card':
        return 'Banka Kartı';
      case 'mobile_payment':
        return 'Mobil Ödeme';
      case 'online_payment':
        return 'Online Ödeme';
      default:
        return 'Diğer';
    }
  }
} 