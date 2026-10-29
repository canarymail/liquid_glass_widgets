import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The materialize scope the anchor wraps its child in (the nearest one above
/// [key]'s widget).
GlassMaterializeScope _anchorScope(WidgetTester tester, Key key) =>
    tester.widget<GlassMaterializeScope>(find
        .ancestor(
            of: find.byKey(key), matching: find.byType(GlassMaterializeScope))
        .last);

Widget _app({required bool morphFromAnchor}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: const Alignment(0.6, -0.8),
        child: GlassMenuAnchor(
          child: SizedBox(
            key: const Key('capsule'),
            width: 120,
            height: 44,
            child: Row(
              children: [
                const SizedBox(key: Key('other'), width: 60, height: 44),
                GlassMenu(
                  morphFromAnchor: morphFromAnchor,
                  trigger: const SizedBox(
                    key: Key('trigger'),
                    width: 60,
                    height: 44,
                    child: ColoredBox(color: Colors.red),
                  ),
                  items: [
                    for (var i = 0; i < 3; i++)
                      GlassMenuItem(title: 'Item $i', onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('morphFromAnchor hides the whole anchor and restores it',
      (tester) async {
    // Arrange
    await tester.pumpWidget(_app(morphFromAnchor: true));
    final inputCapsule = tester.getRect(find.byKey(const Key('capsule')));
    expect(_anchorScope(tester, const Key('other')).glassProgress, 1.0);

    // Act: open.
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();

    // Assert: the anchor (sibling button included) is hidden, the trigger
    // itself is not faded on its own, and the menu body covers the capsule's
    // corner (its geometry comes from the anchor, not the trigger).
    final actualOpen = _anchorScope(tester, const Key('other'));
    expect(actualOpen.glassProgress, 0.0);
    expect(actualOpen.contentOpacity, 0.0);
    final triggerOpacity = tester.widget<Opacity>(find
        .ancestor(
            of: find.byKey(const Key('trigger')),
            matching: find.byType(Opacity))
        .first);
    expect(triggerOpacity.opacity, 1.0);
    final menuRect = tester.getRect(find.byType(GlassContainer).last);
    expect(menuRect.top, closeTo(inputCapsule.top, 0.5));
    expect(menuRect.right, closeTo(inputCapsule.right, 0.5));

    // Act: close.
    await tester.tapAt(const Offset(10, 500));
    await tester.pumpAndSettle();

    // Assert: restored.
    expect(_anchorScope(tester, const Key('other')).glassProgress, 1.0);
    expect(_anchorScope(tester, const Key('other')).contentOpacity, 1.0);
  });

  testWidgets('without morphFromAnchor the anchor is left alone',
      (tester) async {
    // Arrange
    await tester.pumpWidget(_app(morphFromAnchor: false));

    // Act
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();

    // Assert
    expect(_anchorScope(tester, const Key('other')).glassProgress, 1.0);
    final triggerOpacity = tester.widget<Opacity>(find
        .ancestor(
            of: find.byKey(const Key('trigger')),
            matching: find.byType(Opacity))
        .first);
    expect(triggerOpacity.opacity, 0.0);
  });
}
