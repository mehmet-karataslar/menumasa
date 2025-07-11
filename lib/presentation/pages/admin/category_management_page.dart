import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import '../../widgets/shared/empty_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/category.dart';
import '../../../core/services/data_service.dart';

class CategoryManagementPage extends StatefulWidget {
  final String businessId;

  const CategoryManagementPage({Key? key, required this.businessId})
    : super(key: key);

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isReordering = false;
  String _searchQuery = '';

  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _dataService.initialize();
      await _dataService.initializeSampleData();

      final categories = await _dataService.getCategories(
        businessId: widget.businessId,
      );

      setState(() {
        _categories = categories;
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
        'Kategori Yönetimi',
        style: AppTypography.h3.copyWith(color: AppColors.white),
      ),
      backgroundColor: AppColors.primary,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _isReordering ? Icons.check : Icons.reorder,
            color: AppColors.white,
          ),
          onPressed: _toggleReordering,
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
        _buildSearchSection(),

        // Category list
        Expanded(child: _buildCategoryList()),
      ],
    );
  }

  Widget _buildSearchSection() {
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
              hintText: 'Kategori ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.greyLight,
            ),
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                'Toplam',
                '${_categories.length}',
                AppColors.primary,
              ),
              _buildStatChip(
                'Aktif',
                '${_categories.where((c) => c.isActive).length}',
                AppColors.success,
              ),
              _buildStatChip(
                'Pasif',
                '${_categories.where((c) => !c.isActive).length}',
                AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final filteredCategories = _categories.where((category) {
      return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredCategories.isEmpty) {
      return EmptyState(
        icon: Icons.category,
        title: 'Kategori Bulunamadı',
        message: _searchQuery.isEmpty
            ? 'Henüz kategori eklenmemiş.'
            : 'Aradığınız kriterlere uygun kategori bulunamadı.',
        actionText: _searchQuery.isEmpty ? 'Kategori Ekle' : 'Aramayı Temizle',
        onActionPressed: _searchQuery.isEmpty
            ? _showAddCategoryDialog
            : () {
                setState(() {
                  _searchQuery = '';
                });
              },
      );
    }

    return _isReordering
        ? _buildReorderableList(filteredCategories)
        : _buildNormalList(filteredCategories);
  }

  Widget _buildNormalList(List<Category> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildReorderableList(List<Category> categories) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category, key: ValueKey(category.categoryId));
      },
    );
  }

  Widget _buildCategoryCard(Category category, {Key? key}) {
    return Card(
      key: key,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildCategoryIcon(category),
        title: Text(
          category.name,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                category.description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _buildCategoryMetadata(category),
          ],
        ),
        trailing: _isReordering
            ? const Icon(Icons.drag_handle)
            : _buildCategoryActions(category),
      ),
    );
  }

  Widget _buildCategoryIcon(Category category) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: category.isActive
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.textLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getCategoryIcon(category.name),
        color: category.isActive ? AppColors.primary : AppColors.textLight,
        size: 24,
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'çorbalar':
        return Icons.soup_kitchen;
      case 'ana yemekler':
        return Icons.restaurant_menu;
      case 'tatlılar':
        return Icons.cake;
      case 'içecekler':
        return Icons.local_drink;
      case 'başlangıçlar':
        return Icons.restaurant;
      case 'salatalar':
        return Icons.eco;
      default:
        return Icons.category;
    }
  }

  Widget _buildCategoryMetadata(Category category) {
    return Row(
      children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: category.isActive
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            category.isActive ? 'Aktif' : 'Pasif',
            style: AppTypography.bodySmall.copyWith(
              color: category.isActive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Sort order
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Sıra: ${category.sortOrder + 1}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.info,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryActions(Category category) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleCategoryAction(value, category),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Düzenle'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: ListTile(
            leading: Icon(
              category.isActive ? Icons.visibility_off : Icons.visibility,
            ),
            title: Text(category.isActive ? 'Pasif Yap' : 'Aktif Yap'),
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
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showAddCategoryDialog,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: AppColors.white),
    );
  }

  void _handleCategoryAction(String action, Category category) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(category);
        break;
      case 'toggle':
        _toggleCategoryStatus(category);
        break;
      case 'delete':
        _showDeleteConfirmation(category);
        break;
    }
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog(null);
  }

  void _showEditCategoryDialog(Category category) {
    _showCategoryDialog(category);
  }

  void _showCategoryDialog(Category? category) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    bool isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Kategori Düzenle' : 'Kategori Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı',
                  hintText: 'Örn: Ana Yemekler',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (İsteğe bağlı)',
                  hintText: 'Kategori açıklaması',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Aktif'),
                subtitle: Text(
                  isActive
                      ? 'Kategorii müşteriler görebilir'
                      : 'Kategori gizli',
                ),
                value: isActive,
                onChanged: (value) {
                  setState(() {
                    isActive = value;
                  });
                },
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
                if (nameController.text.trim().isNotEmpty) {
                  await _saveCategory(
                    category,
                    nameController.text.trim(),
                    descriptionController.text.trim(),
                    isActive,
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

  Future<void> _saveCategory(
    Category? category,
    String name,
    String description,
    bool isActive,
  ) async {
    try {
      if (category == null) {
        // Add new category
        final newCategory = Category(
          categoryId: 'cat-${DateTime.now().millisecondsSinceEpoch}',
          businessId: widget.businessId,
          name: name,
          description: description,
          sortOrder: _categories.length,
          isActive: isActive,
          timeRules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _dataService.saveCategory(newCategory);

        setState(() {
          _categories.add(newCategory);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name kategorisi eklendi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Update existing category
        final updatedCategory = category.copyWith(
          name: name,
          description: description,
          isActive: isActive,
          updatedAt: DateTime.now(),
        );

        await _dataService.saveCategory(updatedCategory);

        final index = _categories.indexWhere(
          (c) => c.categoryId == category.categoryId,
        );
        if (index != -1) {
          setState(() {
            _categories[index] = updatedCategory;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name kategorisi güncellendi'),
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

  Future<void> _toggleCategoryStatus(Category category) async {
    try {
      final updatedCategory = category.copyWith(
        isActive: !category.isActive,
        updatedAt: DateTime.now(),
      );

      await _dataService.saveCategory(updatedCategory);

      final index = _categories.indexWhere(
        (c) => c.categoryId == category.categoryId,
      );
      if (index != -1) {
        setState(() {
          _categories[index] = updatedCategory;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${category.name} ${category.isActive ? 'pasif' : 'aktif'} yapıldı',
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

  void _showDeleteConfirmation(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Sil'),
        content: Text(
          '${category.name} kategorisini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteCategory(category);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      await _dataService.deleteCategory(category.categoryId);

      setState(() {
        _categories.removeWhere((c) => c.categoryId == category.categoryId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.name} kategorisi silindi'),
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

  void _toggleReordering() {
    setState(() {
      _isReordering = !_isReordering;
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final category = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, category);

      // Update sort orders
      for (int i = 0; i < _categories.length; i++) {
        _categories[i] = _categories[i].copyWith(sortOrder: i);
      }
    });

    // Save updated sort orders
    try {
      for (final category in _categories) {
        await _dataService.saveCategory(category);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori sıralaması güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sıralama güncellenirken hata oluştu: $e'),
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
      Category(
        categoryId: 'cat-4',
        businessId: widget.businessId,
        name: 'İçecekler',
        description: 'Sıcak ve soğuk içecekler',
        sortOrder: 3,
        isActive: false,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        categoryId: 'cat-5',
        businessId: widget.businessId,
        name: 'Başlangıçlar',
        description: 'Meze ve başlangıç yemekleri',
        sortOrder: 4,
        isActive: true,
        timeRules: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
