import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

import '../models/customer_user.dart';
import '../models/customer_session.dart';
import '../models/customer_activity_log.dart';
import '../models/customer_profile.dart';
import '../../business/models/business.dart';
import '../../business/models/product.dart';
import '../../data/models/order.dart' as app_order;
import '../../data/models/user.dart' as app_user;
import '../../core/services/storage_service.dart';

class CustomerService {
  static const String _customerCollection = 'customers';
  static const String _customerSessionsCollection = 'customer_sessions';
  static const String _customerLogsCollection = 'customer_activity_logs';
  static const String _customerProfilesCollection = 'customer_profiles';
  static const String _businessCollection = 'businesses';
  static const String _ordersCollection = 'orders';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  CustomerUser? _currentCustomer;
  CustomerSession? _currentSession;
  CustomerProfile? _currentProfile;

  // Singleton pattern
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  // Getters
  CustomerUser? get currentCustomer => _currentCustomer;
  CustomerSession? get currentSession => _currentSession;
  CustomerProfile? get currentProfile => _currentProfile;
  bool get isLoggedIn => _currentCustomer != null && _currentSession?.isValid == true;

  // PROFILE MANAGEMENT METHODS

  /// Müşteri profili getir
  Future<CustomerProfile?> getCustomerProfile(String customerId) async {
    try {
      final doc = await _firestore
          .collection(_customerProfilesCollection)
          .doc(customerId)
          .get();

      if (doc.exists) {
        return CustomerProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw CustomerException('Profil bilgileri getirilemedi: $e');
    }
  }

  /// Müşteri profili oluştur
  Future<CustomerProfile> createCustomerProfile(String customerId) async {
    try {
      final profile = CustomerProfile.newCustomer(customerId);
      
      await _firestore
          .collection(_customerProfilesCollection)
          .doc(customerId)
          .set(profile.toFirestore());

      _currentProfile = profile;
      return profile;
    } catch (e) {
      throw CustomerException('Profil oluşturulamadı: $e');
    }
  }

  /// Profil bilgilerini güncelle
  Future<CustomerProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? birthDate,
    String? gender,
  }) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Kullanıcı girişi yapılmamış');
      }

      CustomerProfile? profile = _currentProfile;
      
      // Profil yoksa oluştur
      if (profile == null) {
        profile = await createCustomerProfile(_currentCustomer!.customerId);
      }

      // Profili güncelle
      final updatedProfile = profile.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_customerProfilesCollection)
          .doc(_currentCustomer!.customerId)
          .update(updatedProfile.toFirestore());

      _currentProfile = updatedProfile;

      // Activity log
      await _logActivity(
        action: CustomerActionType.profileUpdate,
        details: 'Profil güncellendi: ${[
          if (firstName != null) 'Ad',
          if (lastName != null) 'Soyad',
          if (email != null) 'E-posta',
          if (phone != null) 'Telefon',
          if (birthDate != null) 'Doğum tarihi',
          if (gender != null) 'Cinsiyet',
        ].join(', ')}',
        metadata: {
          'updated_fields': [
            if (firstName != null) 'firstName',
            if (lastName != null) 'lastName',
            if (email != null) 'email',
            if (phone != null) 'phone',
            if (birthDate != null) 'birthDate',
            if (gender != null) 'gender',
          ],
        },
      );

      return updatedProfile;
    } catch (e) {
      throw CustomerException('Profil güncellenemedi: $e');
    }
  }

  /// Profil fotoğrafı yükle
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Kullanıcı girişi yapılmamış');
      }

      // Resmi storage'a yükle
      final imageUrl = await _storageService.uploadProfileImage(
        customerId: _currentCustomer!.customerId,
        imageFile: imageFile,
      );

      // Profildeki resim URL'ini güncelle
      CustomerProfile? profile = _currentProfile;
      
      if (profile == null) {
        profile = await createCustomerProfile(_currentCustomer!.customerId);
      }

      final updatedProfile = profile.copyWith(
        profileImageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_customerProfilesCollection)
          .doc(_currentCustomer!.customerId)
          .update({
            'profileImageUrl': imageUrl,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      _currentProfile = updatedProfile;

      return imageUrl;
    } catch (e) {
      throw CustomerException('Profil fotoğrafı yüklenemedi: $e');
    }
  }

  /// Adres ekle
  Future<CustomerAddress> addAddress(CustomerAddress address) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Kullanıcı girişi yapılmamış');
      }

      CustomerProfile? profile = _currentProfile;
      
      if (profile == null) {
        profile = await createCustomerProfile(_currentCustomer!.customerId);
      }

      final addresses = List<CustomerAddress>.from(profile.addresses);
      
      // Eğer bu ilk adres ise veya default olarak işaretlenmişse diğerlerini default olmaktan çıkar
      if (address.isDefault || addresses.isEmpty) {
        for (int i = 0; i < addresses.length; i++) {
          addresses[i] = CustomerAddress.fromMap(addresses[i].toMap()..['isDefault'] = false);
        }
      }

      addresses.add(address);

      final updatedProfile = profile.copyWith(
        addresses: addresses,
        defaultAddress: address.isDefault ? address : profile.defaultAddress,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_customerProfilesCollection)
          .doc(_currentCustomer!.customerId)
          .update(updatedProfile.toFirestore());

      _currentProfile = updatedProfile;

      return address;
    } catch (e) {
      throw CustomerException('Adres eklenemedi: $e');
    }
  }

  /// Konum ayarlarını güncelle
  Future<LocationSettings> updateLocationSettings(LocationSettings settings) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Kullanıcı girişi yapılmamış');
      }

      CustomerProfile? profile = _currentProfile;
      
      if (profile == null) {
        profile = await createCustomerProfile(_currentCustomer!.customerId);
      }

      final updatedProfile = profile.copyWith(
        locationSettings: settings,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_customerProfilesCollection)
          .doc(_currentCustomer!.customerId)
          .update({
            'locationSettings': settings.toMap(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      _currentProfile = updatedProfile;

      return settings;
    } catch (e) {
      throw CustomerException('Konum ayarları güncellenemedi: $e');
    }
  }

  /// Bildirim ayarlarını güncelle
  Future<NotificationSettings> updateNotificationSettings(NotificationSettings settings) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Kullanıcı girişi yapılmamış');
      }

      CustomerProfile? profile = _currentProfile;
      
      if (profile == null) {
        profile = await createCustomerProfile(_currentCustomer!.customerId);
      }

      final updatedProfile = profile.copyWith(
        notificationSettings: settings,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_customerProfilesCollection)
          .doc(_currentCustomer!.customerId)
          .update({
            'notificationSettings': settings.toMap(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      _currentProfile = updatedProfile;

      return settings;
    } catch (e) {
      throw CustomerException('Bildirim ayarları güncellenemedi: $e');
    }
  }

  /// Gizlilik ayarlarını güncelle
  Future<PrivacySettings> updatePrivacySettings(PrivacySettings settings) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Kullanıcı girişi yapılmamış');
      }

      CustomerProfile? profile = _currentProfile;
      
      if (profile == null) {
        profile = await createCustomerProfile(_currentCustomer!.customerId);
      }

      final updatedProfile = profile.copyWith(
        privacySettings: settings,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_customerProfilesCollection)
          .doc(_currentCustomer!.customerId)
          .update({
            'privacySettings': settings.toMap(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      _currentProfile = updatedProfile;

      return settings;
    } catch (e) {
      throw CustomerException('Gizlilik ayarları güncellenemedi: $e');
    }
  }

  /// İstatistikleri güncelle
  Future<CustomerStatistics> updateStatistics(CustomerStatistics stats) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Kullanıcı girişi yapılmamış');
      }

      CustomerProfile? profile = _currentProfile;
      
      if (profile == null) {
        profile = await createCustomerProfile(_currentCustomer!.customerId);
      }

      final updatedProfile = profile.copyWith(
        statistics: stats,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_customerProfilesCollection)
          .doc(_currentCustomer!.customerId)
          .update({
            'statistics': stats.toMap(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      _currentProfile = updatedProfile;

      return stats;
    } catch (e) {
      throw CustomerException('İstatistikler güncellenemedi: $e');
    }
  }

  /// Profil ve oturum yükle
  Future<void> loadCustomerProfileAndSession(String customerId) async {
    try {
      // Profili yükle
      _currentProfile = await getCustomerProfile(customerId);
      
      // Profil yoksa oluştur
      if (_currentProfile == null) {
        _currentProfile = await createCustomerProfile(customerId);
      }
    } catch (e) {
      throw CustomerException('Müşteri profili yüklenemedi: $e');
    }
  }

  /// QR Kod tarama ile business'a erişim
  Future<Map<String, dynamic>> scanQRCode(String qrCodeData) async {
    try {
      // QR kod data'sını parse et
      final qrData = _parseQRCodeData(qrCodeData);
      
      if (qrData['businessId'] == null) {
        throw CustomerException('Geçersiz QR kod');
      }

      final businessId = qrData['businessId'] as String;
      final tableNumber = qrData['tableNumber'] as String?;

      // Business bilgilerini getir
      final business = await _getBusiness(businessId);
      if (business == null) {
        throw CustomerException('İşletme bulunamadı');
      }

      if (!business.isActive || !business.isOpen) {
        throw CustomerException('İşletme şu anda kapalı');
      }

      // Activity log kaydet
      await _logActivity(
        action: CustomerActionType.qrScan,
        targetType: 'BUSINESS',
        targetId: businessId,
        targetName: business.businessName,
        details: 'QR kod tarandı: ${business.businessName}${tableNumber != null ? ' - Masa $tableNumber' : ''}',
        businessId: businessId,
        qrCodeId: qrCodeData,
        metadata: {
          'tableNumber': tableNumber,
          'scanTime': DateTime.now().toIso8601String(),
        },
      );

      // Customer stats güncelle
      if (_currentCustomer != null) {
        await _updateCustomerStats(
          scannedQRCount: _currentCustomer!.stats.scannedQRCount + 1,
        );
      }

      return {
        'success': true,
        'business': business,
        'tableNumber': tableNumber,
        'message': 'QR kod başarıyla tarandı',
      };
    } catch (e) {
      if (e is CustomerException) rethrow;
      throw CustomerException('QR kod tarama hatası: $e');
    }
  }

  /// Müşteri kayıt/giriş (anonim veya Firebase Auth)
  Future<CustomerUser> createOrGetCustomer({
    String? email,
    String? name,
    String? phone,
    String? deviceId,
    String? fcmToken,
    bool isAnonymous = true,
  }) async {
    try {
      String customerId;
      CustomerUser customer;

      if (isAnonymous) {
        // Anonim müşteri oluştur
        customerId = 'anon_${DateTime.now().millisecondsSinceEpoch}';
        customer = CustomerUser(
          customerId: customerId,
          email: email ?? 'anonymous@customer.com',
          fullName: name ?? 'Misafir',
          phone: phone,
          role: CustomerRole.guest,
          status: CustomerStatus.active,
          favoriteBusinessIds: [],
          favoriteProductIds: [],
          preferences: {},
          stats: CustomerStats.empty(),
          recentOrders: [],
          favorites: [],
          productFavorites: [],
          addresses: [],
          paymentMethods: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // Kayıtlı müşteri
        if (email == null) {
          throw CustomerException('Email gerekli');
        }

        // Mevcut müşteriyi kontrol et
        final existingCustomer = await _getCustomerByEmail(email);
        if (existingCustomer != null) {
          customer = existingCustomer;
          customerId = customer.id;
        } else {
          // Yeni müşteri oluştur
          customerId = _firestore.collection(_customerCollection).doc().id;
          customer = CustomerUser(
            customerId: customerId,
            email: email,
            fullName: name ?? 'Müşteri',
            phone: phone,
            role: CustomerRole.member,
            status: CustomerStatus.active,
            favoriteBusinessIds: [],
            favoriteProductIds: [],
            preferences: {},
            stats: CustomerStats.empty(),
            recentOrders: [],
            favorites: [],
            productFavorites: [],
            addresses: [],
            paymentMethods: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await _firestore
              .collection(_customerCollection)
              .doc(customerId)
              .set(customer.toFirestore());
        }
      }

      // Session oluştur
      final session = await _createSession(
        customerId: customerId,
        deviceId: deviceId,
        fcmToken: fcmToken,
      );

      _currentCustomer = customer;
      _currentSession = session;

      // Activity log kaydet
      await _logActivity(
        action: CustomerActionType.login,
        targetType: 'SYSTEM',
        targetId: 'customer_app',
        details: isAnonymous ? 'Anonim giriş yapıldı' : 'Müşteri girişi yapıldı',
      );

      return customer;
    } catch (e) {
      if (e is CustomerException) rethrow;
      throw CustomerException('Müşteri oluşturma hatası: $e');
    }
  }

  /// Sipariş verme
  Future<String> placeOrder({
    required String businessId,
    required List<Map<String, dynamic>> orderItems,
    String? tableNumber,
    String? notes,
    String? customerName,
    String? customerPhone,
  }) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Giriş yapılması gerekli');
      }

      final business = await _getBusiness(businessId);
      if (business == null) {
        throw CustomerException('İşletme bulunamadı');
      }

      // Sipariş oluştur
      final orderId = _firestore.collection(_ordersCollection).doc().id;
      final order = {
        'id': orderId,
        'businessId': businessId,
        'customerId': _currentCustomer!.id,
        'customerName': customerName ?? _currentCustomer!.name,
        'customerPhone': customerPhone ?? _currentCustomer!.phone,
        'businessName': business.businessName,
        'items': orderItems,
        'totalAmount': orderItems.fold<double>(
          0.0, 
          (sum, item) => sum + (item['price'] * item['quantity']),
        ),
        'status': 'pending',
        'tableNumber': tableNumber,
        'notes': notes,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'orderDate': Timestamp.fromDate(DateTime.now()),
        'isPaid': false,
      };

      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .set(order);

      // Activity log kaydet
      await _logActivity(
        action: CustomerActionType.orderPlace,
        targetType: 'ORDER',
        targetId: orderId,
        targetName: 'Sipariş #${orderId.substring(0, 8)}',
        details: 'Sipariş verildi: ${business.businessName} - ${orderItems.length} ürün',
        businessId: businessId,
        metadata: {
          'orderAmount': order['totalAmount'],
          'itemCount': orderItems.length,
          'tableNumber': tableNumber,
        },
      );

      return orderId;
    } catch (e) {
      if (e is CustomerException) rethrow;
      throw CustomerException('Sipariş verme hatası: $e');
    }
  }

  /// Favorilere ekleme/çıkarma
  Future<void> toggleFavorite(String businessId) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Giriş yapılması gerekli');
      }

      final business = await _getBusiness(businessId);
      if (business == null) {
        throw CustomerException('İşletme bulunamadı');
      }

      final isFavorite = _currentCustomer!.favoriteBusinessIds.contains(businessId);
      
      if (isFavorite) {
        // Favorilerden çıkar
        await _removeFavorite(businessId);
        
        await _logActivity(
          action: CustomerActionType.favoriteRemove,
          targetType: 'BUSINESS',
          targetId: businessId,
          targetName: business.businessName,
          details: 'Favorilerden çıkarıldı: ${business.businessName}',
          businessId: businessId,
        );
      } else {
        // Favorilere ekle
        await _addFavorite(businessId, business);
        
        await _logActivity(
          action: CustomerActionType.favoriteAdd,
          targetType: 'BUSINESS',
          targetId: businessId,
          targetName: business.businessName,
          details: 'Favorilere eklendi: ${business.businessName}',
          businessId: businessId,
        );
      }
    } catch (e) {
      if (e is CustomerException) rethrow;
      throw CustomerException('Favori işlemi hatası: $e');
    }
  }

  /// Müşteri siparişlerini getir
  Future<List<app_order.Order>> getCustomerOrders({int? limit}) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Giriş yapılması gerekli');
      }

      Query query = _firestore
          .collection(_ordersCollection)
          .where('customerId', isEqualTo: _currentCustomer!.id)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => app_order.Order.fromJson(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();
    } catch (e) {
      throw CustomerException('Siparişler alınırken hata: $e');
    }
  }

  /// Ürün favorilerine ekleme/çıkarma
  Future<void> toggleProductFavorite(String productId, String businessId) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Giriş yapılması gerekli');
      }

      // Ürün bilgilerini al
      final product = await _getProduct(productId);
      if (product == null) {
        throw CustomerException('Ürün bulunamadı');
      }

      // İşletme bilgilerini al
      final business = await _getBusiness(businessId);
      if (business == null) {
        throw CustomerException('İşletme bulunamadı');
      }

      final isFavorite = _currentCustomer!.favoriteProductIds.contains(productId);
      
      if (isFavorite) {
        // Favorilerden çıkar
        await _removeProductFavorite(productId);
        
        await _logActivity(
          action: CustomerActionType.favoriteRemove,
          targetType: 'PRODUCT',
          targetId: productId,
          targetName: product.productName,
          details: 'Ürün favorilerden çıkarıldı: ${product.productName} (${business.businessName})',
          businessId: businessId,
        );
      } else {
        // Favorilere ekle
        await _addProductFavorite(productId, product, business);
        
        await _logActivity(
          action: CustomerActionType.favoriteAdd,
          targetType: 'PRODUCT',
          targetId: productId,
          targetName: product.productName,
          details: 'Ürün favorilere eklendi: ${product.productName} (${business.businessName})',
          businessId: businessId,
        );
      }
    } catch (e) {
      if (e is CustomerException) rethrow;
      throw CustomerException('Ürün favori işlemi hatası: $e');
    }
  }

  /// Favori ürünlerden sipariş verme
  Future<String> reorderFromFavorite({
    required String productId,
    required String businessId,
    int quantity = 1,
    String? notes,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
  }) async {
    try {
      if (_currentCustomer == null) {
        throw CustomerException('Giriş yapılması gerekli');
      }

      // Ürün ve işletme bilgilerini al
      final product = await _getProduct(productId);
      if (product == null) {
        throw CustomerException('Ürün bulunamadı');
      }

      final business = await _getBusiness(businessId);
      if (business == null) {
        throw CustomerException('İşletme bulunamadı');
      }

      // Sipariş öğesini oluştur
      final orderItems = [{
        'productId': productId,
        'productName': product.productName,
        'price': product.price,
        'quantity': quantity,
        'notes': notes,
        'businessId': businessId,
      }];

      // Sipariş ver
      final orderId = await placeOrder(
        businessId: businessId,
        orderItems: orderItems,
        tableNumber: tableNumber,
        notes: notes,
        customerName: customerName,
        customerPhone: customerPhone,
      );

      // Ürün favorisini güncelle (sipariş sayısı)
      await _updateProductFavoriteOrderCount(productId);

      // Activity log
      await _logActivity(
        action: CustomerActionType.orderPlace,
        targetType: 'PRODUCT',
        targetId: productId,
        targetName: product.productName,
        details: 'Favori üründen sipariş verildi: ${product.productName}',
        businessId: businessId,
        metadata: {
          'orderId': orderId,
          'quantity': quantity,
          'price': product.price,
          'reorderFromFavorite': true,
        },
      );

      return orderId;
    } catch (e) {
      if (e is CustomerException) rethrow;
      throw CustomerException('Favori üründen sipariş verme hatası: $e');
    }
  }

  /// Favori ürünleri getir
  Future<List<app_user.ProductFavorite>> getFavoriteProducts({String? customerId}) async {
    try {
      String? userId;
      
      if (customerId != null) {
        userId = customerId;
      } else if (_currentCustomer != null) {
        userId = _currentCustomer!.id;
      } else {
        // Eğer customer service'te kullanıcı yoksa boş liste döndür
        return [];
      }

      // CustomerProfile'dan favori ürünleri al
      if (_currentProfile?.productFavorites != null && _currentCustomer != null) {
        return _currentProfile!.productFavorites;
      }

      // Firestore'dan favori ürünleri al
      final query = await _firestore
          .collection('product_favorites')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => app_user.ProductFavorite.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Favori ürünler alınırken hata: $e');
      // Hata durumunda boş liste döndür
      return [];
    }
  }

  // Private helper methods
  Map<String, dynamic> _parseQRCodeData(String qrCodeData) {
    try {
      // URL'den parse et
      final uri = Uri.parse(qrCodeData);
      final businessId = uri.queryParameters['businessId'];
      final tableNumber = uri.queryParameters['table'];
      
      return {
        'businessId': businessId,
        'tableNumber': tableNumber,
      };
    } catch (e) {
      throw CustomerException('QR kod formatı geçersiz');
    }
  }

  Future<Business?> _getBusiness(String businessId) async {
    try {
      final doc = await _firestore.collection(_businessCollection).doc(businessId).get();
      if (doc.exists) {
        return Business.fromJson(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<CustomerUser?> _getCustomerByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(_customerCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return CustomerUser.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<CustomerSession> _createSession({
    required String customerId,
    String? deviceId,
    String? fcmToken,
  }) async {
    final sessionId = _firestore.collection(_customerSessionsCollection).doc().id;
    final session = CustomerSession(
      sessionId: sessionId,
      customerId: customerId,
      businessId: '',
      sessionData: {
        'deviceId': deviceId,
        'fcmToken': fcmToken,
      },
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );

    await _firestore
        .collection(_customerSessionsCollection)
        .doc(sessionId)
        .set(session.toFirestore());

    return session;
  }

  Future<void> _logActivity({
    required CustomerActionType action,
    String? targetType,
    String? targetId,
    String? targetName,
    required String details,
    String? businessId,
    String? qrCodeId,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentCustomer == null) return;

    final log = CustomerActivityLog.create(
      customerId: _currentCustomer!.id,
      activityType: _convertActionToActivityType(action),
      activityData: {
        'customerEmail': _currentCustomer!.email,
        'action': action.toString(),
        'targetType': targetType,
        'targetId': targetId,
        'targetName': targetName,
        'details': details,
        'qrCodeId': qrCodeId,
        'metadata': metadata,
      },
      businessId: businessId,
    );

    await _firestore
        .collection(_customerLogsCollection)
        .add(log.toFirestore());
  }

  /// Convert CustomerActionType to CustomerActivityType
  CustomerActivityType _convertActionToActivityType(CustomerActionType action) {
    switch (action) {
      case CustomerActionType.login:
        return CustomerActivityType.login;
      case CustomerActionType.logout:
        return CustomerActivityType.logout;
      case CustomerActionType.qrScan:
        return CustomerActivityType.qrScan;
      case CustomerActionType.businessVisit:
        return CustomerActivityType.businessView;
      case CustomerActionType.orderPlace:
        return CustomerActivityType.orderPlace;
      case CustomerActionType.orderCancel:
        return CustomerActivityType.orderCancel;
      case CustomerActionType.favoriteAdd:
        return CustomerActivityType.favoriteAdd;
      case CustomerActionType.favoriteRemove:
        return CustomerActivityType.favoriteRemove;
      case CustomerActionType.profileUpdate:
        return CustomerActivityType.profileUpdate;
      default:
        return CustomerActivityType.businessView;
    }
  }

  Future<void> _updateCustomerStats({int? scannedQRCount}) async {
    if (_currentCustomer == null) return;

    final updatedStats = _currentCustomer!.stats.copyWith(
      scannedQRCount: scannedQRCount,
    );

    final updatedCustomer = _currentCustomer!.copyWith(
      stats: updatedStats,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(_customerCollection)
        .doc(_currentCustomer!.id)
        .update(updatedCustomer.toFirestore());

    _currentCustomer = updatedCustomer;
  }

  Future<void> _addFavorite(String businessId, Business business) async {
    if (_currentCustomer == null) return;

    final favorite = CustomerFavorite(
      businessId: businessId,
      type: 'business',
      addedAt: DateTime.now(),
    );

    final updatedFavorites = [..._currentCustomer!.favorites, favorite];
    final updatedFavoriteIds = [..._currentCustomer!.favoriteBusinessIds, businessId];

    final updatedCustomer = _currentCustomer!.copyWith(
      favorites: updatedFavorites,
      favoriteBusinessIds: updatedFavoriteIds,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(_customerCollection)
        .doc(_currentCustomer!.id)
        .update(updatedCustomer.toFirestore());

    _currentCustomer = updatedCustomer;
  }

  Future<void> _removeFavorite(String businessId) async {
    if (_currentCustomer == null) return;

    final updatedFavorites = _currentCustomer!.favorites
        .where((f) => f.businessId != businessId)
        .toList();
    final updatedFavoriteIds = _currentCustomer!.favoriteBusinessIds
        .where((id) => id != businessId)
        .toList();

    final updatedCustomer = _currentCustomer!.copyWith(
      favorites: updatedFavorites,
      favoriteBusinessIds: updatedFavoriteIds,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(_customerCollection)
        .doc(_currentCustomer!.id)
        .update(updatedCustomer.toFirestore());

    _currentCustomer = updatedCustomer;
  }

  // =============================================================================
  // ACTIVITY LOGGING
  // =============================================================================

  /// Log customer activity
  Future<void> logActivity({
    required String action,
    required String details,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentCustomer == null) return;

    try {
      // Action string'i CustomerActionType'a map et
      CustomerActionType? actionType;
      
      switch (action.toLowerCase()) {
        case 'qr_scan':
        case 'qrscan':
          actionType = CustomerActionType.qrScan;
          break;
        case 'business_visit':
        case 'businessvisit':
          actionType = CustomerActionType.businessVisit;
          break;
        case 'order_place':
        case 'orderplace':
          actionType = CustomerActionType.orderPlace;
          break;
        case 'favorite_add':
        case 'favoriteadd':
          actionType = CustomerActionType.favoriteAdd;
          break;
        case 'favorite_remove':
        case 'favoriteremove':
          actionType = CustomerActionType.favoriteRemove;
          break;
        case 'profile_update':
        case 'profileupdate':
          actionType = CustomerActionType.profileUpdate;
          break;
        default:
          // Varsayılan olarak session_start kullan
          actionType = CustomerActionType.sessionStart;
      }

      await _logActivity(
        action: actionType,
        details: details,
        metadata: metadata ?? {},
      );
    } catch (e) {
      print('Activity logging error: $e');
    }
  }

  // Private helper methods için ürün fonksiyonları

  Future<Product?> _getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return Product.fromJson(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _addProductFavorite(String productId, Product product, Business business) async {
    if (_currentCustomer == null) return;

    final favoriteId = _firestore.collection('product_favorites').doc().id;
    final favorite = app_user.ProductFavorite(
      id: favoriteId,
      productId: productId,
      businessId: business.id,
      customerId: _currentCustomer!.id,
      createdAt: DateTime.now(),
      productName: product.productName,
      productDescription: product.description,
      productPrice: product.price,
      productImage: product.imageUrl,
      businessName: business.businessName,
             categoryName: null, // product.categoryName yerine null
      addedDate: DateTime.now(),
    );

    // Firestore'a kaydet
    await _firestore
        .collection('product_favorites')
        .doc(favoriteId)
        .set(favorite.toJson());

    // Local customer data güncelle
    final updatedProductFavorites = [..._currentCustomer!.productFavorites, favorite];
    final updatedFavoriteProductIds = [..._currentCustomer!.favoriteProductIds, productId];

    final updatedCustomer = _currentCustomer!.copyWith(
      productFavorites: updatedProductFavorites,
      favoriteProductIds: updatedFavoriteProductIds,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(_customerCollection)
        .doc(_currentCustomer!.id)
        .update(updatedCustomer.toFirestore());

    _currentCustomer = updatedCustomer;
  }

  Future<void> _removeProductFavorite(String productId) async {
    if (_currentCustomer == null) return;

    // Firestore'dan sil
    final query = await _firestore
        .collection('product_favorites')
        .where('customerId', isEqualTo: _currentCustomer!.id)
        .where('productId', isEqualTo: productId)
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }

    // Local customer data güncelle
    final updatedProductFavorites = _currentCustomer!.productFavorites
        .where((f) => f.productId != productId)
        .toList();
    final updatedFavoriteProductIds = _currentCustomer!.favoriteProductIds
        .where((id) => id != productId)
        .toList();

    final updatedCustomer = _currentCustomer!.copyWith(
      productFavorites: updatedProductFavorites,
      favoriteProductIds: updatedFavoriteProductIds,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(_customerCollection)
        .doc(_currentCustomer!.id)
        .update(updatedCustomer.toFirestore());

    _currentCustomer = updatedCustomer;
  }

  Future<void> _updateProductFavoriteOrderCount(String productId) async {
    if (_currentCustomer == null) return;

    try {
      // Firestore'daki favoriyi güncelle
      final query = await _firestore
          .collection('product_favorites')
          .where('customerId', isEqualTo: _currentCustomer!.id)
          .where('productId', isEqualTo: productId)
          .get();

      for (final doc in query.docs) {
        final currentData = doc.data();
        final currentOrderCount = currentData['orderCount'] ?? 0;
        
        await doc.reference.update({
          'orderCount': currentOrderCount + 1,
          'lastOrderedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      // Local data'yı da güncelle
      final updatedProductFavorites = _currentCustomer!.productFavorites.map((favorite) {
        if (favorite.productId == productId) {
          return favorite.copyWith(
            orderCount: favorite.orderCount + 1,
            lastOrderedAt: DateTime.now(),
          );
        }
        return favorite;
      }).toList();

      final updatedCustomer = _currentCustomer!.copyWith(
        productFavorites: updatedProductFavorites,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_customerCollection)
          .doc(_currentCustomer!.id)
          .update(updatedCustomer.toFirestore());

      _currentCustomer = updatedCustomer;
    } catch (e) {
      print('Product favorite order count update error: $e');
    }
  }
} 