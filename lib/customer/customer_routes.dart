import 'package:flutter/material.dart';

import 'pages/customer_home_page.dart';
import 'pages/business_detail_page.dart';
import 'pages/menu_page.dart';
import 'pages/cart_page.dart';
import 'pages/customer_orders_page.dart';
import 'pages/search_page.dart';

class CustomerRoutes {
  // Route constants
  static const String home = '/customer/home';
  static const String businessDetail = '/customer/business-detail';
  static const String menu = '/customer/menu';
  static const String cart = '/customer/cart';
  static const String orders = '/customer/orders';
  static const String search = '/customer/search';

  // Route generation
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] ?? 'guest';
        return MaterialPageRoute(
          builder: (_) => CustomerHomePage(userId: userId),
          settings: settings,
        );

      case businessDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args['business'] != null) {
          return MaterialPageRoute(
            builder: (_) => BusinessDetailPage(
              business: args['business'],
              customerData: args['customerData'],
            ),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      case menu:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args['businessId'] != null) {
          return MaterialPageRoute(
            builder: (_) => MenuPage(
              businessId: args['businessId'] as String,
            ),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      case cart:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args['businessId'] != null) {
          return MaterialPageRoute(
            builder: (_) => CartPage(
              businessId: args['businessId'] as String,
            ),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      case orders:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args['businessId'] != null) {
          return MaterialPageRoute(
            builder: (_) => CustomerOrdersPage(
              businessId: args['businessId'] as String,
              customerPhone: args['customerPhone'] as String?,
            ),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      case search:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (_) => SearchPage(
              businesses: args['businesses'] ?? [],
              categories: args['categories'] ?? [],
            ),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      default:
        return _errorRoute(settings);
    }
  }

  // Error route for invalid navigation
  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Hata'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Sayfa bulunamadı: ${settings.name}',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(_).pushReplacementNamed(home),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
      settings: settings,
    );
  }

  // Helper methods for navigation
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamed(context, home);
  }

  static void navigateToBusinessDetail(
    BuildContext context,
    dynamic business, {
    dynamic customerData,
  }) {
    Navigator.pushNamed(
      context,
      businessDetail,
      arguments: {
        'business': business,
        'customerData': customerData,
      },
    );
  }

  static void navigateToMenu(BuildContext context, String businessId) {
    Navigator.pushNamed(
      context,
      menu,
      arguments: {'businessId': businessId},
    );
  }

  static void navigateToCart(BuildContext context, String businessId) {
    Navigator.pushNamed(
      context,
      cart,
      arguments: {'businessId': businessId},
    );
  }

  static void navigateToOrders(
    BuildContext context,
    String businessId, {
    String? customerPhone,
  }) {
    Navigator.pushNamed(
      context,
      orders,
      arguments: {
        'businessId': businessId,
        'customerPhone': customerPhone,
      },
    );
  }

  static void navigateToSearch(
    BuildContext context, {
    List<dynamic> businesses = const [],
    List<dynamic> categories = const [],
  }) {
    Navigator.pushNamed(
      context,
      search,
      arguments: {
        'businesses': businesses,
        'categories': categories,
      },
    );
  }
} 