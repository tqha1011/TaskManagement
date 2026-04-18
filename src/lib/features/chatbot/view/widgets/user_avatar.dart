import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.size, this.avatarUrl});

  final double size;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallbackUrl =
        (Supabase.instance.client.auth.currentUser?.userMetadata?['avatar_url'] as String?)?.trim();
    final resolvedUrl = (avatarUrl ?? fallbackUrl ?? '').trim();
    final canLoadNetworkImage = _isValidHttpUrl(resolvedUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: canLoadNetworkImage
          ? Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.person,
                size: size * 0.6,
                color: scheme.primary,
              ),
            )
          : Icon(Icons.person, size: size * 0.6, color: scheme.primary),
    );
  }

  bool _isValidHttpUrl(String value) {
    if (value.isEmpty || value.length > 2048) return false;
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.hasAbsolutePath && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}

