# Customer Module 📱

Customer modülü, müşteri deneyimi ve işlevselliği için organize edilmiş, bağımsız bir modüldür. Bu modül Admin ve Business modülleri ile aynı yapıyı takip eder.

## 📁 Klasör Yapısı

```
lib/customer/
├── customer.dart                 # Ana modül export dosyası
├── customer_routes.dart          # Customer rotaları
├── README.md                     # Bu dosya
├── models/                       # Veri modelleri
│   ├── customer_user.dart        # Müşteri kullanıcı modeli
│   ├── customer_session.dart     # Müşteri oturum modeli
│   ├── customer_activity_log.dart # Müşteri aktivite logu
│   ├── customer_preferences.dart  # Müşteri tercihleri
│   └── customer_stats.dart       # Müşteri istatistikleri
├── pages/                        # Sayfa widget'ları
│   ├── customer_dashboard_page.dart   # Ana dashboard (unified & modernized)
│   ├── business_detail_page.dart # İşletme detay sayfası
│   ├── menu_page.dart            # Menü sayfası
│   ├── cart_page.dart            # Sepet sayfası
│   ├── customer_orders_page.dart # Siparişler sayfası
│   ├── search_page.dart          # Arama sayfası
│   └── category_filter_page.dart # Kategori filtreleme
├── services/                     # Servis sınıfları
│   └── customer_service.dart     # Customer servisi
└── widgets/                      # Özel widget'lar
    ├── business_header.dart      # İşletme başlığı
    ├── category_list.dart        # Kategori listesi
    ├── product_grid.dart         # Ürün grid'i
    ├── search_bar.dart           # Arama çubuğu
    └── filter_bottom_sheet.dart  # Filtre bottom sheet
```

## 🎯 Temel Özellikler

### 📱 Customer Pages
- **Home Page**: İşletmeleri görüntüleme ve arama
- **Business Detail**: İşletme detayları ve menü önizleme
- **Menu Page**: Tam menü görüntüleme ve ürün seçimi
- **Cart Page**: Sepet yönetimi ve sipariş verme
- **Orders Page**: Sipariş geçmişi ve takip
- **Search Page**: Gelişmiş arama ve filtreleme

### 🧩 Customer Models
- **CustomerUser**: Müşteri profil ve bilgileri
- **CustomerSession**: Oturum yönetimi
- **CustomerActivityLog**: Aktivite takibi
- **CustomerPreferences**: Kullanıcı tercihleri
- **CustomerStats**: İstatistik ve analitik

### ⚙️ Customer Services
- **CustomerService**: QR kod okuma, oturum yönetimi
- Müşteri verileri yönetimi
- Sipariş geçmişi takibi
- Favori işletme/ürün yönetimi

### 🎨 Customer Widgets
- **BusinessHeader**: İşletme başlık komponenti
- **CategoryList**: Kategori seçim listesi
- **ProductGrid**: Ürün görüntüleme grid'i
- **SearchBar**: Özel arama çubuğu
- **FilterBottomSheet**: Filtreleme paneli

## 🔄 Kullanım

### Modülü İmport Etme
```dart
import 'package:masamenu/customer/customer.dart';
```

### Customer Rotaları
```dart
import 'package:masamenu/customer/customer_routes.dart';

// Rota tanımları
CustomerRoutes.dashboard     // '/customer/dashboard'
CustomerRoutes.menu          // '/customer/menu'
CustomerRoutes.cart          // '/customer/cart'
CustomerRoutes.orders        // '/customer/orders'
```

### Customer Service Kullanımı
```dart
final customerService = CustomerService();

// QR kod tarama
final qrResult = await customerService.scanQRCode(qrData);

// Müşteri oturumu
final session = await customerService.createSession(customerData);

// Favori işletme ekleme
await customerService.addFavoriteBusiness(customerId, businessId);
```

## 🏗️ Mimari Yapı

### Katmanlı Yaklaşım
1. **Pages Layer**: UI sayfaları ve navigasyon
2. **Widgets Layer**: Yeniden kullanılabilir UI bileşenleri
3. **Services Layer**: İş mantığı ve veri işleme
4. **Models Layer**: Veri yapıları ve tip tanımları

### Bağımlılıklar
- Core katmanı (constants, services, utils)
- Data katmanı (models, repositories)
- Presentation katmanı (shared widgets)

## 🔧 Konfigürasyon

### QR Kod Okuma
```dart
// QR kod tarama konfigürasyonu
final qrConfig = QRConfig(
  autoScan: true,
  scanTimeout: Duration(seconds: 30),
  supportedFormats: ['JSON', 'URL'],
);
```

### Müşteri Tercihleri
```dart
// Varsayılan tercihler
final preferences = CustomerPreferences.defaultPreferences(customerId);

// Tercih güncelleme
final updated = preferences.copyWith(
  theme: 'dark',
  language: 'en',
  notificationsEnabled: false,
);
```

## 📊 Özellikler

### ✅ Tamamlanan
- [x] QR kod okuma ve işletme erişimi
- [x] Menü görüntüleme ve ürün seçimi
- [x] Sepet yönetimi ve sipariş verme
- [x] Sipariş takibi ve geçmiş
- [x] Arama ve filtreleme
- [x] Favori işletme/ürün yönetimi
- [x] Müşteri profil ve tercihleri

### 🔄 Devam Eden
- [ ] Sosyal özellikler (yorumlar, puanlama)
- [ ] Ödeme entegrasyonu
- [ ] Bildirim sistemi
- [ ] Offline desteği

### 📋 Planlanan
- [ ] Müşteri sadakat programı
- [ ] Kupon ve indirim sistemi
- [ ] Sosyal medya paylaşımı
- [ ] Canlı sipariş takibi

## 🚀 Performans

### Optimizasyonlar
- Lazy loading ile hızlı sayfa yükleme
- Cache mekanizması ile veri yönetimi
- Optimized image loading
- Pagination ile liste performansı

### Monitoring
- Kullanıcı aktivite takibi
- Crash reporting
- Performance metrics
- User analytics

## 🔒 Güvenlik

### Veri Koruması
- Kullanıcı verilerinin şifrelenmesi
- Secure session management
- API endpoint güvenliği
- GDPR uyumluluğu

## 📝 Katkıda Bulunma

1. Customer modülüne yeni özellik eklerken mevcut yapıyı takip edin
2. Model değişikliklerini migration ile yönetin
3. Test coverage %80'in üzerinde tutun
4. Performance impact'ini değerlendirin

## 📚 Dokümantasyon

- [API Documentation](../docs/api/customer.md)
- [Widget Documentation](../docs/widgets/customer.md)
- [Service Documentation](../docs/services/customer.md)
- [Migration Guide](../docs/migrations/customer.md)

---

**Son Güncelleme**: 2024
**Versiyon**: 1.0.0
**Durum**: ✅ Stabil 