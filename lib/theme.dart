import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF1A1A1A);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF000000);
  static const primary = Color(0xFFC8102E);
  static const textOnCard = Color(0xFF1A1A1A);
  static const textSecondaryOnCard = Color(0xFF6B7280);
  static const textOnDark = Color(0xFFF0F0F0);
  static const textSecondaryOnDark = Color(0xFF9CA3AF);
  static const divider = Color(0xFFE5E7EB);
  static const success = Color(0xFF2DC653);
  static const warning = Color(0xFFF4A261);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.background,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textOnDark,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textOnDark),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );
}
