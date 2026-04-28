import 'package:flutter/material.dart';

/// Paleta de cores do Glamour Agenda
/// Tema escuro com tons rose/lavender
class AppColors {
  AppColors._();

  // ── Fundo ──────────────────────────────────
  static const Color background    = Color(0xFF0F0A14);
  static const Color card          = Color(0xFF1A1225);
  static const Color cardBorder    = Color(0xFF2D1F3D);
  static const Color inputFill     = Color(0xFF1A1225);

  // ── Primária: Rose ─────────────────────────
  static const Color rose          = Color(0xFFE8527A);
  static const Color roseDark      = Color(0xFFC43060);
  static const Color roseLight     = Color(0xFFFF85A1);

  // ── Secundária: Lavanda ────────────────────
  static const Color lavender      = Color(0xFFB47FD4);
  static const Color lavenderLight = Color(0xFFD4A8F0);

  // ── Feedback ───────────────────────────────
  static const Color green         = Color(0xFF4ECBA0);  // Pago / Disponível
  static const Color gold          = Color(0xFFF0C060);  // Pendente / Parcial
  static const Color error         = Color(0xFFE8527A);  // Erro / Lotado

  // ── Texto ──────────────────────────────────
  static const Color text          = Color(0xFFF5EEF8);
  static const Color textMuted     = Color(0xFF8A7A9A);
  static const Color textDim       = Color(0xFF5A4A6A);

  // ── Procedimentos (cores por tipo) ─────────
  static const Color cilios              = Color(0xFFB47FD4); // Lavanda
  static const Color ciliosTufinho       = Color(0xFF9B6FD4); // Lavanda escuro
  static const Color sobrancelhaHenna    = Color(0xFF4ECBA0); // Green
  static const Color sobrancelhaLamina   = Color(0xFFE8527A); // Rose
  static const Color spaLabios           = Color(0xFFFF9898); // Rosa claro
  static const Color depilacao           = Color(0xFF98CFFF); // Azul claro
  static const Color limpezaPele         = Color(0xFFF0C060); // Gold

  /// Retorna a cor de acordo com o procedimento
  static Color forProcedure(String procedure) {
    // Suporta tanto procedimento único como string de combo ("A + B")
    final first = procedure.split(' + ').first.trim();
    switch (first) {
      case 'Cílios':               return cilios;
      case 'Cílios Tufinho':       return ciliosTufinho;
      case 'Sobrancelha com Henna':return sobrancelhaHenna;
      case 'Sobrancelha sem Henna':return sobrancelhaLamina;
      case 'Spa dos Lábios':       return spaLabios;
      case 'Depilação':            return depilacao;
      case 'Limpeza de Pele':      return limpezaPele;
      default:                     return lavender;
    }
  }
}
