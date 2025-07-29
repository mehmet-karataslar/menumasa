/// QR Menu Module - Universal QR Menu System
///
/// Bu modül evrensel QR menü sistemi için gerekli tüm bileşenleri sağlar.
/// Misafir modu ve kayıtlı kullanıcı modu destekler.

library qr_menu;

// Controllers
export 'controllers/qr_menu_controller.dart';
export 'controllers/qr_menu_state.dart';

// Services
export 'services/qr_menu_service.dart';
export 'services/qr_waiter_service.dart';
export 'services/qr_validation_service.dart';

// Models
export 'models/qr_menu_data.dart';
export 'models/qr_guest_session.dart';

// Widgets
export 'widgets/qr_menu_header.dart';
export 'widgets/qr_menu_search.dart';
export 'widgets/qr_menu_categories.dart';
export 'widgets/qr_menu_products.dart';
export 'widgets/qr_menu_dialogs.dart';
export 'widgets/qr_menu_loading.dart';
export 'widgets/qr_menu_error.dart';

// Utils
export 'utils/qr_menu_utils.dart';
export 'utils/qr_error_utils.dart';

// Main Page
export 'pages/universal_qr_menu_page.dart';
