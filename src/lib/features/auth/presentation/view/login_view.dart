import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/auth_layout_template.dart';
import '../../../../core/theme/custom_text_field.dart';
import '../viewmodels/auth_viewmodels.dart';
import 'register_view.dart';
import 'forgot_password_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _vm = LoginViewModel();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) => AuthLayoutTemplate(
        title: 'Task Management',
        subtitle: 'Chào mừng trở lại!',
        submitText: 'Đăng nhập',
        isLoading: _vm.isLoading,
        showSocial: true,
        onGoogleTap: () async {
          final error = await _vm.loginWithGoogle();
          if (error != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
          }
        },
        onFacebookTap: () async {
          final error = await _vm.loginWithFacebook();
          if (error != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
          }
        },
        onSubmit: () async {
          FocusScope.of(context).unfocus();
          final errorMessage = await _vm.login();
          if (!context.mounted) return;

          if (errorMessage == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập thành công!'), backgroundColor: AppColors.success));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error));
          }
        },
        formContent: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CustomTextField(label: 'Email', hint: 'example@gmail.com', icon: Icons.mail, controller: _vm.emailCtrl),
            CustomTextField(
              label: 'Mật khẩu', hint: '••••••••', icon: Icons.lock, controller: _vm.passCtrl,
              isPassword: true, obscureText: _vm.obscurePass, onToggleVisibility: _vm.togglePass,
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordView())),
              child: const Text('Quên mật khẩu?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        footerContent: _buildFooter('Chưa có tài khoản? ', 'Đăng ký ngay', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterView()));
        }),
      ),
    );
  }

  Widget _buildFooter(String text, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(minimumSize: const Size(50, 48)),
            child: Text(action, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}