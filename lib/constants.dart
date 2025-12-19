import 'package:flutter/material.dart';

class AppColors {
  static const Color primary =  Color(0xFF0F1E3E);//Color(0xFF2E354E);//Colors.blue;
  static const Color onPrimary = Colors.white;//Color(0xFFF5FAC4);//
  static const Color background = Color(0xFF89CFF0);
  //Color(0xFFF5FAC4);//Colors.white;
  static const Color surface = Colors.white;
  static const Color error = Colors.red;
  static const Color onError = Colors.white;
  static const Color newAppBar = Color(0xFF2E354E);
  static const Color newBody = Color(0xFF89CFF0);//Color(0xFFF5FAC4);

}

class AppStyles {
  static const TextStyle titleLarge = TextStyle(
  fontFamily: 'Comic Sans',
  fontSize: 20,
  color: AppColors.onPrimary,
  fontWeight: FontWeight.bold,
  );


  static ButtonStyle buttonStyle =
  ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  padding: EdgeInsets.symmetric(vertical: 14),
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(14),
  ),
  );

  static TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}