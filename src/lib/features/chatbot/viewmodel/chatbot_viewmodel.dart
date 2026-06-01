import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/chatmessage_model.dart';
import '../services/chatbot_services.dart';
import 'package:task_management_app/features/statistics/viewmodel/statistics_viewmodel.dart';
import 'package:task_management_app/features/tasks/viewmodel/task_viewmodel.dart';

class ChatBotViewModel extends ChangeNotifier {
  static const String _historyKey = 'chatbot_history_v1';
  static const int _maxHistoryMessages = 200;

  final _aiService = ChatBotAssistantService();
  final List<ChatMessageModel> _messages = [];
  final TaskViewModel? _taskViewModel;
  final StatisticsViewmodel? _statisticsViewmodel;

  ChatBotViewModel({TaskViewModel? taskViewModel, StatisticsViewmodel? statisticsViewmodel})
      : _taskViewModel = taskViewModel,
        _statisticsViewmodel = statisticsViewmodel {
    _loadHistory();
  }

  List<ChatMessageModel> _initialMessages() => [
    ChatMessageModel(
      text: 'Chào bạn! Tôi là trợ lý năng suất. Hôm nay bạn cần tôi giúp gì?',
      isUser: false,
    ),
  ];

  List<ChatMessageModel> get messages => _messages;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);

      if (raw == null || raw.trim().isEmpty) {
        _messages
          ..clear()
          ..addAll(_initialMessages());
        await _saveHistory();
      } else {
        final storedMessages = ChatMessageModel.decodeList(raw);
        _messages
          ..clear()
          ..addAll(
            storedMessages.isEmpty ? _initialMessages() : storedMessages,
          );
      }
    } catch (e) {
      debugPrint('Error loading chatbot history: $e');
      _messages
        ..clear()
        ..addAll(_initialMessages());
    }

    notifyListeners();
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_messages.length > _maxHistoryMessages) {
        _messages.removeRange(0, _messages.length - _maxHistoryMessages);
      }
      await prefs.setString(
        _historyKey,
        ChatMessageModel.encodeList(_messages),
      );
    } catch (e) {
      debugPrint('Error saving chatbot history: $e');
    }
  }

  Future<void> _refreshAfterMutation() async {
    await _taskViewModel?.fetchTasks();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await _statisticsViewmodel?.getStatisticsData(userId);
    }
  }

  Future<void> sendMessage(String text) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return;

    _messages.add(ChatMessageModel(text: normalizedText, isUser: true));
    _isLoading = true;
    notifyListeners();
    await _saveHistory();

    final response = await _aiService.sendMessage(normalizedText);

    if (response.didMutateTasks) {
      await _refreshAfterMutation();
    }

    _messages.add(ChatMessageModel(text: response.text, isUser: false));
    _isLoading = false;
    await _saveHistory();
    notifyListeners();
  }
}
