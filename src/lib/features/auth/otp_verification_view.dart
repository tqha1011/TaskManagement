import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../viewmodels/auth_viewmodels.dart';
import 'new_password_view.dart';

class OtpVerificationView extends StatefulWidget {
  const OtpVerificationView({super.key});

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  // Bật chế độ 'chờ' cho ViewModel xử lý logic 8 số
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
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _vm,
        builder: (context, child) {
          return SafeArea(
            child: SingleChildScrollView( // Bọc lại đề phòng keyboard hiện lên làm tràn màn hình
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mark_email_read,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Nhập mã 8 số', // Hiển thị đúng 8 số
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mã đã được gửi đến email của bạn.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 40),

                    // --- KHU VỰC 8 Ô OTP (ĐÃ SỬA LỖI) ---
                    // Dùng LayoutBuilder để tự tính toán kích thước ô cho vừa mọi màn hình
                    LayoutBuilder(
                        builder: (context, constraints) {
                          // Tính toán độ rộng của ô dựa trên màn hình thật, trừ đi khoảng cách giữa các ô
                          double availableWidth = constraints.maxWidth;
                          double spaceBetweenBoxes = 6.0; // Khoảng cách giữa các ô
                          double totalSpace = spaceBetweenBoxes * 7; // Có 7 khoảng trống giữa 8 ô
                          double boxWidth = (availableWidth - totalSpace) / 8; // Độ rộng tối đa mỗi ô

                          // Khống chế độ rộng ô không quá to để nhìn cho art (max 35-40)
                          double finalBoxWidth = boxWidth > 38 ? 38 : boxWidth;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center, // Căn giữa hàng 8 ô
                            children: List.generate(
                              8, // SỬA: Đã tạo đúng 8 ô ở đây
                                  (index) => Padding(
                                padding: EdgeInsets.symmetric(horizontal: spaceBetweenBoxes / 2),
                                child: _buildOtpBox(index, context, finalBoxWidth),
                              ),
                            ),
                          );
                        }
                    ),
                    const SizedBox(height: 40),

                    // Nút xác nhận xịn sò (Nhận lỗi cụ thể từ Server)
                    ElevatedButton(
                      onPressed: _vm.isLoading
                          ? null
                          : () async {
                        FocusScope.of(context).unfocus();
                        // Gọi hàm verify(), nó trả về String? errorMessage
                        final errorMessage = await _vm.verify();
                        if (!context.mounted) return;

                        if (errorMessage == null) {
                          // Thành công: Nhảy sang bước 3 (Đổi mật khẩu mới)
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NewPasswordView(),
                            ),
                          );
                        } else {
                          // Thất bại: Hiện thông báo lỗi cụ thể (ví dụ: "Mã OTP hết hạn")
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _vm.isLoading
                          ? const CircularProgressIndicator(
                        color: AppColors.white,
                      )
                          : const Text(
                        'XÁC NHẬN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- NÚT GỬI LẠI MÃ (CHỈ CÓ Ở BẢN XỊN) ---
                    TextButton.icon(
                      onPressed: _vm.isLoading
                          ? null
                          : () async {
                        final errorMessage = await _vm.resend();
                        if (!context.mounted) return;

                        if (errorMessage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã gửi lại mã OTP!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: AppColors.error,
                            ),
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
            ),
          );
        },
      ),
    );
  }

  // SỬA: Nhận thêm 'boxWidth' để tự động co dãn cho vừa 8 ô
  Widget _buildOtpBox(int index, BuildContext context, double boxWidth) {
    return Container(
      width: boxWidth, // Sử dụng độ rộng đã tính toán
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        onChanged: (value) {
          _vm.updateDigit(index, value);
          // SỬA: Logic nhảy focus chuẩn cho 8 ô (index chạy từ 0 đến 7)
          if (value.isNotEmpty && index < 7) {
            FocusScope.of(context).nextFocus();
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }
}