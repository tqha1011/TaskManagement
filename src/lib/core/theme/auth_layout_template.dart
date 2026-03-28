import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The master layout template for all authentication screens.
/// Handles the UI skeleton, loading states, backgrounds, and responsive scrolling.
class AuthLayoutTemplate extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget formContent;
  final String submitText;
  final VoidCallback onSubmit;
  final bool isLoading;
  final bool showSocial;
  final bool useCard;
  final Widget? customHeaderIcon;
  final Widget? footerContent;
  final VoidCallback? onGoogleTap; // Login with Google
  final VoidCallback? onFacebookTap; // Login with Facebook

  const AuthLayoutTemplate({
    super.key,
    required this.title,
    required this.subtitle,
    required this.formContent,
    required this.submitText,
    required this.onSubmit,
    this.isLoading = false,
    this.showSocial = false,
    this.useCard = true,
    this.customHeaderIcon,
    this.footerContent,
    this.onGoogleTap,
    this.onFacebookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                useCard ? _buildCardContainer() : _buildTransparentContainer(),
                const SizedBox(height: 32),
                if (footerContent != null) footerContent!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        customHeaderIcon ??
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.task_alt, size: 48, color: AppColors.primary),
              ),
            ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCardContainer() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _buildFormElements(),
    );
  }

  Widget _buildTransparentContainer() => _buildFormElements();

  Widget _buildFormElements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        formContent,
        const SizedBox(height: 16),
        ElevatedButton(
          // Disable button if loading
          onPressed: isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isLoading ? 0 : 4,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      submitText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
        if (showSocial) ...[
          const SizedBox(height: 32),
          const Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGoogleTap,
                  icon: const Icon(
                    Icons.g_mobiledata,
                    color: Colors.red,
                    size: 28,
                  ),
                  label: const Text('Google'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFacebookTap,
                  icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                  label: const Text('Facebook'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
