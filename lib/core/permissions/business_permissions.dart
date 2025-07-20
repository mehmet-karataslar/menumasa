enum BusinessPermission {
  // Menu Management
  viewMenu('view_menu', 'Menüyü Görüntüle'),
  editMenu('edit_menu', 'Menüyü Düzenle'),
  addProducts('add_products', 'Ürün Ekle'),
  editProducts('edit_products', 'Ürün Düzenle'),
  deleteProducts('delete_products', 'Ürün Sil'),
  manageCategories('manage_categories', 'Kategorileri Yönet'),
  
  // Order Management
  viewOrders('view_orders', 'Siparişleri Görüntüle'),
  editOrders('edit_orders', 'Siparişleri Düzenle'),
  cancelOrders('cancel_orders', 'Siparişleri İptal Et'),
  managePayments('manage_payments', 'Ödemeleri Yönet'),
  
  // Business Management
  viewAnalytics('view_analytics', 'Analitikleri Görüntüle'),
  manageSettings('manage_settings', 'Ayarları Yönet'),
  manageStaff('manage_staff', 'Personeli Yönet'),
  manageDiscounts('manage_discounts', 'İndirimleri Yönet'),
  manageQrCodes('manage_qr_codes', 'QR Kodları Yönet'),
  
  // Customer Management
  viewCustomers('view_customers', 'Müşterileri Görüntüle'),
  manageCustomers('manage_customers', 'Müşterileri Yönet'),
  
  // Reports
  viewReports('view_reports', 'Raporları Görüntüle'),
  exportData('export_data', 'Veri Dışa Aktar');

  const BusinessPermission(this.value, this.displayName);
  final String value;
  final String displayName;

  static BusinessPermission fromString(String value) {
    return BusinessPermission.values.firstWhere(
      (perm) => perm.value == value,
      orElse: () => BusinessPermission.viewMenu,
    );
  }
} 