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
    this.cellExtent = 16,
  });

  final Set<int> notes;
  final int? highlightedNote;
  final bool isSingleCandidate;
  final bool isHiddenSingleCandidate;
  final double cellExtent;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const SizedBox();
    }

    final noteColor = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.85);
    final noteFontSize = (cellExtent * 0.62).clamp(7.0, 10.0);
    final emphasizedNoteFontSize = (cellExtent * 0.7).clamp(8.0, 11.0);
    final noteRadius = (cellExtent * 0.38).clamp(4.0, 6.0);
    final gridPadding = (cellExtent * 0.18).clamp(1.5, 3.0);

    return Padding(
      padding: EdgeInsets.all(gridPadding),
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
              width: cellExtent,
              height: cellExtent,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isHiddenSingleNote
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.28)
                    : isHighlighted
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                    : isSingleCandidateNote
                        ? const Color(0xFFF1E5CD)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(noteRadius),
              ),
              child: Text(
                isVisible ? '$noteValue' : '',
                style: GoogleFonts.notoSans(
                  fontSize:
                      isHighlighted || isSingleCandidateNote || isHiddenSingleNote
                          ? emphasizedNoteFontSize
                          : noteFontSize,
                  fontWeight:
                      isHighlighted || isSingleCandidateNote || isHiddenSingleNote
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: isHiddenSingleNote
                      ? Theme.of(context).colorScheme.primary
                      : isHighlighted
                      ? Theme.of(context).colorScheme.primary
                      : isSingleCandidateNote
                          ? const Color(0xFFB87638)
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
