import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medisathi/main.dart';

void main() {
  testWidgets('MediSathiApp loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MediSathiApp(),
      ),
    );
    await tester.pump();
    expect(find.text('MediSathi'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
  });
}
