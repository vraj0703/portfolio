// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/gallery/live_frames.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

class _Sink implements Analytics {
  final List<(String, Map<String, Object?>)> sent = [];
  @override
  void capture(String e, Map<String, Object?> p, {bool beforeUnload = false}) =>
      sent.add((e, p));
  @override
  void screen(String path, Map<String, Object?> p) {}
  @override
  bool flag(String key, {required bool orElse}) => orElse;
  @override
  Listenable get flagsChanged => ChangeNotifier();
  @override
  void captureException(Object error, StackTrace? stack) {}
}

void main() {
  late _Sink sink;
  late SceneBloc bloc;

  setUp(() {
    sink = _Sink();
    bloc = SceneBloc(events: SiteEvents(sink, viewport: () => (1280, 800)));
    bloc.emit(const SceneState.gallery());
  });
  tearDown(() => bloc.close());

  Future<void> send(SceneEvent e) async {
    bloc.add(e);
    await Future<void>.delayed(Duration.zero);
  }

  LiveFrame live() => (bloc.state as Gallery).live;

  group(
    'the focused frame\'s live site is a rule on the scene (PORTFOLIO-6)',
    () {
      test(
        'asked for: loading; loaded: live, and project_live_viewed',
        () async {
          await send(
            const SceneEvent.liveFrameRequested(projectId: 'shunya-systems'),
          );
          expect(live().status, LiveFrameStatus.loading);
          expect(live().projectId, 'shunya-systems');
          await send(const SceneEvent.liveFrameLoaded(ms: 840));
          expect(live().status, LiveFrameStatus.live);
          final viewed = sink.sent.where((e) => e.$1 == 'project_live_viewed');
          expect(viewed, hasLength(1));
          expect(viewed.single.$2['id'], 'shunya-systems');
          expect(viewed.single.$2['ms_to_load'], 840);
        },
      );

      test('it failed: the picture stays, no live view counted', () async {
        await send(
          const SceneEvent.liveFrameRequested(projectId: 'shunya-systems'),
        );
        await send(const SceneEvent.liveFrameFailed());
        expect(live().status, LiveFrameStatus.failed);
        expect(sink.sent.where((e) => e.$1 == 'project_live_viewed'), isEmpty);
      });

      test('focus left: down at once; a late load is a stray', () async {
        await send(
          const SceneEvent.liveFrameRequested(projectId: 'shunya-systems'),
        );
        await send(const SceneEvent.liveFrameEnded());
        expect(live(), LiveFrame.none);
        await send(const SceneEvent.liveFrameLoaded(ms: 900));
        expect(live(), LiveFrame.none);
        expect(sink.sent.where((e) => e.$1 == 'project_live_viewed'), isEmpty);
      });

      test('a frame without a live site asks for nothing', () async {
        await send(
          const SceneEvent.liveFrameRequested(projectId: 'twin-health'),
        );
        expect(live(), LiveFrame.none);
      });

      test('outside the gallery the events are strays', () async {
        bloc.emit(const SceneState.title());
        await send(
          const SceneEvent.liveFrameRequested(projectId: 'shunya-systems'),
        );
        expect(bloc.state, isA<Title>());
      });
    },
  );
}
