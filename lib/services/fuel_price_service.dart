import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../utils/constants.dart';

/// Service responsible for fetching the latest fuel prices from data.gov.my.
class FuelPriceService {
  /// Creates a [FuelPriceService].
  ///
  /// An optional [http.Client] can be injected for testing.
  FuelPriceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetches the latest fuel price record.
  ///
  /// Returns a [FuelPrice] parsed from the first element of the response array.
  /// Throws an exception if the request fails or the response is empty.
  Future<FuelPrice> getFuelPrice() async {
    final response = await _client.get(Uri.parse(ApiUrls.fuelPriceUrl));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to fetch fuel price: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    if (data.isEmpty) {
      throw Exception('Fuel price response was empty');
    }

    return FuelPrice.fromJson(data.first as Map<String, dynamic>);
  }
}
