import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/storage_service.dart';
import '../models/staff.dart';
import '../services/staff_service.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';

class StaffManagementPage extends StatefulWidget {
  final String businessId;

  const StaffManagementPage({
    super.key,
    required this.businessId,
  });

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final StaffService _staffService = StaffService();
  final TextEditingController _searchController = TextEditingController();

  List<Staff> _allStaff = [];
  List<Staff> _filteredStaff = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  StaffRole? _roleFilter;
  StaffStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadStaff();
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
    _filteredStaff = _allStaff.where((staff) {
      final matchesSearch = staff.fullName.toLowerCase().contains(_searchQuery) ||
          staff.email.toLowerCase().contains(_searchQuery) ||
          staff.phone.contains(_searchQuery);
      
      final matchesRole = _roleFilter == null || staff.role == _roleFilter;
      final matchesStatus = _statusFilter == null || staff.status == _statusFilter;
      
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();

    // Sıralama: Aktif olanlar önce, sonra role göre, sonra isme göre
    _filteredStaff.sort((a, b) {
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }
      if (a.role != b.role) {
        return a.role.index.compareTo(b.role.index);
      }
      return a.fullName.compareTo(b.fullName);
    });
  }

  Future<void> _loadStaff() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final staff = await _staffService.getStaffByBusiness(widget.businessId);
      
      setState(() {
        _allStaff = staff;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Personel Yönetimi'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStaff,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Personel Ekle'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: ErrorMessage(
          message: _errorMessage!,
          onRetry: _loadStaff,
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(child: _buildStaffList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personel Yönetimi',
                      style: AppTypography.h6.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_filteredStaff.length} aktif personel',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatsCard(),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final activeCount = _allStaff.where((s) => s.isActive).length;
    final managerCount = _allStaff.where((s) => s.role == StaffRole.manager).length;
    final waiterCount = _allStaff.where((s) => s.role == StaffRole.waiter).length;
    final kitchenCount = _allStaff.where((s) => s.role == StaffRole.kitchen).length;
    final cashierCount = _allStaff.where((s) => s.role == StaffRole.cashier).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Özet',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatItem('Aktif', activeCount, Colors.green),
          _buildStatItem('Müdür', managerCount, Colors.purple),
          _buildStatItem('Garson', waiterCount, Colors.blue),
          _buildStatItem('Mutfak', kitchenCount, Colors.orange),
          _buildStatItem('Kasiyer', cashierCount, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Personel ara (ad, email, telefon)',
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildRoleFilter(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusFilter(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list_off,
                  color: (_roleFilter != null || _statusFilter != null) 
                      ? AppColors.primary 
                      : AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _roleFilter = null;
                    _statusFilter = null;
                    _applyFilters();
                  });
                },
                tooltip: 'Filtreleri Temizle',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilter() {
    return DropdownButtonFormField<StaffRole?>(
      value: _roleFilter,
      decoration: InputDecoration(
        labelText: 'Rol',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<StaffRole?>(
          value: null,
          child: Text('Tüm Roller'),
        ),
        ...StaffRole.values.map((role) => DropdownMenuItem<StaffRole?>(
          value: role,
          child: Text(role.displayName),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _roleFilter = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<StaffStatus?>(
      value: _statusFilter,
      decoration: InputDecoration(
        labelText: 'Durum',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<StaffStatus?>(
          value: null,
          child: Text('Tüm Durumlar'),
        ),
        ...StaffStatus.values.map((status) => DropdownMenuItem<StaffStatus?>(
          value: status,
          child: Text(status.displayName),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _statusFilter = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildStaffList() {
    if (_filteredStaff.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: _searchQuery.isNotEmpty ? 'Arama sonucu bulunamadı' : 'Henüz personel eklenmemiş',
        message: _searchQuery.isNotEmpty 
            ? 'Farklı terimlerle aramayı deneyin'
            : 'İlk personeli eklemek için "+" butonuna tıklayın',
        actionText: _searchQuery.isNotEmpty ? 'Filtreleri Temizle' : 'Personel Ekle',
        onActionPressed: _searchQuery.isNotEmpty 
            ? () {
                _searchController.clear();
                setState(() {
                  _roleFilter = null;
                  _statusFilter = null;
                  _applyFilters();
                });
              }
            : _showAddStaffDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStaff.length,
      itemBuilder: (context, index) {
        final staff = _filteredStaff[index];
        return _buildStaffCard(staff);
      },
    );
  }

  Widget _buildStaffCard(Staff staff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showStaffDetailsDialog(staff),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStaffAvatar(staff),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStaffInfo(staff),
              ),
              _buildStaffActions(staff),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffAvatar(Staff staff) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getRoleColor(staff.role).withOpacity(0.1),
        border: Border.all(
          color: staff.isActive ? _getRoleColor(staff.role) : AppColors.textSecondary,
          width: 2,
        ),
      ),
      child: staff.profileImageUrl != null
          ? ClipOval(
              child: Image.network(
                staff.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar(staff);
                },
              ),
            )
          : _buildInitialsAvatar(staff),
    );
  }

  Widget _buildInitialsAvatar(Staff staff) {
    return Center(
      child: Text(
        staff.initials,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: staff.isActive ? _getRoleColor(staff.role) : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildStaffInfo(Staff staff) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                staff.fullName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: staff.isActive ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(staff.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getRoleColor(staff.role).withOpacity(0.3)),
              ),
              child: Text(
                staff.role.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(staff.role),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          staff.email,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          staff.phone,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildStatusChip(staff.status),
            const SizedBox(width: 8),
            _buildShiftChip(staff.currentShift),
            if (!staff.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pasif',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(StaffStatus status) {
    Color color;
    switch (status) {
      case StaffStatus.available:
        color = Colors.green;
        break;
      case StaffStatus.busy:
        color = Colors.orange;
        break;
      case StaffStatus.break_:
        color = Colors.blue;
        break;
      case StaffStatus.offline:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildShiftChip(StaffShift shift) {
    Color color;
    switch (shift) {
      case StaffShift.none:
        color = Colors.grey;
        break;
      case StaffShift.morning:
        color = Colors.orange;
        break;
      case StaffShift.afternoon:
        color = Colors.blue;
        break;
      case StaffShift.night:
        color = Colors.purple;
        break;
      case StaffShift.evening:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        shift.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStaffActions(Staff staff) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) {
        switch (value) {
          case 'view':
            _showStaffDetailsDialog(staff);
            break;
          case 'edit':
            _showEditStaffDialog(staff);
            break;
          case 'toggle_status':
            _toggleStaffStatus(staff);
            break;
          case 'delete':
            _showDeleteConfirmation(staff);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: ListTile(
            leading: Icon(Icons.visibility),
            title: Text('Detayları Görüntüle'),
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
        PopupMenuItem(
          value: 'toggle_status',
          child: ListTile(
            leading: Icon(staff.isActive ? Icons.person_off : Icons.person),
            title: Text(staff.isActive ? 'Pasif Yap' : 'Aktif Yap'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Sil', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(StaffRole role) {
    switch (role) {
      case StaffRole.manager:
        return Colors.purple;
      case StaffRole.waiter:
        return Colors.blue;
      case StaffRole.kitchen:
        return Colors.orange;
      case StaffRole.cashier:
        return Colors.red;
    }
  }

  // CRUD Operations

  Future<void> _showAddStaffDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _StaffFormDialog(
        businessId: widget.businessId,
        onSaved: () {
          _loadStaff();
        },
      ),
    );
  }

  Future<void> _showEditStaffDialog(Staff staff) async {
    await showDialog(
      context: context,
      builder: (context) => _StaffFormDialog(
        businessId: widget.businessId,
        staff: staff,
        onSaved: () {
          _loadStaff();
        },
      ),
    );
  }

  Future<void> _showStaffDetailsDialog(Staff staff) async {
    await showDialog(
      context: context,
      builder: (context) => _StaffDetailsDialog(staff: staff),
    );
  }

  Future<void> _toggleStaffStatus(Staff staff) async {
    try {
      // Loading göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${staff.fullName} durumu güncelleniyor...'),
          duration: const Duration(seconds: 1),
        ),
      );

      await _staffService.updateStaff(
        staff.copyWith(isActive: !staff.isActive),
      );

      _loadStaff();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${staff.fullName} ${!staff.isActive ? 'aktif' : 'pasif'} yapıldı',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncellenirken hata: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(Staff staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personeli Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${staff.fullName} personelini silmek istediğinizden emin misiniz?'),
            const SizedBox(height: 8),
            Text(
              'Bu işlem geri alınamaz ve personelin tüm verileri silinecektir.',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteStaff(staff);
    }
  }

  Future<void> _deleteStaff(Staff staff) async {
    try {
      // Loading göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${staff.fullName} siliniyor...'),
          duration: const Duration(seconds: 1),
        ),
      );

      await _staffService.deleteStaff(staff.staffId);

      _loadStaff();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${staff.fullName} başarıyla silindi'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Personel silinirken hata: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// Staff Form Dialog
class _StaffFormDialog extends StatefulWidget {
  final String businessId;
  final Staff? staff;
  final VoidCallback onSaved;

  const _StaffFormDialog({
    required this.businessId,
    this.staff,
    required this.onSaved,
  });

  @override
  State<_StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<_StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final StaffService _staffService = StaffService();
  final StorageService _storageService = StorageService();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _notesController;

  StaffRole _selectedRole = StaffRole.waiter;
  StaffStatus _selectedStatus = StaffStatus.available;
  StaffShift _selectedShift = StaffShift.none;
  List<int> _assignedTables = [];
  
  bool _isLoading = false;
  File? _selectedImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    
    _firstNameController = TextEditingController(text: widget.staff?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.staff?.lastName ?? '');
    _emailController = TextEditingController(text: widget.staff?.email ?? '');
    _phoneController = TextEditingController(text: widget.staff?.phone ?? '');
    _passwordController = TextEditingController();
    _notesController = TextEditingController(text: widget.staff?.notes ?? '');
    
    if (widget.staff != null) {
      _selectedRole = widget.staff!.role;
      _selectedStatus = widget.staff!.status;
      _selectedShift = widget.staff!.currentShift;
      _assignedTables = List.from(widget.staff!.assignedTables);
      _profileImageUrl = widget.staff!.profileImageUrl;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildForm(),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.staff == null ? Icons.person_add : Icons.person_outline,
            color: AppColors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.staff == null ? 'Yeni Personel Ekle' : 'Personel Düzenle',
              style: AppTypography.h6.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileImageSection(),
          const SizedBox(height: 20),
          _buildBasicInfoSection(),
          const SizedBox(height: 20),
          _buildRoleAndStatusSection(),
          const SizedBox(height: 20),
          _buildTablesSection(),
          const SizedBox(height: 20),
          _buildNotesSection(),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: _selectedImage != null
                  ? ClipOval(
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _profileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          ),
                        )
                      : _buildDefaultAvatar(),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Fotoğraf Seç'),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 50,
      color: AppColors.primary,
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temel Bilgiler',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ad gerekli';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Soyad *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Soyad gerekli';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'E-posta *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'E-posta gerekli';
            }
            if (!value.contains('@')) {
              return 'Geçerli bir e-posta adresi girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Telefon *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Telefon gerekli';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: widget.staff == null ? 'Şifre *' : 'Yeni Şifre (Boş bırakılabilir)',
            border: const OutlineInputBorder(),
            helperText: widget.staff == null 
                ? 'Minimum 6 karakter' 
                : 'Şifreyi değiştirmek istemiyorsanız boş bırakın',
          ),
          obscureText: true,
          validator: (value) {
            if (widget.staff == null && (value == null || value.trim().isEmpty)) {
              return 'Yeni personel için şifre gerekli';
            }
            if (value != null && value.isNotEmpty && value.length < 6) {
              return 'Şifre en az 6 karakter olmalı';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleAndStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rol ve Durum',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<StaffRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: StaffRole.values.map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.displayName),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<StaffStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Durum',
                  border: OutlineInputBorder(),
                ),
                items: StaffStatus.values.map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<StaffShift>(
          value: _selectedShift,
          decoration: const InputDecoration(
            labelText: 'Vardiya',
            border: OutlineInputBorder(),
          ),
          items: StaffShift.values.map((shift) => DropdownMenuItem(
            value: shift,
            child: Text(shift.displayName),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedShift = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTablesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atanmış Masalar',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Personelin sorumlu olduğu masa numaralarını girin (virgülle ayırın)',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Masa Numaraları',
            hintText: 'Örn: 1,2,3,4',
            border: OutlineInputBorder(),
          ),
          initialValue: _assignedTables.join(','),
          onChanged: (value) {
            setState(() {
              _assignedTables = value
                  .split(',')
                  .map((s) => int.tryParse(s.trim()))
                  .where((n) => n != null)
                  .cast<int>()
                  .toList();
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notlar',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Ek Notlar',
            hintText: 'Personel hakkında ek bilgiler...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveStaff,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.staff == null ? 'Ekle' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _profileImageUrl;
      
      // Yeni resim seçildiyse upload et
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadFile(
          _selectedImage!,
          'staff_profiles/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      if (widget.staff == null) {
        // Yeni personel ekle
        final staff = Staff.create(
          businessId: widget.businessId,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
          status: _selectedStatus,
          currentShift: _selectedShift,
          assignedTables: _assignedTables.map((t) => t.toString()).toList(),
          profileImageUrl: imageUrl,
          notes: _notesController.text.trim(),
        );

        await _staffService.addStaff(staff);
      } else {
        // Mevcut personeli güncelle
        final updatedStaff = widget.staff!.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          status: _selectedStatus,
          currentShift: _selectedShift,
          assignedTables: _assignedTables.map((t) => t.toString()).toList(),
          profileImageUrl: imageUrl,
          notes: _notesController.text.trim(),
        );

        await _staffService.updateStaff(updatedStaff);

        // Şifre güncellemesi varsa ayrıca yap
        if (_passwordController.text.trim().isNotEmpty) {
          // TODO: Implement password update in StaffService
        }
      }

      widget.onSaved();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.staff == null ? 'Personel başarıyla eklendi' : 'Personel başarıyla güncellendi',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Staff Details Dialog
class _StaffDetailsDialog extends StatelessWidget {
  final Staff staff;

  const _StaffDetailsDialog({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.white,
            child: staff.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      staff.profileImageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          staff.initials,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    staff.initials,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.fullName,
                  style: AppTypography.h6.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  staff.role.displayName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoSection('İletişim Bilgileri', [
          _buildInfoRow('E-posta', staff.email, Icons.email),
          _buildInfoRow('Telefon', staff.phone, Icons.phone),
        ]),
        const SizedBox(height: 20),
        _buildInfoSection('Çalışma Bilgileri', [
          _buildInfoRow('Durum', staff.status.displayName, Icons.circle, 
              color: _getStatusColor(staff.status)),
          _buildInfoRow('Vardiya', staff.currentShift.displayName, Icons.schedule),
          _buildInfoRow('Aktif', staff.isActive ? 'Evet' : 'Hayır', Icons.person,
              color: staff.isActive ? Colors.green : Colors.red),
        ]),
        const SizedBox(height: 20),
        if (staff.assignedTables.isNotEmpty)
          _buildInfoSection('Atanmış Masalar', [
            _buildInfoRow('Masalar', staff.assignedTables.join(', '), Icons.table_restaurant),
          ]),
        const SizedBox(height: 20),
        _buildInfoSection('İstatistikler', [
          _buildInfoRow('Sipariş Sayısı', staff.statistics.totalOrders.toString(), Icons.receipt),
          _buildInfoRow('Müşteri Sayısı', staff.statistics.totalCustomers.toString(), Icons.people),
          _buildInfoRow('Çağrı Yanıt Oranı', '${staff.statistics.responseRate.toStringAsFixed(1)}%', Icons.phone_in_talk),
          _buildInfoRow('Çalışma Günü', staff.statistics.workingDays.toString(), Icons.calendar_today),
        ]),
        if (staff.notes.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildInfoSection('Notlar', [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Text(
                staff.notes,
                style: AppTypography.bodyMedium,
              ),
            ),
          ]),
        ],
        const SizedBox(height: 20),
        _buildInfoSection('Kayıt Bilgileri', [
          _buildInfoRow('Oluşturulma', _formatDate(staff.createdAt), Icons.access_time),
          _buildInfoRow('Son Güncelleme', _formatDate(staff.updatedAt), Icons.update),
        ]),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StaffStatus status) {
    switch (status) {
      case StaffStatus.available:
        return Colors.green;
      case StaffStatus.busy:
        return Colors.orange;
      case StaffStatus.break_:
        return Colors.blue;
      case StaffStatus.offline:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 