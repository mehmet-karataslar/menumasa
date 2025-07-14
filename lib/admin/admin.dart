import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/admin_service.dart';
import 'models/admin_user.dart';
import 'models/admin_session.dart';
import 'models/admin_activity_log.dart';

export 'models/admin_user.dart';

// Services
export 'services/admin_service.dart';

// Pages
export 'pages/admin_login_page.dart';
export 'pages/admin_dashboard_page.dart';
export 'pages/admin_management_page.dart';

export 'pages/customer_management_page.dart';
export 'pages/analytics_page.dart';
export 'pages/system_settings_page.dart';
export 'pages/activity_logs_page.dart';

// Routes
export 'admin_routes.dart';

// Admin Module Configuration
class AdminModule {
  static const String moduleName = 'Admin Module';
  static const String version = '1.0.0';
  static const String description = 'Sistem Yönetimi Modülü';
  
  // Admin route prefix
  static const String routePrefix = '/admin';
  
  // Admin collection names
  static const String adminUsersCollection = 'admin_users';
  static const String adminSessionsCollection = 'admin_sessions';
  static const String adminLogsCollection = 'admin_activity_logs';
  
  // Admin security settings
  static const int sessionTimeoutHours = 24;
  static const int maxLoginAttempts = 5;
  static const int passwordMinLength = 6;
  
  // Admin permissions
  static const List<String> superAdminPermissions = [
    'view_businesses',
    'edit_businesses',
    'delete_businesses',
    'suspend_businesses',
    'approve_businesses',
    'view_customers',
    'edit_customers',
    'delete_customers',
    'ban_customers',
    'moderate_content',
    'delete_content',
    'edit_content',
    'approve_content',
    'view_analytics',
    'manage_system',
    'view_logs',
    'manage_admins',
    'view_reports',
    'manage_reports',
    'view_audit_logs',
    'manage_settings',
    'manage_categories',
    'manage_tags',
  ];
  
  // Admin roles
  static const Map<String, String> adminRoles = {
    'super_admin': 'Süper Yönetici',
    'admin': 'Yönetici',
    'moderator': 'Moderatör',
    'support': 'Destek',
  };
  
  /// Admin modülünü başlat
  static Future<void> initialize() async {
    print('$moduleName v1.0.0 başlatılıyor...');
    
    try {
      // Firebase Authentication durumunu kontrol et
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      if (currentUser != null) {
        // Kullanıcı zaten giriş yapmış, admin bilgilerini kontrol et
        try {
          final adminDoc = await FirebaseFirestore.instance
              .collection('admin_users')
              .doc(currentUser.uid)
              .get();
          
          if (adminDoc.exists) {
            final adminData = adminDoc.data()!;
            if (adminData['isActive']) {
              print('Mevcut admin oturumu bulundu');
              return;
            }
          }
        } catch (e) {
          print('Admin oturumu kontrol edilirken hata: $e');
        }
      }
      
      // Admin kullanıcılarını kontrol et (Firebase Auth olmadan)
      try {
        final adminQuery = await FirebaseFirestore.instance
            .collection('admin_users')
            .limit(1)
            .get();
        
        // Eğer hiç admin yoksa, ilk admin'i oluştur
        if (adminQuery.docs.isEmpty) {
          print('İlk admin kullanıcısı oluşturuluyor...');
          
          // Firebase Authentication ile ilk admin'i oluştur
          final adminEmail = 'superadmin@admin.masamenu.com';
          final adminPassword = 'admin123';
          
          try {
            final userCredential = await auth.createUserWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );
            
            // Firestore'a admin bilgilerini kaydet
            await FirebaseFirestore.instance
                .collection('admin_users')
                .doc(userCredential.user!.uid)
                .set({
              'id': userCredential.user!.uid,
              'username': 'superadmin',
              'email': adminEmail,
              'name': 'Süper Yönetici',
              'role': 'superAdmin',
              'permissions': AdminPermission.values.map((p) => p.value).toList(),
              'createdAt': DateTime.now().toIso8601String(),
              'lastLoginAt': DateTime.now().toIso8601String(),
              'isActive': true,
              'passwordHash': '', // Firebase Auth kullandığımız için boş
            });
            
            print('İlk admin kullanıcısı oluşturuldu: superadmin / admin123');
            print('⚠️  Güvenlik için şifreyi değiştirmeyi unutmayın!');
          } catch (e) {
            print('İlk admin oluşturulurken hata: $e');
          }
        } else {
          print('Mevcut admin kullanıcıları bulundu');
        }
      } catch (e) {
        print('Admin kullanıcıları kontrol edilirken hata: $e');
      }
    } catch (e) {
      print('Admin modülü başlatılırken hata: $e');
    }
    
    print('$moduleName başarıyla başlatıldı');
  }
  
  // İlk admin kullanıcısını oluştur
  static Future<void> _createInitialAdmin() async {
    try {
      // Admin service'i başlat
      final adminService = AdminService();
      
      // Admin kullanıcılarını kontrol et (yetki kontrolü yapma)
      List<AdminUser> admins = [];
      try {
        admins = await adminService.getAllAdmins(skipPermissionCheck: true);
      } catch (e) {
        print('Admin kullanıcıları kontrol edilirken hata: $e');
        // Firestore permission hatası durumunda boş liste kullan
        admins = [];
      }
      
      // Eğer hiç admin yoksa, ilk admin'i oluştur
      if (admins.isEmpty) {
        try {
          await adminService.createAdmin(
            username: 'superadmin',
            email: 'admin@masamenu.com',
            fullName: 'Süper Yönetici',
            password: 'admin123',
            role: AdminRole.superAdmin,
            permissions: AdminPermission.values.toList(),
            skipPermissionCheck: true, // İlk admin için yetki kontrolü yapma
          );
          
          print('İlk admin kullanıcısı oluşturuldu: superadmin / admin123');
          print('⚠️  Güvenlik için şifreyi değiştirmeyi unutmayın!');
        } catch (createError) {
          print('İlk admin oluşturulurken hata: $createError');
          // Admin oluşturma hatası durumunda devam et
        }
      }
    } catch (e) {
      print('İlk admin oluşturulurken genel hata: $e');
    }
  }
  
  // Admin route kontrolü
  static bool isAdminRoute(String route) {
    return route.startsWith(routePrefix);
  }
  
  // Admin güvenlik kontrolü
  static bool isSecureRoute(String route) {
    final secureRoutes = [
      '$routePrefix/dashboard',
      '$routePrefix/businesses',
      '$routePrefix/customers',
      '$routePrefix/admins',
      '$routePrefix/analytics',
      '$routePrefix/settings',
      '$routePrefix/logs',
    ];
    
    return secureRoutes.contains(route);
  }
  
  // Admin modülü kapatma
  static Future<void> dispose() async {
    print('$moduleName kapatılıyor...');
    
    // Admin service'i temizle
    try {
      final adminService = AdminService();
      await adminService.signOut();
    } catch (e) {
      print('Admin service kapatılırken hata: $e');
    }
    
    print('$moduleName kapatıldı');
  }
}

// Admin Module Constants
class AdminConstants {
  // Admin UI Constants
  static const double sidebarWidth = 280.0;
  static const double headerHeight = 64.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;
  
  // Admin Colors
  static const int adminPrimaryColor = 0xFFD32F2F; // Error color
  static const int adminSecondaryColor = 0xFF1976D2; // Primary color
  static const int adminSuccessColor = 0xFF388E3C; // Success color
  static const int adminWarningColor = 0xFFF57C00; // Warning color
  
  // Admin Text Styles
  static const String adminFontFamily = 'Poppins';
  static const double adminFontSize = 14.0;
  static const double adminHeaderFontSize = 18.0;
  
  // Admin Spacing
  static const double adminPadding = 16.0;
  static const double adminMargin = 8.0;
  static const double adminSpacing = 12.0;
  
  // Admin Animation
  static const Duration adminAnimationDuration = Duration(milliseconds: 300);
}

// Admin Module Utils
class AdminUtils {
  // Tarih formatla
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  // Dosya boyutu formatla
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  // IP adresi gizle
  static String maskIpAddress(String ip) {
    final parts = ip.split('.');
    if (parts.length == 4) {
      return '${parts[0]}.${parts[1]}.*.*';
    }
    return ip;
  }
  
  // Email gizle
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length == 2) {
      final username = parts[0];
      final domain = parts[1];
      
      if (username.length <= 2) {
        return '$username***@$domain';
      }
      
      return '${username.substring(0, 2)}***@$domain';
    }
    return email;
  }
  
  // Güvenli şifre kontrolü
  static bool isSecurePassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }
  
  // Şifre gücü hesapla
  static int calculatePasswordStrength(String password) {
    int strength = 0;
    
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    
    return strength;
  }
  
  // Şifre gücü metni
  static String getPasswordStrengthText(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Çok Zayıf';
      case 2:
        return 'Zayıf';
      case 3:
        return 'Orta';
      case 4:
        return 'Güçlü';
      case 5:
        return 'Çok Güçlü';
      default:
        return 'Bilinmiyor';
    }
  }
  
  // Şifre gücü rengi
  static int getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 0xFFD32F2F; // Red
      case 2:
        return 0xFFFF9800; // Orange
      case 3:
        return 0xFFFFEB3B; // Yellow
      case 4:
        return 0xFF4CAF50; // Green
      case 5:
        return 0xFF2E7D32; // Dark Green
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
} 