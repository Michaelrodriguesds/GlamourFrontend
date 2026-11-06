import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';

/// Abre a lista de estilos e devolve o estilo tocado (ou null se fechar).
///
/// Quem chama decide o que fazer com a escolha (ver home_screen.dart).
/// Assim este painel só "mostra e devolve", sem saber como o tema é salvo.
Future<AppPalette?> showThemePicker(BuildContext context) {
  return showModalBottomSheet<AppPalette>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ThemePickerSheet(current: AppColors.palette),
  );
}

class _ThemePickerSheet extends StatelessWidget {
  final AppPalette current;
  const _ThemePickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Estilo do app',
                  style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Escolha as cores do Glamour. A escolha fica salva neste aparelho.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, box) {
                  final columns = box.maxWidth >= 520 ? 3 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                    children: [
                      for (final palette in AppPalette.all)
                        _PaletteCard(
                          palette: palette,
                          selected: palette.id == current.id,
                          onTap: () => Navigator.pop(context, palette),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cartão de um estilo. A miniatura usa as cores DA PRÓPRIA paleta
/// (palette.background, palette.card…), não as do AppColors: assim a
/// usuária vê como o app vai ficar antes de escolher.
class _PaletteCard extends StatelessWidget {
  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteCard({required this.palette, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Estilo ${palette.name}',
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.rose : AppColors.cardBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Preview(palette: palette)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Text(palette.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  if (selected) Icon(Icons.check_circle_rounded, color: AppColors.rose, size: 18),
                ]),
                const SizedBox(height: 2),
                Text(palette.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniatura de uma tela com as cores da paleta.
class _Preview extends StatelessWidget {
  final AppPalette palette;
  const _Preview({required this.palette});

  Widget _bar(Color color, double widthFactor, double height) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
      );

  Widget _dot(Color color) => Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _bar(palette.text, 0.7, 5),
                    _bar(palette.textMuted, 0.5, 4),
                    Row(children: [_dot(palette.lavender), _dot(palette.green), _dot(palette.gold)]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 14,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: palette.rose, borderRadius: BorderRadius.circular(5)),
              child: Container(
                width: 22,
                height: 3,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
