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
            _MicButton(
              isListening: isListening,
              isSending: isSending,
              onMicPressed: onMicPressed,
              scheme: scheme,
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

class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.isListening,
    required this.isSending,
    required this.onMicPressed,
    required this.scheme,
  });

  final bool isListening;
  final bool isSending;
  final VoidCallback onMicPressed;
  final ColorScheme scheme;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.isListening)
          ScaleTransition(
            scale: _animation,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.scheme.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          onPressed: widget.isSending ? null : widget.onMicPressed,
          icon: Icon(
            widget.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
            color: widget.isListening ? widget.scheme.primary : widget.scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
