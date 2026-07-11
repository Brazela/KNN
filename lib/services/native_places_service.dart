import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../utils/constants.dart';

/// Service for place autocomplete using the new Google Places API.
///
/// Calls `POST /v1/places:autocomplete` with the API key in the header
/// (same pattern as the Nearby Search and Place Details migration).
class NativePlacesService {
  final http.Client _client;

  /// Creates a [NativePlacesService].
  ///
  /// An optional [http.Client] can be injected for testing.
  NativePlacesService({http.Client? client}) : _client = client ?? http.Client();

  /// Returns autocomplete predictions using the new Places API.
  ///
  /// [query] must be at least 2 characters.
  Future<List<PlaceSuggestion>> autocomplete(String query) async {
    if (query.trim().length < 2) return [];

    final body = <String, dynamic>{
      'input': query,
      // Bias results towards Malaysia (max radius is 50 000 m).
      'locationBias': {
        'circle': {
          'center': {'latitude': 4.2105, 'longitude': 101.9758},
          'radius': 50000.0,
        },
      },
    };

    final uri = Uri.parse(ApiUrls.googlePlacesNewAutocompleteUrl);

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': GoogleMapsConfig.apiKey,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch suggestions: ${response.statusCode} — ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List<dynamic>? ?? [];

      return suggestions.map((json) {
        final map = json as Map<String, dynamic>;
        final prediction = map['placePrediction'] as Map<String, dynamic>?;
        final structured =
            prediction?['structuredFormat'] as Map<String, dynamic>?;
        final mainText =
            structured?['mainText'] as Map<String, dynamic>?;
        final secondaryText =
            structured?['secondaryText'] as Map<String, dynamic>?;

        return PlaceSuggestion(
          placeId: prediction?['placeId'] as String? ?? '',
          description: prediction?['placeDescription'] as String? ?? '',
          mainText: mainText?['text'] as String?,
          secondaryText: secondaryText?['text'] as String?,
        );
      }).toList();
    } on http.ClientException catch (e) {
      throw Exception(
          'Network error fetching suggestions: ${e.message} (uri: $uri)');
    }
  }
}
