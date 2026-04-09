import 'package:flutter/material.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                _buildHeader(context),
                const SizedBox(height: 32),
                useCard
                    ? _buildCardContainer(context)
                    : _buildTransparentContainer(context),
                const SizedBox(height: 32),
                if (footerContent != null) footerContent!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        customHeaderIcon ??
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.task_alt,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCardContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _buildFormElements(context),
    );
  }

  Widget _buildTransparentContainer(BuildContext context) =>
      _buildFormElements(context);

  Widget _buildFormElements(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        formContent,
        const SizedBox(height: 16),
        ElevatedButton(
          // Disable button if loading
          onPressed: isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            disabledBackgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isLoading ? 0 : 4,
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.surface,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      submitText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: Theme.of(context).colorScheme.surface,
                      size: 20,
                    ),
                  ],
                ),
        ),
        if (showSocial) ...[
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Divider(color: Theme.of(context).colorScheme.outline),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Divider(color: Theme.of(context).colorScheme.outline),
              ),
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
