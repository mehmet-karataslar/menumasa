/// Utility functions for QR Menu operations
class QRMenuUtils {
  QRMenuUtils._();

  /// Generate guest user ID
  static String generateGuestId() {
    return 'guest_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Check if user is in guest mode
  static bool isGuestMode(String? userId) {
    return userId == null || userId.startsWith('guest_');
  }

  /// Format table number for display
  static String formatTableNumber(int? tableNumber) {
    return tableNumber != null ? 'Masa $tableNumber' : 'Genel Menü';
  }

  /// Get business display title
  static String getBusinessTitle(String businessName, int? tableNumber) {
    if (tableNumber != null) {
      return '$businessName - Masa $tableNumber | MasaMenu';
    }
    return '$businessName - Menü | MasaMenu';
  }

  /// Validate business ID format
  static bool isValidBusinessId(String? businessId) {
    if (businessId == null || businessId.isEmpty) return false;
    // Add more validation logic as needed
    return businessId.length > 5;
  }

  /// Format error message for user display
  static String formatErrorForUser(String error) {
    // Use QRErrorUtils for consistent error handling
    return error;
  }
}
