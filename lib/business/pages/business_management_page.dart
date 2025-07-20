import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../services/business_service.dart';
import '../models/business_user.dart';
import '../../presentation/widgets/shared/loading_indicator.dart';
import '../../presentation/widgets/shared/error_message.dart';
import '../../presentation/widgets/shared/empty_state.dart';

class BusinessManagementPage extends StatefulWidget {
  const BusinessManagementPage({super.key});

  @override
  State<BusinessManagementPage> createState() => _BusinessManagementPageState();
}

class _BusinessManagementPageState extends State<BusinessManagementPage> {
  final BusinessService _businessService = BusinessService();
  
  List<BusinessUser> _businesses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final businesses = await _businessService.getAllBusinesses();
      setState(() {
        _businesses = businesses;
      });
    } on BusinessException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Business listesi yüklenirken hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
              ? Center(child: ErrorMessage(message: _errorMessage!))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Header
        _buildHeader(),
        
        // Business listesi
        Expanded(
          child: _businesses.isEmpty
              ? const EmptyState(
                  icon: Icons.business,
                  title: 'Henüz business yok',
                  message: 'İlk business kullanıcısını oluşturun',
                )
              : _buildBusinessList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.greyLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Yönetimi',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_businesses.length} business kullanıcısı',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _showAddBusinessDialog,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Business'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _businesses.length,
      itemBuilder: (context, index) {
        final business = _businesses[index];
        return _buildBusinessCard(business);
      },
    );
  }

  Widget _buildBusinessCard(BusinessUser business) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: business.isOwner 
              ? AppColors.primary 
              : AppColors.secondary,
          child: Text(
            business.initials,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              business.displayName,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: business.isOwner 
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                business.role.displayName,
                style: AppTypography.caption.copyWith(
                  color: business.isOwner 
                      ? AppColors.primary 
                      : AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              business.email,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  business.isOwner ? Icons.business : Icons.person,
                  size: 16,
                  color: business.isOwner ? AppColors.primary : AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  business.isOwner ? 'İşletme Sahibi' : 'Personel',
                  style: AppTypography.caption.copyWith(
                    color: business.isOwner ? AppColors.primary : AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleBusinessAction(value, business),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  Text('Düzenle'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'password',
              child: Row(
                children: [
                  const Icon(Icons.lock, size: 20),
                  const SizedBox(width: 8),
                  Text('Şifre Değiştir'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    business.isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                    color: business.isActive ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(business.isActive ? 'Devre Dışı Bırak' : 'Etkinleştir'),
                ],
              ),
            ),
            if (!business.isOwner) PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 20, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text('Sil', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBusinessAction(String action, BusinessUser business) {
    switch (action) {
      case 'edit':
        _showEditBusinessDialog(business);
        break;
      case 'password':
        _showChangePasswordDialog(business);
        break;
      case 'toggle':
        _toggleBusinessStatus(business);
        break;
      case 'delete':
        _showDeleteConfirmation(business);
        break;
    }
  }

  void _showAddBusinessDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddBusinessDialog(),
    );
  }

  void _showEditBusinessDialog(BusinessUser business) {
    showDialog(
      context: context,
      builder: (context) => EditBusinessDialog(business: business),
    );
  }

  void _showChangePasswordDialog(BusinessUser business) {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(business: business),
    );
  }

  void _toggleBusinessStatus(BusinessUser business) async {
    try {
      await _businessService.updateBusinessStatus(
        businessId: business.businessId,
        isActive: !business.isActive,
      );
      
      await _loadBusinesses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              business.isActive 
                  ? 'Business devre dışı bırakıldı' 
                  : 'Business etkinleştirildi',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BusinessUser business) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Business Sil'),
        content: Text('${business.displayName} adlı business kullanıcısını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBusiness(business);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBusiness(BusinessUser business) async {
    try {
      await _businessService.deleteBusiness(business.businessId);
      await _loadBusinesses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${business.displayName} silindi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// Add Business Dialog
class AddBusinessDialog extends StatefulWidget {
  const AddBusinessDialog({super.key});

  @override
  State<AddBusinessDialog> createState() => _AddBusinessDialogState();
}

class _AddBusinessDialogState extends State<AddBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  BusinessRole _selectedRole = BusinessRole.staff;
  List<BusinessPermission> _selectedPermissions = [];

  final BusinessService _businessService = BusinessService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Business Ekle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kullanıcı adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-posta gerekli';
                  }
                  if (!value.contains('@')) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad soyad gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre gerekli';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BusinessRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: BusinessRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                    _updatePermissionsForRole(value);
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('İzinler:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...BusinessPermission.values.map((permission) {
                return CheckboxListTile(
                  title: Text(permission.displayName),
                  value: _selectedPermissions.contains(permission),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedPermissions.add(permission);
                      } else {
                        _selectedPermissions.remove(permission);
                      }
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ekle'),
        ),
      ],
    );
  }

  void _updatePermissionsForRole(BusinessRole role) {
    switch (role) {
      case BusinessRole.owner:
        _selectedPermissions = BusinessPermission.values.toList();
        break;
      case BusinessRole.manager:
        _selectedPermissions = [
          BusinessPermission.viewMenu,
          BusinessPermission.editMenu,
          BusinessPermission.addProducts,
          BusinessPermission.editProducts,
          BusinessPermission.viewOrders,
          BusinessPermission.editOrders,
          BusinessPermission.viewBusinessInfo,
          BusinessPermission.viewAnalytics,
          BusinessPermission.viewSales,
          BusinessPermission.viewReports,
          BusinessPermission.manageQRCodes,
          BusinessPermission.manageDiscounts,
        ];
        break;
      case BusinessRole.staff:
        _selectedPermissions = [
          BusinessPermission.viewMenu,
          BusinessPermission.viewOrders,
          BusinessPermission.viewBusinessInfo,
        ];
        break;
      case BusinessRole.cashier:
        _selectedPermissions = [
          BusinessPermission.viewMenu,
          BusinessPermission.viewOrders,
          BusinessPermission.editOrders,
        ];
        break;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _businessService.createBusiness(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        permissions: _selectedPermissions,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business kullanıcısı başarıyla oluşturuldu'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Edit Business Dialog
class EditBusinessDialog extends StatefulWidget {
  final BusinessUser business;
  
  const EditBusinessDialog({super.key, required this.business});

  @override
  State<EditBusinessDialog> createState() => _EditBusinessDialogState();
}

class _EditBusinessDialogState extends State<EditBusinessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  BusinessRole _selectedRole = BusinessRole.staff;
  List<BusinessPermission> _selectedPermissions = [];

  final BusinessService _businessService = BusinessService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.business.username;
    _emailController.text = widget.business.email;
    _fullNameController.text = widget.business.fullName;
    _selectedRole = widget.business.role;
    _selectedPermissions = List.from(widget.business.permissions);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Business Düzenle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kullanıcı adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-posta gerekli';
                  }
                  if (!value.contains('@')) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad soyad gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BusinessRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: BusinessRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                    _updatePermissionsForRole(value);
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('İzinler:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...BusinessPermission.values.map((permission) {
                return CheckboxListTile(
                  title: Text(permission.displayName),
                  value: _selectedPermissions.contains(permission),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedPermissions.add(permission);
                      } else {
                        _selectedPermissions.remove(permission);
                      }
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Güncelle'),
        ),
      ],
    );
  }

  void _updatePermissionsForRole(BusinessRole role) {
    switch (role) {
      case BusinessRole.owner:
        _selectedPermissions = BusinessPermission.values.toList();
        break;
      case BusinessRole.manager:
        _selectedPermissions = [
          BusinessPermission.viewMenu,
          BusinessPermission.editMenu,
          BusinessPermission.addProducts,
          BusinessPermission.editProducts,
          BusinessPermission.viewOrders,
          BusinessPermission.editOrders,
          BusinessPermission.viewBusinessInfo,
          BusinessPermission.viewAnalytics,
          BusinessPermission.viewSales,
          BusinessPermission.viewReports,
          BusinessPermission.manageQRCodes,
          BusinessPermission.manageDiscounts,
        ];
        break;
      case BusinessRole.staff:
        _selectedPermissions = [
          BusinessPermission.viewMenu,
          BusinessPermission.viewOrders,
          BusinessPermission.viewBusinessInfo,
        ];
        break;
      case BusinessRole.cashier:
        _selectedPermissions = [
          BusinessPermission.viewMenu,
          BusinessPermission.viewOrders,
          BusinessPermission.editOrders,
        ];
        break;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _businessService.updateBusiness(
        businessId: widget.business.businessId,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        permissions: _selectedPermissions,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business kullanıcısı başarıyla güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Change Password Dialog
class ChangePasswordDialog extends StatefulWidget {
  final BusinessUser business;
  
  const ChangePasswordDialog({super.key, required this.business});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final BusinessService _businessService = BusinessService();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Şifre Değiştir'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.business.displayName} için yeni şifre belirleyin',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Şifre gerekli';
                }
                if (value.length < 6) {
                  return 'Şifre en az 6 karakter olmalı';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Şifre Tekrar',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Şifre tekrarı gerekli';
                }
                if (value != _passwordController.text) {
                  return 'Şifreler eşleşmiyor';
                }
                return null;
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
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Değiştir'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _businessService.changeBusinessPassword(
        businessId: widget.business.businessId,
        newPassword: _passwordController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre başarıyla değiştirildi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 