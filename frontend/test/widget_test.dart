import 'package:flutter_test/flutter_test.dart';

import 'package:yourdreamcar/app/yourdreamcar_app.dart';

void main() {
  testWidgets('Splash then login', (WidgetTester tester) async {
    await tester.pumpWidget(const YourdreamcarApp());
    expect(find.text('Your Dream Car'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
