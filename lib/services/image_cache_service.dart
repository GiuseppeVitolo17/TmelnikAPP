import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'pexels_service.dart';

/// Service for caching project images locally
/// Images are cached on disk and only refreshed when user clicks on them
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  static const String _cacheKeyPrefix = 'project_image_url_';
  static const String _cacheTimestampPrefix = 'project_image_timestamp_';

  /// Get cached image file path for a city/project
  /// Returns null if not cached
  Future<String?> getCachedImagePath(String city) async {
    try {
      if (kIsWeb) {
        // Web: use SharedPreferences to store URLs, not file paths
        final prefs = await SharedPreferences.getInstance();
        final imageUrl = prefs.getString('$_cacheKeyPrefix$city');
        return imageUrl; // Return URL for web
      }

      final cacheDir = await _getCacheDirectory();
      final fileName = _getFileName(city);
      final file = File('${cacheDir.path}/$fileName');
      
      if (await file.exists()) {
        debugPrint('🖼️ [CACHE] Found cached image for $city');
        return file.path;
      }
      
      return null;
    } catch (e) {
      debugPrint('🖼️ [CACHE] Error getting cached image: $e');
      return null;
    }
  }

  /// Get cached image URL (for web) or file path (for mobile)
  Future<String?> getCachedImage(String city) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_cacheKeyPrefix$city');
    } else {
      return await getCachedImagePath(city);
    }
  }

  /// Cache an image URL for a city
  /// Downloads and saves the image locally (mobile) or stores URL (web)
  Future<String?> cacheImage(String city, String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return null;

      if (kIsWeb) {
        // Web: just store the URL
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_cacheKeyPrefix$city', imageUrl);
        await prefs.setInt('$_cacheTimestampPrefix$city', DateTime.now().millisecondsSinceEpoch);
        debugPrint('🖼️ [CACHE] Cached URL for $city (web)');
        return imageUrl;
      }

      // Mobile: download and save file
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFileName(city);
      final file = File('${cacheDir.path}/$fileName');

      // Download image
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        
        // Store URL in SharedPreferences for reference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_cacheKeyPrefix$city', imageUrl);
        await prefs.setInt('$_cacheTimestampPrefix$city', DateTime.now().millisecondsSinceEpoch);
        
        debugPrint('🖼️ [CACHE] Cached image for $city: ${file.path}');
        return file.path;
      }

      return null;
    } catch (e) {
      debugPrint('🖼️ [CACHE] Error caching image: $e');
      return null;
    }
  }

  /// Fetch and cache image for a city (only called when user clicks to refresh)
  Future<String?> fetchAndCacheImage(String city) async {
    try {
      debugPrint('🖼️ [CACHE] Fetching new image for $city');
      final imageUrl = await PexelsService.fetchCityImageUrl(city);
      
      if (imageUrl.isNotEmpty) {
        return await cacheImage(city, imageUrl);
      }
      
      return null;
    } catch (e) {
      debugPrint('🖼️ [CACHE] Error fetching and caching: $e');
      return null;
    }
  }

  /// Clear cache for a specific city
  Future<void> clearCache(String city) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('$_cacheKeyPrefix$city');
        await prefs.remove('$_cacheTimestampPrefix$city');
      } else {
        final cacheDir = await _getCacheDirectory();
        final fileName = _getFileName(city);
        final file = File('${cacheDir.path}/$fileName');
        if (await file.exists()) {
          await file.delete();
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('$_cacheKeyPrefix$city');
        await prefs.remove('$_cacheTimestampPrefix$city');
      }
      debugPrint('🖼️ [CACHE] Cleared cache for $city');
    } catch (e) {
      debugPrint('🖼️ [CACHE] Error clearing cache: $e');
    }
  }

  /// Get cache directory for mobile
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationCacheDirectory();
    final cacheDir = Directory('${appDir.path}/project_images');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Generate a safe filename from city name
  String _getFileName(String city) {
    final hash = md5.convert(utf8.encode(city.toLowerCase().trim())).toString();
    return '${hash}.jpg';
  }
}

