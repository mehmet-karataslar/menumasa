enum UserType {
  customer('customer', 'Müşteri'),
  business('business', 'İşletme'),
  admin('admin', 'Yönetici');

  const UserType(this.value, this.displayName);
  final String value;
  final String displayName;

  static UserType fromString(String value) {
    return UserType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UserType.customer,
    );
  }
} 