import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassEditScope & GlassEditButton', () {
    testWidgets('toggles edit mode ambiently and changes button text',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassEditScope(
            child: Column(
              children: [
                const GlassEditButton(),
                Builder(
                  builder: (context) {
                    final isEditing = GlassEditScope.isEditing(context);
                    return Text(isEditing ? 'Editing Mode' : 'View Mode');
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('View Mode'), findsOneWidget);

      // Tap Edit button to enter edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Editing Mode'), findsOneWidget);

      // Tap Done button to exit edit mode
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('View Mode'), findsOneWidget);
    });

    testWidgets('explicit GlassEditButton respects external state and callback',
        (tester) async {
      var toggled = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassEditButton.explicit(
            isEditing: true,
            onPressed: () => toggled = true,
          ),
        ),
      );

      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      expect(toggled, isTrue);
    });
  });

  group('GlassListTile Edit Mode', () {
    testWidgets('shows delete minus badge in edit mode and confirms deletion',
        (tester) async {
      var deleted = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            isEditing: true,
            title: const Text('Contact Name'),
            onDelete: () => deleted = true,
          ),
        ),
      );

      // Minus circle badge should be present
      final minusFinder = find.byIcon(CupertinoIcons.minus_circle_fill);
      expect(minusFinder, findsOneWidget);
      expect(find.text('Delete'), findsNothing);

      // Tap minus circle badge to reveal Delete button
      await tester.tap(minusFinder);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);

      // Tap Delete button
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('tapping tile body cancels delete confirmation',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            isEditing: true,
            title: const Text('Contact Name'),
            onDelete: _noop,
          ),
        ),
      );

      final minusFinder = find.byIcon(CupertinoIcons.minus_circle_fill);
      await tester.tap(minusFinder);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);

      // Tap on title to cancel confirmation
      await tester.tap(find.text('Contact Name'));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('shows insertion plus badge when onInsert is provided',
        (tester) async {
      var inserted = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            isEditing: true,
            title: const Text('Add Phone'),
            onInsert: () => inserted = true,
          ),
        ),
      );

      final plusFinder = find.byIcon(CupertinoIcons.plus_circle_fill);
      expect(plusFinder, findsOneWidget);

      await tester.tap(plusFinder);
      expect(inserted, isTrue);
    });

    testWidgets('shows selection checkbox in canSelect mode', (tester) async {
      var selected = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            isEditing: true,
            title: const Text('Selectable Item'),
            canSelect: true,
            isSelected: false,
            onSelectedChanged: (val) => selected = val,
          ),
        ),
      );

      final circleFinder = find.byIcon(CupertinoIcons.circle);
      expect(circleFinder, findsOneWidget);

      await tester.tap(circleFinder);
      expect(selected, isTrue);
    });

    testWidgets('shows reorder bars handle when canReorder is true',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassListTile(
            isEditing: true,
            title: Text('Reorderable Item'),
            canReorder: true,
            reorderIndex: 0,
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.bars), findsOneWidget);
      expect(find.byType(ReorderableDragStartListener), findsOneWidget);
    });

    testWidgets('inherits edit mode from ambient GlassEditScope',
        (tester) async {
      final controller = GlassEditController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassEditScope(
            controller: controller,
            child: GlassListTile(
              title: const Text('Scoped Item'),
              onDelete: _noop,
            ),
          ),
        ),
      );

      // Inactive initially
      expect(find.byIcon(CupertinoIcons.minus_circle_fill), findsNothing);

      // Activate edit mode
      controller.startEditing();
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.minus_circle_fill), findsOneWidget);
    });
  });

  group('GlassReorderableList', () {
    testWidgets('renders list and grouped card with dividers', (tester) async {
      final items = ['Item A', 'Item B', 'Item C'];

      await tester.pumpWidget(
        createTestApp(
          child: GlassReorderableList.grouped(
            header: const Text('GROUPED REORDERABLE'),
            footer: const Text('Drag items to reorder'),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return GlassListTile(
                key: ValueKey(items[index]),
                title: Text(items[index]),
                canReorder: true,
                reorderIndex: index,
              );
            },
            onReorder: (oldIndex, newIndex) {},
          ),
        ),
      );

      expect(find.text('GROUPED REORDERABLE'), findsOneWidget);
      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item B'), findsOneWidget);
      expect(find.text('Item C'), findsOneWidget);
      expect(find.byType(GlassCard), findsOneWidget);
      expect(find.byType(GlassDivider), findsWidgets);
    });
  });
}

void _noop() {}
