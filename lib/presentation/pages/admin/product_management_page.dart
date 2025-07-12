import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// CachedNetworkImage removed for Windows compatibility
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import '../../widgets/shared/empty_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/product.dart';
import '../../../data/models/category.dart';
import '../../../data/models/discount.dart';
import '../../../core/services/data_service.dart';

class ProductManagementPage extends StatefulWidget {
  final String businessId;

  const ProductManagementPage({Key? key, required this.businessId})
    : super(key: key);

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Discount> _discounts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategoryId = '';
  String _viewMode = 'grid'; // 'grid' or 'list'

  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _dataService.initialize();
      await _dataService.initializeSampleData();

      final categories = await _dataService.getCategories(
        businessId: widget.businessId,
      );
      final products = await _dataService.getProducts(
        businessId: widget.businessId,
      );
      final discounts = await _dataService.getDiscountsByBusinessId(
        widget.businessId,
      );

      setState(() {
        _categories = categories;
        _products = products;
        _discounts = discounts;
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
        Expanded(child: _buildProductList()),
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
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
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
            flex: 3,
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

                // Status badge
                Positioned(top: 8, right: 8, child: _buildStatusBadge(product)),

                // Actions
                Positioned(top: 8, left: 8, child: _buildQuickActions(product)),
              ],
            ),
          ),

          // Product info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Category
                  Text(
                    _getCategoryName(product.categoryId),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const Spacer(),

                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} ₺',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.priceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handleProductAction(value, product),
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
                          PopupMenuItem(
                            value: 'toggle',
                            child: ListTile(
                              leading: Icon(
                                product.isAvailable
                                    ? Icons.visibility_off
                                    : Icons.visibility,
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
            Row(
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
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
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
      orElse: () => Category(
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
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    final priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    String selectedCategoryId =
        product?.categoryId ?? _categories.first.categoryId;
    bool isAvailable = product?.isAvailable ?? true;
    List<String> imageUrls = List.from(
      product?.images.map((img) => img.url) ?? [],
    );
    final imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Ürün Düzenle' : 'Ürün Ekle'),
          content: SingleChildScrollView(
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
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category.categoryId,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    }
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
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.greyLight,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrls[index],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.image,
                                                size: 40,
                                                color: AppColors.greyLight,
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          imageUrls.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
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

                    // Yeni resim ekleme
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: imageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Resim URL\'si',
                              hintText: 'https://example.com/image.jpg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (imageUrlController.text.trim().isNotEmpty) {
                              setState(() {
                                imageUrls.add(imageUrlController.text.trim());
                                imageUrlController.clear();
                              });
                            }
                          },
                          child: const Text('Ekle'),
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
                          setState,
                          imageUrls,
                        ),
                        _buildSampleImageButton(
                          '🍔 Burger',
                          'https://picsum.photos/400/300?random=2',
                          setState,
                          imageUrls,
                        ),
                        _buildSampleImageButton(
                          '🥗 Salata',
                          'https://picsum.photos/400/300?random=3',
                          setState,
                          imageUrls,
                        ),
                        _buildSampleImageButton(
                          '🍝 Makarna',
                          'https://picsum.photos/400/300?random=4',
                          setState,
                          imageUrls,
                        ),
                      ],
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
                    setState(() {
                      isAvailable = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty &&
                    priceController.text.trim().isNotEmpty) {
                  final price =
                      double.tryParse(priceController.text.trim()) ?? 0;
                  await _saveProduct(
                    product,
                    nameController.text.trim(),
                    descriptionController.text.trim(),
                    price,
                    selectedCategoryId,
                    isAvailable,
                    imageUrls,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Güncelle' : 'Ekle'),
            ),
          ],
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

      await _dataService.saveDiscount(discount);
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
    Function setState,
    List<String> imageUrls,
  ) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
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

  Future<void> _saveProduct(
    Product? product,
    String name,
    String description,
    double price,
    String categoryId,
    bool isAvailable,
    List<String> imageUrls,
  ) async {
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
          allergens: [],
          tags: [],
          isActive: true,
          isAvailable: isAvailable,
          sortOrder: _products.length,
          timeRules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _dataService.saveProduct(newProduct);

        setState(() {
          _products.add(newProduct);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name ürünü eklendi'),
              backgroundColor: AppColors.success,
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
          updatedAt: DateTime.now(),
        );

        await _dataService.saveProduct(updatedProduct);

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
              content: Text('$name ürünü güncellendi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
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

      await _dataService.saveProduct(updatedProduct);

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

      await _dataService.saveProduct(updatedProduct);

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
      await _dataService.deleteProduct(product.productId);

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
    ];
  }

  List<Product> _createSampleProducts() {
    return [
      Product(
        productId: 'prod-1',
        businessId: widget.businessId,
        categoryId: 'cat-1',
        name: 'Mercimek Çorbası',
        description: 'Geleneksel mercimek çorbası',
        detailedDescription: 'Geleneksel mercimek çorbası, sıcak servis edilir',
        price: 15.00,
        currentPrice: 15.00,
        currency: 'TL',
        images: [
          ProductImage(
            url: 'https://picsum.photos/400/300?random=1',
            alt: 'Mercimek Çorbası',
            isPrimary: true,
          ),
        ],
        nutritionInfo: NutritionInfo(
          calories: 120.0,
          protein: 6.0,
          carbs: 20.0,
          fat: 2.0,
          fiber: 4.0,
          sugar: 3.0,
          sodium: 580.0,
        ),
        allergens: [],
        tags: ['hot', 'healthy'],
        isActive: true,
        isAvailable: true,
        sortOrder: 0,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        productId: 'prod-2',
        businessId: widget.businessId,
        categoryId: 'cat-2',
        name: 'Adana Kebap',
        description: 'Acılı kıyma kebabı',
        detailedDescription: 'Acılı kıyma kebabı, ızgara servis edilir',
        price: 45.00,
        currentPrice: 40.50, // 10% discount
        currency: 'TL',
        images: [
          ProductImage(
            url: 'https://picsum.photos/400/300?random=2',
            alt: 'Adana Kebap',
            isPrimary: true,
          ),
        ],
        allergens: [],
        tags: ['spicy', 'popular'],
        isActive: true,
        isAvailable: true,
        sortOrder: 0,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        productId: 'prod-3',
        businessId: widget.businessId,
        categoryId: 'cat-3',
        name: 'Baklava',
        description: 'Antep fıstıklı baklava',
        detailedDescription: 'Antep fıstıklı baklava, ev yapımı',
        price: 25.00,
        currentPrice: 25.00,
        currency: 'TL',
        images: [
          ProductImage(
            url: 'https://picsum.photos/400/300?random=3',
            alt: 'Baklava',
            isPrimary: true,
          ),
        ],
        allergens: ['nuts', 'gluten'],
        tags: ['sweet', 'traditional'],
        isActive: true,
        isAvailable: false,
        sortOrder: 0,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
