import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Font Ailesi
  static const String? fontFamily = null; // Using system default font
  static const String? secondaryFontFamily = null; // Using system default font

  // Font Boyutları
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeRegular = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeExtraLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeXXXLarge = 32.0;

  // Font Kalınlıkları
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Ana Başlık Stilleri
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXXXLarge,
    fontWeight: fontWeightBold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXXLarge,
    fontWeight: fontWeightBold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeExtraLarge,
    fontWeight: fontWeightSemiBold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLarge,
    fontWeight: fontWeightSemiBold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle h5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeRegular,
    fontWeight: fontWeightMedium,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle h6 = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightMedium,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Gövde Metin Stilleri
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeRegular,
    fontWeight: fontWeightRegular,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightRegular,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSmall,
    fontWeight: fontWeightRegular,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSmall,
    fontWeight: fontWeightRegular,
    color: AppColors.textSecondary,
    height: 1.33,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightMedium,
    color: AppColors.textPrimary,
    height: 1.33,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSmall,
    fontWeight: fontWeightRegular,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Buton Stilleri
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeRegular,
    fontWeight: fontWeightSemiBold,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightMedium,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSmall,
    fontWeight: fontWeightMedium,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );

  // Fiyat Stilleri
  static const TextStyle priceRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLarge,
    fontWeight: fontWeightBold,
    color: AppColors.priceColor,
    height: 1.2,
  );

  static const TextStyle priceLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXXLarge,
    fontWeight: fontWeightBold,
    color: AppColors.priceColor,
    height: 1.2,
  );

  static const TextStyle priceDiscount = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeRegular,
    fontWeight: fontWeightMedium,
    color: AppColors.discountColor,
    height: 1.2,
  );

  static const TextStyle priceOriginal = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightRegular,
    color: AppColors.textLight,
    height: 1.2,
    decoration: TextDecoration.lineThrough,
  );

  // Menü Özel Stilleri
  static const TextStyle menuTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXXLarge,
    fontWeight: fontWeightBold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle categoryTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeExtraLarge,
    fontWeight: fontWeightSemiBold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle productTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeRegular,
    fontWeight: fontWeightMedium,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle productDescription = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightRegular,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle businessName = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXXLarge,
    fontWeight: fontWeightBold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle businessDescription = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightRegular,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Form Stilleri
  static const TextStyle inputLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightMedium,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle inputText = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeRegular,
    fontWeight: fontWeightRegular,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle inputHint = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeRegular,
    fontWeight: fontWeightRegular,
    color: AppColors.textLight,
    height: 1.4,
  );

  static const TextStyle inputError = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSmall,
    fontWeight: fontWeightRegular,
    color: AppColors.error,
    height: 1.4,
  );

  // Chip ve Badge Stilleri
  static const TextStyle chipText = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSmall,
    fontWeight: fontWeightMedium,
    color: AppColors.textOnSecondary,
    height: 1.2,
  );

  static const TextStyle badgeText = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSmall,
    fontWeight: fontWeightBold,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );

  // Özel Durumlar
  static const TextStyle outOfStock = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightMedium,
    color: AppColors.outOfStockColor,
    height: 1.4,
  );

  static const TextStyle discount = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightBold,
    color: AppColors.discountColor,
    height: 1.4,
  );

  static const TextStyle newItem = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeSmall,
    fontWeight: fontWeightBold,
    color: AppColors.success,
    height: 1.4,
  );

  // QR Kod Stilleri
  static const TextStyle qrInstructions = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightRegular,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Admin Panel Stilleri
  static const TextStyle adminTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXXLarge,
    fontWeight: fontWeightBold,
    color: AppColors.adminPrimary,
    height: 1.3,
  );

  static const TextStyle adminSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeLarge,
    fontWeight: fontWeightMedium,
    color: AppColors.adminPrimary,
    height: 1.4,
  );

  static const TextStyle adminBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeRegular,
    fontWeight: fontWeightRegular,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Responsive Font Sizes
  static double getResponsiveFontSize(BuildContext context, double fontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return fontSize * 0.9; // Mobil için küçült
    } else if (screenWidth < 900) {
      return fontSize; // Tablet için normal
    } else {
      return fontSize * 1.1; // Desktop için büyüt
    }
  }

  // TextTheme for Material Design
  static TextTheme get textTheme => const TextTheme(
    displayLarge: h1,
    displayMedium: h2,
    displaySmall: h3,
    headlineLarge: h2,
    headlineMedium: h3,
    headlineSmall: h4,
    titleLarge: h3,
    titleMedium: h4,
    titleSmall: h5,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: buttonLarge,
    labelMedium: buttonMedium,
    labelSmall: buttonSmall,
  );
}
 