import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/connectivity_provider.dart';

/// Banner que aparece no topo da tela quando o app está offline.
/// Use como filho direto de uma Column, acima do conteúdo principal.
///
/// Exemplo:
///   Column(children: [
///     const OfflineBanner(),
///     Expanded(child: conteúdo),
///   ])
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height:   isOnline ? 0 : 36,
      color:    AppColors.gold.withValues(alpha: 0.15),
      child: isOnline
          ? const SizedBox.shrink()
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded,
                    color: AppColors.gold, size: 14),
                const SizedBox(width: 8),
                const Text(
                  'Sem internet — exibindo dados salvos',
                  style: TextStyle(
                    color:    AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Indicador compacto de "dados em cache" com timestamp.
/// Usar dentro de AppBar ou abaixo de um card de dados.
class CacheBadge extends StatelessWidget {
  final DateTime? cachedAt;
  const CacheBadge({super.key, this.cachedAt});

  @override
  Widget build(BuildContext context) {
    if (cachedAt == null) return const SizedBox.shrink();

    final diff = DateTime.now().difference(cachedAt!);
    String label;
    if (diff.inMinutes < 1) {
      label = 'atualizado agora';
    } else if (diff.inMinutes < 60) {
      label = 'salvo há ${diff.inMinutes} min';
    } else {
      label = 'salvo às ${cachedAt!.hour.toString().padLeft(2, '0')}:${cachedAt!.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.history_rounded, color: AppColors.gold, size: 11),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(color: AppColors.gold, fontSize: 10,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
