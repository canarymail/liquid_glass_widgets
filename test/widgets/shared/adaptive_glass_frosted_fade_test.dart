import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The product of the [Opacity] widgets above the text.
double effectiveOpacity(WidgetTester tester, String text) {
  var opacity = 1.0;
  for (final widget in tester.widgetList<Opacity>(
    find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
  )) {
    opacity *= widget.opacity;
  }
  return opacity;
}

void main() {
  Future<void> pumpFrosted(WidgetTester tester, double visibility) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AdaptiveGlass(
              shape: const LiquidRoundedSuperellipse(borderRadius: 16),
              settings: LiquidGlassSettings(
                blur: 0,
                glassColor: const Color(0xFFFFFFFF),
                visibility: visibility,
              ),
              quality: GlassQuality.minimal,
              child: const Text('content'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('frosted fallback content', () {
    testWidgets('fades with visibility', (tester) async {
      await pumpFrosted(tester, 0.5);

      expect(effectiveOpacity(tester, 'content'), 0.5);
    });

    testWidgets('is not wrapped at full visibility', (tester) async {
      await pumpFrosted(tester, 1.0);

      expect(effectiveOpacity(tester, 'content'), 1.0);
    });
  });
}
