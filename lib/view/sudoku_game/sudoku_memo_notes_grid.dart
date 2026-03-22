import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
/// 셀 안에 표시하는 3x3 후보(메모) 그리드
class SudokuMemoNotesGrid extends StatelessWidget {
  const SudokuMemoNotesGrid({super.key, required this.notes});

  final Set<int> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const SizedBox();
    }

    final noteColor = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: List.generate(9, (index) {
          final noteValue = index + 1;
          final isVisible = notes.contains(noteValue);
          return Center(
            child: Text(
              isVisible ? '$noteValue' : '',
              style: GoogleFonts.notoSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: noteColor,
              ),
            ),
          );
        }),
      ),
    );
  }
}
