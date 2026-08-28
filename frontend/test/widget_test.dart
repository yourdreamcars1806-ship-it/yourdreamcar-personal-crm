import 'package:flutter_test/flutter_test.dart';

import 'package:yourdreamcar/app/yourdreamcar_app.dart';

void main() {
  testWidgets('Splash then marketplace home', (WidgetTester tester) async {
    await tester.pumpWidget(const YourdreamcarApp());
    expect(find.text('Your Dream Car'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.textContaining('Dream Car'), findsWidgets);
    expect(find.text('Welcome Back!'), findsNothing);
  });
}
