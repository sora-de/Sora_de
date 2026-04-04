import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorade/theme/app_theme.dart';

void main() {
  testWidgets('Sora de theme smoke', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSoraDeTheme(),
        home: const Scaffold(body: Text('Sorade test')),
      ),
    );
    expect(find.text('Sorade test'), findsOneWidget);
  });
}
