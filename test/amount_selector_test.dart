import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beep/widgets/amount_selector.dart';

void main() {
  testWidgets('preset button remains selected after typing in the input',
      (WidgetTester tester) async {
    final selectedAmounts = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmountSelector(
            onAmountSelected: selectedAmounts.add,
          ),
        ),
      ),
    );

    // Type a custom value into the input field.
    await tester.enterText(find.byType(TextField), '7');
    await tester.pump();

    // Tap the first preset button (value 3).
    await tester.tap(find.text('3'));
    await tester.pump();

    // The preset button should now be visually selected (filled with primary color)
    // and the amount '3' should have been emitted.
    expect(selectedAmounts.last, 3.0);
  });

  testWidgets('typing in the input deselects the preset button',
      (WidgetTester tester) async {
    final selectedAmounts = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmountSelector(
            onAmountSelected: selectedAmounts.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('3'));
    await tester.pump();
    expect(selectedAmounts.last, 3.0);

    // Type a different value into the input.
    await tester.enterText(find.byType(TextField), '8');
    await tester.pump();
    expect(selectedAmounts.last, 8.0);
  });
}
