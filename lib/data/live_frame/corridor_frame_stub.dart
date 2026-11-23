import 'package:flutter/widgets.dart';

/// Off the web: no corridor iframes.
abstract final class CorridorFrame {
  static int? loadedMs(String id) => null;
  static Widget view(
    Map<String, String> sites,
    int width,
    int height, {
    required String tint,
  }) => const SizedBox.shrink();
  static void place(String id, List<double>? matrix, {double opacity = 1}) {}
}
