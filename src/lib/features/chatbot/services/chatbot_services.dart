import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/chatmessage_model.dart';

class ChatBotResponse {
  final String text;
  final bool didMutateTasks;
  final String? sessionId;

  const ChatBotResponse({
    required this.text,
    this.didMutateTasks = false,
    this.sessionId,
  });
}

class ChatBotAssistantService {
  final String _apiKey = (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
  GenerativeModel? _model;
  final now = DateTime.now();

  ChatBotAssistantService() {
    if (_apiKey.isEmpty) {
      debugPrint("Forget to set GEMINI_API_KEY in .env file");
      return;
    }

    _model = GenerativeModel(
      apiKey: _apiKey,
      model: 'gemini-2.5-flash', // Updated to a more recent stable tool-supporting model if possible, otherwise gemini-1.5-flash
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
                  'start_time': Schema(
                    SchemaType.string,
                    description:
                        'Thời gian bắt đầu công việc theo định dạng ISO 8601 (VD: 2026-04-18T15:00:00+07:00). Nếu người dùng không nói, bắt buộc hỏi lại thời gian bắt đầu.',
                  ),
                  'due_time': Schema(
                    SchemaType.string,
                    description:
                        'Thời gian kết thúc (deadline) theo định dạng ISO 8601 (VD: 2026-04-18T15:00:00+07:00). Nếu không có, hãy hỏi lại thời gian kết thúc. Nếu người dùng xác nhận không cần đặt thời gian kết thúc, hãy để trống hoặc bỏ qua.',
                  ),
                  'category_name': Schema(
                    SchemaType.string,
                    description:
                        'Phân loại công việc vào 1 trong 4 nhóm: "Cá nhân", "Học tập", "Công việc", hoặc "Giải trí". Nếu không phân loại được, mặc định trả về "Cá nhân".',
                  ),
                },
                requiredProperties: ['title', 'priority', 'tags'],
              ),
            ),

            FunctionDeclaration(
              'update_task_time',
              'Dời lịch hoặc thay đổi thời gian bắt đầu của một công việc. LUẬT BẮT BUỘC: Nếu người dùng yêu cầu dời lịch nhưng CHƯA đề cập đến "thời gian kết thúc" (hạn chót), bạn KHÔNG ĐƯỢC gọi hàm này ngay. Hãy trả lời bằng văn bản để hỏi xem họ có muốn đặt thời gian kết thúc không. Chỉ gọi hàm này sau khi người dùng đã xác nhận thời gian kết thúc hoặc họ nói rõ là "không cần".',
              Schema(
                SchemaType.object,
                properties: {
                  'task_keyword': Schema(
                    SchemaType.string,
                    description: 'Từ khóa ngắn gọn về công việc cần dời.',
                  ),
                  'new_start_time': Schema(
                    SchemaType.string,
                    description: 'Thời gian bắt đầu mới theo định dạng ISO 8601 (VD: 2026-05-18T19:00:00+07:00).',
                  ),
                  'new_due_time': Schema(
                    SchemaType.string,
                    description: 'Thời gian kết thúc mới (ISO 8601). Nếu người dùng xác nhận KHÔNG CẦN, hãy để trống hoặc bỏ qua.',
                  ),
                },
                requiredProperties: ['task_keyword', 'new_start_time'],
              ),
            ),
          ],
        ),
      ],
      systemInstruction: Content.system(
        'Bạn là một chuyên gia quản lý thời gian và trợ lý năng suất cho ứng dụng Task Management. '
        'Hôm nay là ngày ${now.day}/${now.month}/${now.year},'
        'giờ hiện tại là ${now.hour}:${now.minute}.'
        'BẮT BUỘC: Khi tính toán thời gian (start_time, due_time), phải tạo chuỗi ISO 8601'
        'theo múi giờ Việt Nam (UTC+07:00), KHÔNG dùng đuôi Z.'
        'Ví dụ: 8h sáng mai phải trả về dạng "2026-05-18T08:00:00+07:00". '
        'Nhiệm vụ của bạn là đưa ra lời khuyên ngắn gọn (dưới 100 chữ), thực tế để giúp người dùng '
        'hoàn thành công việc. Trả lời bằng tiếng Việt thân thiện, nhiệt tình. '
        'Từ chối mọi câu hỏi không liên quan đến công việc hoặc quản lý thời gian.',
      ),
    );
  }

  List<Content> _mapHistoryToGemini(List<ChatMessageModel> history) {
    return history.map((m) {
      if (m.role == 'user') {
        return Content.text(m.content);
      } else {
        return Content.model([TextPart(m.content)]);
      }
    }).toList();
  }

  Future<ChatBotResponse> sendMessage(
    String userMessage, {
    String? sessionId,
    List<ChatMessageModel> history = const [],
  }) async {
    if (_model == null) {
      return const ChatBotResponse(
        text: 'Chatbot chưa được cấu hình API key. Vui lòng kiểm tra file .env.',
      );
    }

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      return const ChatBotResponse(text: 'Vui lòng đăng nhập để sử dụng chatbot.');
    }

    try {
      String activeSessionId;
      if (sessionId == null) {
        // Create new session in Supabase
        final sessionData = await supabase.from('chat_session').insert({
          'title': userMessage.length > 40 ? '${userMessage.substring(0, 37)}...' : userMessage,
          'profile_id': userId,
        }).select('id').single();
        activeSessionId = sessionData['id'].toString();
      } else {
        activeSessionId = sessionId;
      }

      // 1. Save user message to Supabase
      await supabase.from('chat_message').insert({
        'session_id': int.parse(activeSessionId),
        'role': 'user',
        'content': userMessage,
      });

      // 2. Initialize Gemini Chat Session with history
      final geminiChat = _model!.startChat(history: _mapHistoryToGemini(history));

      // 3. Send message to Gemini
      var response = await geminiChat.sendMessage(Content.text(userMessage));
      bool didMutate = false;

      // 4. Handle Function Calls (Preserving existing logic)
      if (response.functionCalls.isNotEmpty) {
        final functionCall = response.functionCalls.first;
        if (functionCall.name == 'create_task_full') {
          final args = functionCall.args;
          final title = (args['title'] as String?)?.trim();
          final startTime = (args['start_time'] as String?)?.trim();
          final dueTime = (args['due_time'] as String?)?.trim();

          if (title == null || title.isEmpty || startTime == null || startTime.isEmpty) {
            // If essential args are missing, Gemini usually asks back, 
            // but we'll return a helpful text if the model directly failed to provide them.
            // However, normally we just pass the function response back.
          }

          final categoryName = args['category_name'] as String? ?? 'Cá nhân';
          final dbResponse = await supabase.rpc(
            'create_task_full',
            params: {
              'p_title': title ?? 'Task mới',
              'p_priority': (args['priority'] as num?)?.toInt() ?? 1,
              'p_profile_id': userId,
              'p_tag_names': (args['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
              'p_category_name': categoryName,
              'p_start_time': startTime ?? DateTime.now().toIso8601String(),
              'p_due_time': (dueTime == null || dueTime.isEmpty) ? null : dueTime,
            },
          );

          final isSuccess = dbResponse['success'] == true;
          didMutate = isSuccess;
          
          response = await geminiChat.sendMessage(
            Content.functionResponse('create_task_full', {
              'status': isSuccess ? 'Thành công' : 'Thất bại',
              'reason': isSuccess ? '' : dbResponse['error'].toString(),
            }),
          );
        } else if (functionCall.name == 'update_task_time') {
          final args = functionCall.args;
          final keyword = (args['task_keyword'] as String?)?.trim();
          final newStartTime = (args['new_start_time'] as String?)?.trim();
          final newDueTime = (args['new_due_time'] as String?)?.trim();

          final dbResponse = await supabase.rpc(
            'update_task_time_bot',
            params: {
              'p_profile_id': userId,
              'p_keyword': keyword ?? '',
              'p_new_start_time': newStartTime ?? '',
              'p_new_due_time': (newDueTime == null || newDueTime.isEmpty) ? null : newDueTime,
            },
          );
          
          final isSuccess = dbResponse['success'] == true;
          didMutate = isSuccess;

          response = await geminiChat.sendMessage(
            Content.functionResponse('update_task_time', {
              'status': isSuccess ? 'Thành công' : 'Thất bại',
              'reason': isSuccess ? '' : dbResponse['error'].toString(),
            }),
          );
        }
      }

      final botText = response.text ?? 'Xin lỗi, tôi không thể trả lời lúc này.';

      // 5. Save model response to Supabase
      await supabase.from('chat_message').insert({
        'session_id': int.parse(activeSessionId),
        'role': 'model',
        'content': botText,
      });

      return ChatBotResponse(
        text: botText,
        didMutateTasks: didMutate,
        sessionId: activeSessionId,
      );
    } catch (e) {
      debugPrint('ChatBot Error: $e');
      final errorString = e.toString();
      String userFriendlyError = 'Lỗi kết nối AI: $e';
      
      if (errorString.contains('503')) {
        userFriendlyError = 'Hệ thống đang quá tải. Bạn đợi vài phút rồi thử lại nhé!';
      } else if (errorString.contains('429')) {
        userFriendlyError = 'Bạn chat nhanh quá! Vui lòng chờ một chút.';
      }

      return ChatBotResponse(text: userFriendlyError);
    }
  }
}
