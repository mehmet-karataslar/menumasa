# 🏗️ Core Module - Modüler Yapı Rehberi

Bu dokümantasyon, MasaMenu uygulamasının yeni modüler core yapısını açıklamaktadır.

## 📁 Dizin Yapısı

```
lib/core/
├── entities/               # Ana entity sınıfları
│   ├── user_profile.dart      # Kullanıcı profil bilgileri
│   ├── user_auth.dart         # Kimlik doğrulama bilgileri
│   └── business_profile.dart  # İşletme profil bilgileri
├── enums/                  # Enum tanımları
│   ├── user_type.dart         # Kullanıcı tipleri
│   └── user_roles.dart        # Kullanıcı rolleri
├── permissions/            # Yetki tanımları
│   ├── admin_permissions.dart    # Admin yetkileri
│   └── business_permissions.dart # İşletme yetkileri
├── interfaces/            # Soyut arayüzler
│   ├── repository.dart        # Temel repository interface
│   ├── user_repository.dart   # Kullanıcı repository interface
│   ├── database_service.dart  # Veritabanı service interface
│   └── auth_service.dart      # Kimlik doğrulama service interface
├── repositories/          # Repository implementasyonları
│   └── user_repository_impl.dart # Kullanıcı repository Firestore impl
├── services/              # Mevcut servisler
│   ├── permission_service.dart   # Merkezi yetki yönetimi
│   ├── firestore_service.dart    # Firestore servisi
│   ├── auth_service.dart         # Kimlik doğrulama servisi
│   ├── data_service.dart         # Veri servisi
│   ├── cart_service.dart         # Sepet servisi
│   ├── order_service.dart        # Sipariş servisi
│   ├── qr_service.dart           # QR kod servisi
│   └── storage_service.dart      # Dosya depolama servisi
├── exceptions/            # Özel exception sınıfları
│   └── app_exceptions.dart       # Uygulama exception'ları
├── constants/             # Sabitler
│   ├── app_colors.dart           # Renk sabitleri
│   ├── app_typography.dart       # Tipografi sabitleri
│   └── app_dimensions.dart       # Boyut sabitleri
├── utils/                 # Yardımcı fonksiyonlar
│   └── time_rule_utils.dart      # Zaman kuralı yardımcıları
└── core.dart              # Ana export dosyası
```

## 🎯 Modüler Yaklaşımın Avantajları

### ✅ Yeniden Kullanılabilirlik
- Entities farklı modüllerde kullanılabilir
- Services dependency injection ile değiştirilebilir
- Interfaces sayesinde test edilebilirlik arttı

### ✅ Maintainability (Sürdürülebilirlik)
- Her sorumluluk ayrı dosyada
- Büyük dosyalar küçük parçalara bölündü
- Code review daha kolay

### ✅ Scalability (Ölçeklenebilirlik)
- Yeni entities kolayca eklenebilir
- Repository pattern ile farklı database'ler desteklenebilir
- Service abstractions ile farklı implementasyonlar kullanılabilir

### ✅ Testability (Test Edilebilirlik)
- Mock interfaces kolayca oluşturulabilir
- Unit testler bağımsız yazılabilir
- Integration testler daha stabil

## 🧩 Entity Yapısı

### UserProfile
**Amaç:** Kullanıcının temel profil bilgileri
```dart
- id, email, name, phone
- userType, avatarUrl
- createdAt, updatedAt
```

### UserAuth
**Amaç:** Kimlik doğrulama ve güvenlik bilgileri
```dart
- isActive, isEmailVerified
- lastLoginAt, sessionToken
- loginAttempts, isLocked
- lockedUntil
```

### BusinessProfile
**Amaç:** İşletmenin temel profil bilgileri
```dart
- id, ownerId, businessName
- businessDescription, businessType
- businessAddress, logoUrl
- staffIds, categoryIds
```

## 🔐 Permission Sistemi

### Merkezi Yetki Yönetimi
```dart
final permissionService = PermissionService();

// Admin yetki kontrolü
bool canManageUsers = permissionService.hasAdminPermission(
  role,
  userPermissions, 
  AdminPermission.manageUsers
);

// İşletme yetki kontrolü
bool canManageProducts = permissionService.hasBusinessPermission(
  role,
  userPermissions,
  BusinessPermission.manageProducts
);
```

### Rol Tabanlı Varsayılan Yetkiler
```dart
// Admin rolleri için varsayılan yetkiler
List<AdminPermission> permissions = permissionService
    .getDefaultAdminPermissions(AdminRole.admin);

// İşletme rolleri için varsayılan yetkiler
List<BusinessPermission> permissions = permissionService
    .getDefaultBusinessPermissions(BusinessRole.manager);
```

## 🏛️ Repository Pattern

### Interface Tanımı
```dart
abstract class UserRepository extends Repository<UserProfile, String> {
  Future<UserProfile?> getByEmail(String email);
  Future<List<UserProfile>> getByType(UserType userType);
  Future<void> updateAuth(String userId, UserAuth auth);
}
```

### Kullanım
```dart
final UserRepository userRepo = UserRepositoryImpl();

// Kullanıcı getir
final user = await userRepo.getByEmail('user@example.com');

// Kullanıcı kaydet
final userId = await userRepo.save(userProfile);

// Auth bilgisi güncelle
await userRepo.updateAuth(userId, newAuthData);
```

## 🛠️ Service Abstractions

### Database Service
```dart
abstract class DatabaseService {
  Future<Map<String, dynamic>?> getDocument(String collection, String id);
  Future<List<Map<String, dynamic>>> getCollection(String collection);
  Future<String> saveDocument(String collection, Map<String, dynamic> data);
}
```

### Auth Service
```dart
abstract class AuthService {
  Future<UserProfile?> signInWithEmailAndPassword(String email, String password);
  Future<UserProfile?> createUserWithEmailAndPassword(String email, String password, String name);
  Future<void> signOut();
}
```

## 🚨 Exception Handling

### Merkezi Exception Yönetimi
```dart
try {
  await userService.createUser(userData);
} on AuthException catch (e) {
  showError(e.message);
} on ValidationException catch (e) {
  showValidationError(e.message);
} on DataException catch (e) {
  showDataError(e.message);
}
```

### Predefined Exceptions
```dart
// Kimlik doğrulama hataları
throw AuthException.invalidCredentials();
throw AuthException.userNotFound();
throw AuthException.accountLocked();

// Doğrulama hataları
throw ValidationException.required('email');
throw ValidationException.invalidEmail();

// Veri hataları
throw DataException.notFound();
throw DataException.saveFailed();
```

## 📦 Kullanım Örnekleri

### Core Import
```dart
import '../core/core.dart';

// Artık tüm core bileşenler tek import ile kullanılabilir
```

### User Management
```dart
// Kullanıcı profili oluştur
final profile = UserProfile.create(
  id: 'user123',
  email: 'user@example.com',
  name: 'John Doe',
  userType: UserType.customer,
);

// Auth bilgisi oluştur
final auth = UserAuth.initial();

// Repository ile kaydet
final userRepo = UserRepositoryImpl();
await userRepo.save(profile);
await userRepo.updateAuth(profile.id, auth);
```

### Permission Checking
```dart
final permissionService = PermissionService();

if (permissionService.hasBusinessPermission(
  user.role,
  user.permissions,
  BusinessPermission.manageProducts,
)) {
  // Ürün yönetimi işlemleri
}
```

## 🔄 Migration Guide

### Eski Kullanım
```dart
import '../../data/models/user.dart';
import '../../data/models/business.dart';

final user = User(/* büyük constructor */);
```

### Yeni Kullanım
```dart
import '../core/core.dart';

final profile = UserProfile.create(/* basit constructor */);
final auth = UserAuth.initial();
final business = BusinessProfile.create(/* focused constructor */);
```

## 🎯 Gelecek Planları

### ⏭️ Sonraki Adımlar
1. **Domain Layer** genişletilecek
2. **UseCase pattern** eklenecek
3. **Event sourcing** desteği
4. **CQRS pattern** implementasyonu
5. **GraphQL integration**

### 🧪 Test Strategy
1. **Unit Tests** - Her entity ve service için
2. **Integration Tests** - Repository implementations için
3. **Mock Services** - Interface'ler için
4. **E2E Tests** - Full user flows için

## 📝 Best Practices

### ✅ DO
- Entity'ler immutable olmalı (copyWith kullan)
- Interface'leri concrete implementations yerine kullan
- Exception handling için merkezi yapı kullan
- Permission kontrollerini service üzerinden yap

### ❌ DON'T
- Entity'lerde business logic bulundurma
- Direct database calls yapma (repository kullan)
- Generic exception'lar fırlatma
- Büyük constructor'lar oluşturma

## 🤝 Katkıda Bulunma

Yeni modüler yapıya katkıda bulunurken:

1. **Entity** eklerken `entities/` klasörüne ekle
2. **Service** eklerken önce `interfaces/` sonra implementation
3. **Exception** eklerken `app_exceptions.dart`'a ekle
4. **Permission** eklerken ilgili permission dosyasına ekle
5. **Export** etmeyi unutma `core.dart` dosyasında

Bu modüler yapı sayesinde kod daha okunabilir, sürdürülebilir ve test edilebilir hale gelmiştir. 