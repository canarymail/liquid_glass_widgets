import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets(
      'GlassGroupedSection gives rows the card corners (top / square / bottom)',
      (tester) async {
    final captured = <BorderRadius?>[];

    Widget probe() => Builder(builder: (context) {
          captured.add(InheritedGlassSectionRow.maybeOf(context));
          return const SizedBox(height: 40);
        });

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            children: [probe(), probe(), probe()],
          ),
        ),
      ),
    );

    const r = Radius.circular(26);
    expect(captured, [
      const BorderRadius.vertical(top: r),
      BorderRadius.zero,
      const BorderRadius.vertical(bottom: r),
    ]);
  });

  testWidgets('a lone row carries all four card corners', (tester) async {
    BorderRadius? corners;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            children: [
              Builder(builder: (context) {
                corners = InheritedGlassSectionRow.maybeOf(context);
                return const SizedBox(height: 40);
              }),
            ],
          ),
        ),
      ),
    );
    expect(corners, BorderRadius.circular(26));
  });

  testWidgets('rows outside a section have no corner scope', (tester) async {
    BorderRadius? corners = BorderRadius.zero;
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(builder: (context) {
          corners = InheritedGlassSectionRow.maybeOf(context);
          return const SizedBox();
        }),
      ),
    );
    expect(corners, isNull);
  });
}
