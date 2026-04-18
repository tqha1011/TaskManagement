import 'package:flutter/material.dart';
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
        compactMode: true,
        isLoading: _vm.isLoading,
        showSocial: true,
        onGoogleTap: () async {
          final error = await _vm.loginWithGoogle();
          if (error != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        onFacebookTap: () async {
          final error = await _vm.loginWithFacebook();
          if (error != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        onSubmit: () async {
          FocusScope.of(context).unfocus();
          final errorMessage = await _vm.login();
          if (!context.mounted) return;

          if (errorMessage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Đăng nhập thành công!'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            );
            // If LoginView was pushed on top of AuthGate, pop back to root so MainScreen is visible.
            Navigator.of(context).popUntil((route) => route.isFirst);
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CustomTextField(label: 'Email', hint: 'example@gmail.com', icon: Icons.mail, controller: _vm.emailCtrl),
            CustomTextField(
              label: 'Mật khẩu', hint: '••••••••', icon: Icons.lock, controller: _vm.passCtrl,
              isPassword: true, obscureText: _vm.obscurePass, onToggleVisibility: _vm.togglePass,
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordView())),
              style: TextButton.styleFrom(minimumSize: const Size(50, 40), padding: const EdgeInsets.symmetric(horizontal: 4)),
              child: Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        footerContent: _buildFooter(
          context,
          'Chưa có tài khoản? ',
          'Đăng ký ngay',
          () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterView()));
          },
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    String text,
    String action,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(minimumSize: const Size(50, 40)),
            child: Text(
              action,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}