import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennypal/app.dart';

void main() {
  testWidgets('PennyPal branding renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PennyPalTheme.light(),
        home: const Scaffold(
          body: Center(child: PennyPalLogo(showWordmark: true)),
        ),
      ),
    );

    expect(find.text('PennyPal'), findsOneWidget);
    expect(find.bySemanticsLabel('PennyPal logo'), findsOneWidget);
  });
}
