import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';

/// Bildirim servisi - tüm bildirim işlemlerini yönetir
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Bildirim dinleyicileri için haritalar
  final Map<String, StreamSubscription<QuerySnapshot>?> _notificationStreams = {};
  final Map<String, List<Function(List<NotificationModel>)>> _notificationListeners = {};

  bool _isInitialized = false;

  // =============================================================================
  // INITIALIZATION & PERMISSIONS
  // =============================================================================

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Timezone initialization removed (was for flutter_local_notifications)
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      // Request permissions
      await _requestPermissions();
      
      _isInitialized = true;
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    // Local notifications will be handled by Firebase Messaging
    // This method is kept for compatibility but doesn't use flutter_local_notifications
    print('Local notifications initialized via Firebase Messaging');
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _requestPermissions() async {
    // Request notification permission for Android 13+
    if (!kIsWeb) {
      final status = await Permission.notification.request();
      print('Notification permission status: $status');
    }

    // Request Firebase messaging permission for iOS
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );
    
    print('Firebase messaging permission granted: ${settings.authorizationStatus}');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;
    
    final status = await Permission.notification.status;
    return status == PermissionStatus.granted;
  }

  /// Open app settings for notification permissions
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  // =============================================================================
  // LOCAL NOTIFICATIONS
  // =============================================================================

  /// Show local notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    // Local notifications are now handled via Firebase Messaging
    print('Local notification: $title - $body');
  }

  /// Schedule notification for later
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Scheduled notifications are now handled via Firebase Messaging
    print('Schedule notification: $title at $scheduledDate');
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    // Notifications are handled by Firebase Messaging
    print('Cancel notification: $id');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    // Notifications are handled by Firebase Messaging
    print('Cancel all notifications');
  }

  // =============================================================================
  // FIREBASE MESSAGING HANDLERS
  // =============================================================================

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    if (message.notification != null) {
      showLocalNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'MasaMenu',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Handle navigation based on message data
    _navigateBasedOnPayload(message.data);
  }

  void _onNotificationTapped(Map<String, dynamic> payload) {
    print('Local notification tapped: $payload');
    // Handle local notification tap
    _navigateBasedOnPayload(payload);
  }

  void _navigateBasedOnPayload(Map<String, dynamic> data) {
    // TODO: Implement navigation logic based on notification data
    print('Navigation data: $data');
  }

  /// Get FCM token for this device
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  // =============================================================================
  // BİLDİRİM DİNLEYİCİ YÖNETİMİ
  // =============================================================================

  /// İşletme için bildirim dinleyicisi ekle
  void addNotificationListener(String businessId, Function(List<NotificationModel>) listener) {
    if (!_notificationListeners.containsKey(businessId)) {
      _notificationListeners[businessId] = [];
      _startNotificationStream(businessId);
    }
    _notificationListeners[businessId]!.add(listener);
  }

  /// Bildirim dinleyicisini kaldır
  void removeNotificationListener(String businessId, Function(List<NotificationModel>) listener) {
    _notificationListeners[businessId]?.remove(listener);
    if (_notificationListeners[businessId]?.isEmpty == true) {
      _notificationListeners.remove(businessId);
      _notificationStreams[businessId]?.cancel();
      _notificationStreams.remove(businessId);
    }
  }

  /// İşletme için bildirim akışını başlat
  void _startNotificationStream(String businessId) {
    _notificationStreams[businessId] = _firestore
        .collection('notifications')
        .where('businessId', isEqualTo: businessId)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen(
          (snapshot) {
            final notifications = snapshot.docs.map((doc) {
              final data = doc.data();
              return NotificationModel.fromJson(data, id: doc.id);
            }).toList();

            _notifyListeners(businessId, notifications);
          },
          onError: (error) {
            print('İşletme $businessId için bildirim akışı hatası: $error');
          },
        );
  }

  /// Bildirim dinleyicilerini bilgilendir
  void _notifyListeners(String businessId, List<NotificationModel> notifications) {
    final listeners = _notificationListeners[businessId];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(notifications);
        } catch (e) {
          print('Bildirim dinleyicisini çağırma hatası: $e');
        }
      }
    }
  }

  // =============================================================================
  // BİLDİRİM İŞLEMLERİ
  // =============================================================================

  /// Yeni sipariş bildirimi oluştur
  Future<void> createOrderNotification({
    required String businessId,
    required String orderId,
    required String customerName,
    required int tableNumber,
    required double totalAmount,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        businessId: businessId,
        type: NotificationType.newOrder,
        title: 'Yeni Sipariş',
        message: 'Masa $tableNumber - $customerName\nToplam: ${totalAmount.toStringAsFixed(2)} ₺',
        data: {
          'orderId': orderId,
          'customerName': customerName,
          'tableNumber': tableNumber,
          'totalAmount': totalAmount,
        },
        read: false,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toJson());
      
      print('Sipariş bildirimi oluşturuldu: $orderId');
    } catch (e) {
      print('Sipariş bildirimi oluşturma hatası: $e');
    }
  }

  /// Sipariş durumu değişiklik bildirimi
  Future<void> createOrderStatusNotification({
    required String businessId,
    required String orderId,
    required String status,
    required String customerName,
    required int tableNumber,
  }) async {
    try {
      String title = 'Sipariş Güncellendi';
      String message = 'Masa $tableNumber - $customerName\nDurum: $status';

      final notification = NotificationModel(
        id: '',
        businessId: businessId,
        type: NotificationType.orderUpdate,
        title: title,
        message: message,
        data: {
          'orderId': orderId,
          'status': status,
          'customerName': customerName,
          'tableNumber': tableNumber,
        },
        read: false,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toJson());
    } catch (e) {
      print('Sipariş durum bildirimi oluşturma hatası: $e');
    }
  }

  /// Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Bildirimi okundu işaretleme hatası: $e');
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead(String businessId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('businessId', isEqualTo: businessId)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Tüm bildirimleri okundu işaretleme hatası: $e');
    }
  }

  /// Okunmamış bildirim sayısını al
  Future<int> getUnreadCount(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('businessId', isEqualTo: businessId)
          .where('read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Okunmamış bildirim sayısı alma hatası: $e');
      return 0;
    }
  }

  /// Bildirimleri getir
  Future<List<NotificationModel>> getNotifications(String businessId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('businessId', isEqualTo: businessId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationModel.fromJson(data, id: doc.id);
      }).toList();
    } catch (e) {
      print('Bildirimleri alma hatası: $e');
      return [];
    }
  }

  // =============================================================================
  // GENEL BİLDİRİM GÖNDERİMİ
  // =============================================================================

  /// Genel bildirim gönder
  Future<void> sendNotification({
    required String businessId,
    required String recipientId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = {
        'businessId': businessId,
        'recipientId': recipientId,
        'title': title,
        'message': message,
        'type': type.value,
        'data': data ?? {},
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('notifications').add(notification);
    } catch (e) {
      print('Bildirim gönderme hatası: $e');
    }
  }

  // =============================================================================
  // SİPARİŞ BİLDİRİM METODLARİ
  // =============================================================================

  /// Genel sipariş bildirimi gönder
  Future<void> sendOrderNotification({
    required String businessId,
    required String customerId,
    required String title,
    required String message,
    String? orderId,
  }) async {
    await sendNotification(
      businessId: businessId,
      recipientId: customerId,
      title: title,
      message: message,
      type: NotificationType.orderUpdate,
      data: orderId != null ? {'orderId': orderId} : null,
    );
  }

  /// Sipariş onay bildirimi
  Future<void> sendOrderConfirmationNotification(String customerId, String orderId) async {
    await sendOrderNotification(
      businessId: 'business',
      customerId: customerId,
      title: 'Sipariş Onaylandı',
      message: 'Siparişiniz onaylandı ve hazırlanıyor.',
      orderId: orderId,
    );
  }

  /// Sipariş hazırlanıyor bildirimi
  Future<void> sendOrderPreparingNotification(String customerId, String orderId) async {
    await sendOrderNotification(
      businessId: 'business',
      customerId: customerId,
      title: 'Sipariş Hazırlanıyor',
      message: 'Siparişiniz hazırlanıyor.',
      orderId: orderId,
    );
  }

  /// Sipariş hazır bildirimi
  Future<void> sendOrderReadyNotification(String customerId, String orderId) async {
    await sendOrderNotification(
      businessId: 'business',
      customerId: customerId,
      title: 'Sipariş Hazır',
      message: 'Siparişiniz hazır. Teslim alabilirsiniz.',
      orderId: orderId,
    );
  }

  /// Sipariş teslim edildi bildirimi
  Future<void> sendOrderDeliveredNotification(String customerId, String orderId) async {
    await sendOrderNotification(
      businessId: 'business',
      customerId: customerId,
      title: 'Sipariş Teslim Edildi',
      message: 'Siparişiniz teslim edildi.',
      orderId: orderId,
    );
  }

  /// Sipariş iptal bildirimi
  Future<void> sendOrderCancelledNotification(String customerId, String orderId) async {
    await sendOrderNotification(
      businessId: 'business',
      customerId: customerId,
      title: 'Sipariş İptal Edildi',
      message: 'Siparişiniz iptal edildi.',
      orderId: orderId,
    );
  }

  // =============================================================================
  // UYGULAMA İÇİ BİLDİRİM GÖSTERME
  // =============================================================================

  /// Uygulama içi bildirim göster
  void showInAppNotification(
    BuildContext context,
    NotificationModel notification, {
    VoidCallback? onTap,
  }) {
    if (!context.mounted) return;

    HapticFeedback.lightImpact();

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: InAppNotificationWidget(
            notification: notification,
            onTap: () {
              overlayEntry.remove();
              onTap?.call();
            },
            onDismiss: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 4 saniye sonra otomatik kaldır
    Timer(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Tüm dinleyicileri temizle
  void dispose() {
    for (final stream in _notificationStreams.values) {
      stream?.cancel();
    }
    _notificationStreams.clear();
    _notificationListeners.clear();
  }
}

// =============================================================================
// BİLDİRİM MODELİ
// =============================================================================

/// Bildirim veri modeli
class NotificationModel {
  final String id;
  final String businessId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime timestamp;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.businessId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.read,
    required this.timestamp,
    this.readAt,
  });

  /// JSON'dan NotificationModel oluştur
  factory NotificationModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return NotificationModel(
      id: id ?? json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      type: NotificationType.fromString(json['type'] ?? 'order_update'),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      read: json['read'] ?? false,
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      readAt: json['readAt'] != null
          ? (json['readAt'] is Timestamp
              ? (json['readAt'] as Timestamp).toDate()
              : DateTime.parse(json['readAt']))
          : null,
    );
  }

  /// NotificationModel'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'type': type.value,
      'title': title,
      'message': message,
      'data': data,
      'read': read,
      'timestamp': Timestamp.fromDate(timestamp),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }
}

// =============================================================================
// BİLDİRİM TİPLERİ
// =============================================================================

/// Bildirim türleri enum'u
enum NotificationType {
  newOrder('new_order', 'Yeni Sipariş'),
  orderUpdate('order_update', 'Sipariş Güncellendi'),
  waiterCall('waiter_call', 'Garson Çağrısı'),
  promotion('promotion', 'Promosyon'),
  reminder('reminder', 'Hatırlatma'),
  system('system', 'Sistem Bildirimi');

  const NotificationType(this.value, this.displayName);

  final String value;
  final String displayName;

  /// String değerden NotificationType oluştur
  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.orderUpdate,
    );
  }
}

// =============================================================================
// UYGULAMA İÇİ BİLDİRİM WİDGET'I
// =============================================================================

/// Uygulama içi bildirim gösterme widget'ı
class InAppNotificationWidget extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const InAppNotificationWidget({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<InAppNotificationWidget> createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<InAppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // İkon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getTypeColor(widget.notification.type),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _getTypeIcon(widget.notification.type),
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // İçerik
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.notification.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.notification.message,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Kapatma butonu
                        IconButton(
                          onPressed: widget.onDismiss,
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Bildirim tipine göre renk al
  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return AppColors.success;
      case NotificationType.orderUpdate:
        return AppColors.info;
      case NotificationType.waiterCall:
        return AppColors.primary;
      case NotificationType.promotion:
        return AppColors.accent;
      case NotificationType.reminder:
        return AppColors.warning;
      case NotificationType.system:
        return AppColors.warning;
    }
  }

  /// Bildirim tipine göre ikon al
  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return Icons.shopping_cart;
      case NotificationType.orderUpdate:
        return Icons.update;
      case NotificationType.waiterCall:
        return Icons.room_service;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.system:
        return Icons.info;
    }
  }
} 

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Initialize Firebase if needed
  // await Firebase.initializeApp();
}

enum NotificationPriority { low, normal, high, urgent }

 