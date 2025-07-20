// Business Module - İşletme Yönetimi Modülü

// Models
export 'models/business_user.dart';
export 'models/business_session.dart';
export 'models/business_activity_log.dart';
export 'models/analytics_models.dart';
export 'models/stock_models.dart';

// Services
export 'services/business_service.dart';
export 'services/analytics_service.dart';
export 'services/stock_service.dart';

// Pages
export 'pages/business_login_page.dart';
export 'pages/business_dashboard_page.dart';
export 'pages/business_management_page.dart';
export 'pages/customer_management_page.dart';
export 'pages/analytics_page.dart';
export 'pages/system_settings_page.dart';
export 'pages/activity_logs_page.dart';
export 'pages/stock_management_page.dart';

// Routes are now managed centrally in AppRoutes

// Business Module sınıfı
class BusinessModule {
  static void initialize() {
    // Business modülü başlatma işlemleri
    print('Business Module initialized');
  }


} 