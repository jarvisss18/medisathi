import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisathi/features/scan/scan_screen.dart';

void main() {
  testWidgets('ScanScreen renders title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScanScreen(),
      ),
    );
    expect(find.text('Scan Medicine'), findsOneWidget);
  });
}
