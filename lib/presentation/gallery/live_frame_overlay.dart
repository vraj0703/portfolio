import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/data/live_frame/live_frame_view.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/contact/contact_links.dart';
import 'package:portfolio/domain/gallery/live_frames.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';

/// The focused frame's live site, laid exactly over its picture
/// (PORTFOLIO-6, layer 2), and the link that opens it in its own tab.
///
/// What is up is the scene's rule ([Gallery.live]); where the card is on
/// the screen is [cardRect], projected by the gallery each frame (a
/// rectangle a frame is not the bloc's business). The iframe only covers the
/// card: the frame's own controls sit below the moulding and stay reachable.
class LiveFrameOverlay extends StatelessWidget {
  const LiveFrameOverlay({required this.cardRect, super.key});

  /// The focused frame whose project has a site, and where its card is,
  /// once the camera has arrived square to it; null otherwise.
  final ValueListenable<FocusedCard?> cardRect;

  /// The link's height, above the card's top-right corner, on the moulding.
  static const double linkHeight = 32;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SceneBloc, SceneState, LiveFrame>(
      selector: (s) => s is Gallery ? s.live : LiveFrame.none,
      builder: (context, live) {
        return ValueListenableBuilder<FocusedCard?>(
          valueListenable: cardRect,
          builder: (context, card, _) {
            if (card == null) return const SizedBox.shrink();
            final id = card.projectId;
            final site = LiveFrames.siteFor(id);
            if (site == null) return const SizedBox.shrink();
            final rect = card.rect;
            final url = LiveFrames.urlFor(id);
            return Stack(
              children: <Widget>[
                // The live site, while the scene has it up for this frame.
                if (url != null && live.isUp && live.projectId == id)
                  Positioned.fromRect(
                    rect: rect,
                    child: _Loader(key: ValueKey<String>(id), url: url),
                  ),
                // Up, failed or loading alike: the way to the site is never
                // lost (a blocked frame shows the picture and this).
                Positioned(
                  right: (MediaQuery.sizeOf(context).width - rect.right).clamp(
                    0.0,
                    double.infinity,
                  ),
                  top: (rect.top - linkHeight - 4).clamp(0.0, double.infinity),
                  height: linkHeight,
                  child: _OpenSite(projectId: id, url: site),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// The iframe, and the clock on it. Stateful for the one reason the rules
/// allow: it owns a timer (the load's timeout), which it reports, as it
/// reports the load, to the scene.
class _Loader extends StatefulWidget {
  const _Loader({required this.url, super.key});

  final String url;

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  final Stopwatch _clock = Stopwatch();
  Timer? _timeout;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _clock.start();
    _timeout = Timer(LiveFrames.loadTimeout, () {
      if (_done || !mounted) return;
      _done = true;
      context.read<SceneBloc>().queue(
        event: const SceneEvent.liveFrameFailed(),
      );
    });
  }

  void _loaded() {
    if (_done || !mounted) return;
    _done = true;
    _timeout?.cancel();
    context.read<SceneBloc>().queue(
      event: SceneEvent.liveFrameLoaded(ms: _clock.elapsedMilliseconds),
    );
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LiveFrameView(
    url: widget.url,
    onLoaded: _loaded,
    fade: LiveFrames.crossFade,
  );
}

/// "open site": the site in its own tab, counted as the link out of a piece
/// always was (project_link_opened).
class _OpenSite extends StatelessWidget {
  const _OpenSite({required this.projectId, required this.url});

  final String projectId;
  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: colors.panelInk,
        backgroundColor: colors.panelSurface,
        minimumSize: const Size(48, LiveFrameOverlay.linkHeight),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: () {
        final uri = Uri.parse(url);
        locate<SiteEvents>().projectLinkOpened(projectId, uri.host);
        unawaited(locate<ContactLinks>().open(uri));
      },
      child: Text(context.strings.openSite),
    );
  }
}

/// The focused frame whose project has a site, and its card's rectangle on
/// the screen (set by the gallery once the camera has arrived).
@immutable
class FocusedCard {
  const FocusedCard({required this.projectId, required this.rect});

  final String projectId;
  final Rect rect;

  @override
  bool operator ==(Object other) =>
      other is FocusedCard &&
      other.projectId == projectId &&
      other.rect == rect;

  @override
  int get hashCode => Object.hash(projectId, rect);
}
