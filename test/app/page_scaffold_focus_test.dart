import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The focus order of a [PageScaffold] whose body has scrolled. By default
/// Flutter orders controls by position on the screen, and controls scrolled
/// away above the view count as higher than the app bar, so Back would come
/// between them.
void main() {
  final list = [for (var i = 1; i <= 12; i++) 'B$i'];

  Widget app() => MaterialApp(
    initialRoute: '/list',
    routes: {
      '/': (_) => const SizedBox(),
      '/list': (_) => PageScaffold(
        title: 'List',
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Help',
            icon: const Icon(Icons.help),
          ),
        ],
        children: [
          for (final label in list)
            SizedBox(
              height: 80,
              child: TextButton(onPressed: () {}, child: Text(label)),
            ),
        ],
      ),
    },
  );

  Future<List<String>> press(
    WidgetTester tester,
    int n, {
    bool shift = false,
  }) async {
    final out = <String>[];
    for (var i = 0; i < n; i++) {
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      final focused = tester.binding.focusManager.primaryFocus!.context!;
      final tooltip = focused.findAncestorWidgetOfExactType<Tooltip>();
      final label = find.descendant(
        of: find.byWidget(focused.widget),
        matching: find.byType(Text),
      );
      out.add(tooltip?.message ?? tester.widget<Text>(label).data!);
    }
    return out;
  }

  testWidgets('Tab and Shift+Tab keep the app bar out of a scrolled body', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Forward: the app bar, the whole list, and round to the app bar.
    expect(await press(tester, 16), ['Back', 'Help', ...list, 'Back', 'Help']);
    // The list really scrolled: its first button is above the view.
    await press(tester, 12);
    expect(tester.getTopLeft(find.text('B1')).dy, lessThan(0));
    // Backward from the last button: the list in reverse, then the app bar.
    expect(await press(tester, 13, shift: true), [
      ...list.reversed.skip(1),
      'Help',
      'Back',
    ]);
  });
}
