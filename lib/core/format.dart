/// Number formatting for idle-game magnitudes: 999 → 1.00K → ... → 1.00aa.
String fmt(double v) {
  if (v.isNaN) return '0';
  if (v.isInfinite) return '∞';
  final neg = v < 0;
  var x = v.abs();
  String out;
  if (x < 1000) {
    out = x < 10 && x != x.roundToDouble()
        ? x.toStringAsFixed(1)
        : x.floor().toString();
  } else {
    const units = ['K', 'M', 'B', 'T'];
    var idx = -1;
    while (x >= 1000 && idx < 1000) {
      x /= 1000;
      idx++;
    }
    final unit = idx < units.length ? units[idx] : _letters(idx - units.length);
    final digits = x >= 100 ? 0 : (x >= 10 ? 1 : 2);
    out = '${x.toStringAsFixed(digits)}$unit';
  }
  return neg ? '-$out' : out;
}

String _letters(int i) {
  const a = 97;
  return String.fromCharCode(a + (i ~/ 26) % 26) + String.fromCharCode(a + i % 26);
}

/// Rate per second, e.g. "+1.2K/秒".
String fmtRate(double perSecond) => '${perSecond >= 0 ? '+' : ''}${fmt(perSecond)}/秒';

/// "3時間12分", "45分", "30秒".
String fmtDuration(Duration d) {
  if (d.inHours > 0) {
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours}時間' : '${d.inHours}時間$m分';
  }
  if (d.inMinutes > 0) return '${d.inMinutes}分';
  return '${d.inSeconds}秒';
}

/// "29:59" style countdown.
String fmtClock(Duration d) {
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

String fmtPercent(double ratio) => '${(ratio * 100).toStringAsFixed(ratio < 0.1 ? 1 : 0)}%';
