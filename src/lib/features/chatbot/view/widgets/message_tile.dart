import 'package:flutter/material.dart';

import '../../model/chatmessage_model.dart';
import 'bot_avatar.dart';
import 'user_avatar.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MessageTile extends StatelessWidget {
  const MessageTile({super.key, required this.message, this.userAvatarUrl});

  final ChatMessageModel message;
  final String? userAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isUser = message.isUser;
    final crossAxis = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxBubbleWidth = constraints.maxWidth * 0.72;

          Widget bubble() {
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isUser ? scheme.primary : scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: isUser
                    ? Text(
                        _breakLongTokens(message.content),
                        softWrap: true,
                        style: theme.textTheme.titleMedium?.copyWith(
                          height: 1.45,
                          color: scheme.onPrimary,
                        ),
                      )
                    : MarkdownBody(
                        data: message.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: theme.textTheme.titleMedium?.copyWith(
                            height: 1.45,
                            color: scheme.onSurface,
                          ),
                          listBullet: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: crossAxis,
            children: [
              if (isUser)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: bubble(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    UserAvatar(size: 36, avatarUrl: userAvatarUrl),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BotAvatar(size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: bubble(),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.only(left: isUser ? 0 : 46, right: isUser ? 46 : 0),
                child: Text(
                  _formatTime(context, message.timestamp),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime time) {
    final localTime = TimeOfDay.fromDateTime(time);
    return MaterialLocalizations.of(context).formatTimeOfDay(localTime);
  }

  String _breakLongTokens(String input) {
    final tokenRegex = RegExp(r'\S{24,}');
    return input.replaceAllMapped(tokenRegex, (match) {
      final token = match.group(0) ?? '';
      final buffer = StringBuffer();
      for (int i = 0; i < token.length; i++) {
        buffer.write(token[i]);
        if ((i + 1) % 12 == 0 && i + 1 < token.length) {
          buffer.write('\u200B');
        }
      }
      return buffer.toString();
    });
  }
}

