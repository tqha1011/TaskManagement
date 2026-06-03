import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management_app/features/chatbot/view/widgets/message_composer.dart';
import 'package:task_management_app/features/chatbot/view/widgets/message_tile.dart';
import 'package:task_management_app/features/chatbot/view/widgets/typing_indicator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../viewmodel/chatbot_viewmodel.dart';
import 'package:task_management_app/features/statistics/viewmodel/statistics_viewmodel.dart';
import 'package:task_management_app/features/tasks/viewmodel/task_viewmodel.dart';

class ChatBotView extends StatelessWidget {
  const ChatBotView({super.key, this.userAvatarUrl});

  final String? userAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatBotViewModel(
        taskViewModel: context.read<TaskViewModel>(),
        statisticsViewmodel: context.read<StatisticsViewmodel>(),
      ),
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
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: _handleSpeechStatus,
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mic error: ${error.errorMsg}')),
        );
      },
    );
    if (!mounted) return;
    setState(() => _speechAvailable = available);
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() => _isListening = false);
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mic chưa sẵn sàng')),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    final listening = await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
    );

    if (!mounted) return;
    setState(() => _isListening = listening);
  }

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
    _speech.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(ChatBotViewModel viewModel) async {
    final text = _controller.text.trim();
    if (text.isEmpty || viewModel.isLoading) return;

    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }

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
    final viewModel = context.watch<ChatBotViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI Assistant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            onPressed: () => viewModel.createNewSession(),
            tooltip: 'Cuộc trò chuyện mới',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primary),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_toy_rounded, color: Colors.white, size: 48),
                    SizedBox(height: 10),
                    Text(
                      'Lịch sử trò chuyện',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.add, color: scheme.primary),
              title: const Text('Cuộc trò chuyện mới', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                viewModel.createNewSession();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: viewModel.sessions.length,
                itemBuilder: (context, index) {
                  final session = viewModel.sessions[index];
                  final isActive = session.id == viewModel.activeSessionId;
                  return ListTile(
                    leading: Icon(Icons.chat_bubble_outline_rounded, 
                      color: isActive ? scheme.primary : scheme.onSurfaceVariant),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                    selected: isActive,
                    selectedTileColor: scheme.primary.withOpacity(0.1),
                    onTap: () {
                      viewModel.loadSessionMessages(session.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                itemCount: viewModel.messages.length,
                itemBuilder: (context, index) {
                  final message = viewModel.messages[index];
                  return MessageTile(
                    message: message,
                    userAvatarUrl: widget.userAvatarUrl,
                  );
                },
              ),
            ),
            if (viewModel.isLoading)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TypingIndicator(),
              ),
            MessageComposer(
              controller: _controller,
              isSending: viewModel.isLoading,
              isListening: _isListening,
              onMicPressed: _toggleListening,
              onSend: () => _sendMessage(viewModel),
            ),
          ],
        ),
      ),
    );
  }
}
