import 'package:flutter/material.dart';

import '../../../../core/theme/auth_layout_template.dart';
import '../../../../core/theme/custom_text_field.dart';
import '../viewmodels/auth_viewmodels.dart';

class NewPasswordView extends StatefulWidget {
  const NewPasswordView({super.key});
  @override
  State<NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<NewPasswordView> {
  final _vm = NewPassViewModel();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) => AuthLayoutTemplate(
        title: 'Tạo mật khẩu mới',
        subtitle: 'Mật khẩu mới phải khác với mật khẩu cũ',
        submitText: 'Cập nhật',
        isLoading: _vm.isLoading,
        customHeaderIcon: CircleAvatar(
          radius: 40,
          backgroundColor: isDark ? const Color(0xFF213A63) : const Color(0xFFEBF2FF),
          child: Icon(
            Icons.lock_reset,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onSubmit: () async {
          FocusScope.of(context).unfocus();

          // Hứng lỗi (nếu có)
          final errorMessage = await _vm.updatePassword();
          if (!context.mounted) return;

          if (errorMessage == null) {
            // Null -> Thành công -> Báo xanh mướt
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Đổi mật khẩu thành công!'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            );
            // Cú đá chót: Xóa hết lịch sử trang, đá thẳng mặt về trang Login (isFirst)
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            // Nếu lỗi do User nhập lệch pass -> Chửi
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        formContent: Column(
          children: [
            CustomTextField(
              label: 'Mật khẩu mới', hint: '••••••••', icon: Icons.lock, controller: _vm.passCtrl,
              isPassword: true, obscureText: _vm.obscurePass, onToggleVisibility: _vm.togglePass,
            ),
            CustomTextField(
              label: 'Xác nhận mật khẩu mới', hint: '••••••••', icon: Icons.lock, controller: _vm.confirmPassCtrl,
              isPassword: true, obscureText: _vm.obscurePass, onToggleVisibility: _vm.togglePass,
            ),
            // Cục Info hướng dẫn
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF223A63)
                    : const Color(0xFFEBF2FF),
                borderRadius: BorderRadius.circular(12),
                border: isDark
                    ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mật khẩu tối thiểu 6 ký tự để đảm bảo an toàn.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}