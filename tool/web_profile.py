"""Record and read a Chrome performance trace of the web build on a phone profile.

usage:
  python tool/web_profile.py record --url URL --scenario NAME --label LABEL [--runs 3] [--out DIR]
  python tool/web_profile.py read TRACE.json [TRACE.json ...]

`record` launches real Chrome (not headless: PostHog and some GPU paths treat headless as a
bot), minimised, with a Pixel profile (Android user agent, 412x915 at DPR 2.625, touch on),
4x CPU throttling and DevTools' Fast 4G, cache off. It waits for the logo screen, taps in,
waits for the title, then traces one named scenario driven by touch input, and writes
DIR/LABEL-N.trace.json and DIR/LABEL-N.summary.json for each run, then prints the spread.

`read` prints the same summary for traces already on disk.

Scenarios (add one by adding a function to SCENARIOS):
  flame-scroll   title -> eight touch swipes up -> the scroll into the gallery
  gallery-walk   (after the scroll) eight more swipes down the corridor

Needs: python3 with `websockets`, Google Chrome at the usual Windows path (CHROME env to
override). Everything it knows about a trace is in `summarise()`; see the skill
.claude/skills/web-profile/SKILL.md for what each number means.
"""
import argparse, asyncio, base64, io, json, os, statistics, subprocess, sys, tempfile, time, urllib.request
from collections import Counter, defaultdict

CHROME = os.environ.get("CHROME", r"C:\Program Files\Google\Chrome\Application\chrome.exe")
PORT = int(os.environ.get("CDP_PORT", "9338"))
W, H, DPR = 412, 915, 2.625
UA = ("Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/157.0.0.0 Mobile Safari/537.36")
CATEGORIES = ",".join([
    "devtools.timeline", "disabled-by-default-devtools.timeline",
    "disabled-by-default-devtools.timeline.frame", "v8.execute", "blink.user_timing",
    "disabled-by-default-v8.cpu_profiler", "v8", "disabled-by-default-v8.gc", "gpu",
    "viz", "cc", "benchmark", "toplevel", "disabled-by-default-devtools.screenshot",
])


# --------------------------------------------------------------------------- recording

class Cdp:
    def __init__(self, ws):
        self.ws, self.n, self.events = ws, 0, []

    async def __call__(self, method, **params):
        self.n += 1
        my = self.n
        await self.ws.send(json.dumps({"id": my, "method": method, "params": params}))
        while True:
            msg = json.loads(await self.ws.recv())
            if msg.get("id") == my:
                if "error" in msg:
                    raise RuntimeError(f"{method}: {msg['error']}")
                return msg.get("result", {})
            self.events.append(msg)

    async def send(self, method, **params):
        """Send without waiting: the reply is read later by the next awaited call, and dropped
        (it has no `method`, so wait_event never matches it)."""
        self.n += 1
        await self.ws.send(json.dumps({"id": self.n, "method": method, "params": params}))

    async def wait_event(self, name, timeout=120):
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            for i, e in enumerate(self.events):
                if e.get("method") == name:
                    return self.events.pop(i)
            try:
                self.events.append(json.loads(await asyncio.wait_for(self.ws.recv(), 1)))
            except asyncio.TimeoutError:
                pass
        raise TimeoutError(name)


async def mean_colour(cdp):
    """Mean RGB of the screen: enough to tell the logo's tan from the title's dark.

    Never with a `clip`: on Android Chrome a clipped capture resizes the viewport for the shot
    (412x764 to 980x1819 and back, seen 2026-11-17 on the ROG), and the app under test pays for
    every flip: CanvasKit's resizeCanvas, and flutter_scene reallocating its render targets. The
    whole screen at low quality, scaled down here, costs the page nothing."""
    try:
        r = await cdp("Page.captureScreenshot", format="jpeg", quality=20)
    except RuntimeError:
        # Between navigation and the first frame there is no page to capture yet.
        return (0, 0, 0)
    data = base64.b64decode(r.get("data", ""))
    if not data:
        return (0, 0, 0)
    from PIL import Image
    im = Image.open(io.BytesIO(data)).convert("RGB").resize((8, 16))
    raw = im.tobytes()
    px = [tuple(raw[i:i + 3]) for i in range(0, len(raw), 3)]
    return tuple(sum(p[i] for p in px) / len(px) for i in range(3))


ADB = os.environ.get("ADB")  # set in --remote mode: input goes through `adb shell input`
SCALE = [1.0]  # CSS px to device px, read from the page in --remote mode


def adb_input(*args):
    subprocess.run([ADB, "shell", "input", *[str(a) for a in args]], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


async def touch_drag(cdp, x, y1, y2, ms=300, steps=6):
    """A touch drag through CDP, so the page sees pointerType 'touch'. The corridor
    (gallery_view.dart) accepts touch and stylus only; `adb shell input swipe` arrives in Chrome
    with an empty pointerType (Flutter's PointerDeviceKind.unknown) and never walks it. On a
    phone each CDP call is a round trip over adb (about a second), so the events are sent
    without waiting for their replies, paced by the clock, and one call at the end drains them."""
    await cdp.send("Input.dispatchTouchEvent", type="touchStart", touchPoints=[{"x": x, "y": y1}])
    for i in range(1, steps + 1):
        await asyncio.sleep(ms / 1000 / steps)
        y = y1 + (y2 - y1) * i / steps
        await cdp.send("Input.dispatchTouchEvent", type="touchMove", touchPoints=[{"x": x, "y": y}])
    await cdp.send("Input.dispatchTouchEvent", type="touchEnd", touchPoints=[])
    await cdp("Runtime.evaluate", expression="0")


async def touch_swipe(cdp, x, y1, y2, ms=300, steps=12, corridor=False):
    """A swipe. With `corridor`, always a CDP touch drag (see touch_drag); otherwise, in --remote
    mode, a kernel-level `adb shell input swipe`, which the Flame title scrolls by."""
    if corridor:
        await touch_drag(cdp, x, y1, y2, ms)
        return
    if ADB:
        # Real kernel-level touch at the device's own pace. CDP touch events over adb are one
        # round trip each (about a second), so a CDP "swipe" on a phone is not a swipe.
        k = SCALE[0]
        await asyncio.to_thread(adb_input, "swipe", int(x * k), int(y1 * k), int(x * k), int(y2 * k), ms)
        return
    await cdp("Input.dispatchTouchEvent", type="touchStart", touchPoints=[{"x": x, "y": y1}])
    for i in range(1, steps + 1):
        y = y1 + (y2 - y1) * i / steps
        await cdp("Input.dispatchTouchEvent", type="touchMove", touchPoints=[{"x": x, "y": y}])
        await asyncio.sleep(ms / 1000 / steps)
    await cdp("Input.dispatchTouchEvent", type="touchEnd", touchPoints=[])


async def touch_tap(cdp, x, y):
    if ADB:
        k = SCALE[0]
        await asyncio.to_thread(adb_input, "tap", int(x * k), int(y * k))
        return
    await cdp("Input.dispatchTouchEvent", type="touchStart", touchPoints=[{"x": x, "y": y}])
    await asyncio.sleep(0.08)
    await cdp("Input.dispatchTouchEvent", type="touchEnd", touchPoints=[])


async def scenario_flame_scroll(cdp):
    """The Flame half: from the title, eight swipes up, half a second apart."""
    for _ in range(8):
        await touch_swipe(cdp, W / 2, H * 0.75, H * 0.25)
        await asyncio.sleep(0.5)
    await asyncio.sleep(2)


async def scenario_gallery_walk(cdp):
    """The gallery half: scroll in first (untraced), then eight swipes down the corridor."""
    await scenario_flame_scroll(cdp)
    await asyncio.sleep(4)
    for _ in range(8):
        await touch_swipe(cdp, W / 2, H * 0.75, H * 0.25, corridor=True)
        await asyncio.sleep(0.5)
    await asyncio.sleep(2)


async def phase(cdp, name):
    """A `performance.mark` in the page, so the trace says which part of the journey a stall
    belongs to (`stalls` reads them back)."""
    await cdp("Runtime.evaluate", expression=f"performance.mark('journey:{name}')")


async def scenario_journey(cdp):
    """The rest of the whole journey, after load, logo and title (traced from navigation, see
    TRACE_FROM_LOAD): the touch scroll from the title into the gallery, a walk down the
    corridor, and focusing the first frame on the left."""
    await phase(cdp, "scroll")
    for _ in range(8):
        await touch_swipe(cdp, W / 2, H * 0.75, H * 0.25)
        await asyncio.sleep(0.5)
    await asyncio.sleep(4)
    await phase(cdp, "corridor")
    for _ in range(2):
        await touch_swipe(cdp, W / 2, H * 0.6, H * 0.5, corridor=True)
        await asyncio.sleep(1)
    await asyncio.sleep(2)
    await phase(cdp, "focus")
    await touch_tap(cdp, W * 0.04, H * 0.49)
    await asyncio.sleep(4)
    await phase(cdp, "end")


SCENARIOS = {"flame-scroll": scenario_flame_scroll, "gallery-walk": scenario_gallery_walk,
             "journey": scenario_journey}
# Steps of a scenario that happen before the trace starts (setup, untraced).
UNTRACED_PREFIX = {"gallery-walk": scenario_flame_scroll}
# Scenarios traced from navigation: loading, the logo and the title's entrance are in the trace.
# The logo is still found by sampling the screen's colour (a screenshot a second), which costs
# a little and shows in the trace as Page.captureScreenshot work.
TRACE_FROM_LOAD = {"journey"}


async def record_one(url, scenario, path, remote=None):
    """One trace. With `remote` (a local port forwarded to a phone's Chrome, see the skill),
    no browser is launched and nothing is emulated or throttled: the tool opens one tab of its
    own on the device, touches only that tab, and closes it at the end."""
    global W, H
    import websockets
    proc = None
    attach = os.environ.get("REMOTE_ATTACH")
    if remote and attach:
        # A tab of ours already in front (opened with a marker in its URL, see the skill):
        # a phone renders only the foreground tab of the foreground app.
        tabs = json.load(urllib.request.urlopen(f"http://127.0.0.1:{remote}/json"))
        page = next(t for t in tabs if t.get("type") == "page" and attach in t.get("url", ""))
    elif remote:
        req = urllib.request.Request(f"http://127.0.0.1:{remote}/json/new?about:blank", method="PUT")
        page = json.load(urllib.request.urlopen(req))
    else:
        prof = tempfile.mkdtemp(prefix="cdp-prof-")
        proc = subprocess.Popen([CHROME, "--start-minimized", "--disable-features=CalculateNativeWinOcclusion",
                                 "--no-first-run", "--no-default-browser-check",
                                 f"--remote-debugging-port={PORT}", f"--user-data-dir={prof}",
                                 f"--window-size={W},{H}", "about:blank"])
    try:
        if not remote:
            page = None
            for _ in range(150):
                try:
                    tabs = json.load(urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json"))
                    page = next(t for t in tabs if t["type"] == "page")
                    break
                except Exception:
                    time.sleep(0.2)
            if page is None:
                raise RuntimeError("Chrome did not answer on the debugging port")
        async with websockets.connect(page["webSocketDebuggerUrl"], max_size=None, ping_interval=None) as ws:
            cdp = Cdp(ws)
            for d in ("Page", "Network", "Runtime"):
                await cdp(f"{d}.enable")
            await cdp("Network.setCacheDisabled", cacheDisabled=True)
            if remote:
                # A real phone: its own CPU, GPU, screen and network. Only the viewport is read,
                # for touch coordinates.
                r = await cdp("Runtime.evaluate", expression="[innerWidth, innerHeight, devicePixelRatio]",
                              returnByValue=True)
                W, H, SCALE[0] = r["result"]["value"]
            else:
                await cdp("Network.emulateNetworkConditions", offline=False, latency=60,
                          downloadThroughput=9_000_000 / 8, uploadThroughput=1_500_000 / 8)
                await cdp("Emulation.setCPUThrottlingRate", rate=4)
                await cdp("Emulation.setDeviceMetricsOverride", width=W, height=H,
                          deviceScaleFactor=DPR, mobile=True)
                await cdp("Emulation.setUserAgentOverride", userAgent=UA, platform="Android")
                await cdp("Emulation.setTouchEmulationEnabled", enabled=True, maxTouchPoints=5)
            from_load = scenario in TRACE_FROM_LOAD
            if from_load:
                await cdp("Tracing.start", categories=CATEGORIES, transferMode="ReturnAsStream",
                          options="sampling-frequency=10000")
            await cdp("Page.navigate", url=url)
            if from_load:
                await asyncio.sleep(0.5)
                await phase(cdp, "load")

            # The logo screen: its tan ground. Then tap in until the screen leaves it.
            t0 = time.monotonic()
            while time.monotonic() - t0 < 240:
                r, g, b = await mean_colour(cdp)
                if r > 150 and r - b > 40:
                    break
                await asyncio.sleep(1)
            else:
                raise TimeoutError("logo screen never showed")
            if from_load:
                await phase(cdp, "logo")
            for _ in range(30):
                # The tap the logo accepts is `site_loaded`; the last `journey:tap` mark is it.
                if from_load:
                    await phase(cdp, "tap")
                await touch_tap(cdp, W / 2, H * 0.89)
                await asyncio.sleep(1.5)
                r, g, b = await mean_colour(cdp)
                if r < 140:
                    break
            if from_load:
                await phase(cdp, "title")
            await asyncio.sleep(12)  # the title's entrance, at 4x CPU

            if scenario in UNTRACED_PREFIX:
                await UNTRACED_PREFIX[scenario](cdp)
                await asyncio.sleep(4)
                body = {"gallery-walk": _walk_only}[scenario]
            else:
                body = SCENARIOS[scenario]

            if not from_load:
                await cdp("Tracing.start", categories=CATEGORIES, transferMode="ReturnAsStream",
                          options="sampling-frequency=10000")
            await body(cdp)
            await cdp("Tracing.end")
            done = await cdp.wait_event("Tracing.tracingComplete", timeout=180)
            stream = done["params"]["stream"]
            chunks = []
            while True:
                r = await cdp("IO.read", handle=stream, size=4 * 1024 * 1024)
                data = r.get("data", "")
                chunks.append(base64.b64decode(data).decode("utf-8", "replace") if r.get("base64Encoded") else data)
                if r.get("eof"):
                    break
            await cdp("IO.close", handle=stream)
            raw = "".join(chunks)
            with open(path, "w", encoding="utf-8") as f:
                f.write(raw)
    finally:
        if remote and not attach:
            try:
                urllib.request.urlopen(f"http://127.0.0.1:{remote}/json/close/{page['id']}")
            except Exception:
                pass
        elif proc is not None:
            proc.terminate()
            try:
                proc.wait(10)
            except Exception:
                proc.kill()


async def _walk_only(cdp):
    for _ in range(8):
        await touch_swipe(cdp, W / 2, H * 0.75, H * 0.25, corridor=True)
        await asyncio.sleep(0.5)
    await asyncio.sleep(2)


# --------------------------------------------------------------------------- reading

SCRIPT = {"FunctionCall", "EvaluateScript", "v8.compile", "v8.compileModule", "V8.CompileCode",
          "RunMicrotasks", "TimerFire", "EventDispatch", "v8.callFunction", "v8.run"}
RENDER = {"Layout", "UpdateLayoutTree", "Paint", "PrePaint", "Layerize", "UpdateLayer",
          "CompositeLayers", "Commit", "RasterTask", "Decode Image", "ScrollLayer"}
GC = {"MinorGC", "MajorGC", "V8.GCScavenger", "V8.GCCompactor", "V8.GCFinalizeMC",
      "V8.GC_MC_BACKGROUND_MARKING", "BlinkGC.AtomicPhase", "V8.GCIncrementalMarking"}


def load_events(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return data["traceEvents"] if isinstance(data, dict) else data


def pct(values, p):
    if not values:
        return None
    v = sorted(values)
    k = max(0, min(len(v) - 1, int(round(p / 100 * (len(v) - 1)))))
    return v[k]


def summarise(events):
    """The numbers the skill asks for, from one trace. Durations in ms."""
    names = {}
    for e in events:
        if e.get("ph") == "M" and e.get("name") == "thread_name":
            names[(e["pid"], e["tid"])] = e["args"]["name"]
    main = [k for k, v in names.items() if v == "CrRendererMain"]
    gpu = [k for k, v in names.items() if v in ("CrGpuMain", "VizCompositorThread")]
    # The renderer that did the work: the CrRendererMain with the most RunTask time.
    busy = Counter()
    for e in events:
        if e.get("ph") == "X" and (e["pid"], e["tid"]) in main and e.get("name") in ("RunTask", "ThreadControllerImpl::RunTask"):
            busy[(e["pid"], e["tid"])] += e.get("dur", 0)
    mt = busy.most_common(1)[0][0] if busy else (main[0] if main else None)

    on_main = [e for e in events if e.get("ph") == "X" and (e.get("pid"), e.get("tid")) == mt]
    tasks = [e["dur"] / 1000 for e in on_main if e.get("name") in ("RunTask", "ThreadControllerImpl::RunTask")]
    span = 0
    if on_main:
        span = (max(e["ts"] + e.get("dur", 0) for e in on_main) - min(e["ts"] for e in on_main)) / 1000

    # Frames as Flutter sees them: it draws on requestAnimationFrame, so the interval between
    # successive FireAnimationFrame events is the frame time a visitor gets.
    raf = sorted(e["ts"] for e in on_main if e.get("name") == "FireAnimationFrame")
    # The frame a visitor feels as "the scroll hangs": the longest animation frame within a
    # second of the first touch.
    touches = sorted(e["ts"] for e in on_main if e.get("name") == "EventDispatch"
                     and (e.get("args", {}).get("data", {}) or {}).get("type") == "touchstart")
    first_touch_frame = None
    if touches:
        t0 = touches[0]
        near = [e["dur"] / 1000 for e in on_main if e.get("name") == "FireAnimationFrame"
                and t0 <= e["ts"] <= t0 + 1_000_000]
        first_touch_frame = round(max(near)) if near else None
    intervals = [(b - a) / 1000 for a, b in zip(raf, raf[1:])]

    def total(selector):
        """Wall time covered by the events `selector` picks, as the union of their intervals:
        events nest (a FunctionCall inside a FireAnimationFrame), so summing them double counts."""
        spans = sorted((e["ts"], e["ts"] + e.get("dur", 0)) for e in on_main if selector(e.get("name", "")))
        covered, end = 0, None
        for a, b in spans:
            if end is None or a > end:
                covered += b - a
                end = b
            elif b > end:
                covered += b - end
                end = b
        return covered / 1000

    # Top-level self-ish split: time inside each family on the main thread.
    script = total(lambda n: n in SCRIPT or n == "FireAnimationFrame")
    render = total(lambda n: n in RENDER)
    gc_events = [e for e in events if e.get("ph") == "X" and e.get("name") in GC]
    gc = [e["dur"] / 1000 for e in gc_events if (e.get("pid"), e.get("tid")) == mt]
    gc_wall = total(lambda n: n in GC)
    # Flutter's own Timeline, which a profile build reports through performance.mark/measure:
    # cost the release build does not pay. Reported so it is not mistaken for the app's.
    gpu_busy = sum(e["dur"] for e in events if e.get("ph") == "X" and (e.get("pid"), e.get("tid")) in gpu
                   and e.get("name") in ("RunTask", "ThreadControllerImpl::RunTask")) / 1000

    # Dropped frames, where Chrome reports them (PipelineReporter, newer Chrome).
    states = Counter()
    for e in events:
        if e.get("name") == "PipelineReporter" and e.get("ph") in ("b", "X"):
            st = (e.get("args", {}).get("chrome_frame_reporter", {}) or {}).get("state")
            if st:
                states[st] += 1

    # Top self time by function, from the V8 sampling profiler (ProfileChunk on the main thread).
    nodes, self_us = {}, Counter()
    for e in events:
        if e.get("name") != "ProfileChunk" or e.get("pid") != (mt[0] if mt else None):
            continue
        cp = e.get("args", {}).get("data", {}).get("cpuProfile", {})
        for n in cp.get("nodes", []):
            cf = n.get("callFrame", {})
            nodes[n["id"]] = cf.get("functionName") or "(anonymous)"
        deltas = e["args"]["data"].get("timeDeltas", [])
        for sid, dt in zip(cp.get("samples", []), deltas):
            self_us[sid] += max(dt, 0)
    by_name = Counter()
    for sid, us in self_us.items():
        by_name[nodes.get(sid, f"#{sid}")] += us
    top = [(n, round(us / 1000, 1)) for n, us in by_name.most_common(15)]
    # Flutter's Timeline in a profile build: performance.mark/measure and the work that feeds
    # them. Not paid by the release build; subtract it before blaming the app.
    instrument = sum(us for n, us in by_name.items() if n in ("mark", "measure")) / 1000

    return {
        "span_ms": round(span),
        "long_tasks": {"count": sum(1 for t in tasks if t > 50), "max_ms": round(max(tasks or [0])),
                       "total_ms": round(sum(t for t in tasks if t > 50))},
        "stalls_over_500ms": sum(1 for t in tasks if t > 500),
        "first_touch_frame_ms": first_touch_frame,
        "frames": {"count": len(intervals), "p50_ms": pct(intervals, 50) and round(pct(intervals, 50), 1),
                   "p95_ms": pct(intervals, 95) and round(pct(intervals, 95), 1),
                   "over_33ms": sum(1 for i in intervals if i > 33.4),
                   "pipeline_states": dict(states)},
        "main_thread_ms": {"script": round(script), "layout_paint": round(render),
                           "gc": round(gc_wall), "gpu_thread_busy": round(gpu_busy)},
        "gc": {"count": len(gc), "max_ms": round(max(gc or [0]), 1), "total_ms": round(sum(gc))},
        "top_self_ms": top,
        "profile_instrumentation_ms": round(instrument),
    }


def stalls(events, over_ms=100):
    """Every main-thread task longer than `over_ms`: when (s from the trace's start), which part
    of the journey (the last `journey:` mark before it), how long, and what ran in it (top self
    time from the sampling profiler inside its window). The list item 7 of a phone round asks for."""
    names = {}
    for e in events:
        if e.get("ph") == "M" and e.get("name") == "thread_name":
            names[(e["pid"], e["tid"])] = e["args"]["name"]
    busy = Counter()
    for e in events:
        if e.get("ph") == "X" and names.get((e.get("pid"), e.get("tid"))) == "CrRendererMain"                 and e.get("name") in ("RunTask", "ThreadControllerImpl::RunTask"):
            busy[(e["pid"], e["tid"])] += e.get("dur", 0)
    if not busy:
        return []
    mt = busy.most_common(1)[0][0]
    t_start = min(e["ts"] for e in events if e.get("ts"))
    marks = sorted((e["ts"], e["name"].split(":", 1)[1]) for e in events
                   if str(e.get("name", "")).startswith("journey:") and e.get("ts"))

    # Sample timestamps: each Profile's startTime plus the running sum of its chunks' deltas.
    starts = {e.get("id"): e["args"]["data"].get("startTime") for e in events
              if e.get("name") == "Profile" and e.get("pid") == mt[0]}
    clock, nodes, samples = {}, {}, []
    for e in sorted((e for e in events if e.get("name") == "ProfileChunk" and e.get("pid") == mt[0]),
                    key=lambda e: e["ts"]):
        pid_ = e.get("id")
        cp = e["args"]["data"].get("cpuProfile", {})
        for n in cp.get("nodes", []):
            nodes[(pid_, n["id"])] = n.get("callFrame", {}).get("functionName") or "(anonymous)"
        t = clock.get(pid_, starts.get(pid_) or e["ts"])
        for sid, dt in zip(cp.get("samples", []), e["args"]["data"].get("timeDeltas", [])):
            t += dt
            samples.append((t, nodes.get((pid_, sid), f"#{sid}"), max(dt, 0)))
        clock[pid_] = t
    samples.sort()

    out, end = [], -1
    tasks_ = sorted((e for e in events if (e.get("pid"), e.get("tid")) == mt and e.get("ph") == "X"
                     and e.get("name") in ("RunTask", "ThreadControllerImpl::RunTask")),
                    key=lambda e: (e["ts"], -e.get("dur", 0)))
    for e in tasks_:
        # Chrome emits both names for one task, one nested in the other: count it once.
        if e["ts"] < end:
            continue
        end = e["ts"] + e.get("dur", 0)
        dur = e.get("dur", 0) / 1000
        if dur <= over_ms:
            continue
        a, b = e["ts"], e["ts"] + e["dur"]
        where = "before marks"
        for ts, name in marks:
            if ts <= a:
                where = name
        inside = Counter()
        for t, name, us in samples:
            if a <= t <= b:
                inside[name] += us
        top = [(n, round(us / 1000)) for n, us in inside.most_common(4) if n not in ("(program)",)][:3]
        out.append({"at_s": round((a - t_start) / 1e6, 2), "phase": where, "ms": round(dur), "top": top})
    return sorted(out, key=lambda r: r["at_s"])


def after_loaded(events, over_ms=100):
    """What the visitor meets after `site_loaded` (the logo accepting the tap, the last
    `journey:tap` mark): the stalls over `over_ms`, the longest task, and ms_ready, the time
    from navigation to that tap, as the app's own `site_loaded` reports it."""
    taps = sorted(e["ts"] for e in events if e.get("name") == "journey:tap" and e.get("ts"))
    if not taps:
        return None
    t_start = min(e["ts"] for e in events if e.get("ts"))
    nav = [e["ts"] for e in events if e.get("name") == "navigationStart" and e.get("ts") is not None]
    at = (taps[-1] - t_start) / 1e6
    every = stalls(events, 0)
    after = [r for r in every if r["at_s"] >= at]
    return {
        "ms_ready": round((taps[-1] - min(nav)) / 1000) if nav else None,
        "stalls": [r for r in after if r["ms"] > over_ms],
        "longest": max(after, key=lambda r: r["ms"], default=None),
    }


def spread(rows, key):
    vals = [k for k in (key(r) for r in rows) if k is not None]
    if not vals:
        return "n/a"
    return f"{min(vals)} / {statistics.median(vals)} / {max(vals)}"


def print_spread(rows):
    print("metric | min / median / max over", len(rows), "runs")
    print("frame p50 ms |", spread(rows, lambda r: r["frames"]["p50_ms"]))
    print("frame p95 ms |", spread(rows, lambda r: r["frames"]["p95_ms"]))
    print("frames > 33 ms |", spread(rows, lambda r: r["frames"]["over_33ms"]))
    print("first-touch frame ms |", spread(rows, lambda r: r.get("first_touch_frame_ms")))
    print("long tasks |", spread(rows, lambda r: r["long_tasks"]["count"]))
    print("longest task ms |", spread(rows, lambda r: r["long_tasks"]["max_ms"]))
    print("stalls > 500 ms |", spread(rows, lambda r: r["stalls_over_500ms"]))
    print("script ms |", spread(rows, lambda r: r["main_thread_ms"]["script"]))
    print("layout+paint ms |", spread(rows, lambda r: r["main_thread_ms"]["layout_paint"]))
    print("gpu thread ms |", spread(rows, lambda r: r["main_thread_ms"]["gpu_thread_busy"]))
    print("gc ms (count) |", spread(rows, lambda r: r["gc"]["total_ms"]), "(",
          spread(rows, lambda r: r["gc"]["count"]), ")")
    print("profile-build mark/measure ms |", spread(rows, lambda r: r.get("profile_instrumentation_ms")))
    print("top self time, run 1:")
    for n, ms in rows[0]["top_self_ms"][:10]:
        print(f"  {ms:8.1f} ms  {n}")


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("record")
    r.add_argument("--url", required=True)
    r.add_argument("--scenario", required=True, choices=sorted(SCENARIOS))
    r.add_argument("--label", required=True)
    r.add_argument("--runs", type=int, default=3)
    r.add_argument("--out", default="build/profile")
    r.add_argument("--remote", type=int, default=None,
                   help="local port forwarded to a phone's Chrome (adb forward tcp:PORT "
                        "localabstract:chrome_devtools_remote); no emulation, no throttling")
    rd = sub.add_parser("read")
    rd.add_argument("traces", nargs="+")
    st = sub.add_parser("stalls", help="every main-thread task over --over ms, with its cause")
    st.add_argument("trace")
    st.add_argument("--over", type=float, default=100)
    ld = sub.add_parser("loaded", help="after site_loaded: stalls over --over ms, longest task, ms_ready")
    ld.add_argument("traces", nargs="+")
    ld.add_argument("--over", type=float, default=100)
    a = ap.parse_args()

    if a.cmd == "loaded":
        for p in a.traces:
            r = after_loaded(load_events(p), a.over)
            if r is None:
                print(f"{p}: no journey:tap mark (traced before the mark existed?)")
                continue
            lg = r["longest"]
            print(f"{os.path.basename(p)}: ms_ready {r['ms_ready']}, stalls > {a.over:g} ms after "
                  f"site_loaded {len(r['stalls'])}, longest {lg['ms'] if lg else 0} ms"
                  f" ({lg['phase'] if lg else '-'})")
            for s in r["stalls"]:
                top = ", ".join(f"{n} {ms}" for n, ms in s["top"])
                print(f"   {s['at_s']:7.2f} s  {s['phase']:<9} {s['ms']:5d} ms  {top}")
        return

    if a.cmd == "stalls":
        for r in stalls(load_events(a.trace), a.over):
            top = ", ".join(f"{n} {ms}" for n, ms in r["top"])
            print(f"{r['at_s']:7.2f} s  {r['phase']:<9} {r['ms']:5d} ms  {top}")
        return

    if a.cmd == "record":
        os.makedirs(a.out, exist_ok=True)
        rows = []
        for i in range(1, a.runs + 1):
            path = os.path.join(a.out, f"{a.label}-{i}.trace.json")
            asyncio.run(record_one(a.url, a.scenario, path, remote=a.remote))
            s = summarise(load_events(path))
            with open(path.replace(".trace.json", ".summary.json"), "w", encoding="utf-8") as f:
                json.dump(s, f, indent=1)
            rows.append(s)
            print(f"run {i}: p50 {s['frames']['p50_ms']} p95 {s['frames']['p95_ms']} "
                  f"long tasks {s['long_tasks']['count']} max {s['long_tasks']['max_ms']} ms", flush=True)
        print_spread(rows)
    else:
        print_spread([summarise(load_events(p)) for p in a.traces])


if __name__ == "__main__":
    main()
