import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 셀 안에 표시하는 3x3 후보(메모) 그리드
class SudokuMemoNotesGrid extends StatelessWidget {
  const SudokuMemoNotesGrid({
    super.key,
    required this.notes,
    this.highlightedNote,
    this.isSingleCandidate = false,
    this.isHiddenSingleCandidate = false,
  });

  final Set<int> notes;
  final int? highlightedNote;
  final bool isSingleCandidate;
  final bool isHiddenSingleCandidate;

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
          final isHighlighted =
              isVisible && highlightedNote != null && highlightedNote == noteValue;
          final isSingleCandidateNote = isVisible && isSingleCandidate;
          final isHiddenSingleNote =
              isVisible && isHiddenSingleCandidate && highlightedNote == noteValue;
          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isHiddenSingleNote
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.28)
                    : isHighlighted
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                    : isSingleCandidateNote
                        ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.22)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isVisible ? '$noteValue' : '',
                style: GoogleFonts.notoSans(
                  fontSize:
                      isHighlighted || isSingleCandidateNote || isHiddenSingleNote
                          ? 10
                          : 9,
                  fontWeight:
                      isHighlighted || isSingleCandidateNote || isHiddenSingleNote
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: isHiddenSingleNote
                      ? Theme.of(context).colorScheme.primary
                      : isHighlighted
                      ? Theme.of(context).colorScheme.primary
                      : isSingleCandidateNote
                          ? Theme.of(context).colorScheme.tertiary
                      : noteColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
