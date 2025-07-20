import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/error_message.dart';
import '../../widgets/shared/empty_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/category.dart';
import '../../../data/models/discount.dart';
import '../../../core/services/firestore_service.dart';

class CategoryManagementPage extends StatefulWidget {
  final String businessId;

  const CategoryManagementPage({Key? key, required this.businessId})
    : super(key: key);

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Category> _categories = [];
  List<Discount> _discounts = [];
  bool _isLoading = true;
  bool _isReordering = false;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, active, inactive

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
      // Load categories and discounts in parallel
      final futures = await Future.wait([
        _firestoreService.getBusinessCategories(widget.businessId),
        _firestoreService.getDiscounts(businessId: widget.businessId),
      ]);

      setState(() {
        _categories = futures[0] as List<Category>;
        _discounts = futures[1] as List<Discount>;
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
      backgroundColor: AppColors.backgroundLight,
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    return Column(
      children: [
        // Header with stats and search
        _buildHeader(),

        // Filter tabs
        _buildFilterTabs(),

        // Category list
        Expanded(child: _buildCategoryList()),
      ],
    );
  }

  Widget _buildHeader() {
    final activeCount = _categories.where((c) => c.isActive).length;
    final inactiveCount = _categories.length - activeCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Kategori ara...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Toplam',
                  '${_categories.length}',
                  AppColors.primary,
                  Icons.category,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Aktif',
                  '$activeCount',
                  AppColors.success,
                  Icons.visibility,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pasif',
                  '$inactiveCount',
                  AppColors.error,
                  Icons.visibility_off,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildFilterChip('all', 'Tümü', _categories.length),
            const SizedBox(width: 8),
            _buildFilterChip('active', 'Aktif', _categories.where((c) => c.isActive).length),
            const SizedBox(width: 8),
            _buildFilterChip('inactive', 'Pasif', _categories.where((c) => !c.isActive).length),
            const SizedBox(width: 16),
            // Reorder button
            InkWell(
              onTap: _toggleReordering,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isReordering ? AppColors.primary : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isReordering ? AppColors.primary : AppColors.greyLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isReordering ? Icons.check : Icons.reorder,
                      color: _isReordering ? AppColors.white : AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isReordering ? 'Tamamla' : 'Sırala',
                      style: AppTypography.caption.copyWith(
                        color: _isReordering ? AppColors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, int count) {
    final isSelected = _selectedFilter == filter;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.white : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final filteredCategories = _getFilteredCategories();

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

  List<Category> _getFilteredCategories() {
    List<Category> filtered = _categories;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((category) {
        return category.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (category.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply status filter
    switch (_selectedFilter) {
      case 'active':
        filtered = filtered.where((c) => c.isActive).toList();
        break;
      case 'inactive':
        filtered = filtered.where((c) => !c.isActive).toList();
        break;
    }

    return filtered;
  }

  Widget _buildNormalList(List<Category> categories) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(category);
        },
      ),
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
    final categoryDiscounts = _discounts.where((d) => 
      d.applicableCategories.contains(category.categoryId) && d.isActive
    ).length;

    return Card(
      key: key,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _isReordering ? null : () => _showCategoryDetails(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon
              _buildCategoryIcon(category),
              
              const SizedBox(width: 16),
              
              // Category info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.categoryName,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(category),
                      ],
                    ),
                    
                    if (category.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Metadata
                    Row(
                      children: [
                        if (categoryDiscounts > 0) ...[
                          _buildInfoChip(
                            icon: Icons.local_offer,
                            label: '$categoryDiscounts indirim',
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildInfoChip(
                          icon: Icons.sort,
                          label: 'Sıra ${category.sortOrder + 1}',
                          color: AppColors.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              if (_isReordering)
                Icon(
                  Icons.drag_handle,
                  color: AppColors.textSecondary,
                )
              else
                _buildCategoryActions(category),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(Category category) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: category.isActive
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.textLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: category.isActive ? AppColors.primary.withOpacity(0.3) : AppColors.greyLight,
        ),
      ),
      child: Icon(
        _getCategoryIcon(category.categoryName),
        color: category.isActive ? AppColors.primary : AppColors.textLight,
        size: 28,
      ),
    );
  }

  Widget _buildStatusBadge(Category category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: category.isActive
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: category.isActive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Text(
        category.isActive ? 'Aktif' : 'Pasif',
        style: AppTypography.caption.copyWith(
          color: category.isActive ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('çorba')) return Icons.soup_kitchen;
    if (name.contains('ana') || name.contains('yemek')) return Icons.restaurant_menu;
    if (name.contains('tatlı') || name.contains('desert')) return Icons.cake;
    if (name.contains('içecek') || name.contains('drink')) return Icons.local_drink;
    if (name.contains('başlangıç') || name.contains('meze')) return Icons.restaurant;
    if (name.contains('salata')) return Icons.eco;
    if (name.contains('pizza')) return Icons.local_pizza;
    if (name.contains('burger')) return Icons.lunch_dining;
    if (name.contains('kahve') || name.contains('coffee')) return Icons.local_cafe;
    return Icons.category;
  }

  Widget _buildCategoryActions(Category category) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleCategoryAction(value, category),
      icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Detaylar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Düzenle'),
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
              category.isActive ? Icons.visibility_off : Icons.visibility,
            ),
            title: Text(category.isActive ? 'Pasif Yap' : 'Aktif Yap'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
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
    return FloatingActionButton.extended(
      onPressed: _showAddCategoryDialog,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      icon: const Icon(Icons.add),
      label: const Text('Kategori Ekle'),
    );
  }

  void _handleCategoryAction(String action, Category category) {
    switch (action) {
      case 'view':
        _showCategoryDetails(category);
        break;
      case 'edit':
        _showEditCategoryDialog(category);
        break;
      case 'discount':
        _showDiscountDialog(category);
        break;
      case 'toggle':
        _toggleCategoryStatus(category);
        break;
      case 'delete':
        _showDeleteConfirmation(category);
        break;
    }
  }

  void _showCategoryDetails(Category category) {
    final categoryDiscounts = _discounts.where((d) => 
      d.applicableCategories.contains(category.categoryId) && d.isActive
    ).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildCategoryIcon(category),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.categoryName,
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusBadge(category),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (category.description?.isNotEmpty == true) ...[
              Text(
                'Açıklama',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category.description!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    'Sıra',
                    '${category.sortOrder + 1}',
                    Icons.sort,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    'İndirimler',
                    '${categoryDiscounts.length}',
                    Icons.local_offer,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditCategoryDialog(category);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Düzenle'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDiscountDialog(category);
                    },
                    icon: const Icon(Icons.local_offer),
                    label: const Text('İndirim Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            
            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog(null);
  }

  void _showEditCategoryDialog(Category category) {
    _showCategoryDialog(category);
  }

  void _showCategoryDialog(Category? category) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.categoryName ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    bool isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit : Icons.add,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(isEditing ? 'Kategori Düzenle' : 'Kategori Ekle'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category name
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Kategori Adı *',
                    hintText: 'Örn: Ana Yemekler',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Kategori açıklaması (isteğe bağlı)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                
                const SizedBox(height: 16),
                
                // Active status
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyLight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SwitchListTile(
                    title: const Text('Aktif Kategori'),
                    subtitle: Text(
                      isActive
                          ? 'Kategori müşteriler tarafından görülebilir'
                          : 'Kategori gizli olacak',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                    activeColor: AppColors.success,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '* Zorunlu alan',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                  ),
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
                if (nameController.text.trim().isNotEmpty) {
                  await _saveCategory(
                    category,
                    nameController.text.trim(),
                    descriptionController.text.trim(),
                    isActive,
                  );
                  if (mounted) Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kategori adı zorunludur'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscountDialog(Category category) {
    // This would show a dialog to create discount for this category
    // For now, just show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${category.categoryName} için İndirim'),
        content: const Text('İndirim oluşturma özelliği yakında eklenecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
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
          categoryId: '',
          businessId: widget.businessId,
          name: name,
          description: description,
          sortOrder: _categories.length,
          isActive: isActive,
          timeRules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final categoryId = await _firestoreService.saveCategory(newCategory);
        final savedCategory = newCategory.copyWith(categoryId: categoryId);

        setState(() {
          _categories.add(savedCategory);
        });

        if (mounted) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name kategorisi eklendi'),
              backgroundColor: AppColors.success,
              action: SnackBarAction(
                label: 'Geri Al',
                textColor: AppColors.white,
                onPressed: () => _deleteCategory(savedCategory),
              ),
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

        await _firestoreService.saveCategory(updatedCategory);

        final index = _categories.indexWhere(
          (c) => c.categoryId == category.categoryId,
        );
        if (index != -1) {
          setState(() {
            _categories[index] = updatedCategory;
          });
        }

        if (mounted) {
          HapticFeedback.lightImpact();
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
        HapticFeedback.heavyImpact();
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

      await _firestoreService.saveCategory(updatedCategory);

      final index = _categories.indexWhere(
        (c) => c.categoryId == category.categoryId,
      );
      if (index != -1) {
        setState(() {
          _categories[index] = updatedCategory;
        });
      }

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${category.categoryName} ${category.isActive ? 'pasif' : 'aktif'} yapıldı',
            ),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Geri Al',
              textColor: AppColors.white,
              onPressed: () => _toggleCategoryStatus(updatedCategory),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
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
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Kategori Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${category.categoryName} kategorisini silmek istediğinizden emin misiniz?',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu işlem geri alınamaz ve kategoriye ait tüm ürünler etkilenebilir.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
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
      await _firestoreService.deleteCategory(category.categoryId);

      setState(() {
        _categories.removeWhere((c) => c.categoryId == category.categoryId);
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.categoryName} kategorisi silindi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
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
    
    HapticFeedback.selectionClick();
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
      final futures = _categories.map((category) => 
        _firestoreService.saveCategory(category)
      ).toList();
      
      await Future.wait(futures);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori sıralaması güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sıralama güncellenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
