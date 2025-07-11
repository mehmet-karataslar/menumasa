import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Ana Renk Paleti
  static const Color primary = Color(0xFF2C1810); // Koyu kahverengi
  static const Color primaryLight = Color(0xFF4A2C1A); // Açık kahverengi
  static const Color primaryDark = Color(0xFF1A0E08); // Çok koyu kahverengi

  static const Color secondary = Color(0xFFD4A574); // Altın sarısı
  static const Color secondaryLight = Color(0xFFE8C49A); // Açık altın
  static const Color secondaryDark = Color(0xFFB8924F); // Koyu altın

  static const Color accent = Color(0xFFE74C3C); // Kırmızı accent
  static const Color accentLight = Color(0xFFFF6B5B); // Açık kırmızı
  static const Color accentDark = Color(0xFFC0392B); // Koyu kırmızı

  // Neutral Renkler
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF616161);
  static const Color greyExtraLight = Color(0xFFF5F5F5);
  static const Color lightGrey = Color(0xFFF0F0F0);

  // Border ve UI Renkleri
  static const Color borderColor = Color(0xFFE0E0E0);

  // Semantic Renkler
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Arka Plan Renkleri
  static const Color background = Color(0xFFFAFAFA);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8F8F8);
  static const Color surfaceDark = Color(0xFFE8E8E8);

  // Metin Renkleri
  static const Color textPrimary = Color(0xFF2C1810);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF2C1810);

  // Kart ve Gölge Renkleri
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x33000000);

  // Menü Özel Renkleri
  static const Color menuBackground = Color(0xFFFFFBF5);
  static const Color categoryBackground = Color(0xFFF8F4ED);
  static const Color productBackground = Color(0xFFFFFFFF);
  static const Color priceColor = Color(0xFF2C1810);
  static const Color discountColor = Color(0xFFE74C3C);
  static const Color outOfStockColor = Color(0xFF9E9E9E);

  // Gradient Renkleri
  static const List<Color> primaryGradient = [
    Color(0xFF2C1810),
    Color(0xFF4A2C1A),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFFD4A574),
    Color(0xFFE8C49A),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFE74C3C),
    Color(0xFFFF6B5B),
  ];

  // QR Kod Renkleri
  static const Color qrCodeBackground = Color(0xFFFFFFFF);
  static const Color qrCodeForeground = Color(0xFF2C1810);

  // Admin Panel Renkleri
  static const Color adminPrimary = Color(0xFF1565C0);
  static const Color adminSecondary = Color(0xFF42A5F5);
  static const Color adminAccent = Color(0xFFFF9800);
  static const Color adminBackground = Color(0xFFE3F2FD);

  // Durum Renkleri
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFFFF5722);
  static const Color pending = Color(0xFFFFC107);
  static const Color active = Color(0xFF2196F3);
  static const Color inactive = Color(0xFF9E9E9E);
}

class AppColorScheme {
  static ColorScheme get lightScheme => ColorScheme.light(
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryLight,
    secondary: AppColors.secondary,
    secondaryContainer: AppColors.secondaryLight,
    tertiary: AppColors.accent,
    tertiaryContainer: AppColors.accentLight,
    surface: AppColors.surface,
    background: AppColors.background,
    error: AppColors.error,
    onPrimary: AppColors.textOnPrimary,
    onSecondary: AppColors.textOnSecondary,
    onSurface: AppColors.textPrimary,
    onBackground: AppColors.textPrimary,
    onError: AppColors.white,
    brightness: Brightness.light,
  );

  static ColorScheme get darkScheme => ColorScheme.dark(
    primary: AppColors.primaryLight,
    primaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondaryLight,
    secondaryContainer: AppColors.secondaryDark,
    tertiary: AppColors.accentLight,
    tertiaryContainer: AppColors.accentDark,
    surface: AppColors.primaryDark,
    background: AppColors.black,
    error: AppColors.error,
    onPrimary: AppColors.textOnPrimary,
    onSecondary: AppColors.textOnSecondary,
    onSurface: AppColors.white,
    onBackground: AppColors.white,
    onError: AppColors.white,
    brightness: Brightness.dark,
  );
}
 