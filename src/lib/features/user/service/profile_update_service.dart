import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileUpdateService {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  /// Picks an image from gallery, uploads it to Supabase storage,
  /// and updates the user's profile with the new avatar URL.
  Future<String?> uploadAndSaveAvatar() async {
    try {
      // 1. Pick Image: Use image_picker to let the user select an image from the gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Optional: compress image slightly
      );

      if (pickedFile == null) {
        print('User canceled image picking');
        return null;
      }

      // 2. Process File: Convert picked image into a File object
      final File file = File(pickedFile.path);
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userId = user.id;
      // Generate a unique file path to avoid cache issues
      final String fileExt = pickedFile.path.split('.').last;
      final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final String path = '$userId/$fileName';

      // 3. Upload to Storage: Upload file to the 'avatars' bucket
      await _supabase.storage.from('avatars').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // 4. Get Public URL: Retrieve the public URL of the uploaded image
      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);

      // 5. Update Profile Table: Save the new URL into the avatar column
      await _supabase
          .from('profile')
          .update({'avatar': publicUrl})
          .eq('id', userId);

      // 6. Return the new publicUrl
      return publicUrl;
    } catch (e) {
      print('Error in uploadAndSaveAvatar: $e');
      return null;
    }
  }
}
