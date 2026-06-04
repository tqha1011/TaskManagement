# 🤖 Tài liệu Vấn đáp: Luồng Chatbot (AI Assistant)

## 1. Tổng quan & Luồng Dữ Liệu (Data Flow)
**Tính năng**: Trợ lý AI thông minh hỗ trợ quản lý thời gian và công việc qua ngôn ngữ tự nhiên. Tích hợp công nghệ **Function Calling** (Gemini API) để thực thi hành động trực tiếp trên Database và hỗ trợ định dạng **Markdown** để hiển thị nội dung phong phú.

**User Flow**:
1.  **Gửi yêu cầu**: Người dùng nhập text hoặc dùng Speech-to-Text. `ChatBotViewModel` thực hiện **Optimistic UI Update**, thêm ngay tin nhắn vào danh sách để tạo cảm giác mượt mà.
2.  **Xử lý Logic**: ViewModel gọi `ChatBotAssistantService`. Service gửi tin nhắn kèm lịch sử hội thoại lên Gemini.
3.  **Hành động AI (AI-in-the-loop)**: Nếu AI yêu cầu tạo/sửa Task, Service thực thi **Supabase RPC**. Kết quả DB được gửi ngược lại cho AI để xác nhận với người dùng.
4.  **Lưu trữ**: Toàn bộ tin nhắn (User & Model) được lưu vào bảng `chat_message` theo đúng `session_id`.
5.  **Hiển thị**: Dữ liệu trả về (chứa Markdown) được `MessageTile` tại tầng View render thông qua thư viện `flutter_markdown`.

## 2. Phân tích Chuyên sâu Tầng Service (Xử lý Dữ liệu)
**Hàm cốt lõi**: `sendMessage` (file: `lib/features/chatbot/services/chatbot_services.dart`).

```dart
Future<ChatBotResponse> sendMessage(String userMessage, {String? sessionId, List<ChatMessageModel> history = const []}) async {
  try {
    // 1. Lưu tin nhắn User vào Supabase
    await supabase.from('chat_message').insert({
      'session_id': int.parse(activeSessionId),
      'role': 'user',
      'content': userMessage,
    });

    // 2. Gọi Gemini và xử lý Function Calling
    final geminiChat = _model!.startChat(history: _mapHistoryToGemini(history));
    var response = await geminiChat.sendMessage(Content.text(userMessage));

    if (response.functionCalls.isNotEmpty) {
      final functionCall = response.functionCalls.first;
      if (functionCall.name == 'create_task_full') {
        // Thực thi RPC nghiệp vụ
        final dbResponse = await supabase.rpc('create_task_full', params: { ... });
        // Truyền kết quả DB ngược lại cho AI
        response = await geminiChat.sendMessage(
          Content.functionResponse('create_task_full', { 'status': 'Thành công', 'reason': '' }),
        );
      }
    }
    
    final botText = response.text ?? '...';
    // 3. Lưu phản hồi AI vào DB
    await supabase.from('chat_message').insert({
      'session_id': int.parse(activeSessionId),
      'role': 'model',
      'content': botText,
    });

  try {
    final response = await _aiService.sendMessage(text, sessionId: _activeSessionId, history: history);
    if (response.didMutateTasks) {
      await _refreshDataAfterMutation(); // Đồng bộ Task mới
    }
    _messages.add(ChatMessageModel(role: 'model', content: response.text));
  } catch (e) {
    debugPrint('ChatBot Critical Error: $e');
    // Error Handling: Trả về thông báo tiếng Việt thân thiện theo loại lỗi (503, 429, Network)
    return ChatBotResponse(text: userFriendlyError);
  }
}
```
**Giải thích Step-by-Step**:
- **Input**: Nhận tin nhắn, ID phiên và lịch sử hội thoại (List Model).
- **Cơ chế Tooling**: Đây là điểm phức tạp nhất. Service không chỉ nhận văn bản mà còn thực hiện "lệnh" từ AI thông qua JSON arguments, đảm bảo an toàn dữ liệu trước khi gọi RPC.
- **Xử lý Bất đồng bộ**: Sử dụng `await` cho cả API AI và Supabase, bọc trong `try-catch` để đảm bảo ứng dụng không bao giờ bị treo khi AI quá tải.

## 3. Phân tích Chuyên sâu Tầng ViewModel (Quản lý Trạng thái)
**Hàm cốt lõi**: `sendMessage` (file: `lib/features/chatbot/viewmodel/chatbot_viewmodel.dart`).

```dart
Future<void> sendMessage(String text) async {
  // 1. Capture history & Optimistic Update
  final history = List<ChatMessageModel>.from(_messages);
  _messages.add(ChatMessageModel(role: 'user', content: text));
  _isLoading = true;
  notifyListeners(); // Trigger UI vẽ ngay tin nhắn người dùng

  try {
    final response = await _aiService.sendMessage(text, sessionId: _activeSessionId, history: history);
    
    // 2. Cross-ViewModel Sync: Tự động cập nhật Task ở màn Home nếu AI vừa tạo Task
    if (response.didMutateTasks) {
      await _refreshDataAfterMutation(); 
    }
    
    _messages.add(ChatMessageModel(role: 'model', content: response.text));
  } catch (e) {
    _messages.add(ChatMessageModel(role: 'model', content: 'Lỗi gửi tin nhắn...'));
  } finally {
    _isLoading = false;
    notifyListeners(); // Tắt Typing Indicator
  }
}
```
**Giải thích Step-by-Step**:
- **Nắm giữ State**: Quản lý `List<ChatMessageModel>`, `_activeSessionId` và trạng thái `_isLoading`.
- **Notify UI**: Gọi `notifyListeners()` 2 lần (lúc bắt đầu và kết thúc) để tạo hiệu ứng mượt mà và hiển thị `TypingIndicator`.
- **Duy trì ngữ cảnh**: Trích xuất lịch sử (`history`) *trước* khi thêm tin nhắn mới để truyền vào Gemini API theo đúng giao thức.

## 4. Phân tích Chuyên sâu Tầng View (Giao diện)
**Đoạn code UI**: `MessageTile` (file: `lib/features/chatbot/view/widgets/message_tile.dart`).

```dart
// Render bong bóng chat của Bot bằng MarkdownBody
MarkdownBody(
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
)
```
**Giải thích Step-by-Step**:
- **Markdown Rendering**: Sử dụng `MarkdownBody` để xử lý các ký tự AI trả về như `**bold**`, `*italic*`, hay danh sách `- item`.
- **Styling**: Tinh chỉnh `MarkdownStyleSheet` để giữ nguyên font `titleMedium` và màu sắc đồng bộ với giao diện chung của App (hỗ trợ cả Light/Dark Mode).
- **Lắng nghe sự kiện**: View sử dụng `context.watch<ChatBotViewModel>()` để tự động cuộn xuống và hiển thị tin nhắn mới ngay khi ViewModel thay đổi.

## 5. Quyết định Thiết kế (The 'Why')
- **Tại sao dùng Markdown?**: AI thường cung cấp thông tin theo cấu trúc (ví dụ liệt kê các task cần làm). Markdown giúp hiển thị các thông tin này một cách trực quan, chuyên nghiệp và cực kỳ dễ đọc cho người dùng.
- **Tại sao dùng Cross-ViewModel Sync?**: Sau khi AI tạo Task, nếu không cập nhật `TaskViewModel`, người dùng sẽ thấy thông tin không nhất quán giữa màn hình Chat và màn hình Home. Việc gọi fetch lại dữ liệu đảm bảo **Single Source of Truth**.
- **Kiến trúc MVVM**: Tách biệt hoàn toàn logic gọi AI (Service), quản lý danh sách tin nhắn (ViewModel) và cách hiển thị Markdown (View). Giúp dễ dàng thay thế model AI khác (ví dụ OpenAI) mà không cần sửa UI.

## 6. Bộ câu hỏi Vấn đáp (Q&A) kềm BẰNG CHỨNG TỪ CODE
**Q1: Làm sao em đảm bảo tính bảo mật khi AI yêu cầu gọi hàm thực thi Database?**
- **Trả lời**: AI không trực tiếp gọi SQL. Nó chỉ đề xuất tham số JSON. Em thực thi logic này tại Service thông qua các **RPC** (Stored Procedures) trên Supabase, nơi đã được cài đặt quyền RLS nghiêm ngặt.
- **Bằng chứng**: 
```dart
final dbResponse = await supabase.rpc('create_task_full', params: { ... });
```

**Q2: Làm sao để tin nhắn mới nhất luôn hiển thị ngay lập tức mà không bị trễ bởi mạng?**
- **Trả lời**: Em sử dụng kỹ thuật **Optimistic UI Update**. Tin nhắn người dùng được thêm vào danh sách và gọi `notifyListeners()` ngay lập tức *trước* khi gửi request lên Server.
- **Bằng chứng**: 
```dart
_messages.add(ChatMessageModel(role: 'user', content: text));
_isLoading = true;
notifyListeners();
```

**Q3: Em xử lý thế nào nếu Gemini API trả về lỗi hết hạn mức sử dụng (Quota Exceeded)?**
- **Trả lời**: Em đã bọc toàn bộ logic trong `try-catch` và xây dựng bộ lọc lỗi. Nếu phát hiện chuỗi lỗi chứa mã `429` (Quota), em sẽ trả về một câu thông báo tiếng Việt thân thiện thay vì lỗi kỹ thuật.
- **Bằng chứng**: 
```dart
} catch (e) {
  if (errorString.contains('429')) {
    userFriendlyError = 'Bạn chat nhanh quá hoặc AI đã hết lượt sử dụng...';
  }
  return ChatBotResponse(text: userFriendlyError);
}
```
*(Lưu ý: Logic này đã được refactor tập trung trong chatbot_services.dart).*
