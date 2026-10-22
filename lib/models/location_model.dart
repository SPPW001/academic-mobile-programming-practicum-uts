class LocationResult {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String? admin1;
  final String? admin2;
  final String? admin3;

  const LocationResult({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    this.admin1,
    this.admin2,
    this.admin3,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Lokasi tanpa nama',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      country: json['country']?.toString() ?? 'Indonesia',
      admin1: json['admin1']?.toString(),
      admin2: json['admin2']?.toString(),
      admin3: json['admin3']?.toString(),
    );
  }

  String get shortAddress {
    final parts = <String>[name];

    for (final value in [admin2, admin1]) {
      if (value != null &&
          value.trim().isNotEmpty &&
          !parts.contains(value.trim())) {
        parts.add(value.trim());
      }
    }

    return parts.join(', ');
  }

  String get detailAddress {
    final parts = <String>[];

    for (final value in [name, admin3, admin2, admin1, country]) {
      if (value != null &&
          value.trim().isNotEmpty &&
          !parts.contains(value.trim())) {
        parts.add(value.trim());
      }
    }

    return parts.join(', ');
  }
}
