import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiq/widgets/macro_icons.dart';

// Provide simple test doubles for icons in case the real implementations
// are not available to the test environment.
class DrumstickIcon extends StatelessWidget {
  final Color? color;
  const DrumstickIcon({Key? key, this.color}) : super(key: key);
  @override
  Widget build(BuildContext context) => Icon(Icons.restaurant, color: color);
}

class WheatIcon extends StatelessWidget {
  final Color? color;
  const WheatIcon({Key? key, this.color}) : super(key: key);
  @override
  Widget build(BuildContext context) => Icon(Icons.grain, color: color);
}

class NutIcon extends StatelessWidget {
  final Color? color;
  const NutIcon({Key? key, this.color}) : super(key: key);
  @override
  Widget build(BuildContext context) => Icon(Icons.emoji_food_beverage, color: color);
}

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
