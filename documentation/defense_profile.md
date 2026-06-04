# 👤 Tài liệu Vấn đáp: Luồng Profile (Hồ sơ & Cài đặt)

## 1. Tổng quan & Luồng Dữ Liệu (Data Flow)
- **Tính năng**: Quản lý thông tin cá nhân (tên, avatar), cài đặt giao diện (Light/Dark/System) và cấu hình thông báo.
- **User Flow thực tế**:
    1. Người dùng vào tab Profile, `UserProfileViewModel` tự động load dữ liệu từ `UserService`.
    2. Để đổi avatar: User chọn ảnh -> App nén ảnh -> Upload lên Supabase Storage -> Lấy Public URL -> Cập nhật vào cột `avatar` trong bảng `profile`.
    3. Để đổi theme: User chọn Mode -> Cập nhật Database -> `UserProfileViewModel` thông báo cho `ThemeProvider` để thay đổi toàn bộ UI App.

## 2. Mapping Kiến trúc MVVM (Chỉ đích danh File/Class)
- **Model**: `UserProfileModel` (file: `lib/features/user/model/user_profile_model.dart`). Ánh xạ bảng `profile`.
- **Service/Repository**:
    - `UserService`: Fetch dữ liệu profile.
    - `ProfileUpdateService` (file: `lib/features/user/service/profile_update_service.dart`): Xử lý upload ảnh.
- **ViewModel**: `UserProfileViewModel` (file: `lib/features/user/viewmodel/user_profile_viewmodel.dart`).
    - **Trạng thái**: Quản lý `_user`, `_notificationTime`, `_isLoading`. Cập nhật qua `loadProfile()`.

## 3. Quyết định Thiết kế (The 'Why')
- **Tại sao dùng Supabase Storage cho Avatar?**: Để tránh lưu dữ liệu nhị phân (Binary) trực tiếp vào Database, giúp Database hoạt động hiệu quả hơn. Sử dụng `Public URL` để App có thể cache ảnh bằng `CachedNetworkImage`.
- **Tại sao dùng ThemeProvider phối hợp với ProfileViewModel?**: Theo MVVM, cấu hình giao diện là một phần của User Profile (lưu trên DB). Khi Profile load xong, nó cần "đồng bộ" trạng thái này sang ThemeProvider để UI chuyển đổi đúng mode người dùng đã cài đặt từ trước.
- **Tại sao dùng ImageQuality 80?**: Để nén ảnh trước khi upload, giúp tiết kiệm dung lượng lưu trữ của Server và giảm thời gian chờ đợi của người dùng khi mạng yếu.

## 4. Bộ câu hỏi Vấn đáp (Q&A) kềm BẰNG CHỨNG TỪ CODE
- **Q1: Em xử lý luồng upload ảnh đại diện và lưu vào Database như thế nào để đảm bảo tính nhất quán?**
    - **Trả lời**: Em thực hiện qua 3 bước trong Service: Chọn ảnh bằng `ImagePicker` -> Upload file vào Storage Bucket -> Lấy Public URL và `update` vào bảng `profile` theo `userId`.
    - **Bằng chứng**: File `lib/features/user/service/profile_update_service.dart`
    ```dart
    final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    await _supabase
        .from('profile')
        .update({'avatar': publicUrl})
        .eq('id', userId);
    ```
- **Q2: Làm sao để thay đổi giao diện (Theme) của App ngay lập tức khi người dùng chọn trong Profile?**
    - **Trả lời**: Trong ViewModel, sau khi cập nhật Database thành công, em gọi hàm `updateTheme` của `ThemeProvider` (thông qua Provider) để kích hoạt lệnh `notifyListeners()` trên toàn hệ thống.
    - **Bằng chứng**: File `lib/features/user/viewmodel/user_profile_viewmodel.dart`
    ```dart
    if (context.mounted) {
      context.read<ThemeProvider>().updateTheme(newAppearance);
    }
    ```
- **Q3: Em xử lý thế nào để thông tin Profile được cập nhật ở mọi màn hình sau khi người dùng chỉnh sửa?**
    - **Trả lời**: Em sử dụng mô hình Provider toàn cục. Khi có thay đổi, em gọi `loadProfile()` để lấy dữ liệu mới nhất từ Database và phát tín hiệu `notifyListeners()`.
    - **Bằng chứng**: File `lib/features/user/viewmodel/user_profile_viewmodel.dart`
    ```dart
    Future<void> updateUsername(String newName) async {
      await _supabase.from('profile').update({'username': newName}).eq('id', user.id);
      await loadProfile(); // Tải lại để đồng bộ
    }
    ```
- **Q4: Làm sao để ứng dụng biết được khi nào cần đồng bộ Theme từ Database khi người dùng vừa mở App?**
    - **Trả lời**: Em viết một hàm `syncThemeWithProfile`. Hàm này sẽ kiểm tra nếu giao diện hiện tại khác với giao diện trong Profile vừa load về thì mới thực hiện cập nhật.
    - **Bằng chứng**: File `lib/features/user/viewmodel/user_profile_viewmodel.dart`
    ```dart
    void syncThemeWithProfile(BuildContext context) {
      if (_user == null) return;
      if (_lastAppliedAppearance == _user!.appearance) return;
      _lastAppliedAppearance = _user!.appearance;
      context.read<ThemeProvider>().updateTheme(_user!.appearance);
    }
    ```
