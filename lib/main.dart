import 'package:flutter/material.dart';

import 'pages/home_page.dart';

void main() {
  runApp(const TaniAirApp());
}

class TaniAirApp extends StatelessWidget {
  const TaniAirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaniAir',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
