/// Base exception class for all application exceptions
abstract class AppException implements Exception {
  final String message;
  final String code;
  final Map<String, dynamic>? details;
  final Exception? originalException;

  const AppException(
    this.message, {
    this.code = 'APP_ERROR',
    this.details,
    this.originalException,
  });

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

/// Authentication related exceptions
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code = 'AUTH_ERROR',
    super.details,
    super.originalException,
  });

  // Predefined auth exceptions
  const AuthException.invalidCredentials() : this('Geçersiz kullanıcı adı veya şifre', code: 'INVALID_CREDENTIALS');
  const AuthException.userNotFound() : this('Kullanıcı bulunamadı', code: 'USER_NOT_FOUND');
  const AuthException.userDeactivated() : this('Kullanıcı hesabı devre dışı', code: 'USER_DEACTIVATED');
  const AuthException.emailNotVerified() : this('E-posta adresi doğrulanmamış', code: 'EMAIL_NOT_VERIFIED');
  const AuthException.accountLocked() : this('Hesap geçici olarak kilitlenmiş', code: 'ACCOUNT_LOCKED');
  const AuthException.sessionExpired() : this('Oturum süresi dolmuş', code: 'SESSION_EXPIRED');
  const AuthException.tokenInvalid() : this('Geçersiz token', code: 'TOKEN_INVALID');
}

/// Business logic related exceptions
class BusinessException extends AppException {
  const BusinessException(
    super.message, {
    super.code = 'BUSINESS_ERROR',
    super.details,
    super.originalException,
  });

  // Predefined business exceptions
  const BusinessException.businessNotFound() : this('İşletme bulunamadı', code: 'BUSINESS_NOT_FOUND');
  const BusinessException.businessInactive() : this('İşletme aktif değil', code: 'BUSINESS_INACTIVE');
  const BusinessException.businessNotApproved() : this('İşletme henüz onaylanmamış', code: 'BUSINESS_NOT_APPROVED');
  const BusinessException.insufficientPermissions() : this('Yetersiz yetki', code: 'INSUFFICIENT_PERMISSIONS');
  const BusinessException.businessClosed() : this('İşletme şu anda kapalı', code: 'BUSINESS_CLOSED');
}

/// Customer related exceptions
class CustomerException extends AppException {
  const CustomerException(
    super.message, {
    super.code = 'CUSTOMER_ERROR',
    super.details,
    super.originalException,
  });

  // Predefined customer exceptions
  const CustomerException.customerNotFound() : this('Müşteri bulunamadı', code: 'CUSTOMER_NOT_FOUND');
  const CustomerException.orderNotFound() : this('Sipariş bulunamadı', code: 'ORDER_NOT_FOUND');
  const CustomerException.cartEmpty() : this('Sepet boş', code: 'CART_EMPTY');
  const CustomerException.minimumOrderNotMet() : this('Minimum sipariş tutarı karşılanmamış', code: 'MINIMUM_ORDER_NOT_MET');
}

/// Data/Repository related exceptions
class DataException extends AppException {
  const DataException(
    super.message, {
    super.code = 'DATA_ERROR',
    super.details,
    super.originalException,
  });

  // Predefined data exceptions
  const DataException.notFound() : this('Veri bulunamadı', code: 'DATA_NOT_FOUND');
  const DataException.saveFailed() : this('Veri kaydedilemedi', code: 'SAVE_FAILED');
  const DataException.deleteFailed() : this('Veri silinemedi', code: 'DELETE_FAILED');
  const DataException.updateFailed() : this('Veri güncellenemedi', code: 'UPDATE_FAILED');
  const DataException.connectionFailed() : this('Veritabanı bağlantısı başarısız', code: 'CONNECTION_FAILED');
  const DataException.duplicateEntry() : this('Bu veri zaten mevcut', code: 'DUPLICATE_ENTRY');
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code = 'NETWORK_ERROR',
    super.details,
    super.originalException,
  });

  // Predefined network exceptions
  const NetworkException.noConnection() : this('İnternet bağlantısı yok', code: 'NO_CONNECTION');
  const NetworkException.timeout() : this('Bağlantı zaman aşımına uğradı', code: 'TIMEOUT');
  const NetworkException.serverError() : this('Sunucu hatası', code: 'SERVER_ERROR');
  const NetworkException.badRequest() : this('Geçersiz istek', code: 'BAD_REQUEST');
  const NetworkException.forbidden() : this('Erişim reddedildi', code: 'FORBIDDEN');
  const NetworkException.notFound() : this('Kaynak bulunamadı', code: 'NOT_FOUND');
}

/// Validation related exceptions
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.code = 'VALIDATION_ERROR',
    super.details,
    super.originalException,
  });

  // Predefined validation exceptions
  const ValidationException.required(String field) : this('$field alanı gereklidir', code: 'FIELD_REQUIRED');
  const ValidationException.invalidEmail() : this('Geçersiz e-posta adresi', code: 'INVALID_EMAIL');
  const ValidationException.invalidPhone() : this('Geçersiz telefon numarası', code: 'INVALID_PHONE');
  const ValidationException.passwordTooShort() : this('Şifre çok kısa', code: 'PASSWORD_TOO_SHORT');
  const ValidationException.passwordTooWeak() : this('Şifre çok zayıf', code: 'PASSWORD_TOO_WEAK');
  const ValidationException.invalidFormat(String field) : this('$field alanının formatı geçersiz', code: 'INVALID_FORMAT');
}

/// Permission related exceptions
class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code = 'PERMISSION_ERROR',
    super.details,
    super.originalException,
  });

  // Predefined permission exceptions
  const PermissionException.accessDenied() : this('Erişim reddedildi', code: 'ACCESS_DENIED');
  const PermissionException.insufficientRole() : this('Yetersiz rol yetkisi', code: 'INSUFFICIENT_ROLE');
  const PermissionException.resourceNotOwned() : this('Bu kaynağa sahip değilsiniz', code: 'RESOURCE_NOT_OWNED');
  const PermissionException.featureDisabled() : this('Bu özellik devre dışı', code: 'FEATURE_DISABLED');
}

/// Storage related exceptions
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code = 'STORAGE_ERROR',
    super.details,
    super.originalException,
  });

  // Predefined storage exceptions
  const StorageException.uploadFailed() : this('Dosya yüklenemedi', code: 'UPLOAD_FAILED');
  const StorageException.downloadFailed() : this('Dosya indirilemedi', code: 'DOWNLOAD_FAILED');
  const StorageException.deleteFailed() : this('Dosya silinemedi', code: 'DELETE_FAILED');
  const StorageException.fileNotFound() : this('Dosya bulunamadı', code: 'FILE_NOT_FOUND');
  const StorageException.fileTooLarge() : this('Dosya çok büyük', code: 'FILE_TOO_LARGE');
  const StorageException.invalidFileType() : this('Geçersiz dosya türü', code: 'INVALID_FILE_TYPE');
}

/// Configuration related exceptions
class ConfigException extends AppException {
  const ConfigException(
    super.message, {
    super.code = 'CONFIG_ERROR',
    super.details,
    super.originalException,
  });

  // Predefined config exceptions
  const ConfigException.missingConfig(String key) : this('$key yapılandırması bulunamadı', code: 'MISSING_CONFIG');
  const ConfigException.invalidConfig(String key) : this('$key yapılandırması geçersiz', code: 'INVALID_CONFIG');
  const ConfigException.initializationFailed() : this('Başlatma başarısız', code: 'INITIALIZATION_FAILED');
}

/// Exception handler utility
class ExceptionHandler {
  /// Convert any exception to user-friendly message
  static String getUserMessage(dynamic exception) {
    if (exception is AppException) {
      return exception.message;
    } else if (exception is Exception) {
      return 'Beklenmedik bir hata oluştu';
    } else {
      return 'Bilinmeyen hata';
    }
  }

  /// Get error code from exception
  static String getErrorCode(dynamic exception) {
    if (exception is AppException) {
      return exception.code;
    } else {
      return 'UNKNOWN_ERROR';
    }
  }

  /// Check if exception is retryable
  static bool isRetryable(dynamic exception) {
    if (exception is NetworkException) {
      return exception.code == 'TIMEOUT' || exception.code == 'NO_CONNECTION';
    } else if (exception is DataException) {
      return exception.code == 'CONNECTION_FAILED';
    }
    return false;
  }

  /// Log exception with proper format
  static void logException(dynamic exception, {String? context}) {
    final contextStr = context != null ? '[$context] ' : '';
    
    if (exception is AppException) {
      print('${contextStr}${exception.runtimeType}: ${exception.message} (${exception.code})');
      if (exception.originalException != null) {
        print('Original: ${exception.originalException}');
      }
    } else {
      print('${contextStr}Unhandled Exception: $exception');
    }
  }
} 