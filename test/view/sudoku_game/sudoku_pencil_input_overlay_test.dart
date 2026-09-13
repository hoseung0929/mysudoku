import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_pencil_input_overlay.dart';

void main() {
  Future<void> pumpOverlay(
    WidgetTester tester, {
    int? selectedRow,
    int? selectedCol,
    required void Function(int digit) onDigitEntered,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              SudokuPencilInputOverlay(
                selectedRow: selectedRow,
                selectedCol: selectedCol,
                cellExtent: 60,
                onDigitEntered: onDigitEntered,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders nothing when no cell is selected', (tester) async {
    await pumpOverlay(tester, onDigitEntered: (_) {});

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('renders an input field when a cell is selected', (tester) async {
    await pumpOverlay(tester, selectedRow: 2, selectedCol: 3, onDigitEntered: (_) {});

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('reports the recognized digit and clears the field', (tester) async {
    final recognized = <int>[];
    await pumpOverlay(
      tester,
      selectedRow: 0,
      selectedCol: 0,
      onDigitEntered: recognized.add,
    );

    await tester.enterText(find.byType(TextField), '5');
    await tester.pump();

    expect(recognized, [5]);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
  });

  testWidgets('extracts the first digit out of mixed recognized text',
      (tester) async {
    final recognized = <int>[];
    await pumpOverlay(
      tester,
      selectedRow: 0,
      selectedCol: 0,
      onDigitEntered: recognized.add,
    );

    await tester.enterText(find.byType(TextField), 'a9b');
    await tester.pump();

    expect(recognized, [9]);
  });

  testWidgets('ignores input with no recognizable digit', (tester) async {
    final recognized = <int>[];
    await pumpOverlay(
      tester,
      selectedRow: 0,
      selectedCol: 0,
      onDigitEntered: recognized.add,
    );

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();

    expect(recognized, isEmpty);
  });
}
