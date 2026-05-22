import 'package:flutter_test/flutter_test.dart';
import 'package:quotebuilder/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QuoteBuilderApp());
    expect(find.text('QuoteBuilder'), findsOneWidget);
  });
}
