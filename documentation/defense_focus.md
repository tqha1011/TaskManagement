# ⏳ Tài liệu Vấn đáp: Luồng Focus (Pomodoro & Quick Note)

## 1. Tổng quan & Luồng Dữ Liệu (Data Flow)
**Tính năng**: Cung cấp đồng hồ tập trung Pomodoro tích hợp nhạc nền và ghi chú nhanh.
**User Flow**:
1. Người dùng chọn chế độ (Pomodoro/Break) và bấm Start.
2. `FocusViewModel` khởi tạo `Timer.periodic`.
3. Nhạc nền được phát qua `AudioPlayer`.
4. Người dùng nhập ghi chú/chọn ảnh. Khi bấm Lưu, dữ liệu được lưu vào `SharedPreferences` (Local Storage).
5. UI lắng nghe từng giây để cập nhật đồng hồ và vòng tròn tiến trình.

## 2. Phân tích Chuyên sâu Tầng Service (Xử lý Dữ liệu)
**Hàm cốt lõi**: `saveNotesToDisk` và `_playFocusAudio` (file: `lib/features/note/viewmodel/focus_viewmodel.dart`). 
*(Lưu ý: Luồng Focus sử dụng Local Storage và Audio Service trực tiếp trong ViewModel để đảm bảo tốc độ phản hồi tức thì).*

```dart
Future<void> saveNotesToDisk() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> noteStrings = notes.map((n) => n.toJson()).toList();
  await prefs.setStringList('saved_notes', noteStrings);
}

Future<void> _playFocusAudio() async {
  if (!isPomodoroMode) return;
  try {
    final assetPath = focusSoundAssets[focusSoundKey];
    if (assetPath == null) return;
    await _focusAudioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    await _focusAudioPlayer.setReleaseMode(ReleaseMode.loop);
    await _focusAudioPlayer.setVolume(boostedVolume);
    await _focusAudioPlayer.setSource(AssetSource(assetPath));
    await _focusAudioPlayer.resume();
  } catch (e) {
    debugPrint('Không phát được nhạc nền: $e');
  }
}
```
**Giải thích Step-by-Step**:
- **Lưu trữ**: Chuyển đổi List `NoteModel` sang JSON string để lưu vào `SharedPreferences`. Đây là cách tối ưu cho dữ liệu nhỏ và cần truy cập offline.
- **Audio**: Sử dụng `audioplayers` package. Đặt `ReleaseMode.loop` để nhạc nền lặp vô tận. Bọc trong `try-catch` để tránh crash nếu file asset không tồn tại hoặc lỗi phần cứng âm thanh.
- **Input/Output**: Input là các biến trạng thái (`notes`, `focusSoundKey`). Không có output trả về mà thực hiện thay đổi trạng thái phần cứng/bộ nhớ.

## 3. Phân tích Chuyên sâu Tầng ViewModel (Quản lý Trạng thái)
**Hàm cốt lõi**: `toggleTimer` (file: `lib/features/note/viewmodel/focus_viewmodel.dart`).

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
        _timer?.cancel();
        isRunning = false;
        isRinging = true; 
        unawaited(_stopFocusAudio());
        if (isVibrationEnabled) HapticFeedback.heavyImpact();
        if (ringtoneType == 1) FlutterRingtonePlayer().playAlarm();
      }
      notifyListeners();
    });
  }
  notifyListeners();
}
```
**Giải thích Step-by-Step**:
- **Biến State**: Quản lý `isRunning`, `timeRemaining`, `isRinging`.
- **Logic đếm ngược**: Sử dụng `Timer.periodic` mỗi 1 giây. Khi `timeRemaining == 0`, dừng Timer, kích hoạt Rung (`HapticFeedback`) và Chuông (`FlutterRingtonePlayer`).
- **notifyListeners()**: Được gọi liên tục mỗi giây để đồng hồ trên UI chạy mượt mà.

## 4. Phân tích Chuyên sâu Tầng View (Giao diện)
**Đoạn code UI**: `TimerDisplayWidget` (file: `lib/features/note/view/focus_widget.dart`).

```dart
@override
Widget build(BuildContext context) {
  final vm = context.watch<FocusViewModel>();
  return Stack(
    alignment: Alignment.center,
    children: [
      CircularProgressIndicator(
        value: vm.progress,
        strokeWidth: 14,
        color: Theme.of(context).colorScheme.primary,
      ),
      Text(
        vm.timeString,
        style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900),
      ),
    ],
  );
}
```
**Giải thích Step-by-Step**:
- **Cơ chế lắng nghe**: Sử dụng `context.watch<FocusViewModel>()`. Điều này cực kỳ quan trọng vì UI cần cập nhật mỗi giây theo Timer.
- **Phản hồi**: `CircularProgressIndicator` sử dụng getter `vm.progress` (tính toán dựa trên `timeRemaining / totalTime`) để vẽ vòng tròn tiến trình. `vm.timeString` định dạng giây thành MM:SS để hiển thị.

## 5. Quyết định Thiết kế (The 'Why')
- **Tại sao dùng SharedPreferences thay vì Supabase cho Note?**: Quick Note trong màn hình Focus được thiết kế để ghi chép "nháp" tức thì. Lưu local giúp app hoạt động 100% offline, không có độ trễ mạng, đảm bảo sự tập trung không bị gián đoạn.

## 6. Bộ câu hỏi Vấn đáp (Q&A) kềm BẰNG CHỨNG TỪ CODE
**Q1: Khi người dùng thoát app hoặc tắt màn hình, Timer của em có còn chạy không?**
- **Trả lời**: Trong code hiện tại, `Timer.periodic` sẽ bị dừng nếu hệ điều hành kill app. Tuy nhiên, em đã xử lý `dispose()` để tránh rò rỉ bộ nhớ. Hướng giải quyết là lưu `endTime` vào Local Storage để tính toán lại khi app resume.
- **Bằng chứng**: 
```dart
@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```

**Q2: Làm sao em sắp xếp được các ghi chú Ghim luôn nằm trên đầu?**
- **Trả lời**: Em viết một hàm `_sortNotes()` sử dụng phương thức `sort` của Dart, ưu tiên thuộc tính `pinned` trước, sau đó mới đến `id` (thời gian).
- **Bằng chứng**: 
```dart
void _sortNotes() {
  notes.sort((a, b) {
    if (a.pinned && !b.pinned) return -1;
    if (!a.pinned && b.pinned) return 1;
    return b.id.compareTo(a.id);
  });
}
```

**Q3: Em xử lý việc chọn ảnh từ Gallery như thế nào trong luồng Focus?**
- **Trả lời**: Em sử dụng `ImagePicker`. Sau khi chọn, em chỉ lưu `path` (đường dẫn local) vào `NoteModel` để tiết kiệm bộ nhớ, thay vì lưu toàn bộ file ảnh vào Database.
- **Bằng chứng**: 
```dart
final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
if (image != null) {
  selectedImagePath = image.path;
  notifyListeners();
}
```
