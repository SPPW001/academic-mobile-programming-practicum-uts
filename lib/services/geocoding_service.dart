import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/location_model.dart';

class GeocodingService {
  Future<List<LocationResult>> searchLocations(String query) async {
    final keyword = query.trim();

    if (keyword.length < 2) {
      return const [];
    }

    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {
        'name': keyword,
        'count': '8',
        'language': 'id',
        'format': 'json',
        'countryCode': 'ID',
      },
    );

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Pencarian lokasi gagal dengan status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Format data lokasi tidak sesuai.');
    }

    if (decoded['error'] == true) {
      throw Exception(
        decoded['reason']?.toString() ?? 'Pencarian lokasi gagal.',
      );
    }

    final rawResults = decoded['results'];

    if (rawResults is! List) {
      return const [];
    }

    return rawResults
        .whereType<Map>()
        .map(
          (item) => LocationResult.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}
