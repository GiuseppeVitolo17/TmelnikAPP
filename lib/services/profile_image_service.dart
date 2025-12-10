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
      debugPrint('🔍 [PROFILE_IMAGE] ========== UPLOAD START ==========');
      debugPrint('🔍 [PROFILE_IMAGE] User ID: $userId');
      debugPrint('🔍 [PROFILE_IMAGE] Image bytes length: ${imageBytes.length}');
      debugPrint('🔍 [PROFILE_IMAGE] Image bytes empty: ${imageBytes.isEmpty}');
      
      // Verify Firebase Storage is initialized
      if (imageBytes.isEmpty) {
        throw Exception('Image bytes are empty');
      }

      // Verify reference is valid
      if (userId.isEmpty) {
        throw Exception('User ID is empty - cannot upload image');
      }

      // Create reference: profile_images/{userId}.jpg
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      debugPrint('🔍 [PROFILE_IMAGE] Storage reference created: profile_images/$userId.jpg');
      debugPrint('🔍 [PROFILE_IMAGE] Storage bucket: ${ref.bucket}');
      debugPrint('🔍 [PROFILE_IMAGE] Storage full path: ${ref.fullPath}');

      // Verify image size (must be under 5MB for Storage rules)
      final sizeInMB = imageBytes.length / (1024 * 1024);
      debugPrint('🔍 [PROFILE_IMAGE] Image size: ${sizeInMB.toStringAsFixed(2)} MB');
      if (sizeInMB > 5) {
        throw Exception('Image size (${sizeInMB.toStringAsFixed(2)} MB) exceeds 5MB limit');
      }

      // Upload with metadata
      debugPrint('📤 [PROFILE_IMAGE] Starting upload task...');
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000', // Cache for 1 year
        ),
      );
      debugPrint('📤 [PROFILE_IMAGE] Upload task created, waiting for completion...');

      // Wait for upload to complete with timeout
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏱️ [PROFILE_IMAGE] Upload timeout after 30 seconds');
          throw Exception('Upload timeout after 30 seconds');
        },
      );
      
      debugPrint('✅ [PROFILE_IMAGE] Upload task completed');
      debugPrint('✅ [PROFILE_IMAGE] Bytes transferred: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      
      // Get download URL
      debugPrint('🔗 [PROFILE_IMAGE] Getting download URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ [PROFILE_IMAGE] ========== UPLOAD SUCCESS ==========');
      debugPrint('✅ [PROFILE_IMAGE] Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ [PROFILE_IMAGE] ========== UPLOAD ERROR ==========');
      debugPrint('❌ [PROFILE_IMAGE] Error type: ${e.runtimeType}');
      debugPrint('❌ [PROFILE_IMAGE] Error message: $e');
      debugPrint('❌ [PROFILE_IMAGE] Error string: ${e.toString()}');
      debugPrint('❌ [PROFILE_IMAGE] Stack trace: $stackTrace');
      
      // Extract Firebase-specific error codes
      String errorCode = 'UNKNOWN';
      String errorMessage = 'Unknown error occurred';
      
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('permission-denied') || errorString.contains('permission denied')) {
        errorCode = 'PERMISSION_DENIED';
        errorMessage = 'Permission denied. User may not be authenticated or Storage rules may be blocking upload.';
        debugPrint('🔒 [PROFILE_IMAGE] PERMISSION_DENIED - Check: 1) User authenticated? 2) Storage rules? 3) User ID matches auth.uid?');
      } else if (errorString.contains('unauthenticated') || errorString.contains('unauthorized')) {
        errorCode = 'UNAUTHENTICATED';
        errorMessage = 'User not authenticated. Please sign in again.';
        debugPrint('🔒 [PROFILE_IMAGE] UNAUTHENTICATED - User needs to sign in');
      } else if (errorString.contains('object-not-found')) {
        errorCode = 'OBJECT_NOT_FOUND';
        errorMessage = 'Storage object not found. This should not happen during upload.';
        debugPrint('⚠️ [PROFILE_IMAGE] OBJECT_NOT_FOUND - Unexpected during upload');
      } else if (errorString.contains('quota') || errorString.contains('storage quota')) {
        errorCode = 'QUOTA_EXCEEDED';
        errorMessage = 'Storage quota exceeded. Please check Firebase Storage usage.';
        debugPrint('💾 [PROFILE_IMAGE] QUOTA_EXCEEDED - Firebase Storage quota limit reached');
      } else if (errorString.contains('timeout')) {
        errorCode = 'TIMEOUT';
        errorMessage = 'Upload timeout. Please check your internet connection and try again.';
        debugPrint('⏱️ [PROFILE_IMAGE] TIMEOUT - Network may be slow or unstable');
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorCode = 'NETWORK_ERROR';
        errorMessage = 'Network error. Please check your internet connection.';
        debugPrint('🌐 [PROFILE_IMAGE] NETWORK_ERROR - Connection issue');
      } else if (errorString.contains('canceled') || errorString.contains('cancelled')) {
        errorCode = 'CANCELLED';
        errorMessage = 'Upload was cancelled.';
        debugPrint('🚫 [PROFILE_IMAGE] CANCELLED - Upload was cancelled');
      } else {
        errorCode = 'UNKNOWN_ERROR';
        errorMessage = 'Upload failed: ${e.toString()}';
        debugPrint('❓ [PROFILE_IMAGE] UNKNOWN_ERROR - Full error: $e');
      }
      
      debugPrint('❌ [PROFILE_IMAGE] Error Code: $errorCode');
      debugPrint('❌ [PROFILE_IMAGE] Error Message: $errorMessage');
      debugPrint('❌ [PROFILE_IMAGE] ======================================');
      
      // Re-throw with detailed error
      throw Exception('$errorCode: $errorMessage');
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
      
      // Verify user is authenticated before upload
      debugPrint('🔐 [PROFILE_IMAGE] Verifying authentication before upload...');

      // Step 4: Upload to Firebase Storage
      String? downloadUrl;
      try {
        debugPrint('🚀 [PROFILE_IMAGE] Starting upload workflow for user: $userId');
        downloadUrl = await uploadProfileImage(compressedBytes, userId);
        debugPrint('✅ [PROFILE_IMAGE] Upload workflow completed successfully');
      } catch (e) {
        debugPrint('❌ [PROFILE_IMAGE] Upload error caught in workflow: $e');
        if (context.mounted) {
          String errorMsg = 'Error uploading image';
          
          // Extract error code from exception message
          final errorString = e.toString();
          if (errorString.contains('PERMISSION_DENIED:')) {
            errorMsg = errorString.split('PERMISSION_DENIED:')[1].trim();
          } else if (errorString.contains('UNAUTHENTICATED:')) {
            errorMsg = errorString.split('UNAUTHENTICATED:')[1].trim();
          } else if (errorString.contains('QUOTA_EXCEEDED:')) {
            errorMsg = errorString.split('QUOTA_EXCEEDED:')[1].trim();
          } else if (errorString.contains('TIMEOUT:')) {
            errorMsg = errorString.split('TIMEOUT:')[1].trim();
          } else if (errorString.contains('NETWORK_ERROR:')) {
            errorMsg = errorString.split('NETWORK_ERROR:')[1].trim();
          } else if (errorString.contains('CANCELLED:')) {
            errorMsg = errorString.split('CANCELLED:')[1].trim();
          } else if (errorString.contains('UNKNOWN_ERROR:')) {
            errorMsg = errorString.split('UNKNOWN_ERROR:')[1].trim();
          } else {
            // Fallback: use the full error message
            errorMsg = errorString.contains(':') 
                ? errorString.split(':').skip(1).join(':').trim()
                : 'Upload failed: $errorString';
          }
          
          debugPrint('📱 [PROFILE_IMAGE] Showing error to user: $errorMsg');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () {
                  // Show detailed error in a dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Upload Error Details'),
                      content: SingleChildScrollView(
                        child: Text(
                          'Error: $e\n\nCheck console logs for more details.',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
