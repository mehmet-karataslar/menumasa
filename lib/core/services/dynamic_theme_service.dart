import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../business/models/business.dart';
import '../constants/app_colors.dart';

/// Dinamik tema servis sınıfı
/// İşletme ayarlarına göre real-time tema değişikliklerini yönetir
class DynamicThemeService {
  static final DynamicThemeService _instance = DynamicThemeService._internal();
  factory DynamicThemeService() => _instance;
  DynamicThemeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// İşletme tema ayarlarını dinle
  Stream<MenuSettings> watchBusinessTheme(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final business = Business.fromMap(snapshot.data()!);
        return business.menuSettings;
      }
      // Fallback default settings
      return MenuSettings.defaults();
    });
  }

  /// MenuSettings'den ThemeData oluştur
  ThemeData createThemeData(MenuSettings menuSettings) {
    final primaryColor = _parseColor(menuSettings.colorScheme.primaryColor);
    final secondaryColor = _parseColor(menuSettings.colorScheme.secondaryColor);
    final backgroundColor =
        _parseColor(menuSettings.colorScheme.backgroundColor);
    final textColor = _parseColor(menuSettings.colorScheme.textPrimaryColor);

    final isDark = menuSettings.designTheme.themeType == MenuThemeType.dark ||
        menuSettings.colorScheme.isDark;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,

      // Renk şeması
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        onSurface: textColor,
      ),

      // AppBar tema
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: menuSettings.visualStyle.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(menuSettings.visualStyle.borderRadius),
          ),
        ),
      ),

      // Card tema
      cardTheme: CardThemeData(
        elevation: menuSettings.visualStyle.showShadows
            ? menuSettings.visualStyle.cardElevation
            : 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(menuSettings.visualStyle.borderRadius),
          side: menuSettings.visualStyle.showBorders
              ? BorderSide(
                  color: primaryColor.withOpacity(0.2),
                  width: 1,
                )
              : BorderSide.none,
        ),
      ),

      // Button tema
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(menuSettings.visualStyle.buttonRadius),
          ),
        ),
      ),

      // Text tema
      textTheme: _createTextTheme(menuSettings.typography, textColor),

      // Scaffold tema
      scaffoldBackgroundColor: backgroundColor,
    );
  }

  TextTheme _createTextTheme(MenuTypography typography, Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: typography.fontFamily,
        fontSize: typography.titleFontSize,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: typography.lineHeight,
        letterSpacing: typography.letterSpacing,
      ),
      headlineMedium: TextStyle(
        fontFamily: typography.fontFamily,
        fontSize: typography.headingFontSize,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: typography.lineHeight,
        letterSpacing: typography.letterSpacing,
      ),
      bodyLarge: TextStyle(
        fontFamily: typography.fontFamily,
        fontSize: typography.bodyFontSize,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: typography.lineHeight,
        letterSpacing: typography.letterSpacing,
      ),
      bodyMedium: TextStyle(
        fontFamily: typography.fontFamily,
        fontSize: typography.bodyFontSize * 0.9,
        fontWeight: FontWeight.w400,
        color: textColor.withOpacity(0.8),
        height: typography.lineHeight,
        letterSpacing: typography.letterSpacing,
      ),
    );
  }

  /// Hex string'i Color'a çevir
  Color _parseColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return AppColors.primary; // Fallback color
    }
  }
}

/// Dinamik tema wrapper widget'ı
class DynamicThemeWrapper extends StatelessWidget {
  final String businessId;
  final MenuSettings fallbackSettings;
  final Widget Function(MenuSettings menuSettings, ThemeData themeData) builder;

  const DynamicThemeWrapper({
    super.key,
    required this.businessId,
    required this.fallbackSettings,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MenuSettings>(
      stream: DynamicThemeService().watchBusinessTheme(businessId),
      initialData: fallbackSettings,
      builder: (context, snapshot) {
        final menuSettings = snapshot.data ?? fallbackSettings;
        final themeData = DynamicThemeService().createThemeData(menuSettings);

        return builder(menuSettings, themeData);
      },
    );
  }
}
