import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/gallery/frame_captures.dart';
import 'package:portfolio/domain/gallery/gallery_layout.dart';
import 'package:portfolio/domain/gallery/live_frames.dart';
import 'package:portfolio/domain/gallery/project_data.dart';

void main() {
  group('a frame shows its live site, captured (PORTFOLIO-6)', () {
    const live = 'https://www.vishalraj.space';

    test(
      'shunya.systems allows framing (shunya-site#9): its frame goes live',
      () {
        expect(
          LiveFrames.urlOf('shunya-systems', from: live),
          'https://shunya.systems',
        );
        expect(
          LiveFrames.urlOf('shunya-systems', from: 'https://vishalraj.space'),
          'https://shunya.systems',
        );
      },
    );

    test('the second frame is tantr: its page on the site, live the same '
        'way', () {
      expect(LiveFrames.siteFor('tantr'), 'https://shunya.systems/tantr/');
      expect(
        LiveFrames.urlOf('tantr', from: live),
        'https://shunya.systems/tantr/',
      );
      expect(LiveFrames.corridorIds(from: live), <String>[
        'shunya-systems',
        'tantr',
      ]);
    });

    test('a host the site does not name keeps the picture (and the link): '
        'the browser would put its refusal page in the frame', () {
      const preview = 'https://vishal-raj-space-firebase-home--pr-99-x.web.app';
      expect(LiveFrames.urlOf('shunya-systems', from: preview), isNull);
      expect(LiveFrames.urlOf('tantr', from: preview), isNull);
      expect(LiveFrames.corridorIds(from: preview), isEmpty);
      expect(LiveFrames.siteFor('tantr'), isNotNull);
      expect(LiveFrames.urlOf('twin-health', from: live), isNull);
    });

    test('?pc-live=ORIGIN points every live frame at its own page there', () {
      const local = 'http://127.0.0.1:8782';
      expect(
        LiveFrames.urlOf('shunya-systems', from: local, override: local),
        'http://127.0.0.1:8782',
      );
      expect(
        LiveFrames.urlOf('tantr', from: local, override: local),
        'http://127.0.0.1:8782/tantr/',
      );
      expect(LiveFrames.corridorIds(from: local, override: local), <String>[
        'shunya-systems',
        'tantr',
      ]);
    });

    test('Shunya Systems and tantr have captures; a project without one has '
        'none', () {
      expect(FrameCaptures.assetFor('shunya-systems'), isNotNull);
      expect(FrameCaptures.assetFor('tantr'), isNotNull);
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
        // The declared live source is the frame's own site, wherever the
        // picture was taken from.
        expect(record['url'], LiveFrames.siteFor(id), reason: id);
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
