class BoardCodec {
  const BoardCodec._();

  static String encode(List<List<int>> board) {
    return board.map((row) => row.join(',')).join(';');
  }

  static List<List<int>> decode(String payload) {
    final rows = payload.split(';');
    if (rows.length != 9) {
      throw FormatException('보드 행 수 오류: ${rows.length} (9 필요)', payload);
    }
    return rows.map((row) {
      final cells = row.split(',').map(int.parse).toList();
      if (cells.length != 9) {
        throw FormatException('보드 열 수 오류: ${cells.length} (9 필요)', row);
      }
      return cells;
    }).toList();
  }
}
