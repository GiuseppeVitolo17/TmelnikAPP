import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for fetching images from Pexels API
class PexelsService {
  static const String _apiKey = 'QTwrp3DrnQ9J4jg1oRzPZZEIP3ezzOZ6lElH1Gwk58ILHbzmwyEpuYWD';
  static const String _baseUrl = 'https://api.pexels.com/v1/search';
  
  /// Returns a customized search query for specific cities
  /// This helps get more appropriate images (panoramas, famous monuments) instead of artistic ones
  static String _getCityQuery(String city) {
    final cityLower = city.toLowerCase();
    
    // Custom queries for specific cities to get better results
    switch (cityLower) {
      case 'krakow':
      case 'cracovia':
        return 'Krakow main square panorama'; // Piazza principale o panoramica normale
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
      default:
        // Default fallback: try panorama first, then skyline
        return '$city panorama';
    }
  }
  
  /// Fetches a landscape image URL for a given city
  /// Returns a network URL if successful, otherwise returns empty string
  /// (ProjectCard will show inline placeholder widget for empty string)
  static Future<String> fetchCityImageUrl(String city) async {
    try {
      // First try with custom query
      String query = _getCityQuery(city);
      String? imageUrl = await _tryFetchImage(query);
      
      // If no result, try fallback with skyline query
      if (imageUrl == null || imageUrl.isEmpty) {
        imageUrl = await _tryFetchImage('$city skyline');
      }
      
      return imageUrl ?? '';
    } catch (e) {
      // Log error silently and return empty string
      // ProjectCard will handle empty string and show inline placeholder
      debugPrint('Pexels API error for $city: $e');
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
        
        if (photos != null && photos.isNotEmpty) {
          final photo = photos[0] as Map<String, dynamic>;
          final src = photo['src'] as Map<String, dynamic>?;
          
          if (src != null && src.containsKey('landscape')) {
            return src['landscape'] as String;
          }
        }
      }
      
      return null;
    } catch (e) {
      // Silently handle errors - debugLogger would be better but keeping it simple
      debugPrint('Pexels API fetch error for query "$query": $e');
      return null;
    }
  }
}
