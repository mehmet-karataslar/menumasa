enum AdminPermission {
  // User Management
  viewUsers('view_users', 'Kullanıcıları Görüntüle'),
  createUsers('create_users', 'Kullanıcı Oluştur'),
  editUsers('edit_users', 'Kullanıcı Düzenle'),
  deleteUsers('delete_users', 'Kullanıcı Sil'),
  viewCustomers('view_customers', 'Müşterileri Görüntüle'),
  editCustomers('edit_customers', 'Müşterileri Düzenle'),
  
  // Business Management
  viewBusinesses('view_businesses', 'İşletmeleri Görüntüle'),
  createBusinesses('create_businesses', 'İşletme Oluştur'),
  editBusinesses('edit_businesses', 'İşletme Düzenle'),
  deleteBusinesses('delete_businesses', 'İşletme Sil'),
  approveBusinesses('approve_businesses', 'İşletme Onayla'),
  
  // Order Management
  viewOrders('view_orders', 'Siparişleri Görüntüle'),
  editOrders('edit_orders', 'Siparişleri Düzenle'),
  deleteOrders('delete_orders', 'Siparişleri Sil'),
  
  // System Management
  viewAnalytics('view_analytics', 'Analitikleri Görüntüle'),
  manageSystemSettings('manage_system_settings', 'Sistem Ayarlarını Yönet'),
  viewActivityLogs('view_activity_logs', 'Aktivite Loglarını Görüntüle'),
  manageAdminUsers('manage_admin_users', 'Admin Kullanıcılarını Yönet'),
  manageAdmins('manage_admins', 'Adminleri Yönet'),
  manageSystem('manage_system', 'Sistemi Yönet'),
  viewAuditLogs('view_audit_logs', 'Denetim Loglarını Görüntüle'),
  
  // Content Management
  moderateContent('moderate_content', 'İçerik Modere Et'),
  manageCategories('manage_categories', 'Kategorileri Yönet'),
  manageProducts('manage_products', 'Ürünleri Yönet'),
  
  // Reports
  viewReports('view_reports', 'Raporları Görüntüle');

  const AdminPermission(this.value, this.displayName);
  final String value;
  final String displayName;

  static AdminPermission fromString(String value) {
    return AdminPermission.values.firstWhere(
      (perm) => perm.value == value,
      orElse: () => AdminPermission.viewUsers,
    );
  }
} 