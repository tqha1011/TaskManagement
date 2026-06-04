import 'package:flutter/material.dart';
import '../../../../core/theme/auth_layout_template.dart';
import '../../../../core/theme/custom_text_field.dart';
import '../viewmodels/auth_viewmodels.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) => AuthLayoutTemplate(
        title: 'Quên mật khẩu?',
        subtitle: 'Nhập email của bạn để nhận mã xác thực',
        submitText: 'Gửi mã',
        useCard: false,
        isLoading: _vm.isLoading,
        customHeaderIcon: Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: isDark
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 24,
              )
            ],
          ),
          child: Icon(
            Icons.lock_reset,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onSubmit: () async {
          FocusScope.of(context).unfocus(); // Đóng bàn phím

          // Lấy câu chửi từ ViewModel (nếu có lỗi)
          final errorMessage = await _vm.sendCode();
          if (!context.mounted) return;

          if (errorMessage == null) {
            // Thành công (null) -> Bay qua màn hình điền OTP 6 số
            Navigator.push(context, MaterialPageRoute(builder: (_) => const OtpVerificationView()));
          } else {
            // Có lỗi (như nhập sai định dạng, spam nút) -> Vã cái lỗi màu đỏ ra
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Theme.of(context).colorScheme.error,
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
        footerContent: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.help,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cần hỗ trợ? Liên hệ CSKH',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}