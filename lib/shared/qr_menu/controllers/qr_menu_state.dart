import 'package:flutter/foundation.dart' hide Category;
import '../../../business/models/business.dart';
import '../../../business/models/product.dart';
import '../../../business/models/category.dart';
import '../../../business/models/discount.dart';

/// QR Menu state management
class QRMenuState extends ChangeNotifier {
  // Business data
  Business? _business;
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Product> _filteredProducts = [];
  List<Discount> _discounts = [];
  List<String> _favoriteProductIds = [];

  // URL Parameters
  String? _businessId;
  int? _tableNumber;

  // UI State
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};
  bool _showSearchBar = false;
  int _cartItemCount = 0;
  double _headerOpacity = 1.0;
  String _currentLanguage = 'tr';

  // Guest Mode State
  bool _isGuestMode = false;
  String? _guestUserId;

  // Getters
  Business? get business => _business;
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Product> get filteredProducts => _filteredProducts;
  List<Discount> get discounts => _discounts;
  List<String> get favoriteProductIds => _favoriteProductIds;

  String? get businessId => _businessId;
  int? get tableNumber => _tableNumber;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get filters => _filters;
  bool get showSearchBar => _showSearchBar;
  int get cartItemCount => _cartItemCount;
  double get headerOpacity => _headerOpacity;
  String get currentLanguage => _currentLanguage;

  bool get isGuestMode => _isGuestMode;
  String? get guestUserId => _guestUserId;

  // Setters
  void setBusiness(Business? business) {
    _business = business;
    notifyListeners();
  }

  void setProducts(List<Product> products) {
    _products = products;
    notifyListeners();
  }

  void setCategories(List<Category> categories) {
    _categories = categories;
    notifyListeners();
  }

  void setFilteredProducts(List<Product> products) {
    _filteredProducts = products;
    notifyListeners();
  }

  void setDiscounts(List<Discount> discounts) {
    _discounts = discounts;
    notifyListeners();
  }

  void setFavoriteProductIds(List<String> ids) {
    _favoriteProductIds = ids;
    notifyListeners();
  }

  void setBusinessId(String? id) {
    _businessId = id;
    notifyListeners();
  }

  void setTableNumber(int? number) {
    _tableNumber = number;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(bool hasError, [String? message]) {
    _hasError = hasError;
    _errorMessage = message;
    notifyListeners();
  }

  void setSelectedCategoryId(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilters(Map<String, dynamic> filters) {
    _filters = filters;
    notifyListeners();
  }

  void setShowSearchBar(bool show) {
    _showSearchBar = show;
    notifyListeners();
  }

  void setCartItemCount(int count) {
    _cartItemCount = count;
    notifyListeners();
  }

  void setHeaderOpacity(double opacity) {
    _headerOpacity = opacity;
    notifyListeners();
  }

  void setCurrentLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  void setGuestMode(bool isGuest, [String? guestId]) {
    _isGuestMode = isGuest;
    _guestUserId = guestId;
    notifyListeners();
  }

  // Reset state
  void reset() {
    _business = null;
    _products = [];
    _categories = [];
    _filteredProducts = [];
    _discounts = [];
    _favoriteProductIds = [];
    _businessId = null;
    _tableNumber = null;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _selectedCategoryId = 'all';
    _searchQuery = '';
    _filters = {};
    _showSearchBar = false;
    _cartItemCount = 0;
    _headerOpacity = 1.0;
    _currentLanguage = 'tr';
    _isGuestMode = false;
    _guestUserId = null;
    notifyListeners();
  }
}
