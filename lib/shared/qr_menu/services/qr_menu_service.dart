import '../../../core/services/auth_service.dart';
import '../../../business/services/business_firestore_service.dart';
import '../../../business/models/business.dart';
import '../../../business/models/product.dart';
import '../../../business/models/category.dart';
import '../../../business/models/discount.dart';

/// Service for QR Menu specific operations
class QRMenuService {
  final AuthService _authService = AuthService();
  final BusinessFirestoreService _businessService = BusinessFirestoreService();

  /// Load complete menu data for a business
  Future<QRMenuData> loadMenuData(String businessId) async {
    try {
      // Load business data
      final business = await _businessService.getBusiness(businessId);
      if (business == null) {
        throw Exception('İşletme bulunamadı');
      }

      // Load categories
      final categories =
          await _businessService.getBusinessCategories(businessId);
      final activeCategories = categories.where((c) => c.isActive).toList();

      // Load products
      final products = await _businessService.getBusinessProducts(businessId);
      final activeProducts =
          products.where((p) => p.isActive && p.isAvailable).toList();

      // Load discounts
      final discounts =
          await _businessService.getDiscountsByBusinessId(businessId);

      return QRMenuData(
        business: business,
        categories: activeCategories,
        products: activeProducts,
        discounts: discounts,
      );
    } catch (e) {
      throw Exception('Menü verileri yüklenirken hata oluştu: $e');
    }
  }

  /// Check if business is currently open
  bool isBusinessOpen(Business business) {
    // Simple check - could be enhanced with working hours logic
    return business.isOpen ?? true;
  }

  /// Get current user type for menu display
  String getCurrentUserType() {
    final user = _authService.currentUser;
    return user != null ? 'registered' : 'guest';
  }
}

/// Container for QR Menu data
class QRMenuData {
  final Business business;
  final List<Category> categories;
  final List<Product> products;
  final List<Discount> discounts;

  QRMenuData({
    required this.business,
    required this.categories,
    required this.products,
    required this.discounts,
  });
}
