/// Time source abstraction so game logic is testable.
abstract class Clock {
  int nowMs();
  DateTime nowLocal() => DateTime.fromMillisecondsSinceEpoch(nowMs());
}

class SystemClock extends Clock {
  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}

class FakeClock extends Clock {
  FakeClock(this.ms);
  int ms;
  @override
  int nowMs() => ms;
  void advance(Duration d) => ms += d.inMilliseconds;
}
