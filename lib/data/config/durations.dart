import 'package:portfolio/domain/config/durations.dart';

class AppDurationsImpl implements AppDurations {
  @override
  Duration get blinking => const Duration(milliseconds: 500);

  @override
  Duration get reveal => const Duration(seconds: 1);
}
