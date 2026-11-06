import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// Cores do Glamour Agenda.
///
/// ANTES: cada cor era `static const` — fixa, decidida na compilação.
/// AGORA: cada cor é um `get` que devolve a cor da PALETA escolhida
/// (veja app_palette.dart). As telas continuam escrevendo
/// `AppColors.rose`, `AppColors.card`… sem saber qual estilo está ativo.
///
/// Por isso as cores NÃO são mais `const`: um `const` é calculado uma vez
/// quando o app é compilado e nunca muda. Como a cor agora depende da
/// escolha da usuária, ela só existe com o app rodando.
///
/// Quem troca a paleta é o ThemeController (providers/theme_provider.dart),
/// chamando [AppColors.apply]. Ninguém mais deve chamar [apply].
class AppColors {
  AppColors._();

  static AppPalette _palette = AppPalette.rosePalette;

  /// Paleta ativa agora.
  static AppPalette get palette => _palette;

  /// Troca a paleta ativa. Depois disso o app precisa ser redesenhado
  /// (o main.dart faz isso trocando a `key` do MaterialApp).
  static void apply(AppPalette palette) => _palette = palette;

  // ── Fundo ──────────────────────────────────
  static Color get background => _palette.background;
  static Color get card       => _palette.card;
  static Color get cardBorder => _palette.cardBorder;
  static Color get inputFill  => _palette.inputFill;

  // ── Principal ("rose") e secundária ("lavender") ──
  static Color get rose          => _palette.rose;
  static Color get roseDark      => _palette.roseDark;
  static Color get roseLight     => _palette.roseLight;
  static Color get lavender      => _palette.lavender;
  static Color get lavenderLight => _palette.lavenderLight;

  // ── Avisos ─────────────────────────────────
  static Color get green => _palette.green; // Pago / Disponível
  static Color get gold  => _palette.gold;  // Pendente / Parcial
  static Color get error => _palette.error; // Erro / Lotado

  // ── Texto ──────────────────────────────────
  static Color get text      => _palette.text;
  static Color get textMuted => _palette.textMuted;
  static Color get textDim   => _palette.textDim;

  // ── Procedimentos (cores por tipo) ─────────
  static Color get cilios            => _palette.cilios;
  static Color get ciliosTufinho     => _palette.ciliosTufinho;
  static Color get sobrancelhaHenna  => _palette.sobrancelhaHenna;
  static Color get sobrancelhaLamina => _palette.sobrancelhaLamina;
  static Color get spaLabios         => _palette.spaLabios;
  static Color get depilacao         => _palette.depilacao;
  static Color get limpezaPele       => _palette.limpezaPele;

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
