import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management_app/features/chatbot/view/widgets/chat_header.dart';
import 'package:task_management_app/features/chatbot/view/widgets/day_separator.dart';
import 'package:task_management_app/features/chatbot/view/widgets/message_composer.dart';
import 'package:task_management_app/features/chatbot/view/widgets/message_tile.dart';
import 'package:task_management_app/features/chatbot/view/widgets/typing_indicator.dart';

import '../viewmodel/chatbot_viewmodel.dart';

class ChatBotView extends StatelessWidget {
  const ChatBotView({super.key, this.userAvatarUrl});

  final String? userAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatBotViewModel(),
      child: _ChatBotViewBody(userAvatarUrl: userAvatarUrl),
    );
  }
}

class _ChatBotViewBody extends StatefulWidget {
  const _ChatBotViewBody({this.userAvatarUrl});

  final String? userAvatarUrl;

  @override
  State<_ChatBotViewBody> createState() => _ChatBotViewBodyState();
}

class _ChatBotViewBodyState extends State<_ChatBotViewBody> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(ChatBotViewModel viewModel) async {
    final text = _controller.text.trim();
    if (text.isEmpty || viewModel.isLoading) return;

    _controller.clear();
    _scrollToBottom();

    await viewModel.sendMessage(text);
    if (!mounted) return;

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const ChatHeader(),
            Divider(height: 1, color: scheme.outline.withValues(alpha: 0.4)),
            Expanded(
              child: Consumer<ChatBotViewModel>(
                builder: (context, viewModel, _) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    itemCount: viewModel.messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: DaySeparator(label: 'Today'),
                        );
                      }

                      final message = viewModel.messages[index - 1];
                      return MessageTile(
                        message: message,
                        userAvatarUrl: widget.userAvatarUrl,
                      );
                    },
                  );
                },
              ),
            ),
            Consumer<ChatBotViewModel>(
              builder: (context, viewModel, _) {
                if (!viewModel.isLoading) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TypingIndicator(),
                );
              },
            ),
            Consumer<ChatBotViewModel>(
              builder: (context, viewModel, _) {
                return MessageComposer(
                  controller: _controller,
                  isSending: viewModel.isLoading,
                  onSend: () => _sendMessage(viewModel),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
