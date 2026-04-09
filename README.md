```markdown
# Bản update từ nhánh `priority_selector_and_tag_system`

**Nâng cấp thêm các tag: Thời gian, Trạng thái và Custom**

- **Thời gian & Trạng thái:** Chỉnh sửa sau khi tạo task tại màn hình `task_detail_screen.dart`.
- **Tag Custom:** - Tối đa 12 ký tự/tag.
  - Tối đa 5 tags/nhiệm vụ.
  - Các tag đã tạo sẽ được lưu nội bộ trên máy để dùng lại cho lần sau mà không cần nhập lại.

**⚠️ Lưu ý cài đặt:**
Để sử dụng tính năng lưu tag custom, **phải thêm** package `shared_preferences`. 

Mở file `pubspec.yaml`, tìm phần `dependencies` và dán dòng này vào ngay dưới `provider: ^6.1.5+1`:
```yaml
shared_preferences: ^2.3.2

<img width="445" height="108" alt="image" src="https://github.com/user-attachments/assets/4763d417-a73d-484d-9ae3-b145045dc624" />
