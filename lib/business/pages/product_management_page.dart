import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/url_service.dart';
import '../../core/mixins/url_mixin.dart';
import '../models/product.dart';
import '../models/category.dart' as category_model;
import '../models/discount.dart';
import '../../core/services/storage_service.dart';
import '../services/business_firestore_service.dart';
import 'product_edit_page.dart';

class ProductManagementPage extends StatefulWidget {
  final String businessId;

  const ProductManagementPage({Key? key, required this.businessId})
      : super(key: key);

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage>
    with TickerProviderStateMixin, UrlMixin {
  final BusinessFirestoreService _businessFirestoreService = BusinessFirestoreService();
  final StorageService _storageService = StorageService();
  final UrlService _urlService = UrlService();
  final ImagePicker _imagePicker = ImagePicker();

  List<Product> _products = [];
  List<category_model.Category> _categories = [];
  List<Discount> _discounts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategoryId = '';
  String _viewMode = 'grid'; // 'grid' or 'list'

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();

    // Update URL for product management
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlService.updateBusinessUrl(widget.businessId, 'urunler');
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load products, categories and discounts in parallel
      final futures = await Future.wait([
        _businessFirestoreService.getBusinessProducts(widget.businessId, limit: 100),
        _businessFirestoreService.getBusinessCategories(widget.businessId),
        _businessFirestoreService.getDiscounts(businessId: widget.businessId),
      ]);

      setState(() {
        _products = futures[0] as List<Product>;
        _categories = futures[1] as List<category_model.Category>;
        _discounts = futures[2] as List<Discount>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Ürün Yönetimi',
        style: AppTypography.h3.copyWith(color: AppColors.white),
      ),
      backgroundColor: AppColors.primary,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _viewMode == 'grid' ? Icons.view_list : Icons.view_module,
            color: AppColors.white,
          ),
          onPressed: _toggleViewMode,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    return Column(
      children: [
        // Search and filter section
        _buildSearchAndFilterSection(),

        // Product stats
        _buildProductStats(),

        // Product list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _buildProductList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.greyLight,
            ),
          ),

          const SizedBox(height: 16),

          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryChip(
                    'Tümü',
                    '',
                    isSelected: _selectedCategoryId.isEmpty,
                  );
                }
                final category = _categories[index - 1];
                return _buildCategoryChip(
                  category.name,
                  category.categoryId,
                  isSelected: _selectedCategoryId == category.categoryId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    String name,
    String categoryId, {
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategoryId = selected ? categoryId : '';
          });
        },
        backgroundColor: AppColors.greyLight,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: AppTypography.bodySmall.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildProductStats() {
    final filteredProducts = _getFilteredProducts();
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Toplam', '${_products.length}', AppColors.primary),
          _buildStatItem(
            'Aktif',
            '${_products.where((p) => p.isAvailable).length}',
            AppColors.success,
          ),
          _buildStatItem(
            'Pasif',
            '${_products.where((p) => !p.isAvailable).length}',
            AppColors.error,
          ),
          _buildStatItem(
            'Filtrelenmiş',
            '${filteredProducts.length}',
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProductList() {
    final filteredProducts = _getFilteredProducts();

    if (filteredProducts.isEmpty) {
      return EmptyState(
        icon: Icons.restaurant_menu,
        title: 'Ürün Bulunamadı',
        message: _searchQuery.isEmpty && _selectedCategoryId.isEmpty
            ? 'Henüz ürün eklenmemiş.'
            : 'Aradığınız kriterlere uygun ürün bulunamadı.',
        actionText: _searchQuery.isEmpty && _selectedCategoryId.isEmpty
            ? 'Ürün Ekle'
            : 'Filtreleri Temizle',
        onActionPressed: _searchQuery.isEmpty && _selectedCategoryId.isEmpty
            ? _showAddProductDialog
            : _clearFilters,
      );
    }

    return _viewMode == 'grid'
        ? _buildProductGrid(filteredProducts)
        : _buildProductListView(filteredProducts);
  }

  Widget _buildProductGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductListView(List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductListTile(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: AppColors.greyLight,
                  ),
                  child: product.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            product.images.first.url,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildImagePlaceholder();
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImagePlaceholder(),
                          ),
                        )
                      : _buildImagePlaceholder(),
                ),

                // Status badge
                Positioned(top: 6, right: 6, child: _buildStatusBadge(product)),

                // Actions
                Positioned(top: 6, left: 6, child: _buildQuickActions(product)),
              ],
            ),
          ),

          // Product info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product name and category
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getCategoryName(product.categoryId),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Price and actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${product.price.toStringAsFixed(2)} ₺',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.priceColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        onSelected: (value) =>
                            _handleProductAction(value, product),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit, size: 18),
                              title: Text('Düzenle'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'price',
                            child: ListTile(
                              leading: Icon(Icons.price_change, size: 18),
                              title: Text('Fiyat Güncelle'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: ListTile(
                              leading: Icon(
                                product.isAvailable
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                              ),
                              title: Text(
                                product.isAvailable ? 'Pasif Yap' : 'Aktif Yap',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete,
                                color: AppColors.error,
                                size: 18,
                              ),
                              title: Text(
                                'Sil',
                                style: TextStyle(color: AppColors.error),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListTile(Product product) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColors.greyLight,
          ),
          child: product.images.isNotEmpty
              ? Image.network(
                  product.images.first.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildImagePlaceholder();
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),
        ),
        title: Text(
          product.name,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getCategoryName(product.categoryId),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Price with discount info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current price
                    Text(
                      '${product.currentPrice.toStringAsFixed(2)} ₺',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.priceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Original price if discounted
                    if (product.hasDiscount)
                      Text(
                        '${product.price.toStringAsFixed(2)} ₺',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                // Discount badge
                if (product.hasDiscount)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.formattedDiscountPercentage,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                _buildStatusBadge(product),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProductAction(value, product),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Düzenle'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'price',
              child: ListTile(
                leading: Icon(Icons.price_change),
                title: Text('Fiyat Güncelle'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'discount',
              child: ListTile(
                leading: Icon(Icons.local_offer),
                title: Text('İndirim Ekle'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(
                  product.isAvailable ? Icons.visibility_off : Icons.visibility,
                ),
                title: Text(product.isAvailable ? 'Pasif Yap' : 'Aktif Yap'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text('Sil', style: TextStyle(color: AppColors.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 32,
          color: AppColors.textLight,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Product product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: product.isAvailable
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        product.isAvailable ? 'Aktif' : 'Pasif',
        style: AppTypography.bodySmall.copyWith(
          color: product.isAvailable ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickActions(Product product) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.black,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, color: AppColors.white, size: 16),
            onPressed: () => _showEditProductDialog(product),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.price_change,
              color: AppColors.white,
              size: 16,
            ),
            onPressed: () => _showPriceUpdateDialog(product),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showAddProductDialog,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: AppColors.white),
    );
  }

  List<Product> _getFilteredProducts() {
    return _products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategoryId.isEmpty ||
          product.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  String _getCategoryName(String categoryId) {
    final category = _categories.firstWhere(
      (c) => c.categoryId == categoryId,
      orElse: () => category_model.Category(
        categoryId: '',
        businessId: '',
        name: 'Bilinmeyen',
        description: '',
        sortOrder: 0,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return category.name;
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategoryId = '';
    });
  }

  void _handleProductAction(String action, Product product) {
    switch (action) {
      case 'edit':
        _showEditProductDialog(product);
        break;
      case 'price':
        _showPriceUpdateDialog(product);
        break;
      case 'discount':
        _showDiscountDialog(product);
        break;
      case 'toggle':
        _toggleProductStatus(product);
        break;
      case 'delete':
        _showDeleteConfirmation(product);
        break;
    }
  }

  void _showAddProductDialog() {
    _showProductDialog(null);
  }

  void _showEditProductDialog(Product product) {
    _showProductDialog(product);
  }

  void _showProductDialog(Product? product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductEditPage(
          businessId: widget.businessId,
          product: product,
          categories: _categories,
          onProductSaved: () {
            _loadData(); // Refresh the product list
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _showLegacyProductDialog(Product? product) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    final priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    // Get unique categories for dropdown
    final uniqueCategories = <String, category_model.Category>{};
    for (final category in _categories) {
      uniqueCategories[category.categoryId] = category;
    }
    
    String selectedCategoryId = product?.categoryId ?? '';
    // Validate selected category exists in unique categories
    if (selectedCategoryId.isNotEmpty && !uniqueCategories.containsKey(selectedCategoryId)) {
      selectedCategoryId = '';
    }
    // Set default if empty and categories available
    if (selectedCategoryId.isEmpty && uniqueCategories.isNotEmpty) {
      selectedCategoryId = uniqueCategories.values.first.categoryId;
    }
    bool isAvailable = product?.isAvailable ?? true;
    List<String> imageUrls = List.from(
      product?.images.map((img) => img.url) ?? [],
    );
    List<String> selectedAllergens = List.from(product?.allergens ?? []);
    bool _isDialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental closing
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => WillPopScope(
          onWillPop: () async => !_isDialogLoading,
          child: AlertDialog(
            title: Text(isEditing ? 'Ürün Düzenle' : 'Ürün Ekle'),
            content: _isDialogLoading
                ? SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('İşlem yapılıyor...'),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ürün Adı',
                            hintText: 'Örn: Adana Kebap',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Açıklama',
                            hintText: 'Ürün açıklaması',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Fiyat (₺)',
                            hintText: '0.00',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedCategoryId.isEmpty ? null : selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                          ),
                          items: uniqueCategories.values.map((category) {
                            return DropdownMenuItem(
                              value: category.categoryId,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedCategoryId = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Kategori seçimi zorunludur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Resim ekleme bölümü
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ürün Resimleri',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),

                            // Mevcut resimler
                            if (imageUrls.isNotEmpty)
                              Container(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: imageUrls.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 100,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors.greyLight,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                imageUrls[index],
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return const Icon(
                                                        Icons.image,
                                                        size: 40,
                                                        color:
                                                            AppColors.greyLight,
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),

                                          // Düzenle butonu
                                          Positioned(
                                            top: 4,
                                            left: 4,
                                            child: InkWell(
                                              onTap: () {
                                                _showImageEditDialog(
                                                  context,
                                                  imageUrls[index],
                                                  (editedUrl) {
                                                    setDialogState(() {
                                                      imageUrls[index] =
                                                          editedUrl;
                                                    });
                                                  },
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.edit,
                                                  color: AppColors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Sil butonu
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: InkWell(
                                              onTap: () {
                                                setDialogState(() {
                                                  imageUrls.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.error,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: AppColors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                            const SizedBox(height: 8),

                            // Resim ekleme seçenekleri
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showImagePickerDialog(context, (
                                        imageUrl,
                                      ) {
                                        setDialogState(() {
                                          imageUrls.add(imageUrl);
                                        });
                                      });
                                    },
                                    icon: const Icon(Icons.add_photo_alternate),
                                    label: const Text('Resim Ekle'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _showBulkImageDialog(context, (urls) {
                                        setDialogState(() {
                                          imageUrls.addAll(urls);
                                        });
                                      });
                                    },
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Toplu Ekle'),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Örnek resim butonları
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildSampleImageButton(
                                  '🍕 Pizza',
                                  'https://picsum.photos/400/300?random=1',
                                  setDialogState,
                                  imageUrls,
                                ),
                                _buildSampleImageButton(
                                  '🍔 Burger',
                                  'https://picsum.photos/400/300?random=2',
                                  setDialogState,
                                  imageUrls,
                                ),
                                _buildSampleImageButton(
                                  '🥗 Salata',
                                  'https://picsum.photos/400/300?random=3',
                                  setDialogState,
                                  imageUrls,
                                ),
                                _buildSampleImageButton(
                                  '🍝 Makarna',
                                  'https://picsum.photos/400/300?random=4',
                                  setDialogState,
                                  imageUrls,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Alerjen seçimi
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alerjenler',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bu ürünün içerdiği alerjenleri seçin',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: ProductAllergen.values.map((allergen) {
                                final isSelected = selectedAllergens.contains(
                                  allergen.value,
                                );
                                return FilterChip(
                                  label: Text(allergen.displayName),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setDialogState(() {
                                      if (selected) {
                                        selectedAllergens.add(allergen.value);
                                      } else {
                                        selectedAllergens.remove(
                                          allergen.value,
                                        );
                                      }
                                    });
                                  },
                                  selectedColor: AppColors.error.withOpacity(
                                    0.2,
                                  ),
                                  checkmarkColor: AppColors.error,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Aktif'),
                          subtitle: Text(
                            isAvailable
                                ? 'Ürün müşteriler tarafından görülecek'
                                : 'Ürün gizli olacak',
                          ),
                          value: isAvailable,
                          onChanged: (value) {
                            setDialogState(() {
                              isAvailable = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: _isDialogLoading
                    ? null
                    : () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: _isDialogLoading
                    ? null
                    : () async {
                        if (nameController.text.trim().isNotEmpty &&
                            priceController.text.trim().isNotEmpty) {
                          setDialogState(() {
                            _isDialogLoading = true;
                          });

                          try {
                            final price =
                                double.tryParse(priceController.text.trim()) ??
                                0;
                            await _saveProduct(
                              product,
                              nameController.text.trim(),
                              descriptionController.text.trim(),
                              price,
                              selectedCategoryId,
                              isAvailable,
                              imageUrls,
                              selectedAllergens,
                            );
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            setDialogState(() {
                              _isDialogLoading = false;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata oluştu: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                child: _isDialogLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Güncelle' : 'Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriceUpdateDialog(Product product) {
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final discountController = TextEditingController(
      text: product.discountPercentage.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fiyat Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Fiyat (₺)',
                hintText: '0.00',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(
                labelText: 'İndirim (%)',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price =
                  double.tryParse(priceController.text.trim()) ?? product.price;
              final discount =
                  double.tryParse(discountController.text.trim()) ??
                  product.discountPercentage;
              await _updateProductPrice(product, price, discount);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(Product product) {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    DiscountType selectedType = DiscountType.percentage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${product.name} için İndirim Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'İndirim Adı',
                  hintText: 'Örn: Özel İndirim',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<DiscountType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Tür'),
                      items: DiscountType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type == DiscountType.percentage
                                ? 'Yüzde (%)'
                                : 'Sabit (₺)',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: valueController,
                      decoration: InputDecoration(
                        labelText: 'Değer',
                        suffixText: selectedType == DiscountType.percentage
                            ? '%'
                            : '₺',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mevcut Fiyat: ${product.price.toStringAsFixed(2)} ₺',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (valueController.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Yeni Fiyat: ${_calculateDiscountedPrice(product.price, selectedType, valueController.text).toStringAsFixed(2)} ₺',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => _createProductDiscount(
                product,
                nameController.text.trim(),
                selectedType,
                valueController.text.trim(),
              ),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDiscountedPrice(
    double originalPrice,
    DiscountType type,
    String value,
  ) {
    final numValue = double.tryParse(value) ?? 0;
    if (type == DiscountType.percentage) {
      return originalPrice * (1 - numValue / 100);
    } else {
      return originalPrice - numValue;
    }
  }

  Future<void> _createProductDiscount(
    Product product,
    String name,
    DiscountType type,
    String value,
  ) async {
    if (name.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final numValue = double.tryParse(value);
    if (numValue == null || numValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir indirim değeri girin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final discount = Discount(
        discountId: 'discount-${DateTime.now().millisecondsSinceEpoch}',
        businessId: widget.businessId,
        name: name,
        description: '${product.name} için özel indirim',
        type: type,
        value: numValue,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        targetProductIds: [product.productId],
        targetCategoryIds: [],
        timeRules: [],
        minOrderAmount: 0,
        maxDiscountAmount: type == DiscountType.percentage
            ? (product.price * numValue / 100)
            : numValue,
        usageLimit: 0,
        usageCount: 0,
        isActive: true,
        combineWithOtherDiscounts: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _businessFirestoreService.saveDiscount(discount);
      await _loadData(); // Reload data to refresh UI

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} için indirim eklendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İndirim eklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildSampleImageButton(
    String label,
    String imageUrl,
    Function setDialogState,
    List<String> imageUrls,
  ) {
    return ElevatedButton(
      onPressed: () {
        setDialogState(() {
          if (!imageUrls.contains(imageUrl)) {
            imageUrls.add(imageUrl);
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _showImagePickerDialog(
    BuildContext context,
    Function(String) onImageSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resim Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('URL\'den Ekle'),
              subtitle: const Text('İnternetteki bir resim linkini kullan'),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog(context, onImageSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              subtitle: const Text('Yeni fotoğraf çek'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera(onImageSelected);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlInputDialog(
    BuildContext context,
    Function(String) onImageSelected,
  ) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL\'den Resim Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Resim URL\'si',
                hintText: 'https://example.com/image.jpg',
              ),
            ),
            const SizedBox(height: 16),
            if (urlController.text.isNotEmpty)
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.greyLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    urlController.text,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: AppColors.greyLight,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                onImageSelected(urlController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showSampleImagesDialog(
    BuildContext context,
    Function(String) onImageSelected,
  ) {
    final storageService = StorageService();
    final predefinedImages = storageService.getPredefinedProductImages();
    
    final List<Map<String, String>> sampleImages = [];
    predefinedImages.forEach((category, urls) {
      for (int i = 0; i < urls.length; i++) {
        sampleImages.add({
          'label': '$category ${i + 1}',
          'url': urls[i],
        });
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Örnek Resimler'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemCount: sampleImages.length,
            itemBuilder: (context, index) {
              final image = sampleImages[index];
              return InkWell(
                onTap: () {
                  onImageSelected(image['url']!);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyLight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Image.network(
                            image['url']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          image['label']!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera(Function(String) onImageSelected) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        // Web için file path'i direkt kullan, mobil için path'i url olarak kullan
        final imagePath = image.path;
        onImageSelected(imagePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fotoğraf başarıyla çekildi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromFile(Function(String) onImageSelected) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        try {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Resim yükleniyor...'),
                ],
              ),
            ),
          );

          final storageService = StorageService();
          String uploadedUrl;

          if (file.bytes != null) {
            // Web platform
            final fileName = storageService.generateFileName(file.name);
            uploadedUrl = await storageService.uploadProductImage(
              businessId: widget.businessId,
              productId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
              imageFile: file.bytes!,
              fileName: fileName,
            );
          } else if (file.path != null) {
            // Mobile platform
            final fileName = storageService.generateFileName(file.name);
            uploadedUrl = await storageService.uploadProductImage(
              businessId: widget.businessId,
              productId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
              imageFile: File(file.path!),
              fileName: fileName,
            );
          } else {
            throw Exception('Dosya verisi bulunamadı');
          }

          // Close loading dialog
          if (mounted) Navigator.of(context).pop();
          
          onImageSelected(uploadedUrl);
        } catch (e) {
          // Close loading dialog
          if (mounted) Navigator.of(context).pop();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Resim yüklenirken hata: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dosya başarıyla seçildi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya seçme hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showBulkImageDialog(
    BuildContext context,
    Function(List<String>) onImagesSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Resim Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Birden fazla resim eklemek için seçenekler:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Yemek Kategorisi'),
              subtitle: const Text('Hazır yemek resimleri ekle'),
              onTap: () {
                Navigator.pop(context);
                onImagesSelected([
                  'https://picsum.photos/400/300?random=1',
                  'https://picsum.photos/400/300?random=2',
                  'https://picsum.photos/400/300?random=3',
                ]);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_drink),
              title: const Text('İçecek Kategorisi'),
              subtitle: const Text('Hazır içecek resimleri ekle'),
              onTap: () {
                Navigator.pop(context);
                onImagesSelected([
                  'https://picsum.photos/400/300?random=4',
                  'https://picsum.photos/400/300?random=5',
                  'https://picsum.photos/400/300?random=6',
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageEditDialog(
    BuildContext context,
    String imageUrl,
    Function(String) onImageEdited,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resim Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: AppColors.greyLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Düzenleme özellikleri:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: const Text('Kırp'),
                  avatar: const Icon(Icons.crop, size: 18),
                  onDeleted: () {
                    // Kırpma özelliği
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kırpma özelliği yakında eklenecek'),
                      ),
                    );
                  },
                ),
                Chip(
                  label: const Text('Döndür'),
                  avatar: const Icon(Icons.rotate_right, size: 18),
                  onDeleted: () {
                    // Döndürme özelliği
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Döndürme özelliği yakında eklenecek'),
                      ),
                    );
                  },
                ),
                Chip(
                  label: const Text('Filtre'),
                  avatar: const Icon(Icons.filter_alt, size: 18),
                  onDeleted: () {
                    // Filtre özelliği
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Filtre özelliği yakında eklenecek'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Şimdilik orijinal URL'i geri döndür
              onImageEdited(imageUrl);
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct(
    Product? product,
    String name,
    String description,
    double price,
    String categoryId,
    bool isAvailable,
    List<String> imageUrls,
    List<String> allergens,
  ) async {
    // Validation
    if (name.trim().isEmpty) {
      throw Exception('Ürün adı boş olamaz');
    }
    if (price <= 0) {
      throw Exception('Fiyat sıfırdan büyük olmalıdır');
    }
    if (categoryId.isEmpty) {
      throw Exception('Kategori seçilmelidir');
    }

    // Add delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      if (product == null) {
        // Add new product
        final newProduct = Product(
          productId: 'prod-${DateTime.now().millisecondsSinceEpoch}',
          businessId: widget.businessId,
          categoryId: categoryId,
          name: name,
          description: description,
          detailedDescription: description,
          price: price,
          currentPrice: price,
          currency: 'TL',
          images: imageUrls
              .map(
                (url) => ProductImage(
                  url: url,
                  alt: name,
                  isPrimary: imageUrls.indexOf(url) == 0,
                ),
              )
              .toList(),
          allergens: allergens,
          tags: [],
          isActive: true,
          isAvailable: isAvailable,
          sortOrder: _products.length,
          timeRules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _businessFirestoreService.saveProduct(newProduct);

        if (mounted) {
          setState(() {
            _products.add(newProduct);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name ürünü başarıyla eklendi'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Update existing product
        final updatedProduct = product.copyWith(
          name: name,
          description: description,
          detailedDescription: description,
          price: price,
          currentPrice: price,
          categoryId: categoryId,
          isAvailable: isAvailable,
          images: imageUrls
              .map(
                (url) => ProductImage(
                  url: url,
                  alt: name,
                  isPrimary: imageUrls.indexOf(url) == 0,
                ),
              )
              .toList(),
          allergens: allergens,
          updatedAt: DateTime.now(),
        );

        await _businessFirestoreService.saveProduct(updatedProduct);

        if (mounted) {
          final index = _products.indexWhere(
            (p) => p.productId == product.productId,
          );
          if (index != -1) {
            setState(() {
              _products[index] = updatedProduct;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name ürünü başarıyla güncellendi'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      rethrow; // Let the dialog handle the error
    }
  }

  Future<void> _updateProductPrice(
    Product product,
    double price,
    double discount,
  ) async {
    try {
      final discountedPrice = price * (1 - discount / 100);
      final updatedProduct = product.copyWith(
        price: price,
        currentPrice: discountedPrice,
        updatedAt: DateTime.now(),
      );

      await _businessFirestoreService.saveProduct(updatedProduct);

      final index = _products.indexWhere(
        (p) => p.productId == product.productId,
      );
      if (index != -1) {
        setState(() {
          _products[index] = updatedProduct;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} fiyatı güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleProductStatus(Product product) async {
    try {
      final updatedProduct = product.copyWith(
        isAvailable: !product.isAvailable,
        updatedAt: DateTime.now(),
      );

      await _businessFirestoreService.saveProduct(updatedProduct);

      final index = _products.indexWhere(
        (p) => p.productId == product.productId,
      );
      if (index != -1) {
        setState(() {
          _products[index] = updatedProduct;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${product.name} ${product.isAvailable ? 'pasif' : 'aktif'} yapıldı',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürün Sil'),
        content: Text(
          '${product.name} ürünunu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteProduct(product);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      await _businessFirestoreService.deleteProduct(product.productId);

      setState(() {
        _products.removeWhere((p) => p.productId == product.productId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} ürünü silindi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
