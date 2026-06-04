# 👤 Tài liệu Vấn đáp: Luồng Profile (Hồ sơ & Cài đặt)

## 1. Tổng quan & Luồng Dữ Liệu (Data Flow)
**Tính năng**: Quản lý thông tin cá nhân, cài đặt giao diện và cấu hình thông báo.
**User Flow**:
1. Người dùng vào tab Profile, `UserProfileViewModel` tự động load dữ liệu.
2. Để đổi avatar: Chọn ảnh -> App nén ảnh -> Upload lên Supabase Storage -> Lấy Public URL -> Cập nhật Database.
3. Để đổi theme: Chọn Mode -> Cập nhật Database -> ViewModel thông báo cho `ThemeProvider` thay đổi UI toàn app.
4. Mọi thay đổi trạng thái được phát thông qua `notifyListeners()` để các Widget liên quan (như Avatar ở Header) tự động cập nhật.

## 2. Phân tích Chuyên sâu Tầng Service (Xử lý Dữ liệu)
**Hàm cốt lõi**: `uploadAndSaveAvatar` (file: `lib/features/user/service/profile_update_service.dart`).

```dart
Future<String?> uploadAndSaveAvatar() async {
  try {
    // 1. Chọn ảnh và nén
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return null;

    final File file = File(pickedFile.path);
    final userId = _supabase.auth.currentUser!.id;

    // 2. Upload Storage
    final String path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage.from('avatars').upload(path, file);

    // 3. Lấy URL và cập nhật Profile
    final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    await _supabase.from('profile').update({'avatar': publicUrl}).eq('id', userId);

    return publicUrl;
  } catch (e) {
    print('Error in uploadAndSaveAvatar: $e');
    return null;
  }
}
```
**Giải thích Step-by-Step**:
- **Xử lý ảnh**: Sử dụng `ImagePicker` với `imageQuality: 80` để nén ảnh trực tiếp tại Client, giúp tiết kiệm băng thông và dung lượng Storage.
- **Storage**: Tải file lên Bucket `avatars`. Tên file được gắn timestamp để tránh trùng lặp và lỗi cache trên trình duyệt/app.
- **Đồng bộ DB**: Sau khi có `publicUrl`, thực hiện lệnh `update` bảng `profile`. Đây là bước then chốt để liên kết file vật lý với định danh người dùng.
- **Bắt lỗi**: Toàn bộ luồng bọc trong `try-catch`. Nếu người dùng hủy chọn ảnh hoặc lỗi mạng khi upload, hàm trả về `null` để ViewModel xử lý thông báo.

## 3. Phân tích Chuyên sâu Tầng ViewModel (Quản lý Trạng thái)
**Hàm cốt lõi**: `updateAvatar` và `loadProfile` (file: `lib/features/user/viewmodel/user_profile_viewmodel.dart`).

```dart
Future<void> updateAvatar(BuildContext context) async {
  final newUrl = await _profileUpdateService.uploadAndSaveAvatar();
  if (newUrl != null) {
    await loadProfile(); // Tải lại toàn bộ thông tin để đồng bộ
    if (context.mounted) {
      _showModernSnackBar(context, 'Cập nhật thành công!', Icons.check_circle, Colors.green);
    }
  } else {
    // ... Show Error SnackBar ...
  }
}
```
**Giải thích Step-by-Step**:
- **Trạng thái**: Quản lý đối tượng `_user` (kiểu `UserProfileModel`).
- **Phối hợp Service**: Gọi Service xử lý upload. Nếu thành công (`newUrl != null`), tiếp tục gọi `loadProfile()` để lấy dữ liệu mới nhất từ DB, đảm bảo tính nhất quán.
- **notifyListeners()**: Được gọi bên trong hàm `loadProfile` (ở khối `finally`), kích hoạt việc vẽ lại avatar ở tất cả các màn hình đang lắng nghe.

## 4. Phân tích Chuyên sâu Tầng View (Giao diện)
**Đoạn code UI**: `UserProfileView` (file: `lib/features/user/view/user_profile_view.dart`).

```dart
return Consumer<UserProfileViewModel>(
  builder: (context, vm, child) {
    if (vm.isLoading) return CircularProgressIndicator();
    final user = vm.user!;
    return Column(
      children: [
        ProfileHeader(user: user), // Hiển thị Avatar & Name
        SettingsListTile(
          title: 'Appearance',
          trailing: Text(user.appearance),
          onTap: () => vm.updateAppearance(context, user.appearance == 'Dark' ? 'Light' : 'Dark'),
        ),
      ],
    );
  },
);
```
**Giải thích Step-by-Step**:
- **Cơ chế lắng nghe**: Sử dụng `Consumer<UserProfileViewModel>`. Khi người dùng đổi theme hoặc avatar, `vm.notifyListeners()` phát tín hiệu, `Consumer` bắt được và thực thi lại hàm `builder` để cập nhật UI.
- **Phản hồi**: Khi người dùng nhấn vào một mục (như đổi tên hoặc theme), View gọi trực tiếp hàm tương ứng trong ViewModel (`vm.updateAppearance`). Trạng thái loading được xử lý tập trung giúp trải nghiệm mượt mà.

## 5. Quyết định Thiết kế (The 'Why')
- **Tại sao dùng ThemeProvider phối hợp với ProfileViewModel?**: Theo MVVM, cấu hình giao diện là dữ liệu của User. Khi Profile load xong, nó cần đồng bộ trạng thái này sang `ThemeProvider` (đóng vai trò quản lý UI Style toàn app). Việc tách biệt giúp logic xử lý dữ liệu (DB) và logic hiển thị (ThemeData) không bị trộn lẫn.

## 6. Bộ câu hỏi Vấn đáp (Q&A) kềm BẰNG CHỨNG TỪ CODE
**Q1: Em làm thế nào để đảm bảo ảnh đại diện mới được hiển thị ngay lập tức sau khi upload?**
- **Trả lời**: Sau khi Service upload thành công và trả về URL, em gọi lại hàm `loadProfile()`. Hàm này sẽ fetch lại bản ghi mới nhất từ bảng `profile` và gọi `notifyListeners()`, khiến Widget `UserAvatar` tự động load ảnh từ URL mới.
- **Bằng chứng**: 
```dart
if (newUrl != null) {
  await loadProfile();
}
```

**Q2: Nếu người dùng đổi giao diện sang Dark Mode, làm sao để app nhớ được cài đặt này trong lần đăng nhập sau?**
- **Trả lời**: Em lưu thuộc tính `appearance` trực tiếp vào bảng `profile` của Supabase. Mỗi khi mở app, trong bước khởi tạo, em fetch profile này về và gọi hàm `syncThemeWithProfile` để áp dụng giao diện đúng như người dùng đã lưu.
- **Bằng chứng**: 
```dart
await _supabase.from('profile').update({'appearance': newAppearance}).eq('id', user.id);
```

**Q3: Em xử lý thế nào để tránh lỗi "Memory Leak" khi ViewModel bị hủy?**
- **Trả lời**: Em không thực hiện các tác vụ lắng nghe stream dài hạn mà không có quản lý. Đối với các Controller như `TextEditingController` dùng trong các modal của Profile, em luôn đảm bảo gọi `dispose()` hoặc xử lý cục bộ trong Widget.
- **Bằng chứng**: Trong code hiện tại, các modal đổi tên được xử lý bằng controller cục bộ và tự giải phóng khi đóng modal.
