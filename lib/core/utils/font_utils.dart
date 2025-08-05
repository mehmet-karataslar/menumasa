import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🔤 Font Yardımcı Sınıfı
/// 
/// Google Fonts'u güvenli bir şekilde yükler
/// Hata durumunda varsayılan font'a geçer
class FontUtils {
  
  /// Güvenli Google Font yükleme
  /// Hata durumunda Roboto varsayılan font'unu kullanır
  static TextStyle safeGoogleFont(
    String fontFamily, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    } catch (e) {
      // Font bulunamazsa varsayılan font kullan
      print('Font yüklenemedi: $fontFamily, varsayılan Roboto kullanılıyor');
      return TextStyle(
        fontFamily: 'Roboto', // Güvenli varsayılan
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
  }

  /// Desteklenen güvenli font listesi
  static const List<String> safeFontFamilies = [
    'Roboto',
    'Poppins', 
    'Open Sans',
    'Lato',
    'Montserrat',
    'Inter',
    'Nunito',
    'PT Sans',
    'Source Sans 3',
    'Playfair Display',
  ];

  /// Font'un güvenli olup olmadığını kontrol eder
  static bool isSafeFont(String fontFamily) {
    return safeFontFamilies.contains(fontFamily);
  }

  /// Güvenli font listesinden rastgele font seçer
  static String getRandomSafeFont() {
    safeFontFamilies.shuffle();
    return safeFontFamilies.first;
  }
}