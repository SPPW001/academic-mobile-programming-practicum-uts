import 'package:flutter_test/flutter_test.dart';
import 'package:taniair/main.dart';

void main() {
  testWidgets('TaniAir dapat dijalankan', (WidgetTester tester) async {
    await tester.pumpWidget(const TaniAirApp());

    expect(find.text('TaniAir'), findsOneWidget);
    expect(find.text('Cari lokasi lahan Anda'), findsOneWidget);
  });
}
