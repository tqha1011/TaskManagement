import 'package:flutter/material.dart';

class MessageComposer extends StatelessWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isSending,
    required this.onMicPressed,
    required this.isListening,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final VoidCallback onMicPressed;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              onPressed: () {},
              icon: Icon(Icons.add_circle, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                enabled: !isSending,
                onSubmitted: (_) => onSend(),
                style: TextStyle(color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Type a message or ask for help...',
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              onPressed: isSending ? null : onMicPressed,
              icon: Icon(
                isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: isListening ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 44,
              height: 44,
              child: ElevatedButton(
                onPressed: isSending ? null : onSend,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.zero,
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: isSending
                      ? scheme.onPrimary.withValues(alpha: 0.7)
                      : scheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
