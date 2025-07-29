/// Model for guest user session data
class QRGuestSession {
  final String guestId;
  final DateTime createdAt;
  final String? businessId;
  final int? tableNumber;

  QRGuestSession({
    required this.guestId,
    required this.createdAt,
    this.businessId,
    this.tableNumber,
  });

  factory QRGuestSession.create({
    String? businessId,
    int? tableNumber,
  }) {
    return QRGuestSession(
      guestId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      businessId: businessId,
      tableNumber: tableNumber,
    );
  }

  QRGuestSession copyWith({
    String? guestId,
    DateTime? createdAt,
    String? businessId,
    int? tableNumber,
  }) {
    return QRGuestSession(
      guestId: guestId ?? this.guestId,
      createdAt: createdAt ?? this.createdAt,
      businessId: businessId ?? this.businessId,
      tableNumber: tableNumber ?? this.tableNumber,
    );
  }
}
