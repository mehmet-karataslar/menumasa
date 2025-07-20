import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Notification listeners
  final Map<String, StreamSubscription<QuerySnapshot>?> _notificationStreams = {};
  final Map<String, List<Function(List<NotificationModel>)>> _notificationListeners = {};

  // =============================================================================
  // NOTIFICATION LISTENER MANAGEMENT
  // =============================================================================

  /// İşletme için bildirim listener'ı ekle
  void addNotificationListener(String businessId, Function(List<NotificationModel>) listener) {
    if (!_notificationListeners.containsKey(businessId)) {
      _notificationListeners[businessId] = [];
      _startNotificationStream(businessId);
    }
    _notificationListeners[businessId]!.add(listener);
  }

  /// Bildirim listener'ını kaldır
  void removeNotificationListener(String businessId, Function(List<NotificationModel>) listener) {
    _notificationListeners[businessId]?.remove(listener);
    if (_notificationListeners[businessId]?.isEmpty == true) {
      _notificationListeners.remove(businessId);
      _notificationStreams[businessId]?.cancel();
      _notificationStreams.remove(businessId);
    }
  }

  /// İşletme için bildirim stream'ini başlat
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
            print('Notification stream error for business $businessId: $error');
          },
        );
  }

  /// Bildirim listener'larını bilgilendir
  void _notifyListeners(String businessId, List<NotificationModel> notifications) {
    final listeners = _notificationListeners[businessId];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(notifications);
        } catch (e) {
          print('Error calling notification listener: $e');
        }
      }
    }
  }

  // =============================================================================
  // NOTIFICATION OPERATIONS
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
        message: 'Masa ${tableNumber} - ${customerName}\nToplam: ${totalAmount.toStringAsFixed(2)} ₺',
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
      
      // Haptic feedback için sistemde kayıt
      print('Order notification created: $orderId');
    } catch (e) {
      print('Error creating order notification: $e');
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
      print('Error creating order status notification: $e');
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
      print('Error marking notification as read: $e');
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
      print('Error marking all notifications as read: $e');
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
      print('Error getting unread notification count: $e');
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
      print('Error getting notifications: $e');
      return [];
    }
  }

  // =============================================================================
  // IN-APP NOTIFICATION DISPLAY
  // =============================================================================

  /// App içi bildirim göster
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

    // Auto remove after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Tüm listener'ları temizle
  void dispose() {
    for (final stream in _notificationStreams.values) {
      stream?.cancel();
    }
    _notificationStreams.clear();
    _notificationListeners.clear();
  }
}

// =============================================================================
// NOTIFICATION MODEL
// =============================================================================

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

  factory NotificationModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return NotificationModel(
      id: id ?? json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      type: NotificationType.fromString(json['type'] ?? 'order'),
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

enum NotificationType {
  newOrder('new_order', 'Yeni Sipariş'),
  orderUpdate('order_update', 'Sipariş Güncellendi'),
  system('system', 'Sistem Bildirimi');

  const NotificationType(this.value, this.displayName);

  final String value;
  final String displayName;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.newOrder,
    );
  }
}

// =============================================================================
// IN-APP NOTIFICATION WIDGET
// =============================================================================

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
                    color: AppColors.black.withOpacity(0.1),
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
                        // Icon
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
                        
                        // Content
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
                        
                        // Dismiss button
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

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return AppColors.success;
      case NotificationType.orderUpdate:
        return AppColors.info;
      case NotificationType.system:
        return AppColors.warning;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return Icons.shopping_cart;
      case NotificationType.orderUpdate:
        return Icons.update;
      case NotificationType.system:
        return Icons.info;
    }
  }
} 