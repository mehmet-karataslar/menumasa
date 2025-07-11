import '../../../data/models/category.dart';
import '../../../data/models/product.dart';

class TimeRuleUtils {
  /// Verilen zaman kurallarının şu anda aktif olup olmadığını kontrol eder
  static bool areTimeRulesActive(List<TimeRule> timeRules) {
    if (timeRules.isEmpty) return true; // Kural yoksa her zaman aktif

    final now = DateTime.now();
    final currentDay = now.weekday; // 1=Pazartesi, 7=Pazar
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // En az bir kural aktif olmalı
    for (final rule in timeRules) {
      if (!rule.isActive) continue;

      // Günü kontrol et
      if (!rule.dayOfWeek.contains(currentDay % 7))
        continue; // 0=Pazar, 1=Pazartesi konvertasyonu

      // Saati kontrol et
      if (_isTimeInRange(currentTime, rule.startTime, rule.endTime)) {
        return true;
      }
    }

    return false;
  }

  /// Bir ürünün şu anda görünür olup olmadığını kontrol eder
  static bool isProductVisible(Product product) {
    if (!product.isActive || !product.isAvailable) return false;
    return areTimeRulesActive(product.timeRules);
  }

  /// Bir kategorinin şu anda görünür olup olmadığını kontrol eder
  static bool isCategoryVisible(Category category) {
    if (!category.isActive) return false;
    return areTimeRulesActive(category.timeRules);
  }

  /// Belirli bir zamanın verilen aralıkta olup olmadığını kontrol eder
  static bool _isTimeInRange(
    String currentTime,
    String startTime,
    String endTime,
  ) {
    final current = _timeToMinutes(currentTime);
    final start = _timeToMinutes(startTime);
    final end = _timeToMinutes(endTime);

    if (start <= end) {
      // Normal durum: 09:00 - 17:00
      return current >= start && current <= end;
    } else {
      // Gece yarısını geçen durum: 22:00 - 06:00
      return current >= start || current <= end;
    }
  }

  /// Saat:dakika formatını dakikaya çevirir
  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Belirli bir gün ve saat aralığında aktif olan TimeRule oluşturur
  static TimeRule createTimeRule({
    required String ruleId,
    required String name,
    required List<int> dayOfWeek,
    required String startTime,
    required String endTime,
    bool isActive = true,
  }) {
    return TimeRule(
      ruleId: ruleId,
      name: name,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
    );
  }

  /// Haftanın günlerini human-readable formata çevirir
  static String formatDaysOfWeek(List<int> dayOfWeek) {
    const dayNames = [
      'Pazar',
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
    ];

    if (dayOfWeek.length == 7) return 'Her gün';
    if (dayOfWeek.length == 5 && dayOfWeek.every((d) => d >= 1 && d <= 5))
      return 'Hafta içi';
    if (dayOfWeek.length == 2 && dayOfWeek.contains(0) && dayOfWeek.contains(6))
      return 'Hafta sonu';

    return dayOfWeek.map((d) => dayNames[d]).join(', ');
  }

  /// Zaman aralığını human-readable formata çevirir
  static String formatTimeRange(String startTime, String endTime) {
    return '$startTime - $endTime';
  }

  /// Önceden tanımlanmış zaman kuralları
  static List<TimeRule> get predefinedRules => [
    CategoryDefaults.breakfastTimeRule,
    CategoryDefaults.lunchTimeRule,
    CategoryDefaults.dinnerTimeRule,
    CategoryDefaults.weekendOnlyRule,
    CategoryDefaults.weekdayOnlyRule,
  ];

  /// Zaman kuralının aktif olup olmadığını belirli bir tarih için kontrol eder
  static bool isTimeRuleActiveAt(TimeRule rule, DateTime dateTime) {
    if (!rule.isActive) return false;

    final dayOfWeek = dateTime.weekday % 7; // 0=Pazar, 1=Pazartesi
    final currentTime =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (!rule.dayOfWeek.contains(dayOfWeek)) return false;

    return _isTimeInRange(currentTime, rule.startTime, rule.endTime);
  }

  /// Gelecek aktif zaman aralığını bulur
  static DateTime? findNextActiveTime(List<TimeRule> timeRules) {
    if (timeRules.isEmpty) return null;

    final now = DateTime.now();

    // Bugünden başlayarak 7 gün kontrol et
    for (int i = 0; i < 7; i++) {
      final checkDate = now.add(Duration(days: i));

      for (final rule in timeRules) {
        if (!rule.isActive) continue;

        final dayOfWeek = checkDate.weekday % 7;
        if (!rule.dayOfWeek.contains(dayOfWeek)) continue;

        final startParts = rule.startTime.split(':');
        final startDateTime = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          int.parse(startParts[0]),
          int.parse(startParts[1]),
        );

        // Eğer gelecekteki bir zaman ise
        if (startDateTime.isAfter(now)) {
          return startDateTime;
        }
      }
    }

    return null;
  }

  /// Zaman kuralının ne kadar süre daha aktif olacağını hesaplar
  static Duration? getRemainingActiveTime(List<TimeRule> timeRules) {
    if (timeRules.isEmpty) return null;

    final now = DateTime.now();
    final currentDay = now.weekday % 7;
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (final rule in timeRules) {
      if (!rule.isActive) continue;
      if (!rule.dayOfWeek.contains(currentDay)) continue;

      if (_isTimeInRange(currentTime, rule.startTime, rule.endTime)) {
        final endParts = rule.endTime.split(':');
        final endDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );

        // Eğer end time bugünden sonraysa (gece yarısını geçiyor)
        if (endDateTime.isBefore(now)) {
          endDateTime.add(const Duration(days: 1));
        }

        return endDateTime.difference(now);
      }
    }

    return null;
  }
}
 