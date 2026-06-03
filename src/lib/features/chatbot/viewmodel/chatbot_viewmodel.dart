import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/chatmessage_model.dart';
import '../model/chat_session_model.dart';
import '../services/chatbot_services.dart';
import 'package:task_management_app/features/statistics/viewmodel/statistics_viewmodel.dart';
import 'package:task_management_app/features/tasks/viewmodel/task_viewmodel.dart';

class ChatBotViewModel extends ChangeNotifier {
  final _aiService = ChatBotAssistantService();
  final _supabase = Supabase.instance.client;

  final TaskViewModel? _taskViewModel;
  final StatisticsViewmodel? _statisticsViewmodel;

  List<ChatSessionModel> _sessions = [];
  List<ChatSessionModel> get sessions => _sessions;

  String? _activeSessionId;
  String? get activeSessionId => _activeSessionId;

  List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ChatBotViewModel({
    TaskViewModel? taskViewModel,
    StatisticsViewmodel? statisticsViewmodel,
  })  : _taskViewModel = taskViewModel,
        _statisticsViewmodel = statisticsViewmodel {
    fetchSessions();
  }

  /// 1. Fetch all sessions for current user
  Future<void> fetchSessions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('chat_session')
          .select()
          .eq('profile_id', userId)
          .order('created_at', ascending: false);

      _sessions = (data as List).map((s) => ChatSessionModel.fromJson(s)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
    }
  }

  /// 2. Load messages for a specific session
  Future<void> loadSessionMessages(String sessionId) async {
    _activeSessionId = sessionId;
    _isLoading = true;
    _messages = [];
    notifyListeners();

    try {
      final data = await _supabase
          .from('chat_message')
          .select()
          .eq('session_id', int.parse(sessionId))
          .order('created_at', ascending: true);

      _messages = (data as List).map((m) => ChatMessageModel.fromJson(m)).toList();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 3. Reset UI for a new empty session
  void createNewSession() {
    _activeSessionId = null;
    _messages = [
      ChatMessageModel(
        role: 'model',
        content: 'Chào bạn! Tôi là trợ lý năng suất. Hôm nay bạn cần tôi giúp gì?',
      ),
    ];
    notifyListeners();
  }

  Future<void> _refreshDataAfterMutation() async {
    await _taskViewModel?.fetchTasks();
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _statisticsViewmodel?.getStatisticsData(userId);
    }
  }

  /// 4. Send Message with Session Logic
  Future<void> sendMessage(String text) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return;

    // 1. Capture history BEFORE adding the new message
    // Gemini startChat history should only contain previous rounds.
    final history = List<ChatMessageModel>.from(_messages);

    // 2. Optimistic user message update
    _messages.add(ChatMessageModel(role: 'user', content: normalizedText));
    _isLoading = true;
    notifyListeners();

    try {
      // 3. Send to AI service with the captured history
      final response = await _aiService.sendMessage(
        normalizedText,
        sessionId: _activeSessionId,
        history: history,
      );

      if (response.sessionId != null && _activeSessionId == null) {
        _activeSessionId = response.sessionId;
        await fetchSessions(); // Refresh session list to include the new one
      }

      if (response.didMutateTasks) {
        await _refreshDataAfterMutation();
      }

      _messages.add(ChatMessageModel(role: 'model', content: response.text));
    } catch (e) {
      debugPrint('Error sending message: $e');
      _messages.add(ChatMessageModel(
        role: 'model',
        content: 'Đã xảy ra lỗi khi gửi tin nhắn. Vui lòng thử lại.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
