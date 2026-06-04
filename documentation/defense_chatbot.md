# 🤖 Tài liệu Vấn đáp: Luồng Chatbot (AI Assistant)

## 1. Tổng quan & Luồng Dữ Liệu (Data Flow)
**Tính năng**: Trợ lý AI hỗ trợ quản lý công việc qua ngôn ngữ tự nhiên, tích hợp Function Calling để thực thi hành động thực tế trên Database.
**User Flow**:
1. Người dùng gửi tin nhắn (text hoặc giọng nói qua STT).
2. `ChatBotViewModel` thêm tin nhắn vào UI (Optimistic Update) và gọi Service.
3. `ChatBotAssistantService` giao tiếp với Gemini API.
4. Nếu Gemini trả về yêu cầu gọi hàm, Service thực thi RPC trên Supabase.
5. AI nhận kết quả từ Database và phản hồi lại cho người dùng.
6. Toàn bộ hội thoại được lưu vào bảng `chat_session` và `chat_message`.

## 2. Phân tích Chuyên sâu Tầng Service (Xử lý Dữ liệu)
**Hàm cốt lõi**: `sendMessage` (file: `lib/features/chatbot/services/chatbot_services.dart`).

```dart
Future<ChatBotResponse> sendMessage(String userMessage, {String? sessionId, List<ChatMessageModel> history = const []}) async {
  try {
    // 1. Lưu tin nhắn User
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
        final dbResponse = await supabase.rpc('create_task_full', params: { ... });
        response = await geminiChat.sendMessage(Content.functionResponse('create_task_full', { 'status': 'Thành công' }));
      }
    }
    // ...
    return ChatBotResponse(text: response.text ?? '', didMutateTasks: didMutate, sessionId: activeSessionId);
  } catch (e) {
    debugPrint('ChatBot Error: $e');
    return ChatBotResponse(text: 'Rất tiếc, AI đang gặp sự cố...');
  }
}
```
**Giải thích Step-by-Step**:
- **Luồng AI-in-the-loop**: Service đóng vai trò điều phối. Khi AI muốn thực hiện hành động (như tạo task), nó trả về `functionCall`. Service sẽ thực hiện lệnh SQL thực tế thông qua Supabase RPC và gửi kết quả ngược lại cho AI để AI "xác nhận" với người dùng.
- **Lưu trữ**: Mọi tin nhắn (User & Model) đều được lưu vào Database để duy trì lịch sử.
- **Bắt lỗi**: Toàn bộ quá trình bọc trong `try-catch`. Nếu API AI hoặc Database lỗi, Service sẽ trả về một `ChatBotResponse` có thông báo lỗi thân thiện thay vì crash app.

## 3. Phân tích Chuyên sâu Tầng ViewModel (Quản lý Trạng thái)
**Hàm cốt lõi**: `sendMessage` (file: `lib/features/chatbot/viewmodel/chatbot_viewmodel.dart`).

```dart
Future<void> sendMessage(String text) async {
  final history = List<ChatMessageModel>.from(_messages);
  _messages.add(ChatMessageModel(role: 'user', content: text)); // Optimistic UI
  _isLoading = true;
  notifyListeners();

  try {
    final response = await _aiService.sendMessage(text, sessionId: _activeSessionId, history: history);
    if (response.didMutateTasks) {
      await _refreshDataAfterMutation(); // Đồng bộ Task mới
    }
    _messages.add(ChatMessageModel(role: 'model', content: response.text));
  } catch (e) {
    _messages.add(ChatMessageModel(role: 'model', content: 'Lỗi gửi tin nhắn...'));
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```
**Giải thích Step-by-Step**:
- **Optimistic UI**: Tin nhắn người dùng được thêm vào List `_messages` ngay lập tức trước khi gọi API, giúp tạo cảm giác mượt mà.
- **Đồng bộ hóa**: Nếu AI đã tạo/sửa Task (`didMutateTasks == true`), ViewModel sẽ gọi `_taskViewModel?.fetchTasks()` để cập nhật danh sách công việc ở các màn hình khác.
- **Loading State**: Biến `_isLoading` dùng để hiển thị hiệu ứng "Bot đang soạn thảo" (Typing Indicator).

## 4. Phân tích Chuyên sâu Tầng View (Giao diện)
**Đoạn code UI**: `ChatBotView` (file: `lib/features/chatbot/view/chatbot_view.dart`).

```dart
final viewModel = context.watch<ChatBotViewModel>();
return Column(
  children: [
    Expanded(
      child: ListView.builder(
        itemCount: viewModel.messages.length,
        itemBuilder: (context, index) => MessageTile(message: viewModel.messages[index]),
      ),
    ),
    if (viewModel.isLoading) const TypingIndicator(),
    MessageComposer(onSend: () => _sendMessage(viewModel)),
  ],
);
```
**Giải thích Step-by-Step**:
- **Lắng nghe**: Sử dụng `context.watch<ChatBotViewModel>()` để tự động cuộn và hiển thị tin nhắn mới ngay khi AI phản hồi.
- **Tính năng mở rộng**: Tích hợp Speech-to-Text (`stt.SpeechToText`) trong `_ChatBotViewBodyState` để hỗ trợ nhập liệu bằng giọng nói, sau đó truyền text vào `MessageComposer`.

## 5. Quyết định Thiết kế (The 'Why')
- **Tại sao dùng Function Calling thay vì để AI tự gọi API?**: Để đảm bảo an toàn. AI không có quyền truy cập trực tiếp vào Token hay Database. Nó chỉ có thể "đề xuất" hành động qua JSON, và Code của app sẽ kiểm duyệt các tham số đó trước khi gọi SQL.

## 6. Bộ câu hỏi Vấn đáp (Q&A) kềm BẰNG CHỨNG TỪ CODE
**Q1: Làm sao em giữ được ngữ cảnh (Context) của cuộc hội thoại để AI không bị "quên" tin nhắn trước?**
- **Trả lời**: Em truyền biến `history` (danh sách các tin nhắn cũ) vào mỗi lần gọi API. Em sử dụng hàm `_mapHistoryToGemini` để chuyển đổi Model của App sang định dạng `Content` mà Gemini API yêu cầu.
- **Bằng chứng**: 
```dart
final history = List<ChatMessageModel>.from(_messages);
final geminiChat = _model!.startChat(history: _mapHistoryToGemini(history));
```

**Q2: Nếu AI tạo xong một Task, làm sao người dùng thấy được Task đó ở màn hình chính mà không cần Load lại app?**
- **Trả lời**: Em sử dụng cơ chế Cross-ViewModel Communication. `ChatBotViewModel` giữ tham chiếu đến `TaskViewModel`. Sau khi AI thực thi thành công, em gọi hàm fetch lại dữ liệu.
- **Bằng chứng**: 
```dart
Future<void> _refreshDataAfterMutation() async {
  await _taskViewModel?.fetchTasks();
}
```

**Q3: Em xử lý lỗi thế nào khi Gemini API hết quota hoặc quá tải (Error 429/503)?**
- **Trả lời**: Em đã bọc logic gọi API trong `try-catch`. Nếu phát hiện mã lỗi liên quan đến Quota hoặc Overload trong chuỗi lỗi, em sẽ trả về một thông báo Tiếng Việt thân thiện thay vì thông báo lỗi kỹ thuật.
- **Bằng chứng**: 
```dart
if (errorString.contains('503')) {
  userFriendlyError = 'Hệ đồng đang quá tải...';
} else if (errorString.contains('429')) {
  userFriendlyError = 'Bạn chat nhanh quá hoặc AI đã hết lượt dùng...';
}
```
*(Lưu ý: Bạn đã refactor logic này trong chatbot_services.dart).*
