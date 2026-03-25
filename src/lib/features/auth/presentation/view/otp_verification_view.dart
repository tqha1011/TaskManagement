import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/auth_viewmodels.dart';
import 'new_password_view.dart';

class OtpVerificationView extends StatefulWidget {
  const OtpVerificationView({super.key});
  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final _vm = OtpViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xác thực OTP',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
          animation: _vm,
          builder: (context, child) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mark_email_read, size: 80, color: AppColors.primary),
                    const SizedBox(height: 32),
                    const Text(
                      'Nhập mã 8 số', // Sửa chữ thành 8 số
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mã đã được gửi đến email của bạn.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 40),

                    // Tạo ra 8 ô OTP thay vì 6
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) => _buildOtpBox(index, context)),
                    ),
                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: _vm.isLoading ? null : () async {
                        FocusScope.of(context).unfocus();

                        final errorMessage = await _vm.verify();
                        if (!context.mounted) return;

                        if (errorMessage == null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const NewPasswordView()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _vm.isLoading
                          ? const CircularProgressIndicator(color: AppColors.white)
                          : const Text(
                        'XÁC NHẬN',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton.icon(
                      onPressed: _vm.isLoading ? null : () async {
                        final errorMessage = await _vm.resend();
                        if (!context.mounted) return;

                        if (errorMessage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã gửi lại mã OTP!'), backgroundColor: AppColors.success),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                      label: const Text(
                        'Gửi lại mã',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildOtpBox(int index, BuildContext context) {
    return Container(
      width: 35, height: 48, // Thu nhỏ kích thước ô lại để nhét vừa 8 ô trên 1 dòng
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        onChanged: (value) {
          _vm.updateDigit(index, value);

          // Sửa lại logic nhảy focus: bé hơn 7 thì nhảy tới, lớn hơn 0 thì nhảy lùi
          if (value.isNotEmpty && index < 7) FocusScope.of(context).nextFocus();
          if (value.isEmpty && index > 0) FocusScope.of(context).previousFocus();
        },
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
      ),
    );
  }
}