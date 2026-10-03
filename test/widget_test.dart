import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flight_experience/main.dart';

void main() {
  testWidgets('App smoke test builds HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlightExperienceApp()));
    expect(find.text('Flight Experience'), findsWidgets);
    expect(find.text('Choose experience'), findsOneWidget);
  });
}
