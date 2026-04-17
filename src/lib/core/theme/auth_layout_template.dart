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
  final bool compactMode;

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
    this.compactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF172744)
                        : Theme.of(context).colorScheme.surface,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = compactMode || constraints.maxHeight <= 780;

          return Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF08142D), Color(0xFF0B1A38), Color(0xFF0A1834)],
                    )
                  : null,
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.0, isCompact ? 8.0 : 16.0, 20.0, isCompact ? 16.0 : 36.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(context, isCompact),
                      SizedBox(height: isCompact ? 16 : 28),
                      useCard
                          ? _buildCardContainer(context, isCompact)
                          : _buildTransparentContainer(context, isCompact),
                      SizedBox(height: isCompact ? 12 : 24),
                      if (footerContent != null) footerContent!,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCompact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        customHeaderIcon ??
            Container(
              width: isCompact ? 64 : 80,
              height: isCompact ? 64 : 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2B47) : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.task_alt,
                    size: isCompact ? 36 : 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        SizedBox(height: isCompact ? 12 : 24),
        Text(
          title,
          style: TextStyle(
            fontSize: isCompact ? 24 : 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: isCompact ? 4 : 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCardContainer(BuildContext context, bool isCompact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isCompact ? 20 : 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2945) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: isDark ? Border.all(color: const Color(0xFF2A3E62), width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _buildFormElements(context, isCompact),
    );
  }

  Widget _buildTransparentContainer(BuildContext context, bool isCompact) =>
      _buildFormElements(context, isCompact);

  Widget _buildFormElements(BuildContext context, bool isCompact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        formContent,
        SizedBox(height: isCompact ? 12 : 16),
        ElevatedButton(
          // Disable button if loading
          onPressed: isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            disabledBackgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            padding: EdgeInsets.symmetric(vertical: isCompact ? 14 : 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isLoading ? 0 : (isDark ? 8 : 4),
            shadowColor: isDark
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                : null,
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
                        fontSize: isCompact ? 15 : 16,
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
          SizedBox(height: isCompact ? 16 : 32),
          Row(
            children: [
              Expanded(
                child: Divider(color: Theme.of(context).colorScheme.outline),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    backgroundColor:
                        isDark ? const Color(0xFF1A2945) : Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 14),
                  ),
                  onPressed: onGoogleTap,
                  icon: const Icon(
                    Icons.g_mobiledata,
                    color: Colors.red,
                    size: 28,
                  ),
                  label: const Text('Google'),
                ),
              ),
              SizedBox(width: isCompact ? 10 : 16),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    backgroundColor:
                        isDark ? const Color(0xFF1A2945) : Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 14),
                  ),
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
