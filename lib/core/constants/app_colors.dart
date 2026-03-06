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
  static const Color cilios        = Color(0xFFB47FD4); // Lavanda
  static const Color sobrancelha   = Color(0xFFE8527A); // Rose
  static const Color depilacao     = Color(0xFFF0C060); // Gold
  static const Color designCompleto= Color(0xFF4ECBA0); // Green

  /// Retorna a cor de acordo com o procedimento
  static Color forProcedure(String procedure) {
    switch (procedure) {
      case 'Cílios':          return cilios;
      case 'Sobrancelha':     return sobrancelha;
      case 'Depilação':       return depilacao;
      case 'Design Completo': return designCompleto;
      default:                return lavender;
    }
  }
}