import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassSwipeActions', () {
    testWidgets('renders primary child initially without showing actions',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassSwipeActions(
            trailingActions: [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            child: SizedBox(
              height: 50,
              width: 300,
              child: Text('Primary Row Content'),
            ),
          ),
        ),
      );

      expect(find.text('Primary Row Content'), findsOneWidget);
      // In the Stack, the platter is not built when directionalOffset == 0
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('drag left reveals trailing actions and settles open',
        (tester) async {
      var state = GlassSwipeState.idle;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            onSwipeStateChanged: (s) => state = s,
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              height: 50,
              width: 400,
              child: Text('Row Item'),
            ),
          ),
        ),
      );

      // Drag left to reveal trailing action
      await tester.drag(find.text('Row Item'), const Offset(-100, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(state, GlassSwipeState.openTrailing);
    });

    testWidgets('tapping revealed action executes onTap and closes by default',
        (tester) async {
      var actionTapped = false;
      var state = GlassSwipeState.idle;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            onSwipeStateChanged: (s) => state = s,
            trailingActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.trash),
                label: const Text('Delete'),
                onTap: () => actionTapped = true,
              ),
            ],
            child: const SizedBox(
              height: 50,
              width: 400,
              child: Text('Row Item'),
            ),
          ),
        ),
      );

      // Open trailing action
      await tester.drag(find.text('Row Item'), const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(state, GlassSwipeState.openTrailing);

      // Tap action
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(actionTapped, isTrue);
      expect(state, GlassSwipeState.idle);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('closeOnTap: false keeps row open after action tap',
        (tester) async {
      var actionTapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            trailingActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.flag),
                label: const Text('Flag'),
                closeOnTap: false,
                onTap: () => actionTapped = true,
              ),
            ],
            child: const SizedBox(
              height: 50,
              width: 400,
              child: Text('Row Item'),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Row Item'), const Offset(-100, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flag'));
      await tester.pumpAndSettle();

      expect(actionTapped, isTrue);
      // Row stays open
      expect(find.text('Flag'), findsOneWidget);
    });

    testWidgets('drag right reveals leading actions', (tester) async {
      var state = GlassSwipeState.idle;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            onSwipeStateChanged: (s) => state = s,
            leadingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.mail),
                label: Text('Read'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              height: 50,
              width: 400,
              child: Text('Row Item'),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Row Item'), const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(find.text('Read'), findsOneWidget);
      expect(state, GlassSwipeState.openLeading);
    });

    testWidgets('full swipe triggers outermost action automatically',
        (tester) async {
      var deleteTriggered = false;

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassSwipeActions(
              fullSwipeThreshold: 0.5,
              trailingActions: [
                GlassSwipeAction(
                  icon: const Icon(CupertinoIcons.trash),
                  label: const Text('Delete'),
                  onTap: () => deleteTriggered = true,
                ),
              ],
              child: const SizedBox(
                height: 50,
                width: 300,
                child: Text('Row Item'),
              ),
            ),
          ),
        ),
      );

      // Drag beyond 50% of 300 (e.g. -220px)
      await tester.drag(find.text('Row Item'), const Offset(-220, 0));
      await tester.pumpAndSettle();

      expect(deleteTriggered, isTrue);
      expect(find.text('Delete'), findsNothing); // returns closed
    });

    testWidgets('allowsFullSwipe: false disables auto-execution',
        (tester) async {
      var deleteTriggered = false;

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassSwipeActions(
              allowsFullSwipe: false,
              trailingActions: [
                GlassSwipeAction(
                  icon: const Icon(CupertinoIcons.trash),
                  label: const Text('Delete'),
                  onTap: () => deleteTriggered = true,
                ),
              ],
              child: const SizedBox(
                height: 50,
                width: 300,
                child: Text('Row Item'),
              ),
            ),
          ),
        ),
      );

      // Drag past threshold
      await tester.drag(find.text('Row Item'), const Offset(-250, 0));
      await tester.pumpAndSettle();

      // Action was NOT triggered automatically
      expect(deleteTriggered, isFalse);
      // Row is open at standard width
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('tapping shifted child closes row without triggering child tap',
        (tester) async {
      var childTapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            child: GestureDetector(
              onTap: () => childTapped = true,
              child: const SizedBox(
                height: 50,
                width: 400,
                child: Text('Clickable Child'),
              ),
            ),
          ),
        ),
      );

      // Open row
      await tester.drag(find.text('Clickable Child'), const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);

      // Tap on the shifted child (obscured by tap barrier, hence warnIfMissed: false)
      await tester.tap(find.text('Clickable Child'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Child was NOT tapped; row was closed instead
      expect(childTapped, isFalse);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('programmatic control via GlassSwipeController',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            controller: controller,
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            leadingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.mail),
                label: Text('Read'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              height: 50,
              width: 400,
              child: Text('Row Item'),
            ),
          ),
        ),
      );

      expect(controller.isOpen, isFalse);

      controller.openTrailing();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(controller.swipeState, GlassSwipeState.openTrailing);
      expect(find.text('Delete'), findsOneWidget);

      controller.close();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(find.text('Delete'), findsNothing);

      controller.openLeading();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(controller.swipeState, GlassSwipeState.openLeading);
      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('RTL layout mirrors swipe directions', (tester) async {
      var state = GlassSwipeState.idle;

      await tester.pumpWidget(
        createTestApp(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: GlassSwipeActions(
              onSwipeStateChanged: (s) => state = s,
              trailingActions: const [
                GlassSwipeAction(
                  icon: Icon(CupertinoIcons.trash),
                  label: Text('Delete'),
                  onTap: _noop,
                ),
              ],
              child: const SizedBox(
                height: 50,
                width: 400,
                child: Text('RTL Row Item'),
              ),
            ),
          ),
        ),
      );

      // In RTL, trailing is on the left, so dragging right (+dx) reveals trailing actions!
      await tester.drag(find.text('RTL Row Item'), const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(state, GlassSwipeState.openTrailing);
    });
  });

  group('GlassSwipeActionScope', () {
    testWidgets('enforces mutual exclusivity between rows', (tester) async {
      final controller1 = GlassSwipeController();
      final controller2 = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActionScope(
            child: Column(
              children: [
                GlassSwipeActions(
                  controller: controller1,
                  trailingActions: const [
                    GlassSwipeAction(
                      icon: Icon(CupertinoIcons.trash),
                      label: Text('Delete 1'),
                      onTap: _noop,
                    ),
                  ],
                  child: const SizedBox(
                    height: 50,
                    width: 400,
                    child: Text('Row 1'),
                  ),
                ),
                GlassSwipeActions(
                  controller: controller2,
                  trailingActions: const [
                    GlassSwipeAction(
                      icon: Icon(CupertinoIcons.trash),
                      label: Text('Delete 2'),
                      onTap: _noop,
                    ),
                  ],
                  child: const SizedBox(
                    height: 50,
                    width: 400,
                    child: Text('Row 2'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Open Row 1
      controller1.openTrailing();
      await tester.pumpAndSettle();
      expect(controller1.isOpen, isTrue);
      expect(controller2.isOpen, isFalse);

      // Open Row 2 -> Row 1 should automatically close
      controller2.openTrailing();
      await tester.pumpAndSettle();
      expect(controller1.isOpen, isFalse);
      expect(controller2.isOpen, isTrue);
    });

    testWidgets('scrolling closes open swipe row', (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActionScope(
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GlassSwipeActions(
                    controller: controller,
                    trailingActions: const [
                      GlassSwipeAction(
                        icon: Icon(CupertinoIcons.trash),
                        label: Text('Delete'),
                        onTap: _noop,
                      ),
                    ],
                    child: const SizedBox(
                      height: 50,
                      child: Text('Item 0'),
                    ),
                  );
                }
                return SizedBox(
                  height: 50,
                  child: Text('Item $index'),
                );
              },
            ),
          ),
        ),
      );

      controller.openTrailing();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      // Scroll the list
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
    });
  });

  group('GlassListTile swipe actions integration', () {
    testWidgets('renders GlassListTile with trailing and leading swipe actions',
        (tester) async {
      var deleteTapped = false;
      var readTapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            leading: const Icon(CupertinoIcons.mail),
            title: const Text('Inbox message'),
            leadingSwipeActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.mail),
                label: const Text('Mark Read'),
                backgroundColor: CupertinoColors.systemBlue,
                onTap: () => readTapped = true,
              ),
            ],
            trailingSwipeActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.trash),
                label: const Text('Delete'),
                isDestructive: true,
                onTap: () => deleteTapped = true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Inbox message'), findsOneWidget);

      // Swipe to reveal trailing action
      await tester.drag(find.text('Inbox message'), const Offset(-120, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleteTapped, isTrue);

      // Swipe to reveal leading action
      await tester.drag(find.text('Inbox message'), const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(find.text('Mark Read'), findsOneWidget);
      await tester.tap(find.text('Mark Read'));
      await tester.pumpAndSettle();
      expect(readTapped, isTrue);
    });
  });
}

void _noop() {}
