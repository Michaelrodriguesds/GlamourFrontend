import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // ── Cores base ────────────────────────────
    colorScheme: const ColorScheme.dark(
      primary:    AppColors.rose,
      secondary:  AppColors.lavender,
      surface:    AppColors.card,
      error:      AppColors.error,
    ),

    scaffoldBackgroundColor: AppColors.background,

    // ── Tipografia ────────────────────────────
    textTheme: GoogleFonts.poppinsTextTheme(
      const TextTheme(
        displayLarge:  TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
        headlineMedium:TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
        titleLarge:    TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(color: AppColors.text, fontWeight: FontWeight.w500),
        bodyLarge:     TextStyle(color: AppColors.text),
        bodyMedium:    TextStyle(color: AppColors.textMuted),
        labelSmall:    TextStyle(color: AppColors.textDim, letterSpacing: 1.5),
      ),
    ),

    // ── AppBar ────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.card,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: AppColors.text),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // ── Cards ─────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
    ),

    // ── Inputs ────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textDim),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.rose, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),

    // ── Botões ────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.rose,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),

    // ── BottomNav ─────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.rose,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // ── Divider ───────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.cardBorder,
      thickness: 1,
    ),
  );
}