import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/theme/level_status_colors.dart';

/// 인식이 애매할 때 보이는 후보 선택 바: 후보 숫자들 + "다시 쓰기".
/// 선택 전에는 오답으로 계산되지 않는다.
class PencilCandidateBar extends StatelessWidget {
  const PencilCandidateBar({
    super.key,
    required this.candidates,
    required this.onChoose,
    required this.onRewrite,
  });

  final List<int> candidates;
  final ValueChanged<int> onChoose;
  final VoidCallback onRewrite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = LevelStatusPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.pencilCandidatesTitle,
      child: Material(
        color: cs.surface,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.completedBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.pencilCandidatesTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final digit in candidates)
                    SizedBox(
                      width: 56,
                      height: 52,
                      child: FilledButton(
                        key: ValueKey('pencil-candidate-$digit'),
                        onPressed: () => onChoose(digit),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: palette.completedBackground,
                          foregroundColor: palette.primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: palette.completedBorder),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text('$digit'),
                      ),
                    ),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      key: const ValueKey('pencil-rewrite'),
                      onPressed: onRewrite,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(l10n.pencilRewrite),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 최초로 필기를 켰을 때 한 번만 보이는 비모달 안내.
class PencilCoachmark extends StatelessWidget {
  const PencilCoachmark({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = LevelStatusPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: cs.surface,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.completedBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.draw_outlined, color: palette.primaryPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.pencilWritingCoachmark,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('pencil-coachmark-ok'),
                onPressed: onDismiss,
                child: Text(l10n.commonOk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
