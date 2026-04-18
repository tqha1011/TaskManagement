import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      tools: [
        Tool(
          functionDeclarations: [
            FunctionDeclaration(
              'create_task_full',
              'Tạo một công việc mới. Hãy tự động trích xuất tên công việc, suy luận độ ưu tiên (1-Thấp, 2-Trung bình, 3-Cao) và các thẻ (tags) dựa trên câu nói của người dùng.',
              Schema(
                SchemaType.object,
                properties: {
                  'title': Schema(
                    SchemaType.string,
                    description: 'Tên công việc cần làm',
                  ),
                  'priority': Schema(
                    SchemaType.integer,
                    description:
                        'Độ ưu tiên: 1 (Thấp), 2 (Trung bình), 3 (Cao). Nếu người dùng không nói rõ, mặc định là 1.',
                  ),
                  'tags': Schema(
                    SchemaType.array,
                    items: Schema(SchemaType.string),
                    description:
                        'Danh sách các thẻ phân loại (ví dụ: ["Học tập", "Gấp", "Backend"]). Gửi mảng rỗng [] nếu không có.',
                  ),
                },
                requiredProperties: ['title', 'priority', 'tags'],
              ),
            ),
          ],
        ),
      ],
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

      if (response.functionCalls.isNotEmpty) {
        final functionCall = response.functionCalls.first;
        if (functionCall.name == 'create_task_full') {
          final args = functionCall.args;
          final title = args['title'] as String;
          final priority = (args['priority'] as num?)?.toInt() ?? 1;
          final rawTags = args['tags'] as List<dynamic>? ?? [];
          final tags = rawTags.map((e) => e.toString()).toList();

          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) {
            return 'Vui lòng đăng nhập để tạo công việc.';
          }

          final dbResponse = await Supabase.instance.client.rpc(
            'create_task_full',
            params: {
              'p_title': title,
              'p_priority': priority,
              'p_profile_id': userId,
              'p_tag_names': tags,
            },
          );

          final isSuccess = dbResponse['success'] == true;
          final functionResponse = await _chatSession!.sendMessage(
            Content.functionResponse('create_task_full', {
              'status': isSuccess ? 'Thành công' : 'Thất bại',
            }),
          );
          return functionResponse.text ?? 'Đã xử lý xong yêu cầu của bạn!';
        }
      }
      return response.text ?? 'Xin lỗi, trợ lý đang bận xíu. Thử lại sau nhé!';
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('503')) {
        return 'Bạn đợi vài phút rồi chat lại nhé!';
      } else if (errorString.contains('429')) {
        return 'Bạn chat nhanh quá! Vui lòng chờ chút';
      }
      return 'Lỗi kết nối AI: $e';
    }
  }
}
