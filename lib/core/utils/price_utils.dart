import 'dart:math' as math;

class PriceUtils {
  /// Türkiye'deki market standartlarına göre fiyat yuvarlama
  /// Kuruş kısmına göre akıllı yuvarlama yapar
  static double roundPriceIntelligent(double price) {
    // Tam sayı kısmı
    final wholePart = price.floor();

    // Kuruş kısmı (0-99 arası)
    final centsPart = ((price - wholePart) * 100).round();

    // Akıllı yuvarlama kuralları
    if (centsPart == 0) {
      // Zaten tam sayı
      return price;
    } else if (centsPart <= 25) {
      // 0-25 kuruş arası: aşağı yuvarla
      return wholePart.toDouble();
    } else if (centsPart <= 75) {
      // 26-75 kuruş arası: 50 kuruşa yuvarla
      return wholePart + 0.5;
    } else {
      // 76-99 kuruş arası: yukarı yuvarla
      return (wholePart + 1).toDouble();
    }
  }

  /// Psikolojik fiyatlama için 0.99 fiyatlandırması
  static double roundToPsychological(double price) {
    final wholePart = price.floor();

    // Eğer fiyat zaten .99 ile bitiyorsa dokunma
    if (price - wholePart >= 0.99) {
      return price;
    }

    // Aksi takdirde .99 yap
    return wholePart + 0.99;
  }

  /// Rekabetçi fiyatlama - en yakın 5 veya 10'a yuvarla
  static double roundToCompetitive(double price) {
    final wholePart = price.floor();
    final centsPart = ((price - wholePart) * 100).round();

    if (centsPart <= 25) {
      return wholePart.toDouble();
    } else if (centsPart <= 50) {
      return wholePart + 0.5;
    } else if (centsPart <= 75) {
      return wholePart + 0.5;
    } else {
      return (wholePart + 1).toDouble();
    }
  }

  /// Premium fiyatlama - yukarı yuvarla
  static double roundToPremium(double price) {
    return price.ceil().toDouble();
  }

  /// Ekonomik fiyatlama - aşağı yuvarla
  static double roundToEconomic(double price) {
    return price.floor().toDouble();
  }

  /// Fiyat formatları
  static String formatPrice(
    double price, {
    String currency = 'TL',
    bool showCurrency = true,
  }) {
    String formatted;

    if (price % 1 == 0) {
      // Tam sayı
      formatted = price.toInt().toString();
    } else if (price % 0.5 == 0) {
      // Yarım sayı (.5)
      formatted = price.toStringAsFixed(1).replaceAll('.0', '');
    } else {
      // Kuruşlu
      formatted = price.toStringAsFixed(2);
    }

    return showCurrency ? '$formatted $currency' : formatted;
  }

  /// Fiyat karşılaştırma
  static String comparePrices(
    double originalPrice,
    double discountedPrice, {
    String currency = 'TL',
  }) {
    final savings = originalPrice - discountedPrice;
    final percentSavings = (savings / originalPrice) * 100;

    return '${formatPrice(discountedPrice, currency: currency)} '
        '(${formatPrice(originalPrice, currency: currency)} yerine, '
        '%${percentSavings.toStringAsFixed(0)} tasarruf)';
  }

  /// Fiyat aralığı kontrolü
  static bool isPriceInRange(double price, double minPrice, double maxPrice) {
    return price >= minPrice && price <= maxPrice;
  }

  /// Fiyat artış/azalış hesaplama
  static double calculatePriceChange(double oldPrice, double newPrice) {
    return ((newPrice - oldPrice) / oldPrice) * 100;
  }

  /// Fiyat gradasyonu oluşturma (küçükten büyüğe)
  static List<double> createPriceGradation(
    double startPrice,
    double endPrice,
    int steps,
  ) {
    final List<double> prices = [];
    final increment = (endPrice - startPrice) / (steps - 1);

    for (int i = 0; i < steps; i++) {
      prices.add(startPrice + (increment * i));
    }

    return prices;
  }

  /// Ortalama fiyat hesaplama
  static double calculateAveragePrice(List<double> prices) {
    if (prices.isEmpty) return 0.0;
    return prices.reduce((a, b) => a + b) / prices.length;
  }

  /// Medyan fiyat hesaplama
  static double calculateMedianPrice(List<double> prices) {
    if (prices.isEmpty) return 0.0;

    final sortedPrices = List<double>.from(prices)..sort();
    final middle = sortedPrices.length ~/ 2;

    if (sortedPrices.length % 2 == 0) {
      return (sortedPrices[middle - 1] + sortedPrices[middle]) / 2;
    } else {
      return sortedPrices[middle];
    }
  }

  /// Fiyat dağılımı analizi
  static Map<String, double> analyzePriceDistribution(List<double> prices) {
    if (prices.isEmpty) {
      return {
        'min': 0.0,
        'max': 0.0,
        'average': 0.0,
        'median': 0.0,
        'standardDeviation': 0.0,
      };
    }

    final min = prices.reduce(math.min);
    final max = prices.reduce(math.max);
    final average = calculateAveragePrice(prices);
    final median = calculateMedianPrice(prices);

    // Standart sapma hesaplama
    final variance =
        prices
            .map((price) => math.pow(price - average, 2))
            .reduce((a, b) => a + b) /
        prices.length;
    final standardDeviation = math.sqrt(variance);

    return {
      'min': min,
      'max': max,
      'average': average,
      'median': median,
      'standardDeviation': standardDeviation,
    };
  }

  /// Fiyat kategorisi belirleme
  static PriceCategory determinePriceCategory(
    double price,
    List<double> allPrices,
  ) {
    if (allPrices.isEmpty) return PriceCategory.medium;

    final stats = analyzePriceDistribution(allPrices);
    final average = stats['average']!;
    final standardDeviation = stats['standardDeviation']!;

    if (price < average - standardDeviation) {
      return PriceCategory.low;
    } else if (price > average + standardDeviation) {
      return PriceCategory.high;
    } else {
      return PriceCategory.medium;
    }
  }

  /// Dinamik fiyat önerileri
  static List<double> suggestPrices(
    double basePrice, {
    bool includePsychological = true,
    bool includeCompetitive = true,
    bool includePremium = true,
  }) {
    final Set<double> suggestions = {};

    // Temel fiyat
    suggestions.add(basePrice);

    // Akıllı yuvarlama
    suggestions.add(roundPriceIntelligent(basePrice));

    if (includePsychological) {
      suggestions.add(roundToPsychological(basePrice));
    }

    if (includeCompetitive) {
      suggestions.add(roundToCompetitive(basePrice));
    }

    if (includePremium) {
      suggestions.add(roundToPremium(basePrice));
    }

    // Yakın fiyat seçenekleri
    suggestions.add(basePrice * 0.95); // %5 indirim
    suggestions.add(basePrice * 1.05); // %5 artış

    return suggestions.toList()..sort();
  }
}

/// Fiyat kategorisi enum'u
enum PriceCategory {
  low('Düşük'),
  medium('Orta'),
  high('Yüksek');

  const PriceCategory(this.displayName);
  final String displayName;
}

/// Gelişmiş fiyat yuvarlama kuralları
enum SmartPriceRoundingRule {
  intelligent('Akıllı Yuvarlama'),
  psychological('Psikolojik Fiyatlama'),
  competitive('Rekabetçi Fiyatlama'),
  premium('Premium Fiyatlama'),
  economic('Ekonomik Fiyatlama');

  const SmartPriceRoundingRule(this.displayName);
  final String displayName;

  /// Yuvarlama kuralını uygula
  double apply(double price) {
    switch (this) {
      case SmartPriceRoundingRule.intelligent:
        return PriceUtils.roundPriceIntelligent(price);
      case SmartPriceRoundingRule.psychological:
        return PriceUtils.roundToPsychological(price);
      case SmartPriceRoundingRule.competitive:
        return PriceUtils.roundToCompetitive(price);
      case SmartPriceRoundingRule.premium:
        return PriceUtils.roundToPremium(price);
      case SmartPriceRoundingRule.economic:
        return PriceUtils.roundToEconomic(price);
    }
  }
}

/// Fiyat yuvarlama extension'u
extension PriceRoundingExtension on double {
  /// Akıllı yuvarlama
  double get roundedIntelligent => PriceUtils.roundPriceIntelligent(this);

  /// Psikolojik fiyatlama
  double get roundedPsychological => PriceUtils.roundToPsychological(this);

  /// Rekabetçi fiyatlama
  double get roundedCompetitive => PriceUtils.roundToCompetitive(this);

  /// Premium fiyatlama
  double get roundedPremium => PriceUtils.roundToPremium(this);

  /// Ekonomik fiyatlama
  double get roundedEconomic => PriceUtils.roundToEconomic(this);

  /// Fiyat formatı
  String formatPrice({String currency = 'TL', bool showCurrency = true}) {
    return PriceUtils.formatPrice(
      this,
      currency: currency,
      showCurrency: showCurrency,
    );
  }
}
