import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/storage_service.dart';
import '../models/waiter.dart';
import '../services/waiter_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';

class WaiterManagementPage extends StatefulWidget {
  final String businessId;

  const WaiterManagementPage({
    super.key,
    required this.businessId,
  });

  @override
  State<WaiterManagementPage> createState() => _WaiterManagementPageState();
}

class _WaiterManagementPageState extends State<WaiterManagementPage> {
  final WaiterService _waiterService = WaiterService();
  final TextEditingController _searchController = TextEditingController();

  List<Waiter> _allWaiters = [];
  List<Waiter> _filteredWaiters = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  WaiterStatus? _statusFilter;
  WaiterRank? _rankFilter;

  @override
  void initState() {
    super.initState();
    _loadWaiters();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredWaiters = _allWaiters.where((waiter) {
      final matchesSearch = waiter.fullName.toLowerCase().contains(_searchQuery) ||
          waiter.email.toLowerCase().contains(_searchQuery) ||
          waiter.phone.contains(_searchQuery);
      
      final matchesStatus = _statusFilter == null || waiter.status == _statusFilter;
      final matchesRank = _rankFilter == null || waiter.rank == _rankFilter;
      
      return matchesSearch && matchesStatus && matchesRank;
    }).toList();

    // Sıralama: Aktif olanlar önce, sonra isme göre
    _filteredWaiters.sort((a, b) {
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }
      return a.fullName.compareTo(b.fullName);
    });
  }

  Future<void> _loadWaiters() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final waiters = await _waiterService.getWaitersByBusiness(widget.businessId);
      
      setState(() {
        _allWaiters = waiters;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddWaiterDialog() async {
    final result = await showDialog<Waiter>(
      context: context,
      builder: (context) => _AddWaiterDialog(businessId: widget.businessId),
    );

    if (result != null) {
      await _loadWaiters();
    }
  }

  Future<void> _showEditWaiterDialog(Waiter waiter) async {
    final result = await showDialog<Waiter>(
      context: context,
      builder: (context) => _EditWaiterDialog(waiter: waiter),
    );

    if (result != null) {
      await _loadWaiters();
    }
  }

  Future<void> _showWaiterDetails(Waiter waiter) async {
    await showDialog(
      context: context,
      builder: (context) => _WaiterDetailsDialog(waiter: waiter),
    );
  }

  Future<void> _deleteWaiter(Waiter waiter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Garson Sil', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text('${waiter.fullName} isimli garson silinecek. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _waiterService.deleteWaiter(waiter.waiterId);
        await _loadWaiters();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${waiter.fullName} başarıyla silindi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Garson silinirken hata oluştu: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWaiterDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Garson Ekle'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Garson Yönetimi',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_allWaiters.length} Garson • ${_allWaiters.where((w) => w.isActive).length} Aktif',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Garson ara...',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              'Durum',
              _statusFilter?.displayName ?? 'Tümü',
              () => _showStatusFilter(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterChip(
              'Rütbe',
              _rankFilter?.displayName ?? 'Tümü',
              () => _showRankFilter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: ErrorMessage(message: _errorMessage!));
    }

    if (_filteredWaiters.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.people_outline_rounded,
          title: 'Garson Bulunamadı',
          message: 'Henüz garson eklenmemiş veya arama kriterlerine uygun garson yok.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWaiters,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _filteredWaiters.length,
        itemBuilder: (context, index) => _buildWaiterCard(_filteredWaiters[index]),
      ),
    );
  }

  Widget _buildWaiterCard(Waiter waiter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showWaiterDetails(waiter),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _parseColor(waiter.rankColor),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: waiter.profileImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                waiter.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(waiter),
                              ),
                            )
                          : _buildAvatarFallback(waiter),
                    ),
                    const SizedBox(width: 16),
                    
                    // Bilgiler
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  waiter.fullName,
                                  style: AppTypography.h6.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: waiter.isOnline ? AppColors.success : AppColors.greyDark,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _parseColor(waiter.rankColor).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  waiter.rank.displayName,
                                  style: AppTypography.caption.copyWith(
                                    color: _parseColor(waiter.rankColor),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _parseColor(waiter.statusColor).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  waiter.status.displayName,
                                  style: AppTypography.caption.copyWith(
                                    color: _parseColor(waiter.statusColor),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.phone_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                waiter.phone,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.table_restaurant_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${waiter.assignedTables.length} Masa',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Actions
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 18),
                              SizedBox(width: 12),
                              Text('Düzenle'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Sil', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditWaiterDialog(waiter);
                            break;
                          case 'delete':
                            _deleteWaiter(waiter);
                            break;
                        }
                      },
                    ),
                  ],
                ),
                
                // İstatistikler
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Sipariş',
                          waiter.statistics.totalOrders.toString(),
                          Icons.receipt_long_rounded,
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.greyLight),
                      Expanded(
                        child: _buildStatItem(
                          'Puan',
                          waiter.statistics.averageRating.toStringAsFixed(1),
                          Icons.star_rounded,
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.greyLight),
                      Expanded(
                        child: _buildStatItem(
                          'Yanıt',
                          '${waiter.statistics.responseRate.toStringAsFixed(0)}%',
                          Icons.speed_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(Waiter waiter) {
    return Center(
      child: Text(
        waiter.initials,
        style: AppTypography.h6.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showStatusFilter() async {
    final result = await showModalBottomSheet<WaiterStatus?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet<WaiterStatus>(
        title: 'Durum Filtresi',
        items: WaiterStatus.values,
        selectedItem: _statusFilter,
        itemBuilder: (status) => status.displayName,
      ),
    );

    if (result != null || result == null && _statusFilter != null) {
      setState(() {
        _statusFilter = result;
        _applyFilters();
      });
    }
  }

  void _showRankFilter() async {
    final result = await showModalBottomSheet<WaiterRank?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet<WaiterRank>(
        title: 'Rütbe Filtresi',
        items: WaiterRank.values,
        selectedItem: _rankFilter,
        itemBuilder: (rank) => rank.displayName,
      ),
    );

    if (result != null || result == null && _rankFilter != null) {
      setState(() {
        _rankFilter = result;
        _applyFilters();
      });
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
}

// Filter Bottom Sheet Widget
class _FilterBottomSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemBuilder;

  const _FilterBottomSheet({
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Tümü'),
            trailing: selectedItem == null ? const Icon(Icons.check_rounded) : null,
            onTap: () => Navigator.of(context).pop(null),
          ),
          ...items.map((item) => ListTile(
            title: Text(itemBuilder(item)),
            trailing: selectedItem == item ? const Icon(Icons.check_rounded) : null,
            onTap: () => Navigator.of(context).pop(item),
          )),
        ],
      ),
    );
  }
}

// Add Waiter Dialog
class _AddWaiterDialog extends StatefulWidget {
  final String businessId;

  const _AddWaiterDialog({required this.businessId});

  @override
  State<_AddWaiterDialog> createState() => _AddWaiterDialogState();
}

class _AddWaiterDialogState extends State<_AddWaiterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  WaiterRank _selectedRank = WaiterRank.trainee;
  bool _isLoading = false;
  File? _selectedImage;
  String? _profileImageUrl;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Yeni Garson Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile photo section
              _buildProfilePhotoSection(),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'Ad gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Soyad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'Soyad gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.trim().isEmpty == true) return 'E-posta gerekli';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Geçerli e-posta adresi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.trim().isEmpty == true ? 'Telefon gerekli' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WaiterRank>(
                value: _selectedRank,
                decoration: const InputDecoration(
                  labelText: 'Rütbe',
                  border: OutlineInputBorder(),
                ),
                items: WaiterRank.values.map((rank) => DropdownMenuItem(
                  value: rank,
                  child: Text(rank.displayName),
                )).toList(),
                onChanged: (value) => setState(() => _selectedRank = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addWaiter,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Ekle', style: TextStyle(color: AppColors.white)),
        ),
      ],
    );
  }

  Widget _buildProfilePhotoSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.greyLighter,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.greyLight, width: 2),
              image: _selectedImage != null
                  ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        size: 32,
                        color: AppColors.greyDark,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fotoğraf\nEkle',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.greyDark,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedImage != null)
          TextButton.icon(
            onPressed: () => setState(() => _selectedImage = null),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Kaldır'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilirken hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _addWaiter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? profileImageUrl;
      
      // Eğer fotoğraf seçildiyse Firebase Storage'a yükle
      if (_selectedImage != null) {
        final fileName = 'waiter_${DateTime.now().millisecondsSinceEpoch}.jpg';
        profileImageUrl = await _storageService.uploadWaiterPhoto(
          businessId: widget.businessId,
          waiterId: fileName,
          imageFile: _selectedImage!,
        );
      }

      final waiter = Waiter.create(
        businessId: widget.businessId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        rank: _selectedRank,
        profileImageUrl: profileImageUrl,
      );

      final waiterService = WaiterService();
      await waiterService.addWaiter(waiter);

      if (mounted) {
        Navigator.of(context).pop(waiter);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Garson eklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Edit Waiter Dialog
class _EditWaiterDialog extends StatefulWidget {
  final Waiter waiter;

  const _EditWaiterDialog({required this.waiter});

  @override
  State<_EditWaiterDialog> createState() => _EditWaiterDialogState();
}

class _EditWaiterDialogState extends State<_EditWaiterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  
  late WaiterRank _selectedRank;
  late WaiterStatus _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.waiter.firstName);
    _lastNameController = TextEditingController(text: widget.waiter.lastName);
    _emailController = TextEditingController(text: widget.waiter.email);
    _phoneController = TextEditingController(text: widget.waiter.phone);
    _selectedRank = widget.waiter.rank;
    _selectedStatus = widget.waiter.status;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Garson Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'Ad gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Soyad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty == true ? 'Soyad gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.trim().isEmpty == true) return 'E-posta gerekli';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Geçerli e-posta adresi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.trim().isEmpty == true ? 'Telefon gerekli' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<WaiterRank>(
                      value: _selectedRank,
                      decoration: const InputDecoration(
                        labelText: 'Rütbe',
                        border: OutlineInputBorder(),
                      ),
                      items: WaiterRank.values.map((rank) => DropdownMenuItem(
                        value: rank,
                        child: Text(rank.displayName),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedRank = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<WaiterStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Durum',
                        border: OutlineInputBorder(),
                      ),
                      items: WaiterStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedStatus = value!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateWaiter,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Güncelle', style: TextStyle(color: AppColors.white)),
        ),
      ],
    );
  }

  Future<void> _updateWaiter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedWaiter = widget.waiter.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        rank: _selectedRank,
        status: _selectedStatus,
      );

      final waiterService = WaiterService();
      await waiterService.updateWaiter(updatedWaiter);

      if (mounted) {
        Navigator.of(context).pop(updatedWaiter);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Garson güncellenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Waiter Details Dialog
class _WaiterDetailsDialog extends StatelessWidget {
  final Waiter waiter;

  const _WaiterDetailsDialog({required this.waiter});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _parseColor(waiter.rankColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: waiter.profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            waiter.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(waiter),
                          ),
                        )
                      : _buildAvatarFallback(waiter),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        waiter.fullName,
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _parseColor(waiter.rankColor).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              waiter.rank.displayName,
                              style: AppTypography.bodyMedium.copyWith(
                                color: _parseColor(waiter.rankColor),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _parseColor(waiter.statusColor).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              waiter.status.displayName,
                              style: AppTypography.bodyMedium.copyWith(
                                color: _parseColor(waiter.statusColor),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('İletişim Bilgileri', [
                      _buildDetailItem(Icons.email_rounded, 'E-posta', waiter.email),
                      _buildDetailItem(Icons.phone_rounded, 'Telefon', waiter.phone),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('İş Bilgileri', [
                      _buildDetailItem(Icons.calendar_today_rounded, 'İşe Başlama', 
                          '${waiter.hireDate.day}/${waiter.hireDate.month}/${waiter.hireDate.year}'),
                      _buildDetailItem(Icons.work_rounded, 'Deneyim', '${waiter.experienceYears} yıl'),
                      _buildDetailItem(Icons.table_restaurant_rounded, 'Atanmış Masalar', 
                          waiter.assignedTables.isEmpty ? 'Yok' : waiter.assignedTables.join(', ')),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('İstatistikler', [
                      _buildDetailItem(Icons.receipt_long_rounded, 'Toplam Sipariş', 
                          waiter.statistics.totalOrders.toString()),
                      _buildDetailItem(Icons.people_rounded, 'Toplam Müşteri', 
                          waiter.statistics.totalCustomers.toString()),
                      _buildDetailItem(Icons.star_rounded, 'Ortalama Puan', 
                          waiter.statistics.averageRating.toStringAsFixed(1)),
                      _buildDetailItem(Icons.speed_rounded, 'Yanıt Oranı', 
                          '${waiter.statistics.responseRate.toStringAsFixed(1)}%'),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(Waiter waiter) {
    return Center(
      child: Text(
        waiter.initials,
        style: AppTypography.h4.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
} 