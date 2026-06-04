# 📊 Tài liệu Vấn đáp: Luồng Statistics (Thống kê)

## 1. Tổng quan & Luồng Dữ Liệu (Data Flow)
- **Tính năng**: Cung cấp báo cáo trực quan về hiệu suất làm việc qua biểu đồ và các chỉ số (tổng số task, tỷ lệ hoàn thành, tăng trưởng).
- **User Flow thực tế**:
    1. Khi người dùng vào màn hình thống kê, `StatisticsViewmodel` gọi Service để lấy dữ liệu.
    2. `StatisticsService` thực thi một hàm RPC (`get_user_statistics`) trên Supabase.
    3. Database tính toán các chỉ số (đếm task theo ngày, so sánh tuần này/tuần trước) và trả về một Object JSON duy nhất.
    4. ViewModel xử lý dữ liệu JSON này và chuẩn hóa thành các giá trị phù hợp cho biểu đồ (Bar Chart).

## 2. Mapping Kiến trúc MVVM (Chỉ đích danh File/Class)
- **Model**: `UserStatisticsModel`, `TodayStatsModel`, `RecentTaskModel` (file: `lib/features/statistics/model/StatisticsModel.dart`).
- **Service/Repository**: `StatisticsService` (file: `lib/features/statistics/services/statistics_service.dart`).
    - **Hàm cốt lõi**:
    ```dart
    final response = await supabaseClient.rpc('get_user_statistics', params: {'p_profile_id' : userId});
    ```
- **ViewModel**: `StatisticsViewmodel` (file: `lib/features/statistics/viewmodel/statistics_viewmodel.dart`).
    - **Trạng thái**: Quản lý `statisticsData` và cung cấp các getters như `weeklyBarHeights` để UI vẽ biểu đồ.

## 3. Quyết định Thiết kế (The 'Why')
- **Tại sao dùng RPC (Stored Procedure) thay vì query trực tiếp?**: Vì các chỉ số thống kê (như phần trăm tăng trưởng, đếm task theo từng ngày trong tuần) yêu cầu logic tính toán phức tạp. Thực hiện việc này trên Database (Server-side) giúp App chạy mượt hơn, giảm băng thông truyền tải và tận dụng tối đa sức mạnh của PostgreSQL.
- **Tại sao xử lý Bar Heights trong ViewModel?**: Thư viện biểu đồ yêu cầu các giá trị từ 0.0 đến 1.0 (hoặc tỉ lệ tương đối). ViewModel đóng vai trò "Normalizer" để tính toán tỷ lệ độ cao của các cột dựa trên số lượng Task lớn nhất trong tuần.

## 4. Bộ câu hỏi Vấn đáp (Q&A) kềm BẰNG CHỨNG TỪ CODE
- **Q1: Em làm thế nào để tối ưu hiệu suất khi tính toán thống kê cho hàng ngàn Task?**
    - **Trả lời**: Em không lấy toàn bộ danh sách Task về máy. Em sử dụng câu lệnh `rpc` để gọi một hàm trên Database. Database chỉ trả về các con số đã được tổng hợp (Aggregated data), giúp tốc độ phản hồi cực nhanh.
    - **Bằng chứng**: File `lib/features/statistics/services/statistics_service.dart`
    ```dart
    Future<UserStatisticsModel> getUserStatistics(String userId) async {
      final response = await supabaseClient.rpc('get_user_statistics', params: {'p_profile_id' : userId});
      return UserStatisticsModel.fromJson(response);
    }
    ```
- **Q2: Em xử lý dữ liệu như thế nào để hiển thị lên biểu đồ cột (Bar Chart) một cách cân đối?**
    - **Trả lời**: Em tìm giá trị lớn nhất trong danh sách các ngày (`maxTasks`). Sau đó, em chia số lượng của từng ngày cho giá trị max đó để lấy ra tỷ lệ phần trăm độ cao (từ 0 đến 1).
    - **Bằng chứng**: File `lib/features/statistics/viewmodel/statistics_viewmodel.dart`
    ```dart
    List<double> get weeklyBarHeights {
      if (statisticsData == null) return List.filled(7, 0.1);
      List<int> rawCounts = statisticsData!.dailyCounts;
      int maxTasks = rawCounts.reduce((curr, next) => curr > next ? curr : next);
      if (maxTasks == 0) return List.filled(7, 0.1);
      return rawCounts.map((count) => count / maxTasks).toList();
    }
    ```
- **Q3: Làm sao để đảm bảo thời gian trong thống kê luôn chính xác theo múi giờ Việt Nam?**
    - **Trả lời**: Trong Model, em có một hàm `_toVietnamTime` để ép kiểu dữ liệu từ UTC sang UTC+7 trước khi hiển thị lên UI.
    - **Bằng chứng**: File `lib/features/statistics/model/StatisticsModel.dart`
    ```dart
    static DateTime _toVietnamTime(DateTime value) {
      final utcValue = value.isUtc ? value : value.toUtc();
      return utcValue.add(const Duration(hours: 7));
    }
    ```
- **Q4: Em xử lý lỗi như thế nào khi Server không trả về dữ liệu thống kê?**
    - **Trả lời**: Em sử dụng `try-catch` trong ViewModel và lưu thông báo lỗi vào biến `_errorMessage`. Ngoài ra, em cung cấp dữ liệu mặc định (`List.filled(7, 0.1)`) để UI không bị trống hoặc lỗi render.
    - **Bằng chứng**: File `lib/features/statistics/viewmodel/statistics_viewmodel.dart`
    ```dart
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error fetching statistics: $e");
    ```dart
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    ```

## 5. Phân tích chuyên sâu (Deep-dive) Hàm Cốt Lõi

### Getter `weeklyBarHeights` trong `StatisticsViewmodel`
Đây là hàm xử lý logic chuyển đổi từ dữ liệu thô (Raw Data) sang dữ liệu hiển thị (UI Data), đóng vai trò then chốt cho tính trực quan của biểu đồ.

**Trích xuất Code thực tế:**
```dart
List<double> get weeklyBarHeights {
  // 1. Kiểm tra dữ liệu tồn tại
  if (statisticsData == null) return List.filled(7, 0.1);

  List<int> rawCounts = statisticsData!.dailyCounts;

  // 2. Tìm giá trị lớn nhất để làm mốc tỷ lệ
  int maxTasks = rawCounts.reduce((curr, next) => curr > next ? curr : next);
  
  // 3. Xử lý trường hợp chưa có task nào
  if (maxTasks == 0) return List.filled(7, 0.1);

  // 4. Chuẩn hóa về dải [0.0, 1.0]
  return rawCounts.map((count) => count / maxTasks).toList();
}
```

**Giải thích Step-by-Step:**

1.  **Logic nghiệp vụ**: Biểu đồ cột không thể hiển thị số lượng tuyệt đối (ví dụ 100 task) vì sẽ vượt quá chiều cao màn hình. Hàm này thực hiện "Normalization" (Chuẩn hóa). Nó lấy số lượng task của ngày cao nhất làm 100% chiều cao cột, các ngày khác sẽ tính theo tỷ lệ tương ứng.
2.  **Input/Output**:
    - **Input**: `statisticsData!.dailyCounts` (List<int>) lấy từ Model đã fetch từ API.
    - **Output**: `List<double>` gồm 7 phần tử có giá trị từ 0.0 đến 1.0.
3.  **Bắt lỗi (Safety Check)**: 
    - Dòng `if (statisticsData == null)`: Tránh lỗi `null pointer` khi dữ liệu chưa load xong.
    - Dòng `if (maxTasks == 0)`: Tránh lỗi `Division by zero` (Chia cho 0) cực kỳ nguy hiểm trong toán học lập trình. Trả về `0.1` để biểu đồ vẫn hiện các cột mờ nhỏ thay vì biến mất hoàn toàn.
4.  **Trigger cập nhật UI**: Vì đây là một `getter` trong ViewModel, khi `statisticsData` thay đổi (sau hàm `fetchStatistics`), UI đang lắng nghe (Consumer/watch) sẽ truy cập getter này và tự động vẽ lại các cột biểu đồ với độ cao mới.
     Riverside.
