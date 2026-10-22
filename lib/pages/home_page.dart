import 'package:flutter/material.dart';

import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../services/geocoding_service.dart';
import '../services/weather_service.dart';
import '../widgets/simple_forecast_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GeocodingService _geocodingService = GeocodingService();
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _searchController = TextEditingController();

  Future<List<LocationResult>>? _searchFuture;
  Future<TaniAirData>? _weatherFuture;
  LocationResult? _selectedLocation;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchLocation() {
    final keyword = _searchController.text.trim();

    if (keyword.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ketik minimal 2 huruf nama daerah.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _searchFuture = _geocodingService.searchLocations(keyword);
    });
  }

  void _selectLocation(LocationResult location) {
    setState(() {
      _selectedLocation = location;
      _weatherFuture = _weatherService.fetchWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    });
  }

  void _changeLocation() {
    setState(() {
      _selectedLocation = null;
      _weatherFuture = null;
      _searchFuture = null;
      _searchController.clear();
    });
  }

  void _refreshWeather() {
    final location = _selectedLocation;
    if (location == null) return;

    setState(() {
      _weatherFuture = _weatherService.fetchWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F2),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(
              Icons.eco_outlined,
              color: Color(0xFF2E7D32),
            ),
            SizedBox(width: 8),
            Text(
              'TaniAir',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              tooltip: 'Ganti lokasi',
              onPressed: _changeLocation,
              icon: const Icon(Icons.location_searching_outlined),
            ),
          if (_selectedLocation != null)
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _refreshWeather,
              icon: const Icon(Icons.refresh_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _selectedLocation == null
            ? _LocationSearchView(
                key: const ValueKey('search'),
                controller: _searchController,
                searchFuture: _searchFuture,
                onSearch: _searchLocation,
                onSelect: _selectLocation,
              )
            : _WeatherDashboard(
                key: const ValueKey('dashboard'),
                location: _selectedLocation!,
                weatherFuture: _weatherFuture!,
                onRetry: _refreshWeather,
                onChangeLocation: _changeLocation,
              ),
      ),
    );
  }
}

class _LocationSearchView extends StatelessWidget {
  final TextEditingController controller;
  final Future<List<LocationResult>>? searchFuture;
  final VoidCallback onSearch;
  final ValueChanged<LocationResult> onSelect;

  const _LocationSearchView({
    super.key,
    required this.controller,
    required this.searchFuture,
    required this.onSearch,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.agriculture_outlined,
                size: 38,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Cari lokasi lahan Anda',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cukup ketik nama desa, kecamatan, atau kota. '
                'TaniAir akan mencari lokasi dan membaca kondisi cuaca untuk Anda.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: 'Contoh: Pujon, Batu, Dau...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'Cari',
              onPressed: onSearch,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tidak perlu mengetahui latitude atau longitude.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 22),
        if (searchFuture == null)
          const _SearchHint()
        else
          FutureBuilder<List<LocationResult>>(
            future: searchFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _SearchError(
                  message: snapshot.error.toString(),
                  onRetry: onSearch,
                );
              }

              final locations = snapshot.data ?? const <LocationResult>[];

              if (locations.isEmpty) {
                return const _EmptySearchResult();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih lokasi yang sesuai',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...locations.map(
                    (location) => _LocationTile(
                      location: location,
                      onTap: () => onSelect(location),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF2E7D32),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tips: jika nama daerah terlalu umum, tambahkan nama kabupaten atau kota. '
              'Contoh: “Dau, Jawa Timur”.',
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SearchError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 10),
          const Text(
            'Pencarian belum berhasil',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.location_off_outlined, size: 46),
          SizedBox(height: 10),
          Text(
            'Lokasi belum ditemukan',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Coba nama daerah lain atau tambahkan nama kabupaten/provinsi.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final LocationResult location;
  final VoidCallback onTap;

  const _LocationTile({
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          foregroundColor: Color(0xFF2E7D32),
          child: Icon(Icons.location_on_outlined),
        ),
        title: Text(
          location.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(location.detailAddress),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _WeatherDashboard extends StatelessWidget {
  final LocationResult location;
  final Future<TaniAirData> weatherFuture;
  final VoidCallback onRetry;
  final VoidCallback onChangeLocation;

  const _WeatherDashboard({
    super.key,
    required this.location,
    required this.weatherFuture,
    required this.onRetry,
    required this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TaniAirData>(
      future: weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingWeather(location: location);
        }

        if (snapshot.hasError) {
          return _WeatherError(
            location: location,
            message: snapshot.error.toString(),
            onRetry: onRetry,
            onChangeLocation: onChangeLocation,
          );
        }

        final data = snapshot.data;

        if (data == null) {
          return _WeatherError(
            location: location,
            message: 'Data kondisi lahan tidak tersedia.',
            onRetry: onRetry,
            onChangeLocation: onChangeLocation,
          );
        }

        return _SuccessDashboard(
          location: location,
          data: data,
          onRefresh: onRetry,
        );
      },
    );
  }
}

class _SuccessDashboard extends StatelessWidget {
  final LocationResult location;
  final TaniAirData data;
  final VoidCallback onRefresh;

  const _SuccessDashboard({
    required this.location,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final currentHour = data.nearestHourly;
    final analysis = data.irrigationAnalysis;
    final forecast = data.forecastCards;
    final recommendation = _RecommendationViewData.fromAnalysis(analysis);

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 19,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location.shortAddress,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MainRecommendationCard(data: recommendation),
          const SizedBox(height: 22),
          Text(
            'Kondisi hari ini',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          _SimpleConditionCard(
            icon: Icons.grass_outlined,
            label: 'Kondisi tanah',
            value: _soilLabel(currentHour.soilMoisture),
          ),
          const SizedBox(height: 10),
          _SimpleConditionCard(
            icon: Icons.water_drop_outlined,
            label: 'Peluang hujan',
            value: _rainLabel(analysis.maxRainProbability12h),
          ),
          const SizedBox(height: 10),
          _SimpleConditionCard(
            icon: Icons.wb_sunny_outlined,
            label: 'Penguapan air',
            value: _evaporationLabel(analysis.et0Total12h),
          ),
          const SizedBox(height: 10),
          _SimpleConditionCard(
            icon: Icons.thermostat_outlined,
            label: 'Suhu sekarang',
            value: '${data.current.temperature.toStringAsFixed(0)}°C',
          ),
          const SizedBox(height: 24),
          Text(
            'Beberapa jam ke depan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ringkasan kondisi setiap sekitar 3 jam.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: forecast.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return SimpleForecastItem(weather: forecast[index]);
              },
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => _showTechnicalDetails(
              context,
              data,
              analysis,
              currentHour,
            ),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Lihat rincian data'),
          ),
          const SizedBox(height: 16),
          const _DisclaimerCard(),
          const SizedBox(height: 15),
          Text(
            'Data cuaca: Open-Meteo.com',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  static String _soilLabel(double value) {
    final percent = value * 100;
    if (percent < 18) return 'Kering';
    if (percent < 25) return 'Agak kering';
    if (percent < 35) return 'Cukup lembap';
    return 'Lembap';
  }

  static String _rainLabel(double probability) {
    if (probability >= 70) return 'Tinggi';
    if (probability >= 40) return 'Sedang';
    return 'Rendah';
  }

  static String _evaporationLabel(double et0) {
    if (et0 >= 3) return 'Tinggi';
    if (et0 >= 1.5) return 'Sedang';
    return 'Rendah';
  }

  static void _showTechnicalDetails(
    BuildContext context,
    TaniAirData data,
    IrrigationAnalysis analysis,
    HourlyWeather currentHour,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rincian data',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bagian ini menampilkan angka teknis yang digunakan TaniAir untuk membuat indikator.',
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  label: 'Estimasi kelembapan tanah 0–7 cm',
                  value:
                      '${currentHour.soilMoisturePercent.toStringAsFixed(1)}%',
                ),
                _DetailRow(
                  label: 'ET₀ saat ini',
                  value: '${currentHour.et0.toStringAsFixed(2)} mm',
                ),
                _DetailRow(
                  label: 'ET₀ 12 jam',
                  value: '${analysis.et0Total12h.toStringAsFixed(2)} mm',
                ),
                _DetailRow(
                  label: 'Perkiraan hujan 12 jam',
                  value: '${analysis.rainTotal12h.toStringAsFixed(2)} mm',
                ),
                _DetailRow(
                  label: 'Peluang hujan maksimum',
                  value:
                      '${analysis.maxRainProbability12h.toStringAsFixed(0)}%',
                ),
                _DetailRow(
                  label: 'Kelembapan udara',
                  value: '${data.current.humidity.toStringAsFixed(0)}%',
                ),
                _DetailRow(
                  label: 'Suhu udara',
                  value: '${data.current.temperature.toStringAsFixed(1)}°C',
                ),
                const SizedBox(height: 12),
                Text(
                  'Catatan: kategori seperti “kering”, “penguapan tinggi”, dan rekomendasi penyiraman adalah indikator sederhana TaniAir untuk kebutuhan prototipe, bukan standar agronomi universal.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecommendationViewData {
  final String action;
  final String explanation;
  final String suggestion;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _RecommendationViewData({
    required this.action,
    required this.explanation,
    required this.suggestion,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  factory _RecommendationViewData.fromAnalysis(IrrigationAnalysis analysis) {
    if (analysis.rainTotal12h >= 5 ||
        analysis.maxRainProbability12h >= 80) {
      return const _RecommendationViewData(
        action: 'TUNDA PENYIRAMAN',
        explanation: 'Hujan diperkirakan cukup tinggi dalam beberapa jam ke depan.',
        suggestion: 'Tunggu kondisi hujan dan periksa lahan kembali setelahnya.',
        icon: Icons.umbrella_outlined,
        background: Color(0xFFE3F2FD),
        foreground: Color(0xFF0D47A1),
      );
    }

    switch (analysis.level) {
      case IrrigationLevel.urgent:
        return const _RecommendationViewData(
          action: 'PERLU DISIRAM',
          explanation:
              'Tanah diperkirakan cukup kering dan kehilangan air relatif tinggi.',
          suggestion: 'Jika memungkinkan, lakukan penyiraman pada pagi atau sore hari.',
          icon: Icons.water_drop,
          background: Color(0xFFFFEBEE),
          foreground: Color(0xFFB71C1C),
        );
      case IrrigationLevel.warning:
        return const _RecommendationViewData(
          action: 'PERLU DISIRAM',
          explanation:
              'Tanah mulai kering dan hujan yang diperkirakan masih rendah.',
          suggestion: 'Pertimbangkan penyiraman dan periksa kondisi tanah secara langsung.',
          icon: Icons.water_drop_outlined,
          background: Color(0xFFFFF3E0),
          foreground: Color(0xFFE65100),
        );
      case IrrigationLevel.watch:
        return const _RecommendationViewData(
          action: 'PANTAU DULU',
          explanation:
              'Kondisi tanah masih cukup, tetapi air diperkirakan lebih cepat menguap.',
          suggestion: 'Pantau kembali beberapa jam lagi sebelum memutuskan menyiram.',
          icon: Icons.visibility_outlined,
          background: Color(0xFFFFF8E1),
          foreground: Color(0xFF795548),
        );
      case IrrigationLevel.safe:
        return const _RecommendationViewData(
          action: 'BELUM PERLU DISIRAM',
          explanation: 'Kondisi tanah diperkirakan masih cukup lembap saat ini.',
          suggestion: 'Tetap pantau perubahan cuaca dan kondisi tanaman di lahan.',
          icon: Icons.check_circle_outline,
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF1B5E20),
        );
    }
  }
}

class _MainRecommendationCard extends StatelessWidget {
  final _RecommendationViewData data;

  const _MainRecommendationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: data.foreground.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: data.foreground.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 38,
              color: data.foreground,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            data.action,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: data.foreground,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            data.explanation,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: data.foreground,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              data.suggestion,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: data.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleConditionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SimpleConditionCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 18),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _LoadingWeather extends StatelessWidget {
  final LocationResult location;

  const _LoadingWeather({required this.location});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Membaca kondisi ${location.name}...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherError extends StatelessWidget {
  final LocationResult location;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onChangeLocation;

  const _WeatherError({
    required this.location,
    required this.message,
    required this.onRetry,
    required this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              'Data ${location.name} belum berhasil dimuat',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
            TextButton(
              onPressed: onChangeLocation,
              child: const Text('Cari lokasi lain'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'TaniAir adalah alat bantu. Rekomendasi berasal dari data prakiraan/model cuaca, bukan sensor fisik di lahan. Tetap periksa kondisi tanaman dan tanah secara langsung.',
            ),
          ),
        ],
      ),
    );
  }
}
