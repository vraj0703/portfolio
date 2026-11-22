import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/frame_captures.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/live_frames.dart';
import 'package:portfolio/domain/gallery/project_data.dart';

void main() {
  group('a frame shows its live site, captured (PORTFOLIO-6)', () {
    test('Shunya Systems has a capture; a project without one has none', () {
      expect(FrameCaptures.assetFor('shunya-systems'), isNotNull);
      expect(FrameCaptures.assetFor('twin-health'), isNull);
      for (final id in FrameCaptures.projects) {
        expect(
          GalleryProjects.all.map((p) => p.id),
          contains(id),
          reason: 'a capture for a project that is not in the corridor',
        );
      }
    });

    test('the picture is on disk, listed, at the card\'s shape', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final id in FrameCaptures.projects) {
        final pic = FrameCaptures.assetFor(id)!;
        expect(File(pic).existsSync(), isTrue, reason: pic);
        expect(pubspec, contains('- $pic'));
        expect(pubspec, contains('- ${FrameCaptures.recordFor(id)}'));
        final record =
            jsonDecode(File(FrameCaptures.recordFor(id)).readAsStringSync())
                as Map<String, dynamic>;
        expect(record['captured_at'], isNotEmpty);
        expect(record['tool'], 'tool/capture_frame.py');
        final size = (record['picture'] as String).split('x').map(int.parse);
        final cardW = GalleryLayout.frameWidth - GalleryLayout.frameBorder * 2;
        final cardH = 3.0 - GalleryLayout.frameBorder * 2;
        expect(size.first / size.last, closeTo(cardW / cardH, 0.01));
      }
    });

    test('the capture and the live iframe share one page size', () {
      // tool/capture_frame.py reads LiveFrames.virtualWidth/Height; the
      // iframe is that size scaled to the card, so both show one layout.
      final tool = File('tool/capture_frame.py').readAsStringSync();
      expect(tool, contains('static const int virtualWidth'));
      expect(tool, contains('static const int virtualHeight'));
      for (final id in FrameCaptures.projects) {
        final record =
            jsonDecode(File(FrameCaptures.recordFor(id)).readAsStringSync())
                as Map<String, dynamic>;
        expect(
          record['viewport'],
          '${LiveFrames.virtualWidth}x${LiveFrames.virtualHeight}',
        );
      }
    });
  });
}
