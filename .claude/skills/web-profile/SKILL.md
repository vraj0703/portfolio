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
| `journey` | traced **from navigation**: load, logo, title, the touch scroll into the gallery, a corridor walk, focusing a frame; each part marked `journey:<part>` | yes (Pixel profile) |

For "every stall over 100 ms, with its cause":

```bash
python tool/web_profile.py stalls build/profile/journey-1.trace.json --over 100
```

prints each main-thread task over the threshold: its time, its part of the journey (the last
`journey:` mark before it) and the top self time inside it, e.g.
`49.89 s  load  2685 ms  RenderPipeline$_$4$vertexLayout 2373, ...`.

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

## 7. On a real Android phone (verified 2026-11-16, ROG Phone II, Android 11, Chrome 151)

Same tool, `--remote`, against the phone's own Chrome over USB. No emulation and no
throttling: its own CPU, GPU, screen and network.

1. **adb**: `H:/AppData/android-studio/platform-tools/adb.exe` on the pc (not on PATH).
   `adb devices -l` must say `device`; `unauthorized` or nothing means the phone's owner has
   to enable USB debugging and accept the prompt. Their hands, not yours.
2. **Device facts for the report**: `getprop ro.product.model`, `ro.build.version.release`,
   `dumpsys package com.android.chrome | grep versionName`, and the active refresh rate from
   `dumpsys display` (`mActiveModeId`, the mode's `fps`). The ROG ran at 120 Hz: the frame
   budget is **8.33 ms**, not 16.6.
3. **Wake it and keep it awake**: Chrome exposes `chrome_devtools_remote` only while its UI is
   up, and renders only the foreground tab of the foreground app on a lit screen. With the
   owner's leave, `adb shell svc power stayon usb` for the session and **`svc power stayon
   false` at the end**. If the phone locks, do not try to get past the lock.
4. **Your own tab, in front**: `adb shell am start -a android.intent.action.VIEW -d
   "URL?pc-profile=1" -p com.android.chrome`, then `adb forward tcp:9222
   localabstract:chrome_devtools_remote`. Touch only that tab; close it at the end
   (`/json/close/ID`).
5. **Record**: `ADB=<adb path> REMOTE_ATTACH=<a substring of the tab's URL> python
   tool/web_profile.py record --remote 9222 --url URL --scenario flame-scroll --label L`.
   Match on a substring every URL you navigate the tab to shares; the tool attaches to that
   tab and navigates it.
6. **Input through adb, not CDP**: each CDP touch event over adb is a round trip of about a
   second, so a CDP "swipe" on a phone is a dozen taps a second apart. In `--remote` mode the
   tool sends `adb shell input swipe/tap` in device pixels (CSS px x devicePixelRatio).

What reads differently on the phone:

- **Frame p50/p95 from `FireAnimationFrame` is not reliable there**: the phone's trace held
  only about 25 of them in a 30 s scenario.
- **What to trust on a device**: long tasks (count, longest), stalls over 500 ms, the
  `stalls` list, the GPU thread total, the main-thread script/GC totals, and the top self
  time. All come from task and sampler events, which the phone records fully. Do not report
  frame p50/p95 or "frames > 33 ms" from a device trace.
- **The live site and previews are release builds**: Dart names are minified (`akX`, `Uy`).
  Name a minified caller by finding the API it calls in the package sources, or profile a
  `--profile` build served to the phone.
- **What the phone showed that the emulator did not**: `checkFramebufferStatus` at 1.2-1.7 s
  per trace, called from flutter_scene's web render pass (`lib/src/gpu/web/render_pass.dart`,
  checked every time a pass begins). On a phone GPU that call forces a sync. Desktop
  emulation throttles the CPU, not the GPU, so it barely registers there.
- The emulated win for the bold-text warm-up (first-touch frame 420 to 56 ms median) did **not**
  show as a clear difference on the ROG: before 30 / 294 / 1055 ms, after 49 / 291 / 781 ms.
  Prove a fix on the real device, not only under emulation.

## 8. Counting GL work without a phone's GPU

A desktop GPU hides what a phone's GPU pays, but the *calls* are the same. Inject a wrapper
before the page loads (`Page.addScriptToEvaluateOnNewDocument`) around
`WebGL2RenderingContext.prototype` methods and read the counts from the page: how often
`checkFramebufferStatus` runs, which `renderbufferStorageMultisample` sizes are allocated
and when, blits and `texImage2D` per frame. That is how the gallery's arrival stall on the
ROG was tied to four 1082x2404 x4 multisampled renderbuffers allocated on the first corridor
frame (flutter_scene caches framebuffers, so the check is per new target, not per frame).

## Not verified here

- The `gallery-walk` scenario.
- iOS Safari, which has no CDP. Its Web Inspector timeline is the equivalent, by hand.
- WebAssembly builds (`--wasm`).
