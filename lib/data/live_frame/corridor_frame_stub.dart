import 'package:flutter/widgets.dart';

/// Off the web: no corridor iframe.
abstract final class CorridorFrame {
  static int? get loadedMs => null;
  static Widget view(
    String url,
    int width,
    int height, {
    required String tint,
  }) => const SizedBox.shrink();
  static void place(List<double>? matrix, {double opacity = 1}) {}
}
