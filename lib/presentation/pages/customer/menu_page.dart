import 'package:flutter/material.dart';
import '../../../data/models/business.dart';
import '../../../data/models/category.dart';
import '../../../data/models/product.dart';
import '../../../data/models/discount.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/time_rule_utils.dart';
import '../../../core/services/data_service.dart';
import '../../widgets/customer/business_header.dart';
import '../../widgets/customer/category_list.dart';
import '../../widgets/customer/product_grid.dart';
import '../../widgets/customer/search_bar.dart';
import '../../widgets/customer/filter_bottom_sheet.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import '../../widgets/shared/empty_state.dart';
// CachedNetworkImage removed for Windows compatibility
import 'package:shimmer/shimmer.dart';

class MenuPage extends StatefulWidget {
  final String businessId;

  const MenuPage({Key? key, required this.businessId}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  // State
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Data
  Business? _business;
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Discount> _discounts = [];

  // Services
  final _dataService = DataService();

  // UI State
  String _searchQuery = '';
  String? _selectedCategoryId;
  Map<String, dynamic> _filters = {};
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadMenuData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMenuData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Gerçek veri yükleme
      _business = await _dataService.getBusiness(widget.businessId);
      if (_business == null) {
        throw Exception('İşletme bulunamadı');
      }

      _categories = await _dataService.getCategories(
        businessId: widget.businessId,
      );
      _products = await _dataService.getProducts(businessId: widget.businessId);
      _discounts = await _dataService.getDiscountsByBusinessId(
        widget.businessId,
      );

      // Zaman kurallarına göre filtrele
      _filterProducts();

      // TabController'ı kategorilere göre ayarla
      if (_categories.isNotEmpty) {
        _tabController = TabController(length: _categories.length, vsync: this);

        _tabController.addListener(() {
          if (_tabController.indexIsChanging) {
            _onCategorySelected(_categories[_tabController.index].categoryId);
          }
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Menü yüklenirken bir hata oluştu: $e';
      });
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filterProducts();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterProducts();
    });
  }

  void _onFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters;
      _filterProducts();
    });
  }

  void _filterProducts() {
    _filteredProducts = _products.where((product) {
      // Kategori filtresi
      if (_selectedCategoryId != null &&
          product.categoryId != _selectedCategoryId) {
        return false;
      }

      // Arama filtresi
      if (_searchQuery.isNotEmpty &&
          !product.matchesSearchQuery(_searchQuery)) {
        return false;
      }

      // Zaman kuralları kontrolü - TimeRuleUtils kullanarak
      if (!TimeRuleUtils.isProductVisible(product)) {
        return false;
      }

      // Diğer filtreler
      return product.matchesFilters(
        tagFilters: _filters['tags'],
        allergenFilters: _filters['allergens'],
        minPrice: _filters['minPrice'],
        maxPrice: _filters['maxPrice'],
        isVegetarian: _filters['isVegetarian'],
        isVegan: _filters['isVegan'],
        isHalal: _filters['isHalal'],
        isSpicy: _filters['isSpicy'],
      );
    }).toList();

    // İndirimli fiyatları hesapla
    _filteredProducts = _filteredProducts.map((product) {
      final finalPrice = product.calculateFinalPrice(_discounts);
      return product.copyWith(currentPrice: finalPrice);
    }).toList();

    // Kategorileri de zaman kurallarına göre filtrele
    _categories = _categories.where((category) {
      return TimeRuleUtils.isCategoryVisible(category);
    }).toList();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilters: _filters,
        onFiltersChanged: _onFiltersChanged,
      ),
    );
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchQuery = '';
        _filterProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
            ? _buildErrorState()
            : _buildMenuContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Loading header
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: LoadingIndicator(
              size: AppDimensions.loadingIndicatorSizeL,
              color: AppColors.white,
            ),
          ),
        ),

        // Loading content
        Expanded(
          child: Padding(
            padding: AppDimensions.paddingM,
            child: Column(
              children: [
                // Loading category tabs
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, index) => Shimmer.fromColors(
                      baseColor: AppColors.greyLight,
                      highlightColor: AppColors.white,
                      child: Container(
                        width: 100,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: AppDimensions.borderRadiusM,
                        ),
                      ),
                    ),
                  ),
                ),

                AppSizedBox.h24,

                // Loading products
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: 6,
                    itemBuilder: (context, index) => Shimmer.fromColors(
                      baseColor: AppColors.greyLight,
                      highlightColor: AppColors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: AppDimensions.borderRadiusM,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return ErrorMessage(
      message: _errorMessage ?? 'Bir hata oluştu',
      onRetry: _loadMenuData,
    );
  }

  Widget _buildMenuContent() {
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // Business Header
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: BusinessHeader(
                business: _business!,
                onSharePressed: _onSharePressed,
              ),
            ),
            actions: [
              // Search button
              IconButton(
                icon: Icon(
                  _showSearchBar ? Icons.close : Icons.search,
                  color: AppColors.white,
                ),
                onPressed: _toggleSearchBar,
              ),
              // Filter button
              IconButton(
                icon: const Icon(Icons.filter_list, color: AppColors.white),
                onPressed: _showFilterBottomSheet,
              ),
            ],
          ),

          // Search Bar (if visible)
          if (_showSearchBar)
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.white,
                padding: AppDimensions.paddingM,
                child: CustomSearchBar(
                  onSearchChanged: _onSearchChanged,
                  hintText: 'Ürün ara...',
                ),
              ),
            ),

          // Category Tabs
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.white,
              child: CategoryList(
                categories: _categories,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: _onCategorySelected,
              ),
            ),
          ),
        ];
      },
      body: _buildProductContent(),
    );
  }

  Widget _buildProductContent() {
    if (_filteredProducts.isEmpty) {
      return EmptyState(
        icon: Icons.restaurant_menu,
        title: 'Ürün Bulunamadı',
        message: _searchQuery.isNotEmpty
            ? 'Aradığınız kriterlere uygun ürün bulunamadı.'
            : 'Bu kategoride henüz ürün bulunmamaktadır.',
        actionText: _searchQuery.isNotEmpty ? 'Aramayı Temizle' : null,
        onActionPressed: _searchQuery.isNotEmpty
            ? () {
                _onSearchChanged('');
                _toggleSearchBar();
              }
            : null,
      );
    }

    return Container(
      color: AppColors.menuBackground,
      child: ProductGrid(
        products: _filteredProducts,
        onProductTapped: _onProductTapped,
        padding: AppDimensions.paddingM,
      ),
    );
  }

  void _onProductTapped(Product product) {
    Navigator.pushNamed(
      context,
      '/product-detail',
      arguments: {'product': product, 'business': _business},
    );
  }

  void _onSharePressed() {
    // QR kod veya menü linkini paylaş
    final menuUrl = 'https://masamenu.com/menu/${widget.businessId}';
    // Share.share(menuUrl);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menü linki kopyalandı: $menuUrl'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // Sample data creation methods
  Business _createSampleBusiness() {
    return Business(
      businessId: widget.businessId,
      ownerId: 'sample-owner',
      businessName: 'Lezzet Durağı',
      businessDescription: 'Geleneksel Türk mutfağının en lezzetli örnekleri',
      logoUrl:
          'https://www.google.com/imgres?q=geleneksel%20t%C3%BCrk%20mutfa%C4%9F%C4%B1%20logo&imgurl=https%3A%2F%2Fst3.depositphotos.com%2F1028367%2F33466%2Fv%2F450%2Fdepositphotos_334661516-stock-illustration-turkish-cuisine-dishes-restaurant-menu.jpg&imgrefurl=https%3A%2F%2Fdepositphotos.com%2Ftr%2Fillustrations%2Ft%25C3%25BCrk-mutfa%25C4%259F%25C4%25B1.html&docid=4rKVzLDFD3XJzM&tbnid=ba70uSI9_dRH_M&vet=12ahUKEwjM-ZXQ6bWOAxVdQ_EDHXBEHicQM3oECHkQAA..i&w=600&h=600&hcb=2&ved=2ahUKEwjM-ZXQ6bWOAxVdQ_EDHXBEHicQM3oECHkQAA',
      address: Address(
        street: 'Atatürk Caddesi No:123',
        city: 'İstanbul',
        district: 'Beyoğlu',
        postalCode: '34000',
      ),
      contactInfo: ContactInfo(
        phone: '+90 212 123 45 67',
        email: 'info@lezzetduragi.com',
        website: 'www.lezzetduragi.com',
      ),
      menuSettings: MenuSettings(
        theme: 'default',
        primaryColor: '#2C1810',
        fontFamily: 'Poppins',
        fontSize: 16.0,
        showPrices: true,
        showImages: true,
        imageSize: 'medium',
        language: 'tr',
      ),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  List<Category> _createSampleCategories() {
    return [
      Category(
        categoryId: 'cat-1',
        businessId: widget.businessId,
        name: 'Çorbalar',
        description: 'Sıcak ve lezzetli çorba çeşitleri',
        sortOrder: 0,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        categoryId: 'cat-2',
        businessId: widget.businessId,
        name: 'Ana Yemekler',
        description: 'Geleneksel Türk yemekleri',
        sortOrder: 1,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        categoryId: 'cat-3',
        businessId: widget.businessId,
        name: 'Tatlılar',
        description: 'Ev yapımı tatlılar',
        sortOrder: 2,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        categoryId: 'cat-4',
        businessId: widget.businessId,
        name: 'İçecekler',
        description: 'Sıcak ve soğuk içecekler',
        sortOrder: 3,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  List<Product> _createSampleProducts() {
    return [
      // Çorbalar
      Product(
        productId: 'prod-1',
        businessId: widget.businessId,
        categoryId: 'cat-1',
        name: 'Mercimek Çorbası',
        description: 'Geleneksel mercimek çorbası',
        detailedDescription:
            'Kırmızı mercimek, soğan, havuç ve baharatlarla hazırlanan sıcak çorba',
        price: 25.0,
        currentPrice: 25.0,
        currency: 'TL',
        images: [
          ProductImage(
            url:
                'https://www.google.com/imgres?q=geleneksel%20t%C3%BCrk%20mutfa%C4%9F%C4%B1%20%C3%A7orbalar&imgurl=https%3A%2F%2Fd17wu0fn6x6rgz.cloudfront.net%2Fimg%2Fw%2Fblok%2Fd%2Fshutterstock_771149176.webp&imgrefurl=https%3A%2F%2Fwww.yemektekeyifvar.com%2Fyemek-ve-yasam%2Fturk-mutfagina-ozgu-13-corba&docid=QA-nPQjj-ukUOM&tbnid=vA3aO5X0Cgz4zM&vet=12ahUKEwiqr9D06bWOAxXRBdsEHXzeMxIQM3oECHIQAA..i&w=720&h=486&hcb=2&ved=2ahUKEwiqr9D06bWOAxXRBdsEHXzeMxIQM3oECHIQAA',
            alt: 'Mercimek Çorbası',
            isPrimary: true,
          ),
        ],
        allergens: ['gluten'],
        tags: ['vegetarian', 'healthy'],
        isActive: true,
        isAvailable: true,
        sortOrder: 0,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Ana Yemekler
      Product(
        productId: 'prod-2',
        businessId: widget.businessId,
        categoryId: 'cat-2',
        name: 'Adana Kebap',
        description: 'Acılı kıyma kebabı',
        detailedDescription:
            'Özel baharatlarla hazırlanan acılı kıyma kebabı, közde pişirilir',
        price: 85.0,
        currentPrice: 75.0,
        currency: 'TL',
        images: [
          ProductImage(
            url:
                'https://www.google.com/imgres?q=adana%20kebab&imgurl=https%3A%2F%2Fturkishfoodie.com%2Fwp-content%2Fuploads%2F2018%2F11%2FAdana-Kebab-.jpg&imgrefurl=https%3A%2F%2Fturkishfoodie.com%2Fadana-kebab%2F&docid=DVKiJ4tH1RXwJM&tbnid=4ggWWHcPP_e9qM&vet=12ahUKEwjyhNOD6rWOAxU6QvEDHasHIXwQM3oECBsQAA..i&w=1000&h=563&hcb=2&ved=2ahUKEwjyhNOD6rWOAxU6QvEDHasHIXwQM3oECBsQAA',
            alt: 'Adana Kebap',
            isPrimary: true,
          ),
        ],
        allergens: [],
        tags: ['spicy', 'popular', 'halal'],
        isActive: true,
        isAvailable: true,
        sortOrder: 0,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Tatlılar
      Product(
        productId: 'prod-3',
        businessId: widget.businessId,
        categoryId: 'cat-3',
        name: 'Baklava',
        description: 'Fıstıklı baklava',
        detailedDescription:
            'El açması yufka, Antep fıstığı ve şerbetli geleneksel baklava',
        price: 45.0,
        currentPrice: 45.0,
        currency: 'TL',
        images: [
          ProductImage(
            url:
                'https://www.google.com/imgres?q=baklava&imgurl=https%3A%2F%2Fassets.tmecosys.com%2Fimage%2Fupload%2Ft_web_rdp_recipe_584x480%2Fimg%2Frecipe%2Fras%2FAssets%2F5b3a4f1ef35536dd44ed1a64ed55f2f2%2FDerivates%2F78efec556a9f9d444cae9fac03247ba34195c621.jpg&imgrefurl=https%3A%2F%2Fcookidoo.com.tr%2Frecipes%2Frecipe%2Ftr-TR%2Fr776048&docid=4qMJCqUkrlvh1M&tbnid=JI0CHmQ-0b6SEM&vet=12ahUKEwidia-a6rWOAxU2QfEDHR1rL_MQM3oECBoQAA..i&w=584&h=480&hcb=2&ved=2ahUKEwidia-a6rWOAxU2QfEDHR1rL_MQM3oECBoQAA',
            alt: 'Baklava',
            isPrimary: true,
          ),
        ],
        allergens: ['gluten', 'nuts'],
        tags: ['signature', 'sweet'],
        isActive: true,
        isAvailable: true,
        sortOrder: 0,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // İçecekler
      Product(
        productId: 'prod-4',
        businessId: widget.businessId,
        categoryId: 'cat-4',
        name: 'Türk Kahvesi',
        description: 'Geleneksel Türk kahvesi',
        detailedDescription:
            'Kum ocağında özel olarak demlenen geleneksel Türk kahvesi',
        price: 18.0,
        currentPrice: 18.0,
        currency: 'TL',
        images: [
          ProductImage(
            url:
                'https://assets.tmecosys.com/image/upload/t_web_rdp_recipe_584x480_1_5x/img/recipe/ras/Assets/3023b33a98962390f6fb802e547df3e5/Derivates/854efe88e5fffacf944a6a5607de78fe02c083b9.jpg',
            alt: 'Türk Kahvesi',
            isPrimary: true,
          ),
        ],
        allergens: [],
        tags: ['traditional', 'signature'],
        isActive: true,
        isAvailable: true,
        sortOrder: 0,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
 