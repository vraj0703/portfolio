/// Off the web there is no browser to ask; every answer is "not told".
abstract final class Browser {
  static final Stopwatch _clock = Stopwatch()..start();

  static double now() => _clock.elapsedMicroseconds / 1000;
  static double? firstPaint() => null;
  static int? cores() => null;
  static double? memoryGb() => null;
  static String? connection() => null;
  static String? renderer() => null;
  static bool get visible => true;

  static void watch({
    required void Function() onHide,
    required void Function() onLeave,
  }) {}
}
