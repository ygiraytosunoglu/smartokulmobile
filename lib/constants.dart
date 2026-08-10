import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Ana Palet
  static const Color primary       = Color(0xFF1E3A5F);
  static const Color secondary     = Color(0xFF5DADE2);
  static const Color onPrimary     = Colors.white;

  // Durum Renkleri
  static const Color success       = Color(0xFF5EC576);
  static const Color warning       = Color(0xFFF4B740);
  static const Color error         = Color(0xFFE74C3C);
  static const Color onError       = Colors.white;

  // Zemin & Yüzey
  static const Color background    = Color(0xFFF7FAFC);
  static const Color card          = Color(0xFFFFFFFF);
  static const Color divider       = Color(0xFFE5E7EB);
  static const Color surface       = Color(0xFFFFFFFF);

  // Metin
  static const Color textPrimary   = Color(0xFF20242A);
  static const Color textSecondary = Color(0xFF6B7280);

  // Geriye dönük uyumluluk (eski kod kırarsa diye)
  static const Color newAppBar     = primary;
  static const Color newBody       = background;
}

class AppStyles {
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 20,
    color: AppColors.onPrimary,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
  );

  static ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  );

  static TextStyle get buttonTextStyle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  /// Liste kartları için tutarlı derinlik dekorasyonu
  static BoxDecoration get listCardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.divider, width: 0.8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.10),
        blurRadius: 16,
        spreadRadius: -2,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 4,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.9),
        blurRadius: 0,
        spreadRadius: 0,
        offset: const Offset(0, -1),
      ),
    ],
  );

  /// Dropdown ve TextField sarmalayıcı Container için derinlikli dekorasyon
  static BoxDecoration get fieldDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.divider, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.09),
        blurRadius: 12,
        spreadRadius: -1,
        offset: const Offset(0, 5),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 3,
        spreadRadius: 0,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.9),
        blurRadius: 0,
        spreadRadius: 0,
        offset: const Offset(0, -1),
      ),
    ],
  );

  /// TextField için InputDecoration (Container ile birlikte kullanılır)
  static InputDecoration inputDecoration({String? hint, String? label}) =>
      InputDecoration(
        hintText: hint,
        labelText: label,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
      ),
      dividerColor: AppColors.divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}