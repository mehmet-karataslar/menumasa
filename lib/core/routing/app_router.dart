import 'package:flutter/material.dart';
import '../../presentation/pages/customer/menu_page.dart';
import '../../presentation/pages/customer/product_detail_page.dart';
import '../../presentation/pages/customer/customer_orders_page.dart';
import '../../presentation/pages/admin/admin_dashboard_page.dart';
import '../../presentation/pages/admin/category_management_page.dart';
import '../../presentation/pages/admin/product_management_page.dart';
import '../../presentation/pages/admin/qr_code_management_page.dart';
import '../../presentation/pages/admin/business_info_page.dart';
import '../../presentation/pages/admin/menu_settings_page.dart';
import '../../presentation/pages/admin/discount_management_page.dart';
import '../../presentation/pages/admin/orders_page.dart';
import '../../presentation/pages/admin/responsive_admin_dashboard.dart';
import '../../presentation/pages/qr/qr_menu_page.dart';
import '../../presentation/pages/shared/not_found_page.dart';
import '../../data/models/product.dart';
import '../../data/models/business.dart';

// Menü router sayfası - businessId ve customerPhone/tableNumber parametrelerini alır
class MenuRouterPage extends StatelessWidget {
  const MenuRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final tableNumber =
        args?['tableNumber'] as String? ?? args?['customerPhone'] as String?;

    return QRMenuPage(businessId: businessId, tableNumber: tableNumber);
  }
}

// Ürün detay router sayfası - product ve business parametrelerini alır
class ProductDetailRouterPage extends StatelessWidget {
  const ProductDetailRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return const NotFoundPage();
    }

    final product = args['product'] as Product?;
    final business = args['business'] as Business?;

    if (product == null || business == null) {
      return const NotFoundPage();
    }

    return ProductDetailPage(product: product, business: business);
  }
}

// Admin Dashboard router sayfası
class AdminDashboardRouterPage extends StatelessWidget {
  const AdminDashboardRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';

    // Get current route to determine which page to show
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, card layout for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return AdminDashboardPage(businessId: businessId);
    }
  }
}

// Category Management router sayfası
class CategoryManagementRouterPage extends StatelessWidget {
  const CategoryManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return CategoryManagementPage(businessId: businessId);
    }
  }
}

// Product Management router sayfası
class ProductManagementRouterPage extends StatelessWidget {
  const ProductManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return ProductManagementPage(businessId: businessId);
    }
  }
}

// Business Info router sayfası
class BusinessInfoRouterPage extends StatelessWidget {
  const BusinessInfoRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return BusinessInfoPage(businessId: businessId);
    }
  }
}

// Menu Settings router sayfası
class MenuSettingsRouterPage extends StatelessWidget {
  const MenuSettingsRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return MenuSettingsPage(businessId: businessId);
    }
  }
}

// QR Code Management router sayfası
class QRCodeManagementRouterPage extends StatelessWidget {
  const QRCodeManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return QRCodeManagementPage(businessId: businessId);
    }
  }
}

// Discount Management router sayfası
class DiscountManagementRouterPage extends StatelessWidget {
  const DiscountManagementRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return DiscountManagementPage(businessId: businessId);
    }
  }
}

// Orders router sayfası
class OrdersRouterPage extends StatelessWidget {
  const OrdersRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Responsive layout: Use sidebar layout for web/desktop, direct page for mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 768;

    if (isDesktopOrTablet) {
      return ResponsiveAdminDashboard(
        businessId: businessId,
        initialRoute: currentRoute,
      );
    } else {
      return OrdersPage(businessId: businessId);
    }
  }
}

// Customer Orders router sayfası
class CustomerOrdersRouterPage extends StatelessWidget {
  const CustomerOrdersRouterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final businessId = args?['businessId'] as String? ?? 'demo-business-001';
    final customerPhone = args?['customerPhone'] as String?;

    return CustomerOrdersPage(
      businessId: businessId,
      customerPhone: customerPhone,
    );
  }
}
