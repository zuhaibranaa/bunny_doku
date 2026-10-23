import 'package:bunny_doku/presentation/widgets/how_to_play_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tutorial grid animation loops forever, so `pumpAndSettle` would never
/// return. Pump a fixed slice of time instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('HowToPlayDialog', () {
    testWidgets('opens with the title and the first rule', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HowToPlayDialog()),
      ));
      await settle(tester);

      expect(find.text('How to Play'), findsOneWidget);
      expect(find.text('One bunny per colour region'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('walks forward through every rule', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HowToPlayDialog()),
      ));
      await settle(tester);

      const titles = [
        'One bunny per colour region',
        'One bunny per row',
        'One bunny per column',
        'No touching bunnies',
        'How to place and mark',
      ];

      for (var i = 1; i < titles.length; i++) {
        await tester.tap(find.text('Next'));
        await settle(tester);
        expect(find.text(titles[i]), findsOneWidget,
            reason: 'step $i should show "${titles[i]}"');
      }

      // The last step swaps the button for the closing action.
      expect(find.text("Let's Play"), findsOneWidget);
    });

    testWidgets('Back returns to the previous rule', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HowToPlayDialog()),
      ));
      await settle(tester);

      await tester.tap(find.text('Next'));
      await settle(tester);
      expect(find.text('One bunny per row'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await settle(tester);
      expect(find.text('One bunny per colour region'), findsOneWidget);
    });

    testWidgets('renders one page dot per step', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HowToPlayDialog()),
      ));
      await settle(tester);

      // 5 steps -> 5 dots. The active one is wider, the rest are small.
      expect(find.byType(AnimatedContainer), findsNWidgets(5));
    });

    testWidgets('Skip closes the dialog', (tester) async {
      var finished = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => HowToPlayDialog.show(
                context,
                onFinished: () => finished = true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await settle(tester);
      expect(find.text('How to Play'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await settle(tester);

      expect(find.text('How to Play'), findsNothing);
      expect(finished, isTrue);
    });
  });
}
