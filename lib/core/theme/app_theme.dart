import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  /// Tema do Material montado a partir da PALETA ativa (AppColors.palette).
  /// É um `get`: cada vez que o app é redesenhado depois de trocar o
  /// estilo, o tema é montado de novo com as cores novas.
  static ThemeData get current {
    final p = AppColors.palette;
    final scheme = p.isDark
        ? ColorScheme.dark(
            primary:   AppColors.rose,
            onPrimary: Colors.white,
            secondary: AppColors.lavender,
            surface:   AppColors.card,
            onSurface: AppColors.text,
            error:     AppColors.error,
          )
        : ColorScheme.light(
            primary:   AppColors.rose,
            onPrimary: Colors.white,
            secondary: AppColors.lavender,
            surface:   AppColors.card,
            onSurface: AppColors.text,
            error:     AppColors.error,
          );
    return _build(p.brightness, scheme);
  }

  static ThemeData _build(Brightness brightness, ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    brightness: brightness,

    // ── Cores base ────────────────────────────
    colorScheme: scheme,

    scaffoldBackgroundColor: AppColors.background,

    // ── Tipografia ────────────────────────────
    textTheme: GoogleFonts.poppinsTextTheme(
      TextTheme(
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
      iconTheme: IconThemeData(color: AppColors.text),
      // Ícones da barra de status: claros no tema escuro, escuros no claro.
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),

    // ── Cards ─────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.cardBorder),
      ),
    ),

    // ── Inputs ────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      labelStyle: TextStyle(color: AppColors.textMuted),
      hintStyle: TextStyle(color: AppColors.textDim),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.rose, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
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
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.rose,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // ── Painéis de baixo (bottom sheets) ──────
    // Em tela larga (PC/notebook) o painel não estica pela tela toda:
    // fica centralizado com no máximo 640 px. No celular nada muda.
    bottomSheetTheme: const BottomSheetThemeData(
      constraints: BoxConstraints(maxWidth: 640),
    ),

    // ── Divider ───────────────────────────────
    dividerTheme: DividerThemeData(
      color: AppColors.cardBorder,
      thickness: 1,
    ),
  );
}