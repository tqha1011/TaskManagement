import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/viewmodels/auth_viewmodels.dart';
import '../auth/presentation/view/new_password_view.dart';

class OtpVerificationView extends StatefulWidget {
  const OtpVerificationView({super.key});

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  // Set ViewModel to 'waiting' mode for 8-digit logic processing
  final _vm = OtpViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'OTP Verification',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
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
            child: SingleChildScrollView( // Wrap to prevent keyboard overflow
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mark_email_read,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Enter 8-digit code', // Show correct 8-digit count
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The code has been sent to your email.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- 8 OTP BOXES AREA (FIXED) ---
                    // Use LayoutBuilder to calculate box size to fit any screen
                    LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate box width based on actual screen, subtracting space between boxes
                          double availableWidth = constraints.maxWidth;
                          double spaceBetweenBoxes = 6.0; // Space between boxes
                          double totalSpace = spaceBetweenBoxes * 7; // 7 gaps between 8 boxes
                          double boxWidth = (availableWidth - totalSpace) / 8; // Max width per box

                          // Constrain box width to look artistic (max 35-40)
                          double finalBoxWidth = boxWidth > 38 ? 38 : boxWidth;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center, // Center the row of 8 boxes
                            children: List.generate(
                              8, // FIX: Created 8 boxes here
                                  (index) => Padding(
                                padding: EdgeInsets.symmetric(horizontal: spaceBetweenBoxes / 2),
                                child: _buildOtpBox(index, context, finalBoxWidth),
                              ),
                            ),
                          );
                        }
                    ),
                    const SizedBox(height: 40),

                    // Confirmation button (Handles specific Server errors)
                    ElevatedButton(
                      onPressed: _vm.isLoading
                          ? null
                          : () async {
                        FocusScope.of(context).unfocus();
                        // Call verify(), it returns String? errorMessage
                        final errorMessage = await _vm.verify();
                        if (!context.mounted) return;

                        if (errorMessage == null) {
                          // Success: Navigate to step 3 (Reset new password)
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NewPasswordView(),
                            ),
                          );
                        } else {
                          // Failure: Show specific error message (e.g., "OTP code expired")
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _vm.isLoading
                          ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.surface,
                      )
                          : Text(
                        'CONFIRM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- RESEND CODE BUTTON ---
                    TextButton.icon(
                      onPressed: _vm.isLoading
                          ? null
                          : () async {
                        final errorMessage = await _vm.resend();
                        if (!context.mounted) return;

                        if (errorMessage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('OTP code resent!'),
                              backgroundColor: Theme.of(context).colorScheme.tertiary,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        Icons.refresh,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        'Resend code',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
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

  // FIX: Added 'boxWidth' to automatically scale for 8 boxes
  Widget _buildOtpBox(int index, BuildContext context, double boxWidth) {
    return Container(
      width: boxWidth, // Use calculated width
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: TextField(
        onChanged: (value) {
          _vm.updateDigit(index, value);
          // FIX: Correct focus jump logic for 8 boxes (index from 0 to 7)
          if (value.isNotEmpty && index < 7) {
            FocusScope.of(context).nextFocus();
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
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
