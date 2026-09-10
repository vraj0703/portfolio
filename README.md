# portfolio

**Live: https://www.vishalraj.space**

A site you walk through rather than scroll. It opens on a mark and an
invitation; tapping it puts a name on screen, the name gives way to a line of
bold text, and the bold text hands over to a corridor of work you actually
walk down — pictures on both walls, a radio on, a hall at the far end with the
skills on a floating keyboard and a sign that leads to the contact screen.

Part of a set of three, each independent and each on its own Firebase project:

| | |
|---|---|
| Portfolio | https://www.vishalraj.space |
| Space scene | https://vishalraj-space-scene.web.app |
| Sea scene | https://vishalraj-sea-scene.web.app |

It replaces a React and Three.js site of the same shape. The work, the
testimonials, the skills and the radio's stations are ported across 1:1; the
rooms they sit in are rebuilt.

## Running it

```bash
flutter run -d chrome
```

The gallery draws through Flutter GPU, so on a desktop device it needs the
run flag:

```bash
flutter run --enable-flutter-gpu
```

## Two renderers, one scene

The site is halved, and the halves are drawn by different engines.

**The front half is a Flame game** — the loading curtain, the mark, the name,
the bold text. All 2D, all composited from shaders: five of them, in
[`assets/shaders`](assets/shaders), covering the moving background, the metal
the name is finished in, the god rays behind the mark, the star field the bold
text arrives through, and the mark's own SDF edge.

**The gallery is [`flutter_scene`][]** — a real room with real geometry, lit by
picture lights, walked with the scroll wheel.

[`flutter_scene`]: https://pub.dev/packages/flutter_scene

They coexist because neither is asked to do the other's job, and
[`SceneView`](lib/presentation/screen/scene_view.dart) is stateless despite
owning both: the curtain is a `TweenAnimationBuilder` over a value the state
machine already has, and `GameWidget.controlled` keeps the Flame instance alive
across rebuilds without a `State` to hold it.

## What the gallery is made of

**Nothing in the room is a widget.** The lettering cut into the walls, the
project frames, the testimonial boards — each is rasterised once to an image
and bound to a material. A live widget surface re-rasterises on its update
policy whether or not it is on screen, which puts a capture inside the render
loop for text that never changes; on the manual policy it never rasterises at
all. See [`wall_text.dart`](lib/presentation/gallery/wall_text.dart), which
also explains why the lettering needs a gold inlay to read as a groove rather
than a ridge.

**The plaster is generated, not shipped.** The detail maps are noise, and noise
is cheaper to compute than to download — a few milliseconds of loop against
hundreds of kilobytes of encoded randomness, and without the fixed authoring
resolution. Tiling is expressed as world units per repeat rather than a repeat
count, so a two-hundred-unit floor and a thirty-unit wall end up at the same
grain.

**The walk order is not the declaration order.** The corridor is something the
visitor physically moves down, so "next" steps to the piece they meet next — by
depth, along one wall. Stepping across the corridor would swing the camera
through a hundred and eighty degrees to face the wall behind them, which loses
them entirely. It is pure ordering in
[`walk_order.dart`](lib/domain/gallery/walk_order.dart) so the ends can be
tested; the two failures worth catching are both silent ones.

**The radio is somebody else's server.** Five SomaFM streams, and the only
thing on the site that depends on a service nobody here runs — so every part of
it survives that service being down, slow or blocked. It is on air in the
gallery and nowhere else, and that is a rule on the state
(`SceneState.playsRadio`) rather than a check at each call site: a stage added
later that forgets to switch it off leaves a stream playing under a title
screen, and nothing about that looks wrong in the code that added the stage.

## The stages

One `SceneBloc` over a `freezed` union: loading, logo, title, active (the bold
text), gallery, contact. Three of them share the logo screen's composition —
the mark centred on an empty ground — which is why `showsMark` is a rule on the
state rather than a list each layer keeps for itself. Three copies of one rule
is three chances to add a stage to two of them.

The transitions are reported, not timed. The logo layer says when its entrance
has finished; the bloc does not guess at a duration, because a guessed duration
drifts the moment the timeline is retuned.

## Loading

Three weighted phases in
[`loading_phase.dart`](lib/domain/models/loading_phase.dart) — the Flame game,
the gallery, and a priming pass that draws the finished gallery once behind the
curtain so its pipelines are compiled before anyone arrives in it. That last
one is a phase of its own precisely so the bar *waits* for it: the gallery is
the slow phase and finishes last, so without it the warm-up would get a single
frame, which is the same as not having one.

Weights are relative and normalised, so adding a phase never means rebalancing
the others.

## How it is arranged

- `domain/` — the numbers and the pure logic over them: the corridor's
  dimensions, the camera path, the walk order, the keyboard's layout, the
  timelines. No Flutter where it can be helped; this is the part the tests are
  about.
- `data/` — the container, the audio backend, the radio stream (with a
  conditional import for its web implementation) and the contact links.
- `presentation/` — the bloc, the Flame components, the gallery, and the
  widgets over both.

Colour, type, copy and sound all reach the tree the same way, as
`ThemeExtension`s off `domain/style/`, so no widget knows where any of them
came from. One caution encoded there: the extension's field is named
`typography`, never `type` — `ThemeExtension.type` is the key Flutter files
extensions under, and shadowing it makes the lookup silently find nothing.

## Tests

```bash
flutter test
```

649 of them. They cover the parts that fail quietly: that the walk order does
not run backwards, that the loading bar reaches 1.0, that every audio cue names
a file that is actually shipped, that the radio is off everywhere it should be.

Goldens are excluded in CI and it is not because they are flaky — the reference
images were rendered on Windows and a Linux runner rasterises type differently
enough to fail every one. Run `flutter test` locally, on the machine the images
came from; CI runs `flutter test --exclude-tags golden`. See
[`dart_test.yaml`](dart_test.yaml).

## What a crawler sees

The site is a canvas, so the root document has a title and little else.
[`web/static/index.html`](web/static/index.html) is the plain-text version —
the same words in real markup, with JSON-LD — and `robots.txt` points at it and
at the sitemap. It is served at `/static` by a rewrite in
[`firebase.json`](firebase.json).

## Publishing

A push to `master` runs analyse, test and build in one job, then deploys in a
second that `needs:` it — see
[`.github/workflows/deploy.yml`](.github/workflows/deploy.yml). The compile
happens once and travels between the jobs as an artifact, and a red test stops
the release outright, because `needs:` is a hard dependency. Pull requests
build and test but do not deploy.

Its Firebase project is `vishal-raj-space-firebase-home`, deliberately separate
from the two scenes': Firebase Hosting replaces a site's entire contents on
every deploy, so two things sharing one site would each wipe the other.

**Use `www.vishalraj.space`.** The bare apex reaches Firebase but answers 404 —
it is registered there without being attached to this site — so every apex URL
points a visitor, or a crawler, at nothing.
