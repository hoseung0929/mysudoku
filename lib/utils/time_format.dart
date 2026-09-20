/// 경과 시간 표기: 1시간 미만은 MM:SS, 1시간 이상은 H:MM:SS.
/// 게임 타이머·퍼즐 목록·완료 화면·공유 문구가 같은 형식을 쓰도록 한 곳에 둔다.
String formatElapsedSeconds(int totalSeconds) {
  final total = totalSeconds < 0 ? 0 : totalSeconds;
  final hours = total ~/ 3600;
  final mm = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
  final ss = (total % 60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}
