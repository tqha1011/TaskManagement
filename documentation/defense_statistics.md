# 📊 Tài liệu Vấn đáp: Luồng Statistics (Thống kê)

## 1. Tổng quan & Luồng Dữ Liệu (Data Flow)
**Tính năng**: Cung cấp báo cáo trực quan về hiệu suất công việc.
**User Flow**:
1. Người dùng vào màn hình Thống kê.
2. `StatisticsScreen` gọi `getStatisticsData` trong ViewModel.
3. ViewModel gọi `StatisticsService` để thực thi RPC trên Supabase.
4. Database tính toán và trả về kết quả tổng hợp (JSON).
5. ViewModel xử lý "chuẩn hóa" dữ liệu để vẽ biểu đồ và thông báo cho View hiển thị.

## 2. Phân tích Chuyên sâu Tầng Service (Xử lý Dữ liệu)
**Hàm cốt lõi**: `getUserStatistics` (file: `lib/features/statistics/services/statistics_service.dart`).

```dart
Future<UserStatisticsModel> getUserStatistics(String userId) async {
  try {
    final response = await supabaseClient.rpc(
      'get_user_statistics',
      params: {'p_profile_id' : userId}
    );
    return UserStatisticsModel.fromJson(response);
  } catch(e) {
    throw Exception('Failed to get statistics: $e');
  }
}
```
**Giải thích Step-by-Step**:
- **Input**: Nhận `userId` từ Auth session.
- **RPC Call**: Không query từng bảng, Service gọi hàm `get_user_statistics` đã được định nghĩa sẵn trên PostgreSQL. Điều này giúp tính toán phức tạp (aggregate) diễn ra ở Server-side, giảm tải cho điện thoại.
- **Bắt lỗi**: Sử dụng `try-catch` để bắt các lỗi liên quan đến kết nối DB hoặc lỗi logic SQL.
- **Output**: Trả về `UserStatisticsModel` - một object chứa đầy đủ các chỉ số (Today, Weekly, Recent Tasks).

## 3. Phân tích Chuyên sâu Tầng ViewModel (Quản lý Trạng thái)
**Hàm cốt lõi**: `weeklyBarHeights` (getter) và `getStatisticsData` (file: `lib/features/statistics/viewmodel/statistics_viewmodel.dart`).

```dart
List<double> get weeklyBarHeights {
  if (statisticsData == null) return List.filled(7, 0.1);
  List<int> rawCounts = statisticsData!.dailyCounts;
  int maxTasks = rawCounts.reduce((curr, next) => curr > next ? curr : next);
  if (maxTasks == 0) return List.filled(7, 0.1);
  return rawCounts.map((count) => count / maxTasks).toList();
}
```
**Giải thích Step-by-Step**:
- **Trạng thái**: Nắm giữ `statisticsData` và `_isLoading`.
- **Logic chuẩn hóa**: Biểu đồ yêu cầu tỷ lệ từ 0.0 đến 1.0. ViewModel tìm giá trị lớn nhất trong tuần (`maxTasks`) và chia các ngày khác cho giá trị đó để lấy tỷ lệ chiều cao cột.
- **notifyListeners()**: Được gọi trong hàm `getStatisticsData` (ở khối `finally`) để UI biết khi nào dữ liệu đã sẵn sàng hoặc có lỗi.

## 4. Phân tích Chuyên sâu Tầng View (Giao diện)
**Đoạn code UI**: `StatisticsScreen` (file: `lib/features/statistics/view/screens/statistics_screen.dart`).

```dart
return Consumer<StatisticsViewmodel>(
  builder: (context, viewModel, child) {
    if (viewModel.isLoading) return CircularProgressIndicator();
    if (viewModel.errorMessage != null) return Text("Lỗi: ${viewModel.errorMessage}");
    
    final data = viewModel.statisticsData;
    return Column(
      children: [
        DailyProgressCard(percentage: data.todayCompletedPercentage),
        WeeklyChartCard(weeklyHeights: viewModel.weeklyBarHeights),
      ],
    );
  },
);
```
**Giải thích Step-by-Step**:
- **Cơ chế lắng nghe**: Sử dụng `Consumer<StatisticsViewmodel>`. Đây là cách tối ưu vì chỉ phần UI bên trong `builder` bị rebuild khi dữ liệu thay đổi.
- **Phản hồi**: Kiểm tra `viewModel.isLoading` để hiển thị spinner. Nếu có lỗi (`errorMessage`), hiển thị thông báo lỗi thay vì màn hình trắng.

## 5. Quyết định Thiết kế (The 'Why')
- **Tại sao dùng RPC thay vì query thô?**: Các phép tính như "Tỷ lệ tăng trưởng so với tuần trước" hay "Đếm task theo ngày" nếu làm ở Client sẽ tốn rất nhiều RAM và Pin. Đưa logic này vào Database (RPC) giúp app mượt mà và dữ liệu luôn nhất quán.

## 6. Bộ câu hỏi Vấn đáp (Q&A) kềm BẰNG CHỨNG TỪ CODE
**Q1: Em xử lý thế nào nếu người dùng chưa hoàn thành task nào trong tuần (Max = 0)?**
- **Trả lời**: Em đã check trường hợp `maxTasks == 0`. Nếu xảy ra, em trả về một danh sách các giá trị nhỏ (0.1) để biểu đồ vẫn hiển thị các cột mờ, tránh lỗi chia cho 0.
- **Bằng chứng**: 
```dart
if (maxTasks == 0) return List.filled(7, 0.1);
```

**Q2: Làm sao để đảm bảo dữ liệu Thống kê luôn là mới nhất khi người dùng chuyển tab?**
- **Trả lời**: Em sử dụng `WidgetsBinding.instance.addPostFrameCallback` trong `initState` của View để tự động trigger hàm fetch dữ liệu mỗi khi màn hình được khởi tạo.
- **Bằng chứng**: 
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<StatisticsViewmodel>().getStatisticsData(userId);
  });
}
```

**Q3: Dữ liệu thời gian trả về từ Server thường là UTC, em làm sao để hiển thị đúng múi giờ Việt Nam?**
- **Trả lời**: Trong Model, em có một hàm `_toVietnamTime` để ép kiểu dữ liệu thời gian sang UTC+7 trước khi đưa vào biểu đồ.
- **Bằng chứng**: 
```dart
static DateTime _toVietnamTime(DateTime value) {
  return value.toUtc().add(const Duration(hours: 7));
}
```
*(Lưu ý: Code thực tế trong StatisticsModel.dart có hàm xử lý này).*
