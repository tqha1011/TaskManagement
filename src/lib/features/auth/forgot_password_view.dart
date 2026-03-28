import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/auth_layout_template.dart';
import '../../core/theme/custom_text_field.dart';
import '../../viewmodels/auth_viewmodels.dart';
import 'otp_verification_view.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _vm = ForgotPassViewModel();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) => AuthLayoutTemplate(
        title: 'Quên mật khẩu?',
        subtitle: 'Nhập email của bạn để nhận mã xác thực',
        submitText: 'Gửi mã',
        useCard: false,
        isLoading: _vm.isLoading,
        customHeaderIcon: Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0xFFD1D9E6), blurRadius: 16)],
          ),
          child: const Icon(
            Icons.lock_reset,
            size: 64,
            color: AppColors.primary,
          ),
        ),
        onSubmit: () async {
          FocusScope.of(context).unfocus();
          final success = await _vm.sendCode();
          if (!context.mounted) return;

          if (success) {
            // Jump to Step 2: OTP
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OtpVerificationView()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vui lòng nhập email hợp lệ!'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        formContent: CustomTextField(
          label: 'Địa chỉ Email',
          hint: 'example@gmail.com',
          icon: Icons.mail,
          controller: _vm.emailCtrl,
        ),
        footerContent: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help, size: 16, color: AppColors.primary),
            SizedBox(width: 4),
            Text(
              'Cần hỗ trợ? Liên hệ CSKH',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
