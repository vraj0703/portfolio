---
name: web-profile
version: 1
description: Profile the portfolio's WEB build on a PHONE profile, the Flame half and the gallery half alike, so performance work starts from a trace instead of a guess. Use whenever the site lags, janks, stalls or "hangs" on a phone, before changing any code for speed, and to prove a speed change with before and after numbers.
---

# Profiling the web build on a phone

The site runs on phones as a web page: Dart compiled to JavaScript, Flame and Flutter drawn
by CanvasKit (Skia in WebAssembly) on the browser's main thread, and the gallery drawn by
flutter_scene through WebGL. A laptop hides most of its cost. This skill is the procedure for
measuring it the way a phone feels it, naming the cause from the trace, and proving a fix.

For **what to do about** gallery frame cost (instancing, LOD, culling, the post stack,
textures, shadows) see `.claude/skills/flutter_scene-performance`. This skill does not repeat
it; it gives you the trace that tells you whether you need it.

Everything below was run on the pc seat (Windows 11, Chrome 157, Flutter at this repo's
version) on 2026-11-16. Steps marked **not verified** were not run here.

## 1. Build so the trace is readable

```bash
flutter build web --profile --source-maps -o build/web-profile
```

- **`--profile` keeps Dart names.** In the profile build's `main.dart.js`, `SceneBloc`,
  `MyGame`, `ScrollDriver` and `TitleLayerComponent` appear by name, so the sampling profiler's
  top functions read as Dart (`_driveBoldTextStage$0`, `handleBeginFrame$1`). A release build
  minifies them.
- `--source-maps` writes `main.dart.js.map`; the names above did not need it, but keep it for
  the DevTools "Sources" view.
- **A profile build costs extra.** Flutter's Timeline reports through `performance.mark` and
  `measure`; in the flame-scroll trace that was about 1.6 s of a 20 s trace (`mark`, `measure`,
  and `clamp$2` under `_reportTaskEvent`). `tool/web_profile.py` reports it as
  `profile-build mark/measure ms`: subtract it, never blame it on the app.
- CanvasKit's own functions appear as `wasm-function[N]` (no names). Read them through their
  callers (`Surface.flush`, `Canvas.drawPicture`) and the WebGL calls they make
  (`texSubImage2D`, `getProgramParameter`, `createImageBitmap`).

Serve it locally (`python -m http.server PORT --directory build/web-profile`) or profile a
deployed preview.

## 2. Record a trace for a named scenario

```bash
python tool/web_profile.py record --url http://127.0.0.1:PORT/ --scenario flame-scroll --label before --runs 3 --out build/profile
```

What the tool does, so you can do it by hand if it breaks:

1. **Real Chrome, minimised, not headless** (`--start-minimized`,
   `--disable-features=CalculateNativeWinOcclusion`). Rendering continues while minimised.
   Headless is treated as a bot by PostHog and differs in GPU paths; don't use it to measure.
2. **Phone profile over CDP:** `Emulation.setDeviceMetricsOverride` 412 x 915 at DPR 2.625,
   `mobile: true`; an Android user agent (`Emulation.setUserAgentOverride`);
   `Emulation.setTouchEmulationEnabled`. Input is real touch: `Input.dispatchTouchEvent`
   start, moves, end. Do not also turn on `setEmitTouchEventsForMouse` and send mouse
   events; on this machine that hung the input channel.
3. **4x CPU** (`Emulation.setCPUThrottlingRate rate=4`) and **Fast 4G**
   (`Network.emulateNetworkConditions` latency 60 ms, 9 Mbps down, 1.5 up), cache off.
4. **Get to the scenario's start untraced:** wait for the logo screen (the screen's mean
   colour turns tan), tap until it leaves, wait for the title's entrance.
5. **Trace only the scenario:** `Tracing.start` with the categories in `CATEGORIES` (timeline,
   frames, V8 sampling profiler at 10 kHz, GC, GPU, screenshots), `transferMode
   ReturnAsStream`; run the touch script; `Tracing.end`; read the stream with `IO.read`.
6. Writes `LABEL-N.trace.json` (open it in DevTools' Performance panel or Perfetto) and
   `LABEL-N.summary.json`, then prints the spread over the runs.

Scenarios live in `SCENARIOS` in the tool:

| name | what it does | verified |
|---|---|---|
| `flame-scroll` | title, then eight swipes up half a second apart: the Flame scroll toward the gallery | yes |
| `gallery-walk` | the scroll in (untraced), then eight swipes down the corridor | **not verified** |

Add a scenario as a function; keep it scripted and identical between before and after.

## 3. What the summary gives, and how to read it

`python tool/web_profile.py read TRACE.json [...]` prints min / median / max across traces.

| number | where it comes from | what it means |
|---|---|---|
| frame p50 / p95, frames > 33 ms | intervals between `FireAnimationFrame` on the renderer main thread | the frame time a visitor gets: Flutter draws on requestAnimationFrame |
| first-touch frame | longest `FireAnimationFrame` within 1 s of the first `touchstart` | the "it hangs when I scroll" number |
| long tasks, longest task, stalls > 500 ms | `RunTask` on the main thread over 50 ms / over 500 ms | main-thread blocks; a stall over 500 ms is a visible freeze |
| script | union of `FireAnimationFrame`, `FunctionCall`, `EvaluateScript`, timers, microtasks | Dart work, plus CanvasKit's wasm (it runs inside these) |
| layout+paint | `Layout`, `Paint`, `UpdateLayoutTree`, `Commit` ... | the browser's own DOM work; small for a canvas app |
| gpu thread | `RunTask` on `CrGpuMain` / `VizCompositorThread` | raster and WebGL execution |
| gc | `MinorGC`, `MajorGC`, `V8.GC*` on the main thread | allocation pressure: many short pauses means per-frame allocation |
| top self time | V8 `ProfileChunk` samples, self time by function | the names to look at first |

Reading the top self time:

- **Dart names** (`update$1`, `_drive...`, `render`): your Dart is the cost. Follow callers.
- **`wasm-function[N]` with callers `Canvas.drawPicture` / `Surface.flush`**: CanvasKit
  rasterising the Flame/Flutter layer: draw cost (paths, text, shaders, layers).
- **`getProgramParameter` / `getShaderParameter`**: a shader program compiling. One long
  frame when an effect first appears. Usually the hang.
- **`texSubImage2D` / `createImageBitmap`**: image upload and decode; asset work.
- **`(garbage collector)`, many GC events**: allocation in the frame loop.
- **`mark`, `measure`, `_reportTaskEvent`**: profile-build instrumentation (subtract).

To pin a long frame to a cause, find its window and look at the samples inside it, then the
screenshot just before and after (`Screenshot` events, base64 JPEG) to see what was on screen.

## 4. Discipline

- **One hypothesis per change.** Name the cause from the trace, change one thing, measure.
- **Same scenario, same settings, same build mode** before and after.
- **At least 3 runs each**, and report the spread (min / median / max), not one number.
- **Max 3 runs per measurement**, window minimised, close what you open.
- A change that does not move the number it was meant to move is not a fix, whatever else
  moved.

## 5. Report template

```
Scenario: flame-scroll, Pixel profile 412x915 DPR 2.625, 4x CPU, Fast 4G, profile build
Hypothesis: <cause named from the trace, with the evidence: function, frame, screenshot>
Change: <commit>
                      before (3 runs)      after (3 runs)       min / median / max
first-touch frame ms  ...                  ...
frame p50 / p95 ms    ...                  ...
longest task ms       ...                  ...
long tasks            ...                  ...
gc ms (count)         ...                  ...
mark/measure ms       ...                  ...   (profile-build cost, excluded)
Not moved / next:     <what the trace still shows>
```

## 6. Worked example (2026-11-16)

The touch scroll from the title "hung" on a phone. The trace showed one 403-463 ms frame
0.4 s after the first touch, almost all `getProgramParameter` under `Surface.flush`. The
screenshots before and after it were identical: the cost was an effect starting to draw while
still invisible. `BoldTextComponent` skipped its fragment-shader draw until the scroll began,
so CanvasKit compiled that shader on the first scroll step. A one-pixel transparent draw on
the first frame moved the compile behind the loading screen. First-touch frame
403 / 420 / 463 ms became 49 / 56 / 60 ms; steady frames did not change (p50 about 44 ms at
4x), and the trace names what does: CanvasKit drawing the scene every frame and texture
uploads in `drawPicture`.

## Not verified here

- The `gallery-walk` scenario.
- Real phones over remote debugging (`chrome://inspect`). The emulated profile throttles the
  CPU but not a phone's GPU, so shader compiles and fill rate are worse on a real phone.
- iOS Safari, which has no CDP. Its Web Inspector timeline is the equivalent, by hand.
- WebAssembly builds (`--wasm`).
