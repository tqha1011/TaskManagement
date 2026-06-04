# 🛡️ Tài liệu Vấn đáp: Luồng Authentication (Xác thực)

## 1. Tổng quan & Luồng Dữ Liệu (Data Flow)
**Tính năng**: Quản lý vòng đời xác thực của người dùng bao gồm Đăng nhập, Đăng ký, Quên mật khẩu và xác thực bên thứ ba (Google/Facebook). 
**User Flow**:
1. Người dùng nhập liệu vào `LoginView` / `RegisterView`.
2. `LoginViewModel` thực hiện Validation phía Client (Regex, empty check).
3. Nếu hợp lệ, ViewModel gọi `AuthHelper` (Service) để giao tiếp với Supabase Auth.
4. `AuthHelper` thực hiện xác thực, nếu thành công sẽ `upsert` dữ liệu vào bảng `profile` để đồng bộ.
5. `LoginView` lắng nghe trạng thái từ ViewModel, hiển thị Loading hoặc SnackBar thông báo kết quả.

## 2. Phân tích Chuyên sâu Tầng Service (Xử lý Dữ liệu)
**Hàm cốt lõi**: `login` trong `AuthHelper` (file: `lib/features/auth/services/auth_helper.dart`).

```dart
Future<UserModel?> login(String email, String password) async {
  try {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      final userId = user.id;
      final userMetadata = user.userMetadata ?? {};
      final String? username = userMetadata['username']?.toString();
      final timezoneObj = await FlutterTimezone.getLocalTimezone();
      final String currentTimezone = timezoneObj.toString();

      final profileData = await supabase
          .from('profile')
          .upsert({
            'id': userId,
            if (username != null && username.isNotEmpty) 'username': username,
            'timezone': currentTimezone,
          })
          .select()
          .single();

      return UserModel.fromJson(profileData, email);
    }
    return null;
  } on AuthException catch (e) {
    print('Supabase Auth Error: ${e.message}');
    rethrow;
  } catch (e) {
    print('Unknown Error: $e');
    rethrow;
  }
}
```
**Giải thích Step-by-Step**:
- **Input**: Nhận `email` và `password` thô từ ViewModel.
- **API Call**: Sử dụng `supabase.auth.signInWithPassword` để xác thực. Nếu thành công, tiếp tục lấy `timezone` hệ thống bằng `FlutterTimezone`.
- **Database logic**: Sử dụng lệnh `upsert` vào bảng `profile`. Điều này đảm bảo bản ghi profile luôn tồn tại và cập nhật múi giờ mới nhất mà không cần kiểm tra `exists` trước.
- **Bắt lỗi**: Sử dụng khối `on AuthException` để bắt riêng lỗi từ Supabase và `catch (e)` cho các lỗi ngoại vi (như lỗi mạng). Cả hai đều dùng `rethrow` để đẩy lỗi về ViewModel xử lý UI.
- **Output**: Trả về đối tượng `UserModel` đã được map dữ liệu.

## 3. Phân tích Chuyên sâu Tầng ViewModel (Quản lý Trạng thái)
**Hàm cốt lõi**: `login` trong `LoginViewModel` (file: `lib/features/auth/presentation/viewmodels/auth_viewmodels.dart`).

```dart
Future<String?> login() async {
  final email = emailCtrl.text.trim();
  final pass = passCtrl.text;

  if (email.isEmpty || pass.isEmpty) {
    return 'Vui lòng nhập đầy đủ email và mật khẩu!';
  }
  if (!isValidEmail(email)) {
    return 'Định dạng email không hợp lệ!';
  }

  setLoading(true);
  try {
    final user = await _authHelper.login(email, pass);
    if (user != null) return null; // Success
    return 'Không thể lấy thông tin người dùng!';
  } catch (e) {
    return handleError(e); // Backend errors
  } finally {
    setLoading(false);
  }
}
```
**Giải thích Step-by-Step**:
- **Trạng thái nắm giữ**: Kế thừa `_isLoading` từ `BaseViewModel`.
- **Validation**: Thực hiện check `isEmpty` và `isValidEmail` (Regex) ngay tại FE để giảm tải cho Server.
- **Update State**: Gọi `setLoading(true)` -> kích hoạt `notifyListeners()` bên trong hàm này (thuộc `BaseViewModel`).
- **Xử lý kết quả**: Nếu thành công trả về `null`. Nếu lỗi, gọi `handleError(e)` để dịch các mã lỗi Tiếng Anh của Supabase sang Tiếng Việt thân thiện.
- **notifyListeners()**: Được gọi gián tiếp qua `setLoading(false)` trong khối `finally`.

## 4. Phân tích Chuyên sâu Tầng View (Giao diện)
**Đoạn code UI**: `LoginView` (file: `lib/features/auth/presentation/view/login_view.dart`).

```dart
return AnimatedBuilder(
  animation: _vm,
  builder: (context, _) => AuthLayoutTemplate(
    isLoading: _vm.isLoading,
    onSubmit: () async {
      FocusScope.of(context).unfocus();
      final errorMessage = await _vm.login();
      if (!context.mounted) return;

      if (errorMessage == null) {
        // ... Success SnackBar & Navigate ...
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    },
    // ... formContent ...
  ),
);
```
**Giải thích Step-by-Step**:
- **Cơ chế lắng nghe**: Sử dụng `AnimatedBuilder` với `animation: _vm`. Mỗi khi ViewModel gọi `notifyListeners()`, UI sẽ rebuild.
- **Phản hồi sự kiện**: Khi bấm `onSubmit`, gọi `_vm.login()`. Nếu có `errorMessage`, hiển thị `SnackBar` với màu `error`.
- **Loading State**: Biến `_vm.isLoading` được truyền vào `AuthLayoutTemplate` để hiển thị indicator thay thế cho nút bấm, ngăn chặn người dùng spam request.

## 5. Quyết định Thiết kế (The 'Why')
- **Tại sao chia 3 tầng?**: Việc tách biệt logic Validation và Error Translation vào `BaseViewModel` giúp các ViewModel con (`Register`, `ForgotPass`) tái sử dụng code (`DRY`). View chỉ tập trung vào việc hiển thị, không cần biết logic RegEx hay cách Supabase trả về lỗi như thế nào.

## 6. Bộ câu hỏi Vấn đáp (Q&A) kềm BẰNG CHỨNG TỪ CODE
**Q1: Em xử lý thế nào để tránh việc người dùng bấm đăng nhập nhiều lần liên tiếp gây nghẽn hệ thống?**
- **Trả lời**: Em sử dụng biến trạng thái `isLoading` trong ViewModel. Khi bắt đầu quá trình, em set `isLoading = true`, và ở tầng View, em dựa vào biến này để vô hiệu hóa UI hoặc hiển thị loading indicator.
- **Bằng chứng**: 
```dart
// viewmodels/auth_viewmodels.dart
void setLoading(bool value) {
  _isLoading = value;
  notifyListeners();
}
// view/login_view.dart
isLoading: _vm.isLoading,
```

**Q2: Nếu Supabase trả về lỗi bằng Tiếng Anh (ví dụ: 'invalid login credentials'), em làm sao để người dùng Việt Nam hiểu được?**
- **Trả lời**: Em xây dựng một hàm `handleError` tập trung tại `BaseViewModel` đóng vai trò là một "Từ điển lỗi". Hàm này sẽ parse chuỗi lỗi trả về và map sang thông báo Tiếng Việt tương ứng.
- **Bằng chứng**: 
```dart
// viewmodels/auth_viewmodels.dart
final errorDictionary = {
  'invalid login credentials': 'Email hoặc mật khẩu không chính xác!',
  'rate limit': 'Bạn thao tác quá nhanh, vui lòng thử lại sau!',
};
```

**Q3: Làm sao em đảm bảo tính bảo mật khi cập nhật mật khẩu mới?**
- **Trả lời**: Em không tự xử lý logic Hash mật khẩu. Em sử dụng luồng an toàn của Supabase Auth. Sau khi xác thực OTP thành công, user được cấp session tạm thời, em gọi hàm `updateUser` của Supabase để hệ thống tự động cập nhật mật khẩu vào bảng quản lý riêng của họ.
- **Bằng chứng**: 
```dart
// services/auth_helper.dart
await supabase.auth.updateUser(UserAttributes(password: newPassword));
```
