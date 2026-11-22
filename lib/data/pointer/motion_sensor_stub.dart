import 'package:portfolio/domain/pointer/pointer_path.dart';

/// Off the web there is no tilt and no motion preference to read.
class MotionSensor {
  bool get prefersReducedMotion => false;
  TiltPermission get permission => TiltPermission.notNeeded;
  void requestPermission() {}
  void start(void Function(double beta, double gamma, double angle) onTilt) {}
  void stop() {}
}
