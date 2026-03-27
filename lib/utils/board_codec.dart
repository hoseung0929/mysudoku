class BoardCodec {
  const BoardCodec._();

  static String encode(List<List<int>> board) {
    return board.map((row) => row.join(',')).join(';');
  }

  static List<List<int>> decode(String payload) {
    return payload
        .split(';')
        .map((row) => row.split(',').map((cell) => int.parse(cell)).toList())
        .toList();
  }
}
