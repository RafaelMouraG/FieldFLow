import 'package:flutter/material.dart';

/// Exibe uma nota (0..5) como estrelas + o numero, opcionalmente com o total
/// de avaliacoes. Somente leitura (use [RatingInput] para coletar uma nota).
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.nota,
    this.total = 0,
    this.size = 16,
  });

  final double nota;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= nota.round() ? Icons.star : Icons.star_border,
            size: size,
            color: Colors.amber.shade700,
          ),
        const SizedBox(width: 6),
        Text(
          total > 0
              ? '${nota.toStringAsFixed(1)} ($total)'
              : nota.toStringAsFixed(1),
          style: TextStyle(fontSize: size * 0.8, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

/// Seletor de nota por toque (1..5 estrelas), para o cliente avaliar.
class RatingInput extends StatelessWidget {
  const RatingInput({
    super.key,
    required this.nota,
    required this.onChanged,
    this.size = 40,
  });

  final int nota;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    // FittedBox + botoes compactos evitam overflow em dialogs estreitos.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              onPressed: () => onChanged(i),
              iconSize: size,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                i <= nota ? Icons.star : Icons.star_border,
                color: Colors.amber.shade700,
              ),
            ),
        ],
      ),
    );
  }
}
