# ⏳ Tài liệu Vấn đáp: Luồng Focus (Pomodoro & Quick Note)

## 1. Tổng quan & Luồng Dữ Liệu (Data Flow)
- **Tính năng**: Cung cấp đồng hồ tập trung Pomodoro tích hợp nhạc nền (Lofi, Rain) và ghi chú nhanh (Quick Note) có hỗ trợ hình ảnh.
- **User Flow thực tế**:
    1. Người dùng chọn chế độ (Pomodoro/Short Break) và bắt đầu Timer.
    2. Nhạc nền được phát thông qua `AudioPlayer`.
    3. Trong quá trình tập trung, người dùng nhập text hoặc chọn ảnh từ gallery để tạo ghi chú nhanh.
    4. Ghi chú được lưu tức thì vào bộ nhớ cục bộ (Local Storage).

## 2. Mapping Kiến trúc MVVM (Chỉ đích danh File/Class)
- **Model**: `NoteModel` (file: `lib/features/note/model/note_model.dart`). Lưu thông tin `content`, `pinned`, và `imagePath`.
- **Service/Repository**:
    - **Code hiện tại chưa sử dụng Service riêng cho Note**, logic lưu trữ nằm trực tiếp trong ViewModel thông qua `SharedPreferences`.
    - **Timer Service**: Sử dụng `Timer.periodic` tích hợp sẵn trong ViewModel.
- **ViewModel**: `FocusViewModel` (file: `lib/features/note/viewmodel/focus_viewmodel.dart`).
    - **Trạng thái**: Quản lý `timeRemaining`, `isRunning`, `notes` (List). Cập nhật qua `notifyListeners()`.

## 3. Quyết định Thiết kế (The 'Why')
- **Tại sao dùng SharedPreferences cho Note thay vì Supabase?**: Quick Note trong màn hình Focus được thiết kế để "ghi chép nháp" tức thì. Việc lưu local giúp tính năng hoạt động offline hoàn toàn, không có độ trễ mạng, đảm bảo trải nghiệm tập trung không bị gián đoạn.
- **Tại sao dùng AudioPlayer cho nhạc nền?**: Để hỗ trợ lặp lại nhạc (`ReleaseMode.loop`) và quản lý đa kênh (Mix các loại âm thanh) giúp tạo môi trường làm việc tối ưu.
- **Xử lý Timer khi thoát App**: Code hiện tại sử dụng `Timer.periodic`. (Lưu ý: Nếu App bị kill, Timer sẽ dừng. Trong tương lai cần lưu `endTime` vào local để tính toán lại).

## 4. Bộ câu hỏi Vấn đáp (Q&A) kềm BẰNG CHỨNG TỪ CODE
- **Q1: Em xử lý lưu trữ dữ liệu offline cho tính năng Note như thế nào?**
    - **Trả lời**: Em chuyển đổi danh sách `NoteModel` thành chuỗi JSON và lưu vào `SharedPreferences`. Khi khởi tạo ViewModel, em sẽ load lại dữ liệu này.
    - **Bằng chứng**: File `lib/features/note/viewmodel/focus_viewmodel.dart`
    ```dart
    Future<void> saveNotesToDisk() async {
      final prefs = await SharedPreferences.getInstance();
      List<String> noteStrings = notes.map((n) => n.toJson()).toList();
      await prefs.setStringList('saved_notes', noteStrings);
    }
    ```
- **Q2: Làm sao để đồng hồ Pomodoro cập nhật mượt mà trên UI mà không làm chậm App?**
    - **Trả lời**: Em sử dụng `Timer.periodic` mỗi 1 giây để giảm `timeRemaining` và gọi `notifyListeners()`. UI chỉ rebuild các thành phần cần thiết nhờ sử dụng `context.watch<FocusViewModel>()`.
    - **Bằng chứng**: File `lib/features/note/viewmodel/focus_viewmodel.dart`
    ```dart
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining > 0) {
        timeRemaining--;
      } else {
        // Time is up
        _timer?.cancel();
        // ... trigger alarm ...
      }
      notifyListeners();
    });
    ```
- **Q3: Em xử lý việc "Ghim" (Pin) ghi chú như thế nào để chúng luôn nằm ở đầu danh sách?**
    - **Trả lời**: Em viết một hàm `_sortNotes()` thực hiện sắp xếp dựa trên thuộc tính `pinned` trước, sau đó mới đến `id` (thời gian tạo). Hàm này được gọi mỗi khi thêm hoặc toggle trạng thái pin.
    - **Bằng chứng**: File `lib/features/note/viewmodel/focus_viewmodel.dart`
    ```dart
    void _sortNotes() {
      notes.sort((a, b) {
        if (a.pinned && !b.pinned) return -1;
        if (!a.pinned && b.pinned) return 1;
        return b.id.compareTo(a.id);
      });
    }
    ```
- **Q4: Em tích hợp âm thanh thông báo và rung khi hết giờ như thế nào?**
    - **Trả lời**: Em sử dụng package `flutter_ringtone_player` để phát âm thanh hệ thống và `HapticFeedback` để tạo hiệu ứng rung vật lý.
    - **Bằng chứng**: File `lib/features/note/viewmodel/focus_viewmodel.dart`
    ```dart
    if (isVibrationEnabled) HapticFeedback.heavyImpact();
    if (ringtoneType == 1) {
      FlutterRingtonePlayer().playAlarm();
    }
    ```

## 5. Phân tích chuyên sâu (Deep-dive) Hàm Cốt Lõi

### Hàm `toggleTimer` trong `FocusViewModel`
Hàm này là trung tâm điều khiển luồng thời gian và các phản hồi vật lý (rung, âm thanh) của chế độ tập trung.

**Trích xuất Code thực tế:**
```dart
void toggleTimer() {
  if (isRunning) {
    _timer?.cancel();
    isRunning = false;
    unawaited(_stopFocusAudio());
  } else {
    isRunning = true;
    unawaited(_playFocusAudio());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining > 0) {
        timeRemaining--;
      } else {
        // Hết giờ
        _timer?.cancel();
        isRunning = false;
        isRinging = true;
        unawaited(_stopFocusAudio());

        // Kích hoạt phản hồi phần cứng
        if (isVibrationEnabled) HapticFeedback.heavyImpact();
        if (ringtoneType == 1) FlutterRingtonePlayer().playAlarm();
        // ... các loại chuông khác ...
      }
      notifyListeners();
    });
  }
  notifyListeners();
}
```

**Giải thích Step-by-Step:**

1.  **Logic nghiệp vụ**: Hàm này quản lý máy trạng thái (State Machine) của Timer. Nó không chỉ đơn thuần là đếm số mà còn điều phối tài nguyên: `Timer` (CPU), `AudioPlayer` (Nhạc nền), `Vibrator` (Rung), và `Ringtone` (Chuông). Việc sử dụng `unawaited` cho âm thanh giúp UI phản hồi ngay lập tức mà không chờ file nhạc load xong.
2.  **Input/Output**:
    - **Input**: Trạng thái hiện tại của biến `isRunning` và `timeRemaining`.
    - **Output**: Không trả về giá trị, nhưng thay đổi toàn bộ trạng thái của ViewModel.
3.  **Bắt lỗi (Safety Logic)**: Mặc dù không sử dụng block `try-catch` hiển thị (vì logic đếm ngược khá thuần túy), nhưng hàm sử dụng toán tử an toàn `?.` cho `_timer`. Dòng `_timer?.cancel()` đảm bảo nếu có nhiều timer chạy chồng chéo, chúng sẽ được dọn dẹp sạch sẽ để tránh rò rỉ bộ nhớ hoặc đếm nhanh gấp đôi (Timer Leak).
4.  **Trigger cập nhật UI**: Lệnh `notifyListeners()` được gọi ở hai vị trí chiến lược: 
    - Ngay khi bấm nút (để đổi icon Start/Pause).
    - Mỗi 1 giây bên trong `Timer.periodic` (để cập nhật đồng hồ chạy và vòng tròn tiến trình). Đây là dòng code "sống" duy trì sự mượt mà của màn hình Focus.
