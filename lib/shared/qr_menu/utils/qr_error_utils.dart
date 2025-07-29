/// Utility class for QR error handling and user-friendly messages
class QRErrorUtils {
  QRErrorUtils._();

  /// Convert technical error messages to user-friendly messages
  static String getUserFriendlyErrorMessage(String originalError) {
    if (originalError.contains('İşletme ID\'si bulunamadı')) {
      return 'Bu QR kod geçerli değil veya hasarlı. Lütfen işletmeden yeni bir QR kod isteyin.';
    } else if (originalError.contains('İşletme bulunamadı')) {
      return 'Bu işletme sistemde bulunamıyor. İşletme hesabı kapatılmış olabilir.';
    } else if (originalError.contains('İşletme aktif değil')) {
      return 'Bu işletme şu anda hizmet vermiyor. Lütfen daha sonra tekrar deneyin.';
    } else if (originalError.contains('Veriler yüklenirken hata')) {
      return 'Menü bilgileri yüklenemiyor. İnternet bağlantınızı kontrol edin.';
    } else if (originalError.contains('businesses collection')) {
      return 'Sistemde bir teknik sorun var. Lütfen daha sonra tekrar deneyin.';
    } else if (originalError.contains('Network')) {
      return 'İnternet bağlantısı problemi. Lütfen bağlantınızı kontrol edin.';
    } else if (originalError.contains('Permission')) {
      return 'Erişim izni problemi. Lütfen uygulamayı yeniden başlatın.';
    } else if (originalError.contains('Timeout')) {
      return 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
    } else {
      return 'QR kod okunamadı. Lütfen tekrar deneyin veya işletmeden yardım isteyin.';
    }
  }

  /// Get error category for analytics
  static String getErrorCategory(String error) {
    if (error.contains('QR')) return 'QR_ERROR';
    if (error.contains('Network')) return 'NETWORK_ERROR';
    if (error.contains('Permission')) return 'PERMISSION_ERROR';
    if (error.contains('Business')) return 'BUSINESS_ERROR';
    if (error.contains('Timeout')) return 'TIMEOUT_ERROR';
    return 'GENERAL_ERROR';
  }

  /// Check if error is recoverable
  static bool isRecoverableError(String error) {
    return error.contains('Network') ||
        error.contains('Timeout') ||
        error.contains('Veriler yüklenirken');
  }

  /// Get suggested actions for different error types
  static List<String> getSuggestedActions(String error) {
    if (error.contains('Network') || error.contains('Timeout')) {
      return [
        'İnternet bağlantınızı kontrol edin',
        'WiFi veya mobil veriye geçmeyi deneyin',
        'Bir süre bekleyip tekrar deneyin'
      ];
    } else if (error.contains('QR')) {
      return [
        'QR kodun net ve hasarsız olduğundan emin olun',
        'QR kodu farklı açıdan taramayı deneyin',
        'İşletmeden yeni bir QR kod isteyin'
      ];
    } else if (error.contains('İşletme')) {
      return [
        'İşletmenin aktif olduğunu kontrol edin',
        'İşletme ile direkt iletişime geçin',
        'Farklı bir QR kod deneyin'
      ];
    }
    return [
      'Uygulamayı yeniden başlatın',
      'Daha sonra tekrar deneyin',
      'Destek ekibi ile iletişime geçin'
    ];
  }
}
