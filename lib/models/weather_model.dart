class TaniAirData {
  final double latitude;
  final double longitude;
  final double elevation;
  final CurrentWeather current;
  final List<HourlyWeather> hourly;

  const TaniAirData({
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.current,
    required this.hourly,
  });

  factory TaniAirData.fromJson(Map<String, dynamic> json) {
    final currentJson =
        Map<String, dynamic>.from(json['current'] as Map? ?? <String, dynamic>{});
    final hourlyJson =
        Map<String, dynamic>.from(json['hourly'] as Map? ?? <String, dynamic>{});

    final times = _stringList(hourlyJson['time']);
    final temperatures = _doubleList(hourlyJson['temperature_2m']);
    final humidities = _doubleList(hourlyJson['relative_humidity_2m']);
    final rainProbabilities =
        _doubleList(hourlyJson['precipitation_probability']);
    final precipitation = _doubleList(hourlyJson['precipitation']);
    final et0 = _doubleList(hourlyJson['et0_fao_evapotranspiration']);
    final soilMoisture = _doubleList(hourlyJson['soil_moisture_0_to_7cm']);

    final length = [
      times.length,
      temperatures.length,
      humidities.length,
      rainProbabilities.length,
      precipitation.length,
      et0.length,
      soilMoisture.length,
    ].reduce((a, b) => a < b ? a : b);

    final hourly = <HourlyWeather>[];

    for (var i = 0; i < length; i++) {
      hourly.add(
        HourlyWeather(
          time: DateTime.parse(times[i]),
          temperature: temperatures[i],
          humidity: humidities[i],
          precipitationProbability: rainProbabilities[i],
          precipitation: precipitation[i],
          et0: et0[i],
          soilMoisture: soilMoisture[i],
        ),
      );
    }

    return TaniAirData(
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      elevation: _toDouble(json['elevation']),
      current: CurrentWeather.fromJson(currentJson),
      hourly: hourly,
    );
  }

  HourlyWeather get nearestHourly {
    if (hourly.isEmpty) {
      throw const FormatException('Data prakiraan per jam tidak tersedia.');
    }

    final target = current.time;
    var nearest = hourly.first;
    var smallestDifference = nearest.time.difference(target).abs();

    for (final item in hourly.skip(1)) {
      final difference = item.time.difference(target).abs();

      if (difference < smallestDifference) {
        nearest = item;
        smallestDifference = difference;
      }
    }

    return nearest;
  }

  List<HourlyWeather> get nextTwelveHours {
    if (hourly.isEmpty) {
      return const [];
    }

    final now = current.time;
    var startIndex = hourly.indexWhere(
      (item) => !item.time.isBefore(now),
    );

    if (startIndex < 0) {
      startIndex = 0;
    }

    final endIndex =
        (startIndex + 12 < hourly.length) ? startIndex + 12 : hourly.length;

    return hourly.sublist(startIndex, endIndex);
  }

  List<HourlyWeather> get forecastCards {
    final source = nextTwelveHours;
    if (source.isEmpty) {
      return const [];
    }

    final cards = <HourlyWeather>[];

    for (var i = 0; i < source.length && cards.length < 4; i += 3) {
      cards.add(source[i]);
    }

    return cards;
  }

  IrrigationAnalysis get irrigationAnalysis {
    final currentHour = nearestHourly;
    final future = nextTwelveHours;

    final rainTotal = future.fold<double>(
      0,
      (total, item) => total + item.precipitation,
    );

    final et0Total = future.fold<double>(
      0,
      (total, item) => total + item.et0,
    );

    final maxRainProbability = future.fold<double>(
      0,
      (maximum, item) => item.precipitationProbability > maximum
          ? item.precipitationProbability
          : maximum,
    );

    final soil = currentHour.soilMoisture;

    if (rainTotal >= 5 || maxRainProbability >= 80) {
      return IrrigationAnalysis(
        title: 'Tunda penyiraman',
        level: IrrigationLevel.safe,
        description:
            'Peluang atau akumulasi hujan 12 jam ke depan cukup tinggi. '
            'Penyiraman tambahan berpotensi tidak diperlukan.',
        rainTotal12h: rainTotal,
        et0Total12h: et0Total,
        maxRainProbability12h: maxRainProbability,
      );
    }

    if (soil < 0.18 && et0Total >= 2) {
      return IrrigationAnalysis(
        title: 'Penyiraman sangat disarankan',
        level: IrrigationLevel.urgent,
        description:
            'Estimasi kelembapan tanah rendah dan kehilangan air melalui '
            'evapotranspirasi diperkirakan cukup tinggi.',
        rainTotal12h: rainTotal,
        et0Total12h: et0Total,
        maxRainProbability12h: maxRainProbability,
      );
    }

    if (soil < 0.25 && rainTotal < 2) {
      return IrrigationAnalysis(
        title: 'Penyiraman disarankan',
        level: IrrigationLevel.warning,
        description:
            'Estimasi tanah relatif kering dan hujan 12 jam ke depan '
            'diperkirakan rendah.',
        rainTotal12h: rainTotal,
        et0Total12h: et0Total,
        maxRainProbability12h: maxRainProbability,
      );
    }

    if (soil < 0.30 && et0Total >= 2.5) {
      return IrrigationAnalysis(
        title: 'Pantau kondisi lahan',
        level: IrrigationLevel.watch,
        description:
            'Kelembapan tanah masih moderat, tetapi evapotranspirasi '
            'diperkirakan meningkat.',
        rainTotal12h: rainTotal,
        et0Total12h: et0Total,
        maxRainProbability12h: maxRainProbability,
      );
    }

    return IrrigationAnalysis(
      title: 'Belum perlu penyiraman',
      level: IrrigationLevel.safe,
      description:
          'Estimasi kelembapan tanah masih memadai untuk indikator '
          'sederhana TaniAir.',
      rainTotal12h: rainTotal,
      et0Total12h: et0Total,
      maxRainProbability12h: maxRainProbability,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static List<double> _doubleList(dynamic value) {
    if (value is! List) return const [];
    return value.map(_toDouble).toList();
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CurrentWeather {
  final DateTime time;
  final double temperature;
  final double humidity;
  final double precipitation;

  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.precipitation,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: DateTime.parse(
        json['time']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      temperature: _toDouble(json['temperature_2m']),
      humidity: _toDouble(json['relative_humidity_2m']),
      precipitation: _toDouble(json['precipitation']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class HourlyWeather {
  final DateTime time;
  final double temperature;
  final double humidity;
  final double precipitationProbability;
  final double precipitation;
  final double et0;
  final double soilMoisture;

  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.precipitationProbability,
    required this.precipitation,
    required this.et0,
    required this.soilMoisture,
  });

  double get soilMoisturePercent => soilMoisture * 100;
}

enum IrrigationLevel {
  safe,
  watch,
  warning,
  urgent,
}

class IrrigationAnalysis {
  final String title;
  final IrrigationLevel level;
  final String description;
  final double rainTotal12h;
  final double et0Total12h;
  final double maxRainProbability12h;

  const IrrigationAnalysis({
    required this.title,
    required this.level,
    required this.description,
    required this.rainTotal12h,
    required this.et0Total12h,
    required this.maxRainProbability12h,
  });
}
