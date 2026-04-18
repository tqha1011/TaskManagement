import 'package:flutter/material.dart';

import 'bot_avatar.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const BotAvatar(size: 34),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'TaskBot is typing...',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

