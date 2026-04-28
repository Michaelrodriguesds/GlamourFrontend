import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Overlay de carregamento centralizado
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool   isLoading;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.rose,
                strokeWidth: 2.5,
              ),
            ),
          ),
      ],
    );
  }
}

/// Indicador simples inline
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.rose, strokeWidth: 2.5),
  );
}

/// Estado de erro com botão de retry
class AppError extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const AppError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('😕', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onRetry,
          child: const Text('Tentar novamente', style: TextStyle(color: AppColors.rose)),
        ),
      ],
    ),
  );
}