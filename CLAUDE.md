# portfolio

A Flutter web portfolio at https://www.vishalraj.space. The front half is a
Flame game; the gallery is `flutter_scene` on Flutter GPU. See `README.md` for
what the site actually is — this file is about how to work on it.

## Rules

These are not suggestions. Code that breaks one reads as foreign against
everything around it.

- **No `StatefulWidget` until genuinely required.** Reach for implicit
  animations (`AnimatedOpacity`, `TweenAnimationBuilder`) and
  `ValueListenableBuilder` first. `SceneView` draws the curtain *and* owns the
  Flame game while staying stateless; that is the standard to meet. Legitimate
  reasons so far: owning a `Ticker`, holding GPU resources that must be
  released, or scroll position that must survive rebuilds (`GalleryView`). When
  one applies, say which in the doc comment.
- **Always a `StatelessWidget` class, never a function returning a widget.**
  A builder function cannot be `const`, cannot be keyed, and rebuilds with its
  parent.
- **No mutable service inside immutable data.** `ScenePalette` carries theme
  *values*; `AppAudio` is passed alongside it. Putting the audio backend in the
  palette let two palettes compare equal while sharing different mute state.
- **Blocs come from DI**, never constructed inline. See `data/di/injection.dart`.
- **Every colour, text style and string lives in `domain/style/`.** No literal
  `Color(0x...)`, `TextStyle(...)` or user-facing string at its point of use.
  Reach them through `context.colors`, `context.typography`, `context.strings`,
  `context.audio`.
- **Version control is the user's.** Do not `git add`, `git commit` or
  `git push` unless asked in that message. Make the change, run analyse and
  test, report, leave it uncommitted.

## Architecture

Three layers, and the dependency arrow only points inward.

- **`domain/`** — the numbers and the pure logic over them. No Flutter where it
  can be helped, no GPU, no I/O. This is the part the tests are about:
  `GalleryCameraPath`, `WalkOrder`, `ScrollDriver`, `Crossing`,
  `LoadingProgress`, `GalleryLayout`, the timelines, and all of `style/`.
- **`data/`** — the DI container, the audio backend, the radio (with a
  conditional import for web), the contact links. Implementations of `domain/`
  interfaces.
- **`presentation/`** — `SceneBloc`, the Flame components, the gallery, the
  widgets over both.

### `SceneBloc` is the single authority

A `freezed` union — `loading → logo → logoOverlayRemoving → titleLoading →
title → active → gallery → contact` — and the UI is a pure function of it.
Widgets read state and render; they never drive the sequence.

Three conventions hold it together, and breaking any of them has already
caused a bug worth remembering:

1. **Every handler guards on the current state.** `if (state is! Gallery)
   return null;`. An event from a stage that cannot raise it is a stray.
2. **Cross-cutting rules live on the state, not in the widgets.**
   `showsMark`, `playsRadio`, `showsMenu`, `isScrollable`, `isInteractable`.
   Three layers each keeping their own copy of "which stages centre the mark"
   is three chances to forget one when a stage is added.
3. **Transitions are reported, not timed.** The layer that finished an
   animation raises the event. The bloc never guesses a duration, because a
   guessed duration drifts the moment the animation is retuned.

### What deliberately stays out of the bloc

Anything that changes every frame. A bloc emitting sixty states a second to
carry a double is the wrong instrument.

- `ScrollDriver` owns position *within* a stage (target vs offset, spring
  between them). The bloc owns which stage.
- `GalleryView` uses `ValueNotifier` for `_leaving` and `_markJourney` so one
  rectangle rebuilds, not the corridor.

### Flame has no `BuildContext`

Components sit outside the widget tree, so they cannot read `context.colors`.
`ScenePalette.of(context)` resolves a snapshot at the widget layer and hands it
down. It is a snapshot, not a live binding — a theme change after construction
will not reach it, and the fix when that matters is to rebuild the game.

## Gotchas that have already cost time

- **Never name a `ThemeExtension` field `type`.** `ThemeExtension.type` is the
  key Flutter files extensions under; shadowing it makes
  `Theme.of(context).extension<T>()` silently return null. The field is
  `typography`.
- **`late final Ticker _clock = createTicker(...)..start();` never runs** if
  nothing reads it before `dispose()`. Initialise tickers in `initState`.
- **Anything painted on a gallery wall must clear half the wall's thickness.**
  Walls are slabs centred on their nominal plane, so a sign nudged a
  millimetre toward the room is still buried inside it. See
  `GalleryLayout.paintedOnWall`.
- **A transparent texture needs `AlphaMode.blend` on its material.** On an
  opaque material the renderer ignores alpha and the cleared background
  rasterises solid black, so a sign arrives as a slab.
- **Perspective `Transform` breaks hit-testing.** Hit regions go *outside* the
  transform; a `MouseRegion` inside a non-affine one never fires.
- **Web audio is refused before the first interaction.** Every cue is bound to
  a state change at or after the opening tap.

## Commands

```bash
flutter run -d chrome
flutter run --enable-flutter-gpu   # desktop; the gallery needs Flutter GPU
flutter analyze
flutter test
flutter build web --release
```

`flutter analyze` must be clean and `flutter test` green before reporting a
change done.

**Goldens are excluded in CI and that is deliberate** — the reference images
were rendered on Windows and a Linux runner rasterises type differently enough
to fail every one. `flutter test` locally runs them; CI runs
`flutter test --exclude-tags golden`. Do not "fix" a golden by regenerating it
on another machine.

## Publishing

Push to `master` → analyse, test, build in one job, deploy in a second that
`needs:` it. Firebase project `vishal-raj-space-firebase-home`, deliberately
separate from the two scene sites: Hosting replaces a site's entire contents on
every deploy.

The live host is **`www.vishalraj.space`**. The bare apex reaches Firebase but
is not attached to this site.
