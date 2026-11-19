import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portfolio/data/di/dependency_manager.dart';
import 'package:portfolio/domain/analytics/analytics.dart';
import 'package:portfolio/domain/audio/app_audio.dart';
import 'package:portfolio/domain/radio/radio_player.dart';
import 'package:portfolio/domain/radio/radio_station.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';
import 'package:portfolio/presentation/bloc/scene_bloc.dart';
import 'package:portfolio/presentation/gallery/radio_face.dart';
import 'package:portfolio/presentation/gallery/wall_radio.dart';

/// How the drawer's radio looks (PORTFOLIO-25): like the wall's.
enum DrawerRadioLook {
  /// The wall's own baked face (RadioFace), reused, with hit areas for
  /// play or stop and next. A state the wall has not baked yet falls back
  /// to [text]: the drawer never renders a face as it opens.
  face,

  /// The wall's lettering (typeface, sizes, spacing, wording, layout) set as
  /// text in the drawer's ink.
  text,
}

abstract final class DrawerRadioConfig {
  /// The look that ships. One line to change.
  static const DrawerRadioLook chosen = DrawerRadioLook.text;

  /// [chosen], or `?pc-radio=face|text` on the URL, for shooting both.
  static final DrawerRadioLook current =
      switch (Uri.base.queryParameters['pc-radio']) {
        'face' => DrawerRadioLook.face,
        'text' => DrawerRadioLook.text,
        _ => chosen,
      };
}

/// The drawer's radio, directly under the close button, on every screen.
class DrawerRadio extends StatelessWidget {
  const DrawerRadio({super.key, this.look});

  /// The look; [DrawerRadioConfig.current] when null.
  final DrawerRadioLook? look;

  @override
  Widget build(BuildContext context) {
    final radio = locate<RadioPlayer>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: StreamBuilder<RadioState>(
        stream: radio.changes,
        initialData: radio.state,
        builder: (context, snapshot) {
          final state = snapshot.data ?? radio.state;
          final face = WallRadios.faceImages[WallRadios.faceKey(state)];
          final wanted = look ?? DrawerRadioConfig.current;
          if (wanted == DrawerRadioLook.face && face != null) {
            return _Face(image: face, state: state, radio: radio);
          }
          return _Lettering(state: state, radio: radio);
        },
      ),
    );
  }
}

/// Play or stop, and the next station: the same for both looks.
void _toggle(BuildContext context, RadioPlayer radio, RadioState state) {
  final on = state.isPlaying || state.isTuning;
  context.audio.play(AudioCue.click);
  // The bloc owns the radio: the press goes to it.
  context.read<SceneBloc>().queue(event: const SceneEvent.radioToggled());
  locate<SiteEvents>().radioToggled(on: !on, surface: 'drawer');
}

void _next(BuildContext context, RadioPlayer radio, RadioState state) {
  context.audio.play(AudioCue.click);
  unawaited(radio.next());
  locate<SiteEvents>().radioStationChanged(
    station: RadioDial.at(RadioDial.next(state.station)).name,
    surface: 'drawer',
  );
}

/// The wall's baked face, with its two controls made pressable.
class _Face extends StatelessWidget {
  const _Face({required this.image, required this.state, required this.radio});

  final ui.Image image;
  final RadioState state;
  final RadioPlayer radio;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final on = state.isPlaying || state.isTuning;
    return AspectRatio(
      aspectRatio: RadioFace.width / RadioFace.height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RawImage(image: image, fit: BoxFit.contain),
          // The control row is the face's last third: play or stop on the
          // left half, next on the right.
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.38,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: on
                          ? strings.drawerRadioStop
                          : strings.drawerRadioPlay,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _toggle(context, radio, state),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: strings.drawerRadioNext,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _next(context, radio, state),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The wall's lettering as text: its typeface, its sizes in proportion to
/// the drawer's width, its spacing, wording and layout.
class _Lettering extends StatelessWidget {
  const _Lettering({required this.state, required this.radio});

  final RadioState state;
  final RadioPlayer radio;

  @override
  Widget build(BuildContext context) {
    final ink = context.colors.menuText;
    final sign = context.typography.wallSign;
    final strings = context.strings;
    final on = state.isPlaying || state.isTuning;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The face is RadioFace.width pixels across at the wall's sizes.
        final k = constraints.maxWidth / RadioFace.width;
        TextStyle at(double size, double spacing) => sign.copyWith(
          fontSize: size * k,
          letterSpacing: spacing * k,
          height: 1.2,
          color: ink,
        );
        final control = at(106, 8);
        return Column(
          children: <Widget>[
            Text(
              state.tuned.name.toUpperCase(),
              style: at(sign.fontSize ?? 170, sign.letterSpacing ?? 18),
            ),
            Text(state.readout, style: at(93, 12)),
            SizedBox(height: RadioFace.stationGap * k),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextButton(
                  onPressed: () => _toggle(context, radio, state),
                  child: Text(
                    on ? 'STOP' : 'PLAY',
                    style: control,
                    semanticsLabel: on
                        ? strings.drawerRadioStop
                        : strings.drawerRadioPlay,
                  ),
                ),
                TextButton(
                  onPressed: () => _next(context, radio, state),
                  child: Text(
                    'NEXT',
                    style: control,
                    semanticsLabel: strings.drawerRadioNext,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
