# Admin Module - Sistem Yönetimi Modülü

Bu modül, MasaMenu uygulamasının sistem yönetimi işlevlerini sağlar. Tamamen ayrı ve güvenli bir şekilde çalışır.

## 📁 Klasör Yapısı

```
lib/admin/
├── admin.dart                 # Ana modül dosyası
├── admin_routes.dart          # Admin route'ları
├── models/
│   └── admin_user.dart        # Admin kullanıcı modeli
├── services/
│   └── admin_service.dart     # Admin servisleri
├── pages/
│   ├── admin_login_page.dart      # Admin giriş sayfası
│   ├── admin_dashboard_page.dart  # Admin dashboard
│   ├── admin_management_page.dart # Admin yönetimi
│   ├── business_management_page.dart # İşletme yönetimi
│   ├── customer_management_page.dart # Müşteri yönetimi
│   ├── analytics_page.dart        # Analitikler
│   ├── system_settings_page.dart  # Sistem ayarları
│   └── activity_logs_page.dart    # Aktivite logları
├── widgets/                   # Admin widget'ları
└── utils/                     # Admin yardımcı fonksiyonları
```

## 🔐 Güvenlik Özellikleri

- **Ayrı Veri Modeli**: Admin kullanıcıları tamamen ayrı koleksiyonlarda saklanır
- **Rol Tabanlı Erişim**: Farklı admin rolleri ve izinleri
- **Session Yönetimi**: Güvenli oturum yönetimi
- **Aktivite Logları**: Tüm admin işlemleri loglanır
- **Şifre Hashleme**: Güvenli şifre saklama

## 👥 Admin Rolleri

### 1. Süper Yönetici (Super Admin)
- Tüm sistem yetkileri
- Diğer admin kullanıcılarını yönetebilir
- Sistem ayarlarını değiştirebilir

### 2. Yönetici (Admin)
- İşletme ve müşteri yönetimi
- İçerik moderasyonu
- Analitik görüntüleme

### 3. Moderatör (Moderator)
- İçerik moderasyonu
- Rapor görüntüleme
- Temel yönetim işlemleri

### 4. Destek (Support)
- Müşteri desteği
- Temel görüntüleme yetkileri

## 🚀 Kullanım

### Admin Modülünü Başlatma

```dart
// main.dart'ta
await AdminModule.initialize();
```

### Admin Girişi

```dart
// Admin login sayfasına yönlendirme
Navigator.pushNamed(context, '/admin/login');
```

### Admin Dashboard'a Erişim

```dart
// Admin dashboard'a yönlendirme
Navigator.pushNamed(context, '/admin/dashboard');
```

## 📊 İzinler

### İşletme Yönetimi
- `view_businesses`: İşletmeleri görüntüleme
- `edit_businesses`: İşletmeleri düzenleme
- `delete_businesses`: İşletmeleri silme
- `suspend_businesses`: İşletmeleri askıya alma
- `approve_businesses`: İşletmeleri onaylama

### Müşteri Yönetimi
- `view_customers`: Müşterileri görüntüleme
- `edit_customers`: Müşterileri düzenleme
- `delete_customers`: Müşterileri silme
- `ban_customers`: Müşterileri yasaklama

### İçerik Yönetimi
- `moderate_content`: İçerik moderasyonu
- `delete_content`: İçerik silme
- `edit_content`: İçerik düzenleme
- `approve_content`: İçerik onaylama

### Sistem Yönetimi
- `view_analytics`: Analitik görüntüleme
- `manage_system`: Sistem yönetimi
- `view_logs`: Log görüntüleme
- `manage_admins`: Admin yönetimi

## 🔧 Konfigürasyon

### Admin Modülü Ayarları

```dart
// admin.dart'ta
class AdminModule {
  static const String routePrefix = '/admin';
  static const int sessionTimeoutHours = 24;
  static const int maxLoginAttempts = 5;
  static const int passwordMinLength = 6;
}
```

### İlk Admin Kullanıcısı

Sistem ilk kez başlatıldığında otomatik olarak oluşturulur:
- **Kullanıcı Adı**: `superadmin`
- **Şifre**: `admin123`
- **E-posta**: `admin@masamenu.com`

⚠️ **Güvenlik**: İlk girişten sonra şifreyi mutlaka değiştirin!

## 📝 Aktivite Logları

Tüm admin işlemleri otomatik olarak loglanır:

- Giriş/çıkış işlemleri
- Kullanıcı yönetimi
- İçerik değişiklikleri
- Sistem ayarları
- Güvenlik olayları

## 🛡️ Güvenlik Önlemleri

1. **IP Adresi Takibi**: Tüm girişler IP adresi ile loglanır
2. **Session Timeout**: 24 saat sonra otomatik çıkış
3. **Şifre Güvenliği**: Minimum 6 karakter, hash ile saklama
4. **Yetki Kontrolü**: Her işlem için yetki kontrolü
5. **Audit Trail**: Tüm değişiklikler izlenebilir

## 🔄 Route Yapısı

```
/admin/login          # Admin giriş
/admin/dashboard      # Ana dashboard
/admin/businesses     # İşletme yönetimi
/admin/customers      # Müşteri yönetimi
/admin/admins         # Admin yönetimi
/admin/analytics      # Analitikler
/admin/settings       # Sistem ayarları
/admin/logs           # Aktivite logları
```

## 📱 Responsive Tasarım

Admin paneli web ve mobil cihazlarda uyumlu çalışır:
- **Web**: Tam genişlik sidebar menü
- **Mobil**: Hamburger menü
- **Tablet**: Hibrit tasarım

## 🚨 Hata Yönetimi

- Tüm admin işlemleri try-catch blokları ile korunur
- Kullanıcı dostu hata mesajları
- Detaylı log kayıtları
- Otomatik hata raporlama

## 🔧 Geliştirme

### Yeni Admin Sayfası Ekleme

1. `pages/` klasörüne yeni sayfa dosyası ekle
2. `admin_routes.dart`'a route tanımı ekle
3. `admin.dart`'a export ekle
4. Gerekli izinleri tanımla

### Yeni İzin Ekleme

1. `admin_user.dart`'ta `AdminPermission` enum'una ekle
2. `AdminModule`'da izin listesini güncelle
3. İlgili sayfalarda yetki kontrolü ekle

## 📞 Destek

Admin modülü ile ilgili sorunlar için:
- Log dosyalarını kontrol edin
- Aktivite loglarını inceleyin
- Yetki ayarlarını doğrulayın
- Session durumunu kontrol edin 