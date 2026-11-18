import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/gallery_exit_requests.dart';

/// The drawer's bottom bar: home (the title), the gallery, and the contact
/// page (PORTFOLIO-24).
///
/// It keeps no state. Which destination is current is the scene's to say
/// ([SceneState.navCurrent]); tapping another goes there through the same
/// events today's controls raise, so the gallery's lights-down and the
/// mark's transitions are kept, and closes the drawer. Tapping the current
/// one only closes it.
class DrawerNavBar extends StatelessWidget {
  const DrawerNavBar({super.key, required this.onClose});

  /// Closes the drawer (its own animated close).
  final Future<void> Function() onClose;

  static const double target = 48;
  static const double glyph = 24;

  /// The active indicator, Material 3 style, and the other icons' ink.
  static const double indicatorWidth = 64;
  static const double indicatorHeight = 32;
  static const double restingInk = 0.6;

  static const Map<NavDestination, String> icons = <NavDestination, String>{
    NavDestination.home: 'assets/vectors/home.svg',
    NavDestination.gallery: 'assets/vectors/gallery.svg',
    NavDestination.contact: 'assets/vectors/heart.svg',
  };

  static String labelFor(NavDestination d, AppStrings strings) => switch (d) {
    NavDestination.home => strings.navHome,
    NavDestination.gallery => strings.navGallery,
    NavDestination.contact => strings.menuConnect,
  };

  /// What going to [to] from [state] raises: the scene event, and whether
  /// it has to go through the gallery's own exit (its lights-down).
  static ({SceneEvent event, bool viaGalleryExit}) routeTo(
    NavDestination to,
    SceneState state,
  ) {
    final inGallery = state is Gallery;
    return switch (to) {
      NavDestination.home => (
        event: inGallery
            ? const SceneEvent.galleryExited()
            : const SceneEvent.homeRequested(),
        viaGalleryExit: inGallery,
      ),
      NavDestination.gallery => (
        event: const SceneEvent.galleryRequested(),
        viaGalleryExit: false,
      ),
      NavDestination.contact => (
        event: const SceneEvent.contactRequested(),
        viaGalleryExit: inGallery,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    return BlocSelector<SceneBloc, SceneState, NavDestination?>(
      selector: (state) => state.navCurrent,
      builder: (context, current) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            for (final d in NavDestination.values)
              Semantics(
                button: true,
                selected: d == current,
                label: labelFor(d, strings),
                excludeSemantics: true,
                child: InkResponse(
                  key: ValueKey<NavDestination>(d),
                  radius: target / 2,
                  onTap: () => unawaited(_go(context, d, current)),
                  child: SizedBox(
                    width: indicatorWidth,
                    height: target,
                    child: Center(
                      // A Material 3 style active indicator: a soft pill
                      // behind the current icon, the icon at full ink; the
                      // others at [restingInk]. The same in every scene.
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: indicatorWidth,
                        height: indicatorHeight,
                        decoration: BoxDecoration(
                          color: d == current
                              ? colors.menuNavIndicator
                              : colors.menuNavIndicator.withValues(alpha: 0),
                          borderRadius: BorderRadius.circular(
                            indicatorHeight / 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          icons[d]!,
                          height: glyph,
                          colorFilter: ColorFilter.mode(
                            d == current
                                ? colors.menuText
                                : colors.menuText.withValues(alpha: restingInk),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _go(
    BuildContext context,
    NavDestination to,
    NavDestination? current,
  ) async {
    final bloc = context.read<SceneBloc>();
    final audio = context.audio;
    locate<SiteEvents>().navSelected(
      destination: to.name,
      alreadyCurrent: to == current,
    );
    await onClose();
    if (to == current) return;
    final route = routeTo(to, bloc.state);
    if (route.viaGalleryExit) {
      GalleryExitRequests.instance.request(route.event);
      return;
    }
    audio.play(AudioCue.pageTurn);
    bloc.queue(event: route.event);
  }
}
