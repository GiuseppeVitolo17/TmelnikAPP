import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for fetching images from Pexels API
class PexelsService {
  static const String _apiKey = 'QTwrp3DrnQ9J4jg1oRzPZZEIP3ezzOZ6lElH1Gwk58ILHbzmwyEpuYWD';
  static const String _baseUrl = 'https://api.pexels.com/v1/search';
  
  /// Returns a customized search query for specific cities
  /// This helps get more appropriate images (panoramas, famous monuments, churches) instead of artistic ones
  static String _getCityQuery(String city) {
    final cityLower = city.toLowerCase().trim();
    
    // Custom queries for specific cities to get better results
    switch (cityLower) {
      case 'krakow':
      case 'cracovia':
      case 'kraków':
        return 'Krakow main square panorama';
      case 'berlin':
        return 'Berlin Brandenburg Gate panorama';
      case 'brno':
        return 'Brno city center panorama';
      case 'prague':
      case 'praha':
        return 'Prague old town square panorama';
      case 'warsaw':
      case 'warszawa':
        return 'Warsaw city center panorama';
      case 'vienna':
      case 'wien':
        return 'Vienna city center panorama';
      case 'budapest':
        return 'Budapest parliament panorama';
      case 'ischia':
        return 'Ischia island churches monuments';
      case 'isola d\'ischia':
        return 'Ischia island churches monuments';
      default:
        // Default: try city name with panorama
        return '$city panorama';
    }
  }
  
  /// Returns a list of fallback queries to try if the main query fails
  /// Includes churches, monuments, architecture, and landmarks
  static List<String> _getFallbackQueries(String city) {
    final cityLower = city.toLowerCase().trim();
    return [
      '$city churches',      // Try churches first
      '$city monuments',     // Then monuments
      '$city architecture',   // Architecture
      '$city landmarks',     // Landmarks
      '$city skyline',       // Skyline
      '$city',               // Just the city name as last resort
    ];
  }
  
  /// Fetches a landscape image URL for a given city
  /// Returns a network URL if successful, otherwise returns empty string
  /// (ProjectCard will show inline placeholder widget for empty string)
  static Future<String> fetchCityImageUrl(String city) async {
    try {
      debugPrint('🖼️ [PEXELS] Searching for images of: $city');
      
      // First try with custom query
      String query = _getCityQuery(city);
      debugPrint('🖼️ [PEXELS] Trying primary query: "$query"');
      String? imageUrl = await _tryFetchImage(query);
      
      // If no result, try all fallback queries
      if (imageUrl == null || imageUrl.isEmpty) {
        final fallbackQueries = _getFallbackQueries(city);
        debugPrint('🖼️ [PEXELS] Primary query failed, trying ${fallbackQueries.length} fallback queries');
        
        for (final fallbackQuery in fallbackQueries) {
          debugPrint('🖼️ [PEXELS] Trying fallback: "$fallbackQuery"');
          imageUrl = await _tryFetchImage(fallbackQuery);
          if (imageUrl != null && imageUrl.isNotEmpty) {
            debugPrint('🖼️ [PEXELS] ✅ Found image with query: "$fallbackQuery"');
            break;
          }
        }
      } else {
        debugPrint('🖼️ [PEXELS] ✅ Found image with primary query: "$query"');
      }
      
      if (imageUrl == null || imageUrl.isEmpty) {
        debugPrint('🖼️ [PEXELS] ❌ No image found for $city after all queries');
      }
      
      return imageUrl ?? '';
    } catch (e) {
      // Log error silently and return empty string
      // ProjectCard will handle empty string and show inline placeholder
      debugPrint('🖼️ [PEXELS] ❌ Error fetching image for $city: $e');
      return '';
    }
  }
  
  /// Helper method to try fetching an image with a specific query
  static Future<String?> _tryFetchImage(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final uri = Uri.parse('$_baseUrl?query=$encodedQuery&per_page=1&orientation=landscape');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': _apiKey,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = data['photos'] as List?;
        final totalResults = data['total_results'] as int? ?? 0;
        
        debugPrint('🖼️ [PEXELS] Query "$query": status ${response.statusCode}, found $totalResults results');
        
        if (photos != null && photos.isNotEmpty) {
          final photo = photos[0] as Map<String, dynamic>;
          final src = photo['src'] as Map<String, dynamic>?;
          
          if (src != null && src.containsKey('landscape')) {
            final imageUrl = src['landscape'] as String;
            debugPrint('🖼️ [PEXELS] ✅ Successfully fetched image URL for "$query"');
            return imageUrl;
          }
        } else {
          debugPrint('🖼️ [PEXELS] ⚠️ No photos found for query "$query"');
        }
      } else {
        debugPrint('🖼️ [PEXELS] ⚠️ HTTP error ${response.statusCode} for query "$query"');
      }
      
      return null;
    } catch (e) {
      // Silently handle errors - debugLogger would be better but keeping it simple
      debugPrint('Pexels API fetch error for query "$query": $e');
      return null;
    }
  }
}
