# 🤖 Tài liệu Vấn đáp: Luồng Chatbot (AI Assistant)

## 1. Tổng quan & Luồng Dữ Liệu (Data Flow)
- **Tính năng**: Trợ lý thông minh hỗ trợ tạo và cập nhật công việc bằng ngôn ngữ tự nhiên. Tích hợp Google Gemini AI và khả năng thực thi hành động (Action) thông qua Function Calling.
- **User Flow thực tế**:
    1. Người dùng gửi tin nhắn (ví dụ: "Nhắc tôi học bài lúc 2h chiều").
    2. `ChatBotViewModel` cập nhật tin nhắn vào UI (Optimistic UI) và gửi tới `ChatBotAssistantService`.
    3. `ChatBotAssistantService` gọi API Gemini cùng với danh sách `tools` (Function Declarations).
    4. Nếu Gemini yêu cầu gọi hàm, Service sẽ thực thi SQL RPC trên Supabase (ví dụ: `create_task_full`).
    5. Kết quả từ Database được gửi ngược lại cho Gemini để AI trả lời người dùng một cách tự nhiên.
    6. Lịch sử chat được lưu vào bảng `chat_session` và `chat_message` trên Supabase.

## 2. Mapping Kiến trúc MVVM (Chỉ đích danh File/Class)
- **Model**: `ChatMessageModel` và `ChatSessionModel` (thư mục `lib/features/chatbot/model/`). Ánh xạ từ các bảng cùng tên trong Database.
- **Service/Repository**: `ChatBotAssistantService` (file: `lib/features/chatbot/services/chatbot_services.dart`).
    - **Hàm cốt lõi**: `sendMessage(...)` xử lý luồng giao tiếp giữa AI và Database.
- **ViewModel**: `ChatBotViewModel` (file: `lib/features/chatbot/viewmodel/chatbot_viewmodel.dart`).
    - **Trạng thái**: Quản lý `_messages` (danh sách tin nhắn) và `_isLoading`. Sử dụng `_refreshDataAfterMutation()` để đồng bộ hóa dữ liệu Task sau khi AI thao tác.

## 3. Quyết định Thiết kế (The 'Why')
- **Tại sao dùng Function Calling?**: Để đảm bảo tính chính xác. AI không trực tiếp ghi vào DB mà chỉ trả về các tham số có cấu trúc (JSON). Code của App sẽ kiểm soát việc gọi Database, đảm bảo an toàn dữ liệu.
- **Tại sao dùng Optimistic UI?**: Khi người dùng nhấn gửi, tin nhắn hiện lên ngay lập tức thay vì đợi API AI phản hồi (thường mất 2-3s), giúp cảm giác App mượt mà hơn.
- **Tại sao tách Session?**: Để quản lý lịch sử chat theo từng chủ đề riêng biệt, giúp AI giữ được ngữ cảnh (Context) tốt hơn trong một cuộc hội thoại.

## 4. Bộ câu hỏi Vấn đáp (Q&A) kềm BẰNG CHỨNG TỪ CODE
- **Q1: Em làm thế nào để AI hiểu được định dạng thời gian và các tham số cần thiết khi tạo Task?**
    - **Trả lời**: Em sử dụng `FunctionDeclaration` để định nghĩa một Schema chi tiết cho hàm `create_task_full`, quy định rõ kiểu dữ liệu và mô tả cho từng trường như `title`, `priority`, `start_time`.
    - **Bằng chứng**: File `lib/features/chatbot/services/chatbot_services.dart`
    ```dart
    FunctionDeclaration(
      'create_task_full',
      'Tạo một công việc mới...',
      Schema(
        SchemaType.object,
        properties: {
          'title': Schema(SchemaType.string, description: 'Tên công việc cần làm'),
          'priority': Schema(SchemaType.integer, description: 'Độ ưu tiên: 1-3'),
          // ... các trường khác ...
        },
        requiredProperties: ['title', 'priority', 'tags'],
      ),
    ),
    ```
- **Q2: Làm sao để AI biết được ngày giờ hiện tại để tính toán các mốc thời gian như "mai", "thứ hai tới"?**
    - **Trả lời**: Em truyền ngày giờ hiện tại vào `systemInstruction` của AI mỗi khi khởi tạo Model. Đồng thời ép AI luôn sử dụng múi giờ Việt Nam (UTC+7).
    - **Bằng chứng**: File `lib/features/chatbot/services/chatbot_services.dart`
    ```dart
    systemInstruction: Content.system(
      'Hôm nay là ngày ${now.day}/${now.month}/${now.year},'
      'giờ hiện tại là ${now.hour}:${now.minute}.'
      'BẮT BUỘC: Khi tính toán thời gian, phải tạo chuỗi ISO 8601 theo múi giờ Việt Nam (UTC+07:00)...'
    ),
    ```
- **Q3: Em xử lý thế nào để đồng bộ dữ liệu Task trên UI sau khi AI vừa tạo xong một công việc mới?**
    - **Trả lời**: Trong `ChatBotViewModel`, em kiểm tra flag `didMutateTasks` từ Service trả về. Nếu là `true`, em sẽ gọi hàm `fetchTasks()` của `TaskViewModel`.
    - **Bằng chứng**: File `lib/features/chatbot/viewmodel/chatbot_viewmodel.dart`
    ```dart
    Future<void> _refreshDataAfterMutation() async {
      await _taskViewModel?.fetchTasks();
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _statisticsViewmodel?.getStatisticsData(userId);
      }
    }
    ```
- **Q4: Làm sao để AI không trả lời những câu hỏi ngoài lề hoặc không liên quan đến công việc?**
    - **Trả lời**: Em cấu hình trong `systemInstruction` yêu cầu AI đóng vai trợ lý năng suất và từ chối các yêu cầu không liên quan.
    - **Bằng chứng**: File `lib/features/chatbot/services/chatbot_services.dart`
    ```dart
    'Nhiệm vụ của bạn là đưa ra lời khuyên ngắn gọn... Từ chối mọi câu hỏi không liên quan đến công việc hoặc quản lý thời gian.'
    ```
