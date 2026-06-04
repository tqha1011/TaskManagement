# 🛡️ Tài liệu Vấn đáp: Luồng Authentication (Xác thực)

## 1. Tổng quan & Luồng Dữ Liệu (Data Flow)
- **Tính năng**: Quản lý đăng nhập, đăng ký, quên mật khẩu và xác thực qua mạng xã hội (Google, Facebook). Đảm bảo tính toàn vẹn dữ liệu thông qua Row Level Security (RLS) của Supabase.
- **User Flow thực tế**:
    1. Người dùng nhập thông tin tại `LoginView` hoặc `RegisterView`.
    2. `LoginViewModel`/`RegisterViewModel` gọi hàm xử lý tương ứng trong `AuthHelper`.
    3. `AuthHelper` giao tiếp với Supabase Auth.
    4. Nếu đăng nhập thành công, `AuthHelper` thực hiện `upsert` thông tin vào bảng `profile` để đồng bộ dữ liệu người dùng (username, timezone).
    5. Token được Supabase tự động quản lý và lưu trữ ở local.

## 2. Mapping Kiến trúc MVVM (Chỉ đích danh File/Class)
- **Model**: `UserModel` (file: `lib/features/auth/models/user_model.dart`). Ánh xạ dữ liệu từ bảng `profile` của Supabase.
- **Service/Repository**: `AuthHelper` (file: `lib/features/auth/services/auth_helper.dart`).
    - **Hàm cốt lõi**:
    ```dart
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    ```
- **ViewModel**: `LoginViewModel`, `RegisterViewModel`, `ForgotPassViewModel` (file: `lib/features/auth/presentation/viewmodels/auth_viewmodels.dart`).
    - **Trạng thái**: Cập nhật qua hàm `setLoading(bool value)` và `notifyListeners()` từ `BaseViewModel`.

## 3. Quyết định Thiết kế (The 'Why')
- **Tại sao dùng BaseViewModel?**: Để tránh lặp code (DRY). Tất cả các luồng Auth đều cần trạng thái `isLoading` và logic `handleError` chung.
- **Tại sao dùng upsert trong AuthHelper?**: Khi đăng nhập, app cần đảm bảo profile của user luôn tồn tại và cập nhật timezone mới nhất mà không cần kiểm tra sự tồn tại trước đó, giúp giảm số lượng request tới database.
- **Xử lý lỗi**: Sử dụng `errorDictionary` trong `BaseViewModel` để map các lỗi tiếng Anh từ Supabase sang thông báo tiếng Việt thân thiện với người dùng.

## 4. Bộ câu hỏi Vấn đáp (Q&A) kềm BẰNG CHỨNG TỪ CODE
- **Q1: Em xử lý validation ở phía Client như thế nào để giảm tải cho Server?**
    - **Trả lời**: Em thực hiện validation ngay trong ViewModel trước khi gọi Service. Sử dụng RegEx để kiểm tra định dạng email và độ mạnh mật khẩu.
    - **Bằng chứng**: File `lib/features/auth/presentation/viewmodels/auth_viewmodels.dart`
    ```dart
    bool isValidEmail(String email) {
      final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+");
      return emailRegex.hasMatch(email);
    }
    ```
- **Q2: Làm sao để bảo mật thông tin khi người dùng thực hiện quên mật khẩu?**
    - **Trả lời**: Em sử dụng luồng xác thực 3 bước của Supabase: Gửi email reset -> Xác thực mã OTP -> Cập nhật mật khẩu mới. Sau khi `verifyOTP` thành công, user được tự động login để thực hiện `updateUser`.
    - **Bằng chứng**: File `lib/features/auth/services/auth_helper.dart`
    ```dart
    Future<bool> verifyOTP(String email, String otpCode) async {
      final response = await supabase.auth.verifyOTP(
        email: email,
        token: otpCode,
        type: OtpType.recovery,
      );
      return response.session != null;
    }
    ```
- **Q3: Em xử lý lỗi mạng hoặc lỗi từ Supabase như thế nào để App không bị crash?**
    - **Trả lời**: Em bọc toàn bộ logic gọi API trong `try-catch` và sử dụng một hàm `handleError` tập trung để phân loại và hiển thị lỗi.
    - **Bằng chứng**: File `lib/features/auth/presentation/viewmodels/auth_viewmodels.dart`
    ```dart
    String handleError(dynamic e) {
      if (e is! AuthException) return 'Sever lỗi, vui lòng thử lại!';
      final msg = e.message.toLowerCase();
      // ... check dictionary ...
      return 'Lỗi xác thực: ${e.message}';
    }
    ```
