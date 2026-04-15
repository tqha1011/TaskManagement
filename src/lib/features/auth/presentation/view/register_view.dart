import 'package:flutter/material.dart';
import 'package:task_management_app/features/auth/presentation/view/login_view.dart';
import '../../../../core/theme/auth_layout_template.dart';
import '../../../../core/theme/custom_text_field.dart';
import '../viewmodels/auth_viewmodels.dart';

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
        compactMode: true,
        isLoading: _vm.isLoading,
        showSocial: true,
        onSubmit: () async {
          FocusScope.of(context).unfocus();
          final errorMessage = await _vm.register();
          if (!context.mounted) return;

          if (errorMessage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Đăng ký thành công!'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            );
            // Return to the existing LoginView to avoid stacking duplicate login routes.
            Navigator.pop(context);
          } else {
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
            CustomTextField(label: 'Họ tên', hint: 'Nhập họ và tên', icon: Icons.person, controller: _vm.usernameCtrl),
            CustomTextField(label: 'Email', hint: 'example@gmail.com', icon: Icons.mail, controller: _vm.emailCtrl),
            CustomTextField(
              label: 'Mật khẩu', hint: '••••••••', icon: Icons.lock, controller: _vm.passCtrl,
              isPassword: true, obscureText: _vm.obscurePass, onToggleVisibility: _vm.togglePass,
            ),
            CustomTextField(
              label: 'Xác nhận mật khẩu', hint: '••••••••', icon: Icons.shield, controller: _vm.confirmPassCtrl,
              isPassword: true, obscureText: _vm.obscurePass, onToggleVisibility: _vm.togglePass,
            ),
          ],
        ),
        footerContent: Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Đã có tài khoản? ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(minimumSize: const Size(50, 40)),
                child: Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
