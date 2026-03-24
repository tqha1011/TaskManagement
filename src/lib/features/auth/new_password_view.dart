import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/auth_layout_template.dart';
import '../../core/theme/custom_text_field.dart';
import '../../viewmodels/auth_viewmodels.dart';

class NewPasswordView extends StatefulWidget {
  const NewPasswordView({super.key});

  @override
  State<NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<NewPasswordView> {
  final _vm = NewPassViewModel();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) => AuthLayoutTemplate(
        title: 'Tạo mật khẩu mới',
        subtitle: 'Mật khẩu mới phải khác với mật khẩu cũ',
        submitText: 'Cập nhật',
        isLoading: _vm.isLoading,
        customHeaderIcon: const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFFEBF2FF),
          child: Icon(Icons.lock_reset, size: 40, color: AppColors.primary),
        ),
        onSubmit: () async {
          FocusScope.of(context).unfocus();
          final success = await _vm.updatePassword();
          if (!context.mounted) return;

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đổi mật khẩu thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
            // Complete Flow: Pop everything and return to Login Screen
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mật khẩu không khớp!'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        formContent: Column(
          children: [
            CustomTextField(
              label: 'Mật khẩu mới',
              hint: '••••••••',
              icon: Icons.lock,
              controller: _vm.passCtrl,
              isPassword: true,
              obscureText: _vm.obscurePass,
              onToggleVisibility: _vm.togglePass,
            ),
            CustomTextField(
              label: 'Xác nhận mật khẩu mới',
              hint: '••••••••',
              icon: Icons.lock,
              controller: _vm.confirmPassCtrl,
              isPassword: true,
              obscureText: _vm.obscurePass,
              onToggleVisibility: _vm.togglePass,
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: AppColors.primary, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mật khẩu tối thiểu 8 ký tự để đảm bảo an toàn.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
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
