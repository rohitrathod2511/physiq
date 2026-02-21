import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiq/widgets/macro_icons.dart';

void main() {
  testWidgets('Macro Icons build correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              DrumstickIcon(color: Colors.red),
              WheatIcon(color: Colors.orange),
              NutIcon(color: Colors.blue),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(DrumstickIcon), findsOneWidget);
    expect(find.byType(WheatIcon), findsOneWidget);
    expect(find.byType(NutIcon), findsOneWidget);
  });
}
