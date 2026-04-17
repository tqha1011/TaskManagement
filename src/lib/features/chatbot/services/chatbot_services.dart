import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatBotAssistantService {
  final String _apiKey = (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
  GenerativeModel? _model;
  ChatSession? _chatSession;

  ChatBotAssistantService() {
    if (_apiKey.isEmpty) {
      debugPrint("Forget to set GEMINI_API_KEY in .env file");
      return;
    }

    _model = GenerativeModel(
      apiKey: _apiKey,
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(
        'Bạn là một chuyên gia quản lý thời gian và trợ lý năng suất cho ứng dụng Task Management. '
        'Nhiệm vụ của bạn là đưa ra lời khuyên ngắn gọn (dưới 100 chữ), thực tế để giúp người dùng '
        'hoàn thành công việc. Trả lời bằng tiếng Việt thân thiện, nhiệt tình. '
        'Từ chối mọi câu hỏi không liên quan đến công việc hoặc quản lý thời gian.',
      ),
    );

    _chatSession = _model!.startChat();
  }

  Future<String> sendMessage(String userMessage) async {
    if (_chatSession == null) {
      return 'Chatbot chưa được cấu hình API key. Vui lòng kiểm tra file .env.';
    }

    try {
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );
      return response.text ?? 'Xin lỗi, trợ lý đang bận xíu. Thử lại sau nhé!';
    } catch (e) {
      return 'Lỗi kết nối AI: $e';
    }
  }
}
