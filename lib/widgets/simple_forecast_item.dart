import 'package:flutter/material.dart';

import '../models/weather_model.dart';

class SimpleForecastItem extends StatelessWidget {
  final HourlyWeather weather;

  const SimpleForecastItem({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final advice = _advice(weather);

    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _periodLabel(weather.time),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatHour(weather.time),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Icon(
            advice.icon,
            color: advice.color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            advice.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const Spacer(),
          Text(
            '${weather.temperature.toStringAsFixed(0)}°C • Hujan ${weather.precipitationProbability.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  _ForecastAdvice _advice(HourlyWeather weather) {
    if (weather.precipitationProbability >= 60 || weather.precipitation >= 1) {
      return const _ForecastAdvice(
        title: 'Kemungkinan hujan',
        icon: Icons.water_drop_outlined,
        color: Color(0xFF1565C0),
      );
    }

    if (weather.temperature >= 31) {
      return const _ForecastAdvice(
        title: 'Cuaca cukup panas',
        icon: Icons.wb_sunny_outlined,
        color: Color(0xFFE65100),
      );
    }

    if (weather.soilMoisture < 0.25) {
      return const _ForecastAdvice(
        title: 'Tanah mulai kering',
        icon: Icons.grass_outlined,
        color: Color(0xFF8D6E63),
      );
    }

    return const _ForecastAdvice(
      title: 'Kondisi cukup baik',
      icon: Icons.eco_outlined,
      color: Color(0xFF2E7D32),
    );
  }

  String _periodLabel(DateTime time) {
    final hour = time.hour;

    if (hour >= 4 && hour < 10) return 'Pagi';
    if (hour >= 10 && hour < 15) return 'Siang';
    if (hour >= 15 && hour < 18) return 'Sore';
    return 'Malam';
  }

  String _formatHour(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ForecastAdvice {
  final String title;
  final IconData icon;
  final Color color;

  const _ForecastAdvice({
    required this.title,
    required this.icon,
    required this.color,
  });
}
