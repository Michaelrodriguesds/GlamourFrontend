import 'package:flutter/material.dart';

/// Limita a largura de uma tela em PC/notebook e centraliza no topo.
/// No celular a tela é mais estreita que [maxWidth], então nada muda.
class MaxWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const MaxWidth({super.key, required this.maxWidth, required this.child});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}
