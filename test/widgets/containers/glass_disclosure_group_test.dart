import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassDisclosureGroup', () {
    testWidgets(
        'renders header and keeps children hidden when initiallyExpanded is false',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassDisclosureGroup(
            title: Text('Disclosure Title'),
            subtitle: Text('Disclosure Subtitle'),
            leading: Icon(CupertinoIcons.gear),
            initiallyExpanded: false,
            children: [
              Text('Child Row 1'),
              Text('Child Row 2'),
            ],
          ),
        ),
      );

      expect(find.text('Disclosure Title'), findsOneWidget);
      expect(find.text('Disclosure Subtitle'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.gear), findsOneWidget);

      // In the Align with heightFactor = 0, child is in tree but height is 0
      final alignFinder = find.byType(Align);
      expect(alignFinder, findsOneWidget);
      final align = tester.widget<Align>(alignFinder);
      expect(align.heightFactor, 0.0);
    });

    testWidgets(
        'tapping header toggles expansion and invokes onExpansionChanged',
        (tester) async {
      var expansionState = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassDisclosureGroup(
            title: const Text('Account Details'),
            onExpansionChanged: (val) => expansionState = val,
            children: const [
              Text('Child Account Info'),
            ],
          ),
        ),
      );

      // Tap to expand
      await tester.tap(find.text('Account Details'));
      await tester.pumpAndSettle();

      expect(expansionState, isTrue);
      var align = tester.widget<Align>(find.byType(Align));
      expect(align.heightFactor, 1.0);

      // Tap to collapse
      await tester.tap(find.text('Account Details'));
      await tester.pumpAndSettle();

      expect(expansionState, isFalse);
      align = tester.widget<Align>(find.byType(Align));
      expect(align.heightFactor, 0.0);
    });

    testWidgets('initiallyExpanded: true starts with heightFactor 1.0',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassDisclosureGroup(
            title: Text('Open Group'),
            initiallyExpanded: true,
            children: [
              Text('Visible Child'),
            ],
          ),
        ),
      );

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.heightFactor, 1.0);
    });

    testWidgets('controlled mode reflects isExpanded prop changes',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassDisclosureGroup(
            title: Text('Controlled Group'),
            isExpanded: false,
            children: [
              Text('Controlled Child'),
            ],
          ),
        ),
      );

      expect(tester.widget<Align>(find.byType(Align)).heightFactor, 0.0);

      // Re-pump with isExpanded: true
      await tester.pumpWidget(
        createTestApp(
          child: const GlassDisclosureGroup(
            title: Text('Controlled Group'),
            isExpanded: true,
            children: [
              Text('Controlled Child'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<Align>(find.byType(Align)).heightFactor, 1.0);
    });

    testWidgets('programmatic control via GlobalKey (expand, collapse, toggle)',
        (tester) async {
      final key = GlobalKey<GlassDisclosureGroupState>();

      await tester.pumpWidget(
        createTestApp(
          child: GlassDisclosureGroup(
            key: key,
            title: const Text('Key Controlled'),
            children: const [
              Text('Child Key'),
            ],
          ),
        ),
      );

      expect(key.currentState?.isExpanded, isFalse);

      key.currentState?.expand();
      await tester.pumpAndSettle();
      expect(key.currentState?.isExpanded, isTrue);

      key.currentState?.collapse();
      await tester.pumpAndSettle();
      expect(key.currentState?.isExpanded, isFalse);

      key.currentState?.toggle();
      await tester.pumpAndSettle();
      expect(key.currentState?.isExpanded, isTrue);
    });

    testWidgets(
        'standalone constructor renders with its own GlassContainer layer',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassDisclosureGroup.standalone(
            title: Text('Standalone Group'),
            children: [
              Text('Standalone Child'),
            ],
          ),
        ),
      );

      expect(find.byType(GlassContainer), findsOneWidget);
    });

    testWidgets(
        'custom headerBuilder overrides default header and triggers toggle',
        (tester) async {
      var toggled = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassDisclosureGroup(
            title: const Text('Ignored Title'),
            headerBuilder: (context, isExpanded, toggle) {
              return CupertinoButton(
                onPressed: () {
                  toggled = true;
                  toggle();
                },
                child: Text(isExpanded ? 'Custom Close' : 'Custom Open'),
              );
            },
            children: const [
              Text('Custom Content'),
            ],
          ),
        ),
      );

      expect(find.text('Custom Open'), findsOneWidget);
      await tester.tap(find.text('Custom Open'));
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
      expect(find.text('Custom Close'), findsOneWidget);
    });

    testWidgets(
        'integrates inside GlassGroupedSection with smart divider indentation',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassGroupedSection(
            children: [
              const GlassDisclosureGroup(
                leading: Icon(CupertinoIcons.folder),
                title: Text('Folders'),
                initiallyExpanded: true,
                children: [
                  GlassListTile(
                    title: Text('Subfolder 1'),
                  ),
                  GlassListTile(
                    title: Text('Subfolder 2'),
                  ),
                ],
              ),
              const GlassListTile(
                title: Text('General'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Folders'), findsOneWidget);
      expect(find.text('Subfolder 1'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);

      // Verifies GlassDividers are injected
      expect(find.byType(GlassDivider), findsWidgets);
    });

    testWidgets('chevron rotates properly in RTL text direction',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: GlassDisclosureGroup(
              title: Text('Arabic or Hebrew Title'),
              initiallyExpanded: true,
              children: [
                Text('RTL Child'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Arabic or Hebrew Title'), findsOneWidget);
      final rotationFinder = find.descendant(
        of: find.byType(GlassDisclosureGroup),
        matching: find.byType(RotationTransition),
      );
      expect(rotationFinder, findsOneWidget);
      final rotation = tester.widget<RotationTransition>(rotationFinder);
      // In RTL, turns is -0.25 (counter-clockwise 90 deg) to point down
      expect(rotation.turns.value, -0.25);
    });

    testWidgets('spring physics drives expansion and collapse smoothly',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassDisclosureGroup(
            title: const Text('Spring Disclosure'),
            spring: GlassSpring.snappy(),
            children: const [
              Text('Spring Child Content'),
            ],
          ),
        ),
      );

      // Tap to expand with spring physics
      await tester.tap(find.text('Spring Disclosure'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Mid-animation: height factor should be moving
      var align = tester.widget<Align>(find.byType(Align));
      expect(align.heightFactor! > 0.0, isTrue);

      // Settle spring
      await tester.pumpAndSettle();
      align = tester.widget<Align>(find.byType(Align));
      expect(align.heightFactor, 1.0);

      // Tap to collapse with spring physics
      await tester.tap(find.text('Spring Disclosure'));
      await tester.pumpAndSettle();
      align = tester.widget<Align>(find.byType(Align));
      expect(align.heightFactor, 0.0);
    });
  });
}
