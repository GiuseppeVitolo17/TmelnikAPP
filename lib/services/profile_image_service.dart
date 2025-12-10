import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Service for handling profile image uploads with resize and compression
/// Follows best practices: resize to 320x320 or 160x160, compress, then upload
class ProfileImageService {
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Picks an image from gallery or camera
  /// Returns the selected file path or null if cancelled
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100, // We'll compress manually for better control
        maxWidth: 2048, // Limit initial size to avoid memory issues
        maxHeight: 2048,
      );

      if (pickedFile == null) {
        debugPrint('ℹ️ [PROFILE_IMAGE] User cancelled image selection');
        return null;
      }

      final file = File(pickedFile.path);
      
      // Verify file exists and is readable
      if (!await file.exists()) {
        throw Exception('Selected file does not exist');
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Selected file is empty');
      }
      
      debugPrint('✅ [PROFILE_IMAGE] Selected image: ${file.path} ($fileSize bytes)');
      return file;
    } catch (e, stackTrace) {
      debugPrint('❌ [PROFILE_IMAGE] Error picking image: $e');
      debugPrint('❌ [PROFILE_IMAGE] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Picks an image from gallery only (no camera option)
  Future<File?> pickImageFromGallery(BuildContext context) async {
    return pickImage(source: ImageSource.gallery);
  }

  /// Resizes and compresses image to specified dimensions
  /// Best practice: Use 320x320 for profile images, 160x160 for thumbnails
  Future<Uint8List?> resizeAndCompressImage(
    File imageFile, {
    int maxWidth = 320,
    int maxHeight = 320,
    int quality = 85, // JPEG quality (0-100)
  }) async {
    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      
      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('❌ [PROFILE_IMAGE] Failed to decode image');
        return null;
      }

      // Calculate new dimensions maintaining aspect ratio
      final aspectRatio = image.width / image.height;
      int newWidth = maxWidth;
      int newHeight = maxHeight;

      if (image.width > image.height) {
        // Landscape: width is the limiting factor
        newHeight = (maxWidth / aspectRatio).round();
      } else {
        // Portrait or square: height is the limiting factor
        newWidth = (maxHeight * aspectRatio).round();
      }

      // Resize image
      final resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear, // Good quality, fast
      );

      // Convert to JPEG and compress
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: quality),
      );

      debugPrint('✅ [PROFILE_IMAGE] Resized: ${image.width}x${image.height} → ${newWidth}x${newHeight}');
      debugPrint('✅ [PROFILE_IMAGE] Compressed: ${imageBytes.length} → ${compressedBytes.length} bytes');

      return compressedBytes;
    } catch (e) {
      debugPrint('❌ [PROFILE_IMAGE] Error resizing image: $e');
      return null;
    }
  }

  /// Uploads profile image to Firebase Storage
  /// Returns the download URL or null if upload fails
  Future<String?> uploadProfileImage(
    Uint8List imageBytes,
    String userId,
  ) async {
    try {
      // Verify Firebase Storage is initialized
      if (imageBytes.isEmpty) {
        throw Exception('Image bytes are empty');
      }

      // Create reference: profile_images/{userId}.jpg
      final ref = _storage.ref().child('profile_images/$userId.jpg');

      debugPrint('📤 [PROFILE_IMAGE] Starting upload for user: $userId (${imageBytes.length} bytes)');

      // Upload with metadata
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000', // Cache for 1 year
        ),
      );

      // Wait for upload to complete with timeout
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout after 30 seconds');
        },
      );
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ [PROFILE_IMAGE] Uploaded successfully to: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ [PROFILE_IMAGE] Error uploading image: $e');
      debugPrint('❌ [PROFILE_IMAGE] Stack trace: $stackTrace');
      
      // Provide more specific error messages
      String errorMessage = 'Unknown error';
      if (e.toString().contains('permission-denied') || e.toString().contains('Permission denied')) {
        errorMessage = 'Permission denied. Please check Firebase Storage rules.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Upload timeout. Please check your internet connection.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'Upload failed: ${e.toString()}';
      }
      
      debugPrint('❌ [PROFILE_IMAGE] Error details: $errorMessage');
      rethrow; // Re-throw to be caught by caller
    }
  }

  /// Deletes old profile image from Storage
  Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      
      // Check if file exists before trying to delete
      try {
        await ref.getMetadata();
        // File exists, proceed with deletion
        await ref.delete();
        debugPrint('✅ [PROFILE_IMAGE] Deleted old image for user: $userId');
      } catch (e) {
        // File doesn't exist or can't access metadata
        if (e.toString().contains('object-not-found') || 
            e.toString().contains('not-found')) {
          debugPrint('ℹ️ [PROFILE_IMAGE] No existing image to delete for user: $userId');
          return; // Not an error, just no file exists
        }
        rethrow; // Re-throw if it's a different error
      }
    } catch (e) {
      // Only log as warning if it's not a "not found" error
      if (!e.toString().contains('object-not-found') && 
          !e.toString().contains('not-found')) {
        debugPrint('⚠️ [PROFILE_IMAGE] Error deleting image for user $userId: $e');
      } else {
        debugPrint('ℹ️ [PROFILE_IMAGE] No existing image to delete for user: $userId');
      }
    }
  }

  /// Complete workflow: pick from gallery, resize, compress, and upload profile image
  /// Returns the download URL or null if any step fails
  Future<String?> pickResizeAndUploadProfileImage(
    BuildContext context,
    String userId, {
    int maxWidth = 320,
    int maxHeight = 320,
  }) async {
    try {
      // Step 1: Pick image from gallery only
      final imageFile = await pickImageFromGallery(context);
      if (imageFile == null) return null;

      // Step 2: Resize and compress
      final compressedBytes = await resizeAndCompressImage(
        imageFile,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      if (compressedBytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error processing image'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // Step 3: Delete old image (optional, but good practice)
      // Silently handle deletion errors - it's OK if image doesn't exist
      try {
        await deleteProfileImage(userId);
      } catch (e) {
        debugPrint('ℹ️ [PROFILE_IMAGE] Could not delete old image (non-critical): $e');
        // Continue with upload even if deletion fails
      }

      // Step 4: Upload to Firebase Storage
      String? downloadUrl;
      try {
        downloadUrl = await uploadProfileImage(compressedBytes, userId);
      } catch (e) {
        debugPrint('❌ [PROFILE_IMAGE] Upload error caught: $e');
        if (context.mounted) {
          String errorMsg = 'Error uploading image';
          if (e.toString().contains('object-not-found')) {
            // This shouldn't happen during upload, but handle gracefully
            errorMsg = 'Storage error. Please try again.';
            debugPrint('⚠️ [PROFILE_IMAGE] object-not-found during upload (unexpected)');
          } else if (e.toString().contains('permission-denied') || e.toString().contains('Permission denied')) {
            errorMsg = 'Permission denied. Please check Firebase Storage rules.';
          } else if (e.toString().contains('timeout')) {
            errorMsg = 'Upload timeout. Please check your internet connection.';
          } else if (e.toString().contains('network')) {
            errorMsg = 'Network error. Please check your internet connection.';
          } else {
            errorMsg = 'Upload failed: ${e.toString()}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return null;
      }
      
      if (downloadUrl == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error uploading image'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ [PROFILE_IMAGE] Error in complete workflow: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}
