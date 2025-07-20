import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

import '../models/customer_user.dart';
import '../models/customer_session.dart';
import '../models/customer_activity_log.dart';
import '../../business/models/business.dart';
import '../../data/models/order.dart' as app_order;

class CustomerService {
  static const String _customerCollection = 'customers';
  static const String _customerSessionsCollection = 'customer_sessions';
  static const String _customerLogsCollection = 'customer_activity_logs';
  static const String _businessCollection = 'businesses';
  static const String _ordersCollection = 'orders';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CustomerUser? _currentCustomer;
  CustomerSession? _currentSession;

  // Singleton pattern
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  // Getters
  CustomerUser? get currentCustomer => _currentCustomer;
  CustomerSession? get currentSession => _currentSession;
  bool get isLoggedIn => _currentCustomer != null && _currentSession?.isValid == true;

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
} 