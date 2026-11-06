import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_palette.dart';

/// Estilo (paleta) escolhido no app.
///
/// Fluxo:
///   1. Ao abrir o app, [ThemeController.load] lê a escolha salva no aparelho.
///   2. Na tela Início, o botão de paleta abre a lista de estilos; ao tocar
///      num estilo, [ThemeController.select] é chamado.
///   3. [_apply] troca as cores em AppColors e muda o `state` deste provider.
///   4. O main.dart "observa" este provider: quando o estilo muda, ele
///      redesenha o app inteiro com as cores novas.
///
/// A escolha fica salva no navegador/celular (SharedPreferences), então vale
/// por aparelho: o PC e o celular podem ter estilos diferentes.
final themeProvider = StateNotifierProvider<ThemeController, AppPalette>(
  (ref) => ThemeController(),
);

class ThemeController extends StateNotifier<AppPalette> {
  ThemeController() : super(AppColors.palette);

  static const _storageKey = 'app_theme';

  /// Lê o estilo salvo. Se não houver nada salvo (ou der erro), fica o Rosé.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apply(AppPalette.byId(prefs.getString(_storageKey)));
    } catch (_) {
      // Sem acesso ao armazenamento: segue com o estilo padrão.
    }
  }

  /// Aplica um estilo novo e salva a escolha.
  Future<void> select(AppPalette palette) async {
    _apply(palette);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, palette.id);
    } catch (_) {
      // Não conseguiu salvar: o estilo vale até fechar o app.
    }
  }

  void _apply(AppPalette palette) {
    // A ORDEM importa: primeiro as cores, depois o `state`. Quando o
    // `state` muda, o app se redesenha e já encontra as cores novas.
    AppColors.apply(palette);
    state = palette;
  }
}
