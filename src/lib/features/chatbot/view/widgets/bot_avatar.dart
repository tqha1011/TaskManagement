import 'package:flutter/material.dart';

class BotAvatar extends StatelessWidget {
  const BotAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHighest,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.smart_toy_rounded,
        size: size * 0.58,
        color: scheme.primary,
      ),
    );
  }
}

