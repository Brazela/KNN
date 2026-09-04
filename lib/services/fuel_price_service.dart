import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../utils/constants.dart';

class FuelPriceService {

  FuelPriceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<FuelPrice> getFuelPrice() async {
    final response = await _client.get(Uri.parse(ApiUrls.fuelPriceLatestUrl));

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

  Future<List<FuelPrice>> getFuelPriceHistory({int limit = 50}) async {
    final response = await _client.get(
      Uri.parse(ApiUrls.fuelPriceHistoryUrl(limit: limit)),
    );

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to fetch fuel price history: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    final typedData = data.cast<Map<String, dynamic>>();
    final levelRecords = typedData
        .where((e) => e['series_type'] == 'level')
        .map(FuelPrice.fromJson)
        .toList();

    if (levelRecords.isEmpty) {
      throw Exception('No level-type fuel price records found');
    }

    return levelRecords;
  }
}
