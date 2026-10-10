import 'package:flutter/material.dart';
import 'package:sudoku159/widgets/dialog_metrics.dart';

/// 완료·실패 다이얼로그가 공유하는 틀.
///
/// - 바깥 좌우 여백 최소 20, 최대 너비 400, 내부 좌우 여백 24.
/// - 전체 높이는 안전 영역 높이의 85% 이내. 본문이 길면 본문만 스크롤하고
///   버튼은 하단에 고정한다. 그래도 들어가지 않는 극단적 확대에서는 전체가
///   스크롤된다.
/// - 주요 버튼은 전체 너비·최소 높이 48, 보조 버튼은 최소 터치 높이 44.
class GameResultDialogFrame extends StatelessWidget {
  const GameResultDialogFrame({
    super.key,
    this.header,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final Widget? header;
  final List<Widget> body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final safeHeight =
        media.size.height - media.padding.top - media.padding.bottom;
    // 아이패드: 폭 480·여백 32·버튼 54(아이폰은 기존 값 그대로).
    final m = DialogMetrics.of(context);
    final sidePad = m.size(24.0, 32.0);

    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: onPrimary,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(m.size(48.0, 54.0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: m.isTablet ? const TextStyle(fontSize: 17) : null,
          ),
          child: Text(primaryLabel, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onSecondary,
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            foregroundColor: cs.onSurfaceVariant,
            textStyle: m.isTablet ? const TextStyle(fontSize: 16) : null,
          ),
          child: Text(secondaryLabel, textAlign: TextAlign.center),
        ),
      ],
    );

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: sidePad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            SizedBox(height: m.spacing(24.0, 32.0)),
            Center(child: header),
            SizedBox(height: m.spacing(12.0, 16.0)),
          ] else
            SizedBox(height: m.spacing(24.0, 32.0)),
          ...body,
          SizedBox(height: m.spacing(24.0, 28.0)),
        ],
      ),
    );

    return Dialog(
      backgroundColor: cs.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: m.inset(20), vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m.size(28.0, 30.0)),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: m.maxWidth(phone: 400, tablet: 480),
          maxHeight: safeHeight * 0.85,
        ),
        // 본문은 스크롤, 버튼은 하단 고정. 높이가 너무 작아 버튼까지 못 들어가는
        // 극단적인 경우에는 전체를 스크롤한다.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final buttonArea = Padding(
              padding: EdgeInsets.fromLTRB(
                sidePad,
                0,
                sidePad,
                m.spacing(20.0, 28.0),
              ),
              child: buttons,
            );
            if (constraints.maxHeight < 320) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [content, buttonArea],
                ),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(child: SingleChildScrollView(child: content)),
                buttonArea,
              ],
            );
          },
        ),
      ),
    );
  }
}
