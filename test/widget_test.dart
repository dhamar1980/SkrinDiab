import 'package:flutter_test/flutter_test.dart';
import 'package:skrin_diab/main.dart';

void main() {
  testWidgets('SkrinDiab App smoke test and splash transition',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SkrinDiabApp());

    // Verify SkrinDiab starts
    expect(find.byType(SkrinDiabApp), findsOneWidget);

    // Fast-forward through splash timer
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
