import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/web_safe_image.dart';
import '../../core/services/url_service.dart';
import '../../core/mixins/url_mixin.dart';
import '../models/category.dart' as category_model;
import '../models/discount.dart';

import '../../core/services/storage_service.dart';
import '../services/business_firestore_service.dart';

class CategoryManagementPage extends StatefulWidget {
  final String businessId;

  const CategoryManagementPage({Key? key, required this.businessId})
      : super(key: key);

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage>
    with TickerProviderStateMixin, UrlMixin {
  // --- MEVCUT İŞLEVSEL KODLAR (DEĞİŞTİRİLMEDİ) ---
  final BusinessFirestoreService _businessFirestoreService =
      BusinessFirestoreService();
  final StorageService _storageService = StorageService();
  final UrlService _urlService = UrlService();
  final ImagePicker _imagePicker = ImagePicker();

  List<category_model.Category> _categories = [];
  List<Discount> _discounts = [];
  bool _isLoading = true;
  bool _isReordering = false;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, active, inactive

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlService.updateBusinessUrl(widget.businessId, 'kategoriler');
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
      final futures = await Future.wait([
        _businessFirestoreService.getBusinessCategories(widget.businessId),
        _businessFirestoreService.getDiscounts(businessId: widget.businessId),
      ]);

      setState(() {
        _categories = (futures[0] as List<category_model.Category>)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
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

  // --- YENİDEN TASARLANMIŞ VE DÜZELTİLMİŞ WIDGET'LAR ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
      floatingActionButton: _isReordering ? null : _buildFAB(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    // Filtrelenmiş kategorileri al
    final filteredCategories = _getFilteredCategories();

    return CustomScrollView(
      slivers: [
        _buildHeader(),
        _buildFilterSection(),
        if (filteredCategories.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else if (_isReordering)
          _buildReorderableList(filteredCategories)
        else
          _buildNormalList(filteredCategories),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: AppColors.white,
      pinned: true,
      floating: true,
      elevation: 1,
      expandedHeight: 200.0,
      title: Text('Kategori Yönetimi',
          style: AppTypography.h5.copyWith(color: AppColors.textPrimary)),
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16, 90, 16, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: _buildSearchBar()),
              const SizedBox(height: 12),
              Flexible(child: _buildStatsRow()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Kategori ara...',
        prefixIcon:
            Icon(Icons.search, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildStatsRow() {
    final activeCount = _categories.where((c) => c.isActive).length;
    final inactiveCount = _categories.length - activeCount;

    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Toplam', '${_categories.length}', AppColors.primary),
          const VerticalDivider(thickness: 1, indent: 8, endIndent: 8),
          _buildStatItem('Aktif', '$activeCount', AppColors.success),
          const VerticalDivider(thickness: 1, indent: 8, endIndent: 8),
          _buildStatItem('Pasif', '$inactiveCount', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTypography.h4.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
              bottom: BorderSide(color: AppColors.greyLighter, width: 1)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'Tümü', _categories.length),
              _buildFilterChip('active', 'Aktif',
                  _categories.where((c) => c.isActive).length),
              _buildFilterChip('inactive', 'Pasif',
                  _categories.where((c) => !c.isActive).length),
              const SizedBox(width: 24),
              _buildReorderButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, int count) {
    final isSelected = _selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        onPressed: () => setState(() => _selectedFilter = filter),
        label: Row(
          children: [
            Text(label),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.backgroundLight,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.greyLight,
          width: 1,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
    );
  }

  Widget _buildReorderButton() {
    return TextButton.icon(
      onPressed: _toggleReordering,
      icon: Icon(_isReordering ? Icons.check_circle_outline : Icons.reorder,
          size: 18),
      label: Text(_isReordering ? 'Sıralamayı Bitir' : 'Sırala'),
      style: TextButton.styleFrom(
        foregroundColor:
            _isReordering ? AppColors.success : AppColors.textSecondary,
        backgroundColor: _isReordering
            ? AppColors.success.withOpacity(0.1)
            : AppColors.backgroundLight,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isEmpty
                    ? Icons.category_outlined
                    : Icons.search_off,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'Henüz Kategori Yok' : 'Sonuç Bulunamadı',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'İşletmenizin menüsünü düzenlemek için yeni kategoriler ekleyin.'
                  : 'Arama kriterlerinizi değiştirerek tekrar deneyin.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalList(List<category_model.Category> categories) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCategoryCard(category),
            );
          },
          childCount: categories.length,
        ),
      ),
    );
  }

  Widget _buildReorderableList(List<category_model.Category> categories) {
    return SliverReorderableList(
      itemCount: categories.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Padding(
          key: ValueKey(category.categoryId),
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
          child: _buildCategoryCard(category),
        );
      },
    );
  }

  Widget _buildCategoryCard(category_model.Category category, {Key? key}) {
    final categoryDiscounts = _discounts
        .where((d) =>
            d.applicableCategories.contains(category.categoryId) && d.isActive)
        .length;

    return Card(
      key: key,
      elevation: 2,
      shadowColor: AppColors.shadow.withOpacity(0.1),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: _isReordering ? null : () => _showCategoryDetails(category),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _buildCategoryIcon(category),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            category.name,
                            style: AppTypography.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(category),
                      ],
                    ),
                    if (category.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.sort,
                          label: 'Sıra: ${category.sortOrder + 1}',
                          color: AppColors.info,
                        ),
                        if (categoryDiscounts > 0) ...[
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            icon: Icons.local_offer,
                            label: '$categoryDiscounts İndirim',
                            color: AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _isReordering
                  ? ReorderableDragStartListener(
                      index: _categories.indexOf(category),
                      child: const Icon(Icons.drag_handle,
                          color: AppColors.textLight),
                    )
                  : _buildCategoryActions(category),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(category_model.Category category) {
    Color iconColor =
        category.isActive ? AppColors.primary : AppColors.textLight;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: category.imageUrl != null && category.imageUrl!.isNotEmpty
            ? WebSafeImage(
                imageUrl: category.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Icon(
                    _getCategoryIcon(category.name),
                    color: iconColor,
                    size: 32),
                placeholder: (context, url) =>
                    const Center(child: LoadingIndicator(size: 20)),
              )
            : Icon(_getCategoryIcon(category.name), color: iconColor, size: 32),
      ),
    );
  }

  Widget _buildStatusBadge(category_model.Category category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (category.isActive ? AppColors.success : AppColors.error)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            category.isActive ? Icons.visibility : Icons.visibility_off,
            size: 12,
            color: category.isActive ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            category.isActive ? 'Aktif' : 'Pasif',
            style: AppTypography.caption.copyWith(
              color: category.isActive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
    if (name.contains('çorba')) return Icons.soup_kitchen_outlined;
    if (name.contains('ana') || name.contains('yemek'))
      return Icons.restaurant_menu_outlined;
    if (name.contains('tatlı') || name.contains('desert'))
      return Icons.cake_outlined;
    if (name.contains('içecek') || name.contains('drink'))
      return Icons.local_bar_outlined;
    if (name.contains('başlangıç') || name.contains('meze'))
      return Icons.restaurant_outlined;
    if (name.contains('salata')) return Icons.eco_outlined;
    if (name.contains('pizza')) return Icons.local_pizza_outlined;
    if (name.contains('burger')) return Icons.lunch_dining_outlined;
    if (name.contains('kahve') || name.contains('coffee'))
      return Icons.local_cafe_outlined;
    return Icons.category_outlined;
  }

  Widget _buildCategoryActions(category_model.Category category) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleCategoryAction(value, category),
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      tooltip: 'Seçenekler',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      itemBuilder: (context) => [
        _buildPopupMenuItem(
            icon: Icons.info_outline, text: 'Detaylar', value: 'view'),
        _buildPopupMenuItem(
            icon: Icons.edit_outlined, text: 'Düzenle', value: 'edit'),
        _buildPopupMenuItem(
            icon: Icons.local_offer_outlined,
            text: 'İndirim Ekle',
            value: 'discount'),
        PopupMenuItem<String>(
          value: 'toggle',
          child: ListTile(
            leading: Icon(category.isActive
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
            title: Text(category.isActive ? 'Pasif Yap' : 'Aktif Yap'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Sil', style: TextStyle(color: AppColors.error)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      {required IconData icon, required String text, required String value}) {
    return PopupMenuItem<String>(
      value: value,
      child: ListTile(
        leading: Icon(icon),
        title: Text(text),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddCategoryDialog,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      icon: const Icon(Icons.add),
      label: const Text('Yeni Kategori'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    );
  }

  // --- MEVCUT SHOW DIALOG/MODAL KODLARI (TASARIMLARI YENİLENDİ) ---

  void _showCategoryDetails(category_model.Category category) {
    final categoryDiscounts = _discounts
        .where((d) =>
            d.applicableCategories.contains(category.categoryId) && d.isActive)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryIcon(category),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name,
                            style: AppTypography.h5
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildStatusBadge(category),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Kapat',
                  ),
                ],
              ),
              const Divider(height: 32),
              // Description
              if (category.description.isNotEmpty) ...[
                Text('Açıklama',
                    style: AppTypography.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(category.description,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
              ],
              // Stats
              Row(
                children: [
                  Expanded(
                      child: _buildDetailCard(
                          'Sıra Numarası',
                          '${category.sortOrder + 1}',
                          Icons.sort,
                          AppColors.info)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildDetailCard(
                          'Aktif İndirim',
                          '${categoryDiscounts.length}',
                          Icons.local_offer,
                          AppColors.warning)),
                ],
              ),
              const SizedBox(height: 32),
              // Actions
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditCategoryDialog(category);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Kategoriyi Düzenle'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: AppTypography.h5
                  .copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTypography.caption.copyWith(
                  color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog(null);
  }

  void _showEditCategoryDialog(category_model.Category category) {
    _showCategoryDialog(category);
  }

  void _showCategoryDialog(category_model.Category? category) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController =
        TextEditingController(text: category?.description ?? '');
    bool isActive = category?.isActive ?? true;

    XFile? selectedImageFile;
    Uint8List? selectedImageBytes;
    String? currentImageUrl = category?.imageUrl;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note : Icons.add_circle_outline,
                  color: AppColors.primary),
              const SizedBox(width: 8),
              Text(isEditing ? 'Kategori Düzenle' : 'Yeni Kategori Ekle'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryImageSection(
                  currentImageUrl: currentImageUrl,
                  selectedImageFile: selectedImageFile,
                  selectedImageBytes: selectedImageBytes,
                  isUploadingImage: isUploadingImage,
                  onImagePicked: (XFile? file, Uint8List? bytes) {
                    setDialogState(() {
                      selectedImageFile = file;
                      selectedImageBytes = bytes;
                    });
                  },
                  onUploadStateChanged: (bool uploading) {
                    setDialogState(() => isUploadingImage = uploading);
                  },
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Kategori Adı *',
                      hintText: 'Örn: Ana Yemekler',
                      prefixIcon: Icon(Icons.category_outlined)),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Açıklama (İsteğe Bağlı)',
                      hintText: 'Kısa bir açıklama girin',
                      prefixIcon: Icon(Icons.description_outlined)),
                  maxLines: 3,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  title: const Text('Aktif Kategori'),
                  subtitle: Text(
                      isActive ? 'Menüde görünecek' : 'Menüde gizli kalacak',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary)),
                  value: isActive,
                  onChanged: (value) => setDialogState(() => isActive = value),
                  activeColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  tileColor: AppColors.backgroundLight,
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
                    selectedImageFile,
                  );
                  if (mounted) Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kategori adı zorunludur.'),
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

  // --- MEVCUT İŞLEVSEL KODLAR (DEĞİŞTİRİLMEDİ) ---

  List<category_model.Category> _getFilteredCategories() {
    List<category_model.Category> filtered = List.from(_categories);

    // Önce sortOrder'a göre sırala
    filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((category) {
        return category.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            category.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

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

  void _handleCategoryAction(String action, category_model.Category category) {
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

  void _showDiscountDialog(category_model.Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${category.name} için İndirim'),
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
    category_model.Category? category,
    String name,
    String description,
    bool isActive,
    XFile? imageFile,
  ) async {
    try {
      String? imageUrl = category?.imageUrl;

      if (imageFile != null) {
        final fileName =
            'category_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _storageService.uploadCategoryImage(
          businessId: widget.businessId,
          categoryId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          imageFile: imageFile,
          fileName: fileName,
        );
      }

      if (category == null) {
        // En büyük sortOrder'ı bul ve 1 ekle
        final maxSortOrder = _categories.isEmpty
            ? 0
            : _categories
                    .map((c) => c.sortOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1;

        final newCategory = category_model.Category(
          categoryId: '',
          businessId: widget.businessId,
          name: name,
          description: description,
          imageUrl: imageUrl,
          sortOrder: maxSortOrder,
          isActive: isActive,
          timeRules: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final categoryId =
            await _businessFirestoreService.saveCategory(newCategory);
        final savedCategory = newCategory.copyWith(categoryId: categoryId);

        setState(() {
          _categories.add(savedCategory);
          _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
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
        final updatedCategory = category.copyWith(
          name: name,
          description: description,
          imageUrl: imageUrl,
          isActive: isActive,
          updatedAt: DateTime.now(),
        );

        await _businessFirestoreService.saveCategory(updatedCategory);

        final index =
            _categories.indexWhere((c) => c.categoryId == category.categoryId);
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

  Future<void> _toggleCategoryStatus(category_model.Category category) async {
    try {
      final updatedCategory = category.copyWith(
        isActive: !category.isActive,
        updatedAt: DateTime.now(),
      );

      await _businessFirestoreService.saveCategory(updatedCategory);

      final index =
          _categories.indexWhere((c) => c.categoryId == category.categoryId);
      if (index != -1) {
        setState(() {
          _categories[index] = updatedCategory;
        });
      }

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.name} durumu güncellendi'),
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

  void _showDeleteConfirmation(category_model.Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Kategoriyi Sil'),
          ],
        ),
        content: Text(
            '${category.name} kategorisini kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(category_model.Category category) async {
    try {
      await _businessFirestoreService.deleteCategory(category.categoryId);

      setState(() {
        _categories.removeWhere((c) => c.categoryId == category.categoryId);
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.name} kategorisi silindi'),
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

      // Filtrelenmiş kategorileri kullan
      final filteredCategories = _getFilteredCategories();
      final category = filteredCategories.removeAt(oldIndex);
      filteredCategories.insert(newIndex, category);

      // Tüm kategoriler listesini güncelle ve sortOrder'ları yeniden ata
      for (int i = 0; i < filteredCategories.length; i++) {
        final categoryToUpdate = filteredCategories[i];
        final originalIndex = _categories
            .indexWhere((c) => c.categoryId == categoryToUpdate.categoryId);
        if (originalIndex != -1) {
          _categories[originalIndex] =
              _categories[originalIndex].copyWith(sortOrder: i);
        }
      }

      // Kategorileri sortOrder'a göre sırala
      _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    });

    try {
      // Sadece güncellenmiş kategorileri kaydet
      final updatedCategories = _categories
          .where((cat) => _getFilteredCategories()
              .any((filtered) => filtered.categoryId == cat.categoryId))
          .toList();

      final futures = updatedCategories
          .map((category) => _businessFirestoreService.saveCategory(category))
          .toList();

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
      _loadData();
    }
  }

  Widget _buildCategoryImageSection({
    required String? currentImageUrl,
    required XFile? selectedImageFile,
    required Uint8List? selectedImageBytes,
    required bool isUploadingImage,
    required Function(XFile?, Uint8List?) onImagePicked,
    required Function(bool) onUploadStateChanged,
  }) {
    final hasImage = currentImageUrl != null ||
        selectedImageFile != null ||
        selectedImageBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Fotoğrafı',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kategorinizi temsil eden kare (1:1) format fotoğraf yükleyin',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              // Image container
              GestureDetector(
                onTap: isUploadingImage
                    ? null
                    : () =>
                        _pickCategoryImage(onImagePicked, onUploadStateChanged),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: hasImage
                          ? AppColors.primary.withOpacity(0.3)
                          : AppColors.greyLight,
                      style: BorderStyle.solid,
                      width: hasImage ? 3 : 2,
                    ),
                    boxShadow: hasImage
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageContent(currentImageUrl, selectedImageFile,
                          selectedImageBytes),
                      if (isUploadingImage)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LoadingIndicator(color: Colors.white),
                                SizedBox(height: 8),
                                Text(
                                  'Yükleniyor...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (!hasImage)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.primary,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fotoğraf Ekle',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // Overlay for existing image
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Action buttons
              if (hasImage && !isUploadingImage) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => _pickCategoryImage(
                          onImagePicked, onUploadStateChanged),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Değiştir'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: AppTypography.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => onImagePicked(null, null),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Kaldır'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        textStyle: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              ] else if (!hasImage && !isUploadingImage) ...[
                Text(
                  'Galeri veya kameradan fotoğraf seçin',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(String? currentImageUrl, XFile? selectedImageFile,
      Uint8List? selectedImageBytes) {
    ImageProvider? imageProvider;

    if (kIsWeb && selectedImageBytes != null) {
      imageProvider = MemoryImage(selectedImageBytes);
    } else if (!kIsWeb && selectedImageFile != null) {
      imageProvider = FileImage(File(selectedImageFile.path));
    } else if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
      imageProvider = NetworkImage(currentImageUrl);
    }

    if (imageProvider != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        ),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return const Icon(Icons.image, size: 50, color: AppColors.greyLight);
  }

  Future<void> _pickCategoryImage(
    Function(XFile?, Uint8List?) onImagePicked,
    Function(bool) onUploadStateChanged,
  ) async {
    try {
      onUploadStateChanged(true);

      // Resim kaynağını seç
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) {
        onUploadStateChanged(false);
        return;
      }

      // Resmi seç
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        // Resmi story boyutuna ayarla (9:16 aspect ratio)
        final processedImageData = await _processImageForStory(image);
        onImagePicked(processedImageData['file'], processedImageData['bytes']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçilirken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      onUploadStateChanged(false);
    }
  }

  /// Instagram Story boyutuna (9:16 aspect ratio) resmi ayarla
  Future<Map<String, dynamic>> _processImageForStory(XFile image) async {
    try {
      // Resmi bytes olarak oku
      final Uint8List originalBytes = await image.readAsBytes();

      // Image paketini kullanarak decode et
      final img.Image? originalImage = img.decodeImage(originalBytes);

      if (originalImage == null) {
        throw Exception('Resim decode edilemedi');
      }

      // Story boyutları (9:16 aspect ratio)
      const int storyWidth = 540; // Instagram story genişliği
      const int storyHeight = 960; // Instagram story yüksekliği (540 * 16/9)

      // Resmi story boyutuna resize et ve crop et
      img.Image processedImage;

      // Aspect ratio'yu koruyarak resize
      final double originalAspectRatio =
          originalImage.width / originalImage.height;
      const double storyAspectRatio = storyWidth / storyHeight;

      if (originalAspectRatio > storyAspectRatio) {
        // Resim story'den daha geniş - yüksekliği sabitle, genişliği crop et
        final int newWidth = (originalImage.height * storyAspectRatio).round();
        final int cropX = ((originalImage.width - newWidth) ~/ 2);
        processedImage = img.copyCrop(originalImage,
            x: cropX, y: 0, width: newWidth, height: originalImage.height);
      } else {
        // Resim story'den daha uzun - genişliği sabitle, yüksekliği crop et
        final int newHeight = (originalImage.width / storyAspectRatio).round();
        final int cropY = ((originalImage.height - newHeight) ~/ 2);
        processedImage = img.copyCrop(originalImage,
            x: 0, y: cropY, width: originalImage.width, height: newHeight);
      }

      // Final resize to exact story dimensions
      processedImage = img.copyResize(processedImage,
          width: storyWidth,
          height: storyHeight,
          interpolation: img.Interpolation.cubic);

      // JPEG olarak encode et (%85 kalite)
      final List<int> processedBytes =
          img.encodeJpg(processedImage, quality: 85);
      final Uint8List processedUint8List = Uint8List.fromList(processedBytes);

      // Temporary file oluştur
      final String fileName =
          'story_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb) {
        // Web için XFile oluştur
        final XFile processedXFile = XFile.fromData(
          processedUint8List,
          name: fileName,
          mimeType: 'image/jpeg',
        );

        return {
          'file': processedXFile,
          'bytes': processedUint8List,
        };
      } else {
        // Mobile için temp file yaz
        final Directory tempDir = Directory.systemTemp;
        final File tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(processedBytes);

        final XFile processedXFile = XFile(tempFile.path);

        return {
          'file': processedXFile,
          'bytes': processedUint8List,
        };
      }
    } catch (e) {
      print('Story işleme hatası: $e');
      // Hata durumunda orijinal resmi döndür
      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await image.readAsBytes();
      }
      return {
        'file': image,
        'bytes': bytes,
      };
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resim Kaynağı Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Galeriden Seç'),
              subtitle: const Text('Mevcut fotoğraflarınızdan seçin'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Kamera'),
              subtitle: const Text('Yeni fotoğraf çekin'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}
