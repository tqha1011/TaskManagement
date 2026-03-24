import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/auth_layout_template.dart';
import '../../core/theme/custom_text_field.dart';
import '../../viewmodels/auth_viewmodels.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _vm = RegisterViewModel();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) => AuthLayoutTemplate(
        title: 'Tạo tài khoản mới',
        subtitle: 'Bắt đầu quản lý công việc khoa học',
        submitText: 'Đăng ký',
        isLoading: _vm.isLoading,
        showSocial: true,
        onSubmit: () async {
          FocusScope.of(context).unfocus();
          final success = await _vm.register();
          if (!context.mounted) return;

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đăng ký thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context); // Go back to login
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mật khẩu không khớp hoặc thiếu thông tin!'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        formContent: Column(
          children: [
            CustomTextField(
              label: 'Họ tên',
              hint: 'Nhập họ và tên',
              icon: Icons.person,
              controller: _vm.nameCtrl,
            ),
            CustomTextField(
              label: 'Email',
              hint: 'example@gmail.com',
              icon: Icons.mail,
              controller: _vm.emailCtrl,
            ),
            CustomTextField(
              label: 'Mật khẩu',
              hint: '••••••••',
              icon: Icons.lock,
              controller: _vm.passCtrl,
              isPassword: true,
              obscureText: _vm.obscurePass,
              onToggleVisibility: _vm.togglePass,
            ),
            CustomTextField(
              label: 'Xác nhận mật khẩu',
              hint: '••••••••',
              icon: Icons.shield,
              controller: _vm.confirmPassCtrl,
              isPassword: true,
              obscureText: _vm.obscurePass,
              onToggleVisibility: _vm.togglePass,
            ),
          ],
        ),
        footerContent: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Đã có tài khoản? ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Đăng nhập',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
