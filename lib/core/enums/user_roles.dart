enum CustomerRole {
  regular('regular', 'Normal Müşteri'),
  premium('premium', 'Premium Müşteri'),
  vip('vip', 'VIP Müşteri');

  const CustomerRole(this.value, this.displayName);
  final String value;
  final String displayName;

  static CustomerRole fromString(String value) {
    return CustomerRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => CustomerRole.regular,
    );
  }
}

enum BusinessRole {
  owner('owner', 'İşletme Sahibi', 'Tam işletme kontrolü'),
  manager('manager', 'Yönetici', 'Genel yönetim yetkileri'),
  staff('staff', 'Personel', 'Temel işlemler'),
  cashier('cashier', 'Kasiyer', 'Sipariş ve ödeme işlemleri');

  const BusinessRole(this.value, this.displayName, this.description);
  final String value;
  final String displayName;
  final String description;

  static BusinessRole fromString(String value) {
    return BusinessRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => BusinessRole.staff,
    );
  }
}

enum AdminRole {
  superAdmin('super_admin', 'Süper Admin', 'Tam sistem kontrolü'),
  systemAdmin('system_admin', 'Sistem Admin', 'Sistem yönetimi'),
  admin('admin', 'Admin', 'Genel yönetim'),
  moderator('moderator', 'Moderatör', 'İçerik moderasyonu'),
  support('support', 'Destek', 'Müşteri desteği');

  const AdminRole(this.value, this.displayName, this.description);
  final String value;
  final String displayName;
  final String description;

  static AdminRole fromString(String value) {
    return AdminRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => AdminRole.support,
    );
  }
} 