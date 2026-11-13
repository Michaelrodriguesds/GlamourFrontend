import 'package:agenda_flutter/core/constants/app_colors.dart';
import 'dart:io';

import 'package:agenda_flutter/core/theme/app_palette.dart';
import 'package:agenda_flutter/core/theme/app_theme.dart';
import 'package:agenda_flutter/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contraste WCAG entre duas cores (1 = igual, 21 = preto no branco).
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Cada teste começa com o estilo original, para um não atrapalhar o outro.
  setUp(() => AppColors.apply(AppPalette.rosePalette));

  group('paletas', () {
    test('ids são únicos e existem 6 estilos', () {
      final ids = AppPalette.all.map((p) => p.id).toList();
      expect(ids.length, 6);
      expect(ids.toSet().length, ids.length);
    });

    test('byId: id desconhecido ou vazio volta para o Rosé', () {
      expect(AppPalette.byId('oceano').name, 'Oceano');
      expect(AppPalette.byId('nao-existe').id, 'rose');
      expect(AppPalette.byId(null).id, 'rose');
    });

    test('Rosé mantém exatamente as cores originais do app', () {
      const p = AppPalette.rosePalette;
      expect(p.background, const Color(0xFF0F0A14));
      expect(p.card, const Color(0xFF1A1225));
      expect(p.rose, const Color(0xFFE8527A));
      expect(p.text, const Color(0xFFF5EEF8));
      expect(p.depilacao, const Color(0xFF98CFFF));
    });

    test('só o Claro é claro', () {
      for (final p in AppPalette.all) {
        expect(p.isDark, p.id != 'claro', reason: p.name);
      }
    });
  });

  group('AppColors segue a paleta ativa', () {
    test('trocar a paleta troca as cores', () {
      expect(AppColors.rose, AppPalette.rosePalette.rose);
      AppColors.apply(AppPalette.oceanoPalette);
      expect(AppColors.rose, AppPalette.oceanoPalette.rose);
      expect(AppColors.card, AppPalette.oceanoPalette.card);
      expect(AppColors.forProcedure('Depilação'), AppPalette.oceanoPalette.depilacao);
      expect(AppColors.forProcedure('Outro'), AppPalette.oceanoPalette.lavender);
    });
  });

  group('legibilidade (contraste)', () {
    // Os estilos novos precisam ser legíveis. O Rosé é o original e fica
    // como sempre foi (o cinza das dicas dele é bem apagado de propósito).
    final novos = AppPalette.all.where((p) => p.id != 'rose');

    for (final p in novos) {
      test(p.name, () {
        expect(contrast(p.text, p.card), greaterThanOrEqualTo(4.5), reason: 'texto');
        expect(contrast(p.textMuted, p.card), greaterThanOrEqualTo(4.5), reason: 'texto secundário');
        expect(contrast(p.textDim, p.card), greaterThanOrEqualTo(3.0), reason: 'dicas');
        expect(contrast(Colors.white, p.rose), greaterThanOrEqualTo(3.0), reason: 'texto branco no botão');
        expect(contrast(p.rose, p.card), greaterThanOrEqualTo(3.0), reason: 'cor principal no cartão');
        for (final c in [p.green, p.gold, p.error, p.lavender, p.depilacao, p.spaLabios, p.limpezaPele]) {
          expect(contrast(c, p.card), greaterThanOrEqualTo(3.0), reason: 'cor de aviso/procedimento');
        }
      });
    }
  });

  group('seletores de data/hora seguem o estilo (bug do calendário branco)', () {
    for (final p in AppPalette.all) {
      test(p.name, () {
        AppColors.apply(p);
        final s = AppTheme.scheme;
        // Claro = esquema claro; escuros = esquema escuro.
        expect(s.brightness, p.brightness);
        // Números do calendário (onSurface) legíveis no fundo do seletor (surface).
        expect(s.surface, p.card);
        expect(contrast(s.onSurface, s.surface), greaterThanOrEqualTo(4.5), reason: 'números');
        // Dia marcado: cor principal no fundo e texto branco por cima.
        expect(contrast(s.primary, s.surface), greaterThanOrEqualTo(3.0), reason: 'dia marcado');
      });
    }

    test('nenhuma tela força esquema escuro fixo (ColorScheme.dark fora do app_theme)', () {
      final culpados = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('app_theme.dart'))
          .where((f) => f.readAsStringSync().contains('ColorScheme.dark('))
          .map((f) => f.path)
          .toList();
      expect(culpados, isEmpty);
    });
  });

  group('ThemeController (escolha salva no aparelho)', () {
    test('sem nada salvo: fica o Rosé', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ThemeController();
      await c.load();
      expect(c.state.id, 'rose');
      expect(AppColors.palette.id, 'rose');
    });

    test('escolher um estilo aplica na hora e salva', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ThemeController();
      await c.select(AppPalette.esmeraldaPalette);
      expect(c.state.id, 'esmeralda');
      expect(AppColors.rose, AppPalette.esmeraldaPalette.rose);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme'), 'esmeralda');
    });

    test('ao abrir de novo, carrega o estilo salvo', () async {
      SharedPreferences.setMockInitialValues({'app_theme': 'claro'});
      final c = ThemeController();
      await c.load();
      expect(c.state.id, 'claro');
      expect(AppColors.background, AppPalette.claroPalette.background);
    });

    test('valor salvo inválido não quebra: volta para o Rosé', () async {
      SharedPreferences.setMockInitialValues({'app_theme': 'tema-apagado'});
      final c = ThemeController();
      await c.load();
      expect(c.state.id, 'rose');
    });
  });
}
