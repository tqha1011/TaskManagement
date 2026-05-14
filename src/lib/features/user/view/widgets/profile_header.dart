import 'package:flutter/material.dart';
import '../../model/user_profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfileModel user;

  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final avatarUri = Uri.tryParse(user.avatarUrl.trim());
    final hasValidAvatar =
        avatarUri != null &&
        (avatarUri.scheme == 'http' || avatarUri.scheme == 'https') &&
        avatarUri.host.isNotEmpty;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Rounded Square Avatar
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: hasValidAvatar
                    ? Image.network(
                        user.avatarUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildFallbackAvatar(context),
                        // Smooth image loading transition
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            child: child,
                          );
                        },
                      )
                    : _buildFallbackAvatar(context),
              ),
            ),
            // Edit Button with Ripple
            Material(
              color: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 4,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // TODO: Handle Edit Profile action
                },
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.surface,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Name Only
        Text(
          user.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        // Badges row removed here
      ],
    );
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: 64,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}