import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../services/admin_service.dart';
import '../models/admin_user.dart';
import '../../../presentation/widgets/shared/loading_indicator.dart';
import '../../../presentation/widgets/shared/error_message.dart';
import '../../../presentation/widgets/shared/empty_state.dart';
import '../../business/services/business_service.dart';

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  final AdminService _adminService = AdminService();
  
  List<AdminUser> _admins = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final admins = await _adminService.getAllAdmins();
      setState(() {
        _admins = admins;
      });
    } on AdminException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Admin listesi yüklenirken hata: $e';
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
        
        // Admin listesi
        Expanded(
          child: _admins.isEmpty
              ? const EmptyState(
                  icon: Icons.admin_panel_settings,
                  title: 'Henüz admin yok',
                  message: 'İlk admin kullanıcısını oluşturun',
                )
              : _buildAdminList(),
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
                'Admin Yönetimi',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_admins.length} admin kullanıcısı',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _showAddAdminDialog,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
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

  Widget _buildAdminList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _admins.length,
      itemBuilder: (context, index) {
        final admin = _admins[index];
        return _buildAdminCard(admin);
      },
    );
  }

  Widget _buildAdminCard(AdminUser admin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: admin.isSuperAdmin 
              ? AppColors.error 
              : AppColors.primary,
          child: Text(
            admin.initials,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              admin.displayName,
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
                color: admin.isSuperAdmin 
                    ? AppColors.error.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                admin.role.displayName,
                style: AppTypography.caption.copyWith(
                  color: admin.isSuperAdmin 
                      ? AppColors.error 
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              admin.email,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  admin.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: admin.isActive ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  admin.isActive ? 'Aktif' : 'Pasif',
                  style: AppTypography.caption.copyWith(
                    color: admin.isActive ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Son giriş: ${admin.lastLoginAt != null ? _formatDate(admin.lastLoginAt!) :'Hiç giriş yapmamış'}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleAdminAction(value, admin),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Düzenle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'password',
              child: Row(
                children: [
                  Icon(Icons.lock, size: 20),
                  SizedBox(width: 8),
                  Text('Şifre Değiştir'),
                ],
              ),
            ),
            PopupMenuItem(
              value: admin.isActive ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(
                    admin.isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                    color: admin.isActive ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    admin.isActive ? 'Pasifleştir' : 'Aktifleştir',
                    style: TextStyle(
                      color: admin.isActive ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            if (!admin.isSuperAdmin)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleAdminAction(String action, AdminUser admin) {
    switch (action) {
      case 'edit':
        _showEditAdminDialog(admin);
        break;
      case 'password':
        _showChangePasswordDialog(admin);
        break;
      case 'activate':
      case 'deactivate':
        _toggleAdminStatus(admin);
        break;
      case 'delete':
        _showDeleteConfirmation(admin);
        break;
    }
  }

  void _showAddAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddAdminDialog(),
    ).then((_) => _loadAdmins());
  }

  void _showEditAdminDialog(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => EditAdminDialog(admin: admin),
    ).then((_) => _loadAdmins());
  }

  void _showChangePasswordDialog(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(admin: admin),
    );
  }

  void _toggleAdminStatus(AdminUser admin) async {
    try {
      await _adminService.updateAdmin(
        adminId: admin.adminId,
        isActive: !admin.isActive,
      );
      _loadAdmins();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              admin.isActive 
                  ? 'Admin pasifleştirildi' 
                  : 'Admin aktifleştirildi',
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

  void _showDeleteConfirmation(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Sil'),
        content: Text(
          '${admin.displayName} adlı admin kullanıcısını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAdmin(admin);
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

  Future<void> _deleteAdmin(AdminUser admin) async {
    try {
      await _adminService.deleteAdmin(admin.adminId);
      _loadAdmins();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${admin.displayName} silindi'),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Add Admin Dialog
class AddAdminDialog extends StatefulWidget {
  const AddAdminDialog({super.key});

  @override
  State<AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<AddAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  AdminRole _selectedRole = AdminRole.moderator;
  List<AdminPermission> _selectedPermissions = [];
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
      title: const Text('Yeni Admin Ekle'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    hintText: 'admin',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
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
                    hintText: 'admin@example.com',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'E-posta gerekli';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli e-posta girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    hintText: 'Admin Kullanıcı',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ad soyad gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    hintText: '••••••••',
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AdminRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                  ),
                  items: AdminRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                      _updatePermissionsForRole();
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('İzinler'),
                const SizedBox(height: 8),
                ...AdminPermission.values.map((permission) {
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
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAddAdmin,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ekle'),
        ),
      ],
    );
  }

  void _updatePermissionsForRole() {
    switch (_selectedRole) {
      case AdminRole.superAdmin:
        _selectedPermissions = AdminPermission.values.toList();
        break;
      case AdminRole.systemAdmin:
        _selectedPermissions = [
          AdminPermission.viewUsers,
          AdminPermission.createUsers,
          AdminPermission.editUsers,
          AdminPermission.deleteUsers,
          AdminPermission.viewBusinesses,
          AdminPermission.createBusinesses,
          AdminPermission.editBusinesses,
          AdminPermission.deleteBusinesses,
          AdminPermission.approveBusinesses,
          AdminPermission.viewOrders,
          AdminPermission.editOrders,
          AdminPermission.deleteOrders,
          AdminPermission.viewAnalytics,
          AdminPermission.manageSystemSettings,
          AdminPermission.viewActivityLogs,
          AdminPermission.manageAdminUsers,
          AdminPermission.manageAdmins,
          AdminPermission.manageSystem,
          AdminPermission.viewAuditLogs,
          AdminPermission.moderateContent,
          AdminPermission.manageCategories,
          AdminPermission.manageProducts,
          AdminPermission.viewReports,
        ];
        break;
      case AdminRole.admin:
        _selectedPermissions = [
          AdminPermission.viewBusinesses,
          AdminPermission.editBusinesses,
          AdminPermission.viewCustomers,
          AdminPermission.editCustomers,
          AdminPermission.moderateContent,
          AdminPermission.viewAnalytics,
          AdminPermission.viewReports,
        ];
        break;
      case AdminRole.moderator:
        _selectedPermissions = [
          AdminPermission.viewBusinesses,
          AdminPermission.viewCustomers,
          AdminPermission.moderateContent,
          AdminPermission.viewReports,
        ];
        break;
      case AdminRole.support:
        _selectedPermissions = [
          AdminPermission.viewBusinesses,
          AdminPermission.viewCustomers,
          AdminPermission.viewReports,
        ];
        break;
    }
  }

  Future<void> _handleAddAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = AdminService();
      await adminService.createAdmin(
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
            content: Text('Admin başarıyla oluşturuldu'),
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
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Edit Admin Dialog
class EditAdminDialog extends StatefulWidget {
  final AdminUser admin;
  
  const EditAdminDialog({super.key, required this.admin});

  @override
  State<EditAdminDialog> createState() => _EditAdminDialogState();
}

class _EditAdminDialogState extends State<EditAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  AdminRole _selectedRole = AdminRole.moderator;
  List<AdminPermission> _selectedPermissions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.admin.username;
    _emailController.text = widget.admin.email;
    _fullNameController.text = widget.admin.fullName;
    _selectedRole = widget.admin.role;
    _selectedPermissions = List.from(widget.admin.permissions);
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
      title: const Text('Admin Düzenle'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
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
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'E-posta gerekli';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli e-posta girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ad soyad gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AdminRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                  ),
                  items: AdminRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                      _updatePermissionsForRole();
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('İzinler'),
                const SizedBox(height: 8),
                ...AdminPermission.values.map((permission) {
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
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleEditAdmin,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Güncelle'),
        ),
      ],
    );
  }

  void _updatePermissionsForRole() {
    switch (_selectedRole) {
      case AdminRole.superAdmin:
        _selectedPermissions = AdminPermission.values.toList();
        break;
      case AdminRole.systemAdmin:
        _selectedPermissions = [
          AdminPermission.viewUsers,
          AdminPermission.createUsers,
          AdminPermission.editUsers,
          AdminPermission.deleteUsers,
          AdminPermission.viewBusinesses,
          AdminPermission.createBusinesses,
          AdminPermission.editBusinesses,
          AdminPermission.deleteBusinesses,
          AdminPermission.approveBusinesses,
          AdminPermission.viewOrders,
          AdminPermission.editOrders,
          AdminPermission.deleteOrders,
          AdminPermission.viewAnalytics,
          AdminPermission.manageSystemSettings,
          AdminPermission.viewActivityLogs,
          AdminPermission.manageAdminUsers,
          AdminPermission.manageAdmins,
          AdminPermission.manageSystem,
          AdminPermission.viewAuditLogs,
          AdminPermission.moderateContent,
          AdminPermission.manageCategories,
          AdminPermission.manageProducts,
          AdminPermission.viewReports,
        ];
        break;
      case AdminRole.admin:
        _selectedPermissions = [
          AdminPermission.viewBusinesses,
          AdminPermission.editBusinesses,
          AdminPermission.viewCustomers,
          AdminPermission.editCustomers,
          AdminPermission.moderateContent,
          AdminPermission.viewAnalytics,
          AdminPermission.viewReports,
        ];
        break;
      case AdminRole.moderator:
        _selectedPermissions = [
          AdminPermission.viewBusinesses,
          AdminPermission.viewCustomers,
          AdminPermission.moderateContent,
          AdminPermission.viewReports,
        ];
        break;
      case AdminRole.support:
        _selectedPermissions = [
          AdminPermission.viewBusinesses,
          AdminPermission.viewCustomers,
          AdminPermission.viewReports,
        ];
        break;
    }
  }

  Future<void> _handleEditAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = AdminService();
      await adminService.updateAdmin(
        adminId: widget.admin.adminId,
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
            content: Text('Admin başarıyla güncellendi'),
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
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Change Password Dialog
class ChangePasswordDialog extends StatefulWidget {
  final AdminUser admin;
  
  const ChangePasswordDialog({super.key, required this.admin});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
      title: Text('${widget.admin.displayName} Şifresini Değiştir'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                hintText: '••••••••',
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Şifre en az 6 karakter olmalı';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre Tekrar',
                hintText: '••••••••',
              ),
              validator: (value) {
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleChangePassword,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Değiştir'),
        ),
      ],
    );
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = AdminService();
      await adminService.changeAdminPassword(
        adminId: widget.admin.adminId,
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
      setState(() {
        _isLoading = false;
      });
    }
  }
} 