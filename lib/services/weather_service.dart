import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_model.dart';

class WeatherService {
  static const String _host = 'api.open-meteo.com';
  static const String _path = '/v1/forecast';

  Future<TaniAirData> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      _host,
      _path,
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,precipitation',
        'hourly':
            'temperature_2m,relative_humidity_2m,'
            'precipitation_probability,precipitation,'
            'et0_fao_evapotranspiration,soil_moisture_0_to_7cm',
        'forecast_days': '2',
        'timezone': 'Asia/Jakarta',
      },
    );

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Server Open-Meteo mengembalikan status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Format respons API tidak sesuai.',
      );
    }

    if (decoded['error'] == true) {
      throw Exception(
        decoded['reason']?.toString() ?? 'Open-Meteo menolak permintaan.',
      );
    }

    return TaniAirData.fromJson(decoded);
  }
}
