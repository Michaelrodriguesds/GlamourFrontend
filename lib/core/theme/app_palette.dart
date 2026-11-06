import 'package:flutter/material.dart';

/// Uma PALETA é o conjunto de cores de um estilo do app.
///
/// O app inteiro pinta as telas com `AppColors.algumaCor`. O `AppColors`
/// não guarda cor nenhuma: ele devolve a cor da paleta escolhida agora.
/// Trocar de paleta = trocar todas as cores de uma vez.
///
/// Os nomes dos campos são os mesmos que o app já usava (`rose`,
/// `lavender`…), para não precisar mexer nas telas. Por isso, leia assim:
///   rose     = cor PRINCIPAL do estilo (no "Oceano" ela é azul)
///   lavender = cor SECUNDÁRIA
///   green / gold / error = avisos (pago, pendente, erro)
///
/// Para criar um estilo novo: copie um dos estilos abaixo, mude `id`,
/// `name` e as cores, e acrescente-o na lista [AppPalette.all].
class AppPalette {
  final String id;          // nome interno, salvo no aparelho (não mude depois de publicado)
  final String name;        // nome que aparece para a usuária
  final String description;
  final Brightness brightness; // escuro ou claro (ajusta barra de status, campos etc.)

  // Fundo
  final Color background;
  final Color card;
  final Color cardBorder;
  final Color inputFill;

  // Principal (rose) e secundária (lavender)
  final Color rose;
  final Color roseDark;
  final Color roseLight;
  final Color lavender;
  final Color lavenderLight;

  // Avisos
  final Color green;
  final Color gold;
  final Color error;

  // Texto
  final Color text;
  final Color textMuted;
  final Color textDim;

  // Procedimentos (cada um tem sua cor no calendário e nos cartões)
  final Color cilios;
  final Color ciliosTufinho;
  final Color sobrancelhaHenna;
  final Color sobrancelhaLamina;
  final Color spaLabios;
  final Color depilacao;
  final Color limpezaPele;

  const AppPalette({
    required this.id,
    required this.name,
    required this.description,
    required this.brightness,
    required this.background,
    required this.card,
    required this.cardBorder,
    required this.inputFill,
    required this.rose,
    required this.roseDark,
    required this.roseLight,
    required this.lavender,
    required this.lavenderLight,
    required this.green,
    required this.gold,
    required this.error,
    required this.text,
    required this.textMuted,
    required this.textDim,
    this.cilios            = const Color(0xFFB47FD4),
    this.ciliosTufinho     = const Color(0xFF9B6FD4),
    this.sobrancelhaHenna  = const Color(0xFF4ECBA0),
    this.sobrancelhaLamina = const Color(0xFFE8527A),
    this.spaLabios         = const Color(0xFFFF9898),
    this.depilacao         = const Color(0xFF98CFFF),
    this.limpezaPele       = const Color(0xFFF0C060),
  });

  bool get isDark => brightness == Brightness.dark;

  // ── 1. Rosé — o estilo original do Glamour ───────────────────────
  static const rosePalette = AppPalette(
    id: 'rose',
    name: 'Rosé',
    description: 'O estilo original: escuro com rosa e lavanda',
    brightness: Brightness.dark,
    background:    Color(0xFF0F0A14),
    card:          Color(0xFF1A1225),
    cardBorder:    Color(0xFF2D1F3D),
    inputFill:     Color(0xFF1A1225),
    rose:          Color(0xFFE8527A),
    roseDark:      Color(0xFFC43060),
    roseLight:     Color(0xFFFF85A1),
    lavender:      Color(0xFFB47FD4),
    lavenderLight: Color(0xFFD4A8F0),
    green:         Color(0xFF4ECBA0),
    gold:          Color(0xFFF0C060),
    error:         Color(0xFFE8527A),
    text:          Color(0xFFF5EEF8),
    textMuted:     Color(0xFF8A7A9A),
    textDim:       Color(0xFF5A4A6A),
  );

  // ── 2. Lavanda — escuro com violeta ──────────────────────────────
  static const lavandaPalette = AppPalette(
    id: 'lavanda',
    name: 'Lavanda',
    description: 'Escuro com violeta suave e toques de rosa',
    brightness: Brightness.dark,
    background:    Color(0xFF0E0B18),
    card:          Color(0xFF19152B),
    cardBorder:    Color(0xFF2C2648),
    inputFill:     Color(0xFF19152B),
    rose:          Color(0xFF8D6BEE),
    roseDark:      Color(0xFF7048D8),
    roseLight:     Color(0xFFC4B5FD),
    lavender:      Color(0xFFF0A6CA),
    lavenderLight: Color(0xFFF7C8DF),
    green:         Color(0xFF4ECBA0),
    gold:          Color(0xFFF0C060),
    error:         Color(0xFFF2668B),
    text:          Color(0xFFF3F0FA),
    textMuted:     Color(0xFF9A90B5),
    textDim:       Color(0xFF6E6894),
  );

  // ── 3. Oceano — escuro com azul ──────────────────────────────────
  static const oceanoPalette = AppPalette(
    id: 'oceano',
    name: 'Oceano',
    description: 'Escuro com azul e verde-água, mais calmo',
    brightness: Brightness.dark,
    background:    Color(0xFF08121C),
    card:          Color(0xFF0F1E2D),
    cardBorder:    Color(0xFF1E3448),
    inputFill:     Color(0xFF0F1E2D),
    rose:          Color(0xFF1E88D0),
    roseDark:      Color(0xFF1670B0),
    roseLight:     Color(0xFF7DD3FC),
    lavender:      Color(0xFF2DD4BF),
    lavenderLight: Color(0xFF99F6E4),
    green:         Color(0xFF4ADE80),
    gold:          Color(0xFFFBBF24),
    error:         Color(0xFFF87171),
    text:          Color(0xFFEAF4FB),
    textMuted:     Color(0xFF8BA3B8),
    textDim:       Color(0xFF5A768D),
  );

  // ── 4. Esmeralda — escuro com verde ──────────────────────────────
  static const esmeraldaPalette = AppPalette(
    id: 'esmeralda',
    name: 'Esmeralda',
    description: 'Escuro com verde esmeralda e azul claro',
    brightness: Brightness.dark,
    background:    Color(0xFF07130F),
    card:          Color(0xFF0E1F19),
    cardBorder:    Color(0xFF1D3A2F),
    inputFill:     Color(0xFF0E1F19),
    rose:          Color(0xFF109A6C),
    roseDark:      Color(0xFF0B7F59),
    roseLight:     Color(0xFF6EE7B7),
    lavender:      Color(0xFF7DD3FC),
    lavenderLight: Color(0xFFBAE6FD),
    green:         Color(0xFFA3E635),
    gold:          Color(0xFFFBBF24),
    error:         Color(0xFFF87171),
    text:          Color(0xFFECFDF5),
    textMuted:     Color(0xFF8FB3A5),
    textDim:       Color(0xFF587A6D),
  );

  // ── 5. Champanhe — escuro com dourado ────────────────────────────
  static const champanhePalette = AppPalette(
    id: 'champanhe',
    name: 'Champanhe',
    description: 'Escuro com dourado e terracota, mais sofisticado',
    brightness: Brightness.dark,
    background:    Color(0xFF14110B),
    card:          Color(0xFF1F1A11),
    cardBorder:    Color(0xFF3A311F),
    inputFill:     Color(0xFF1F1A11),
    rose:          Color(0xFFB0822E),
    roseDark:      Color(0xFF8F6822),
    roseLight:     Color(0xFFF2D08A),
    lavender:      Color(0xFFE08E6D),
    lavenderLight: Color(0xFFF2B9A2),
    green:         Color(0xFF4ECBA0),
    gold:          Color(0xFFF59E0B),
    error:         Color(0xFFF87171),
    text:          Color(0xFFFAF5EA),
    textMuted:     Color(0xFFA89B82),
    textDim:       Color(0xFF7A6E57),
  );

  // ── 6. Claro — fundo branco com rosa ─────────────────────────────
  // Num fundo claro as cores precisam ser mais escuras para dar leitura,
  // por isso os procedimentos também têm versões mais fortes aqui.
  static const claroPalette = AppPalette(
    id: 'claro',
    name: 'Claro',
    description: 'Fundo branco com rosa, ótimo de dia e no sol',
    brightness: Brightness.light,
    background:    Color(0xFFFBF7FA),
    card:          Color(0xFFFFFFFF),
    cardBorder:    Color(0xFFEADDE6),
    inputFill:     Color(0xFFFFFFFF),
    rose:          Color(0xFFD63F6B),
    roseDark:      Color(0xFFB02E56),
    roseLight:     Color(0xFFC2335E),
    lavender:      Color(0xFF8E5CC0),
    lavenderLight: Color(0xFF6F42A6),
    green:         Color(0xFF16805E),
    gold:          Color(0xFF9A6412),
    error:         Color(0xFFD63F6B),
    text:          Color(0xFF24161F),
    textMuted:     Color(0xFF6E5B69),
    textDim:       Color(0xFF8C7A88),
    cilios:            Color(0xFF8E5CC0),
    ciliosTufinho:     Color(0xFF7A4FC0),
    sobrancelhaHenna:  Color(0xFF16805E),
    sobrancelhaLamina: Color(0xFFD63F6B),
    spaLabios:         Color(0xFFC94A5E),
    depilacao:         Color(0xFF2F72B8),
    limpezaPele:       Color(0xFF9A6412),
  );

  /// Todos os estilos, na ordem em que aparecem para escolher.
  static const all = [
    rosePalette,
    lavandaPalette,
    oceanoPalette,
    esmeraldaPalette,
    champanhePalette,
    claroPalette,
  ];

  /// Estilo pelo id salvo. Id desconhecido ou vazio = o original (Rosé).
  static AppPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => rosePalette);
}
