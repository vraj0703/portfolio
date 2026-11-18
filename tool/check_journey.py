"""The visitor's journey, end to end, in real Chrome: a check that fails on a hang.

    python tool/check_journey.py --url http://127.0.0.1:PORT/ --profile both

Runs on a DESKTOP profile (1280x800, mouse and wheel) and a PHONE profile (412x915 at DPR
2.625, touch, the Pixel user agent), or on a real phone over adb (`--remote 9222`, a tab of ours
already open with `pc-profile=1` in its URL). Each profile walks the same journey:

  1. load        the logo screen appears
  2. enter       a tap (or click) on the logo leaves it
  3. gallery     wheel (desktop) or swipes (phone) carry title -> bold text -> gallery
  4. back wall   the walk reaches the far end of the corridor (screen settles there)
  5. testimonial the testimonial wall's cards are in front of the visitor
  6. drawer      the menu opens the drawer, with the gallery's radio in it

It fails on a HANG (no step done within its limit, or the screen frozen while input is going in)
and on any console error or uncaught exception. Prints one JSON line per profile and exits
non-zero if any profile failed. Real Chrome, minimised, not headless (see the web-profile
skill). The drawer is found through Flutter's semantics tree, by its labels, not by pixels.

Why it exists: PR 19's wheel strokes passed every unit test and hung the title on desktop
(2026-11-18). Only a journey on both kinds of input catches that class of fault.
"""
import argparse, asyncio, base64, io, json, os, subprocess, sys, tempfile, time, urllib.request

sys.path.insert(0, os.path.dirname(__file__))
import web_profile as wp  # noqa: E402
from PIL import Image, ImageChops, ImageStat  # noqa: E402

PORT = 9335

# How long each step may take before it counts as a hang, in seconds.
LIMITS = {"load": 150, "enter": 30, "gallery": 30, "back wall": 40, "testimonial": 30, "drawer": 10}
# The screen must change at least this often while input is going in.
FROZEN_S = 6

DESKTOP = {"name": "desktop", "w": 1280, "h": 800, "dpr": 1, "mobile": False, "touch": False}
PHONE = {"name": "phone", "w": 412, "h": 915, "dpr": 2.625, "mobile": True, "touch": True}


class Hang(Exception):
    pass


# --------------------------------------------------------------------------- the screen

async def shot(cdp):
    # Right after a navigation the page may not be attached yet: retry briefly.
    for attempt in range(40):
        try:
            r = await cdp("Page.captureScreenshot", format="jpeg", quality=40)
            return Image.open(io.BytesIO(base64.b64decode(r["data"]))).convert("RGB")
        except RuntimeError as e:
            if "Not attached" not in str(e) or attempt == 39:
                raise
            await asyncio.sleep(0.5)


def logo_like(im):
    """The logo screen's tan, as web_profile reads it. Only asked before any input, when the
    bold text (also warm) cannot be on screen."""
    r, g, b = ImageStat.Stat(im.resize((64, 40))).mean
    return r > 150 and r - b > 40


def scene(im):
    """title / bold / gallery, from the screen's mean colour (after the logo)."""
    r, g, b = ImageStat.Stat(im.resize((64, 40))).mean
    if abs(r - g) < 25 and abs(g - b) < 30 and r > 110:
        return "gallery"
    if r > 170 and g > 130:
        return "bold"
    return "title"


def cards_in_front(im):
    """The testimonial wall: a dark brown card filling the middle of the screen."""
    w, h = im.size
    mid = im.crop((int(w * 0.3), int(h * 0.35), int(w * 0.7), int(h * 0.55))).resize((16, 8))
    r, g, b = ImageStat.Stat(mid).mean
    return r - b > 45 and (r + g + b) / 3 < 140


def drawer_open(im):
    """A phone's drawer: one warm panel across the screen, below the browser's own bar."""
    w, h = im.size
    body = im.crop((0, int(h * 0.3), w, int(h * 0.9))).resize((32, 32))
    st = ImageStat.Stat(body)
    r, g, b = st.mean
    return r - b > 30 and max(st.stddev) < 18


def moved(a, b):
    d = ImageChops.difference(a.resize((64, 40)), b.resize((64, 40)))
    return sum(ImageStat.Stat(d).mean) > 2.0


async def marked(cdp, path):
    """Whether the app has marked entering `path` (SiteTelemetry: `scene:<path>`)."""
    r = await cdp("Runtime.evaluate", returnByValue=True,
                  expression=f"performance.getEntriesByName({json.dumps('scene:' + path)}).length > 0")
    return bool(r["result"].get("value"))


# --------------------------------------------------------------------------- input

async def touch(cdp, kind, x=None, y=None):
    pts = [] if kind == "touchEnd" else [{"x": x, "y": y, "id": 1}]
    await cdp("Input.dispatchTouchEvent", type=kind, touchPoints=pts)


async def swipe(cdp, x0, y0, x1, y1, n=10):
    await touch(cdp, "touchStart", x0, y0)
    for k in range(1, n + 1):
        await touch(cdp, "touchMove", x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n)
        await asyncio.sleep(0.016)
    await touch(cdp, "touchEnd")


async def click(cdp, x, y):
    for kind in ("mousePressed", "mouseReleased"):
        await cdp("Input.dispatchMouseEvent", type=kind, x=x, y=y, button="left", clickCount=1)


async def tap(cdp, p, x, y):
    if p["touch"]:
        await touch(cdp, "touchStart", x, y)
        await asyncio.sleep(0.06)
        await touch(cdp, "touchEnd")
    else:
        await click(cdp, x, y)


async def wheel(cdp, delta=100, n=10, gap=0.05):
    # A real mouse is over the page before it scrolls.
    await cdp("Input.dispatchMouseEvent", type="mouseMoved", x=640, y=400)
    for _ in range(n):
        await cdp("Input.dispatchMouseEvent", type="mouseWheel", x=640, y=400, deltaX=0, deltaY=delta)
        await asyncio.sleep(gap)


# --------------------------------------------------------------------------- the journey

def console_errors(cdp):
    """Console errors and uncaught exceptions seen so far (and consumed)."""
    out, keep = [], []
    for e in cdp.events:
        m = e.get("method")
        if m == "Runtime.exceptionThrown":
            out.append(e["params"]["exceptionDetails"].get("text", "exception"))
        elif m == "Runtime.consoleAPICalled" and e["params"].get("type") == "error":
            out.append(" ".join(str(a.get("value", a.get("description", ""))) for a in e["params"]["args"]))
        else:
            keep.append(e)
    cdp.events[:] = keep
    return out


async def until(cdp, step, done, nudge, steps):
    """Run `nudge` (an input) until `done(screen)`; fail on the step's limit or a frozen screen."""
    t0 = time.monotonic()
    last, last_change = await shot(cdp), time.monotonic()
    while True:
        im = await shot(cdp)
        if done(im):
            steps[step] = round(time.monotonic() - t0, 1)
            return im
        if moved(last, im):
            last_change = time.monotonic()
        last = im
        if time.monotonic() - t0 > LIMITS[step]:
            raise Hang(f"{step}: not done in {LIMITS[step]} s (screen reads {scene(im)})")
        if nudge is not None and time.monotonic() - last_change > FROZEN_S:
            raise Hang(f"{step}: screen frozen for {FROZEN_S} s while input was going in")
        if nudge is not None:
            await nudge()
        await asyncio.sleep(0.25)


async def until_marked(cdp, step, path, nudge, steps):
    """Run `nudge` until the app marks entering `path`; fail on the step's limit or a frozen
    screen while input goes in."""
    t0 = time.monotonic()
    last, last_change = await shot(cdp), time.monotonic()
    while not await marked(cdp, path):
        if time.monotonic() - t0 > LIMITS[step]:
            raise Hang(f"{step}: no '{path}' in {LIMITS[step]} s")
        await nudge()
        im = await shot(cdp)
        if moved(last, im):
            last_change = time.monotonic()
        last = im
        if time.monotonic() - last_change > FROZEN_S:
            raise Hang(f"{step}: screen frozen for {FROZEN_S} s while input was going in")
    steps[step] = round(time.monotonic() - t0, 1)


async def semantics_click(cdp, p, label):
    """Click the widget whose semantics label is `label` (turns Flutter's semantics on)."""
    # A click with coordinates inside the placeholder: the mobile enabler checks where the
    # click landed, the desktop one does not.
    js = """(() => { const ph = document.querySelector('flt-semantics-placeholder');
      if (!ph) return 0; const r = ph.getBoundingClientRect();
      const at = {clientX: r.x + r.width / 2, clientY: r.y + r.height / 2, bubbles: true, cancelable: true};
      for (const t of ['pointerdown', 'pointerup']) ph.dispatchEvent(new PointerEvent(t, at));
      ph.dispatchEvent(new MouseEvent('click', at)); return 1; })()"""
    await cdp("Runtime.evaluate", expression=js, returnByValue=True)
    await asyncio.sleep(1.0)
    # This Flutter puts a button's label in its text, not in aria-label.
    find = f"""(() => {{ const e = [...document.querySelectorAll('flt-semantics[role=button], [aria-label]')]
      .find(n => (n.getAttribute('aria-label') || n.textContent || '').trim() === {json.dumps(label)});
      if (!e) return false; e.click(); return true; }})()"""
    r = await cdp("Runtime.evaluate", expression=find, returnByValue=True)
    return bool(r["result"].get("value"))


async def has_label(cdp, label):
    js = f"""[...document.querySelectorAll('[aria-label], flt-semantics')]
      .some(n => (n.getAttribute('aria-label') || n.textContent || '').includes({json.dumps(label)}))"""
    r = await cdp("Runtime.evaluate", expression=js, returnByValue=True)
    return bool(r["result"].get("value"))


async def journey(cdp, p, url):
    W, H = p["w"], p["h"]
    steps = {}
    await cdp("Page.navigate", url=url)

    await until(cdp, "load", logo_like, None, steps)
    await asyncio.sleep(1)

    async def enter_tap():
        await tap(cdp, p, W / 2, H * (0.89 if p["touch"] else 0.5))
        await asyncio.sleep(1.5)
    await until(cdp, "enter", lambda im: not logo_like(im), enter_tap, steps)

    if p["touch"]:
        async def onward():
            await swipe(cdp, W / 2, H * 0.7, W / 2, H * 0.45)
            await asyncio.sleep(2.5)
    else:
        async def onward():
            await wheel(cdp, 100, n=10)
    await until_marked(cdp, "gallery", "/#/gallery", onward, steps)
    await asyncio.sleep(10)  # the corridor's own entrance

    # The walk to the back wall: the stick held forward in one press on a phone, the wheel on a
    # desktop, until the app marks the wall (its region begins at the back wall's stop).
    if p["touch"]:
        await touch(cdp, "touchStart", W / 2, H * 0.82)
        for k in range(1, 6):
            await touch(cdp, "touchMove", W / 2, H * 0.82 - 14 * k)
            await asyncio.sleep(0.02)

        async def walk():
            await asyncio.sleep(0.5)
    else:
        async def walk():
            # The gallery's wheel is inverted on purpose (GalleryInput.wheelDirection): pushing
            # the wheel away walks deeper, so onward is a negative delta here.
            await wheel(cdp, -100, n=8)
    await until_marked(cdp, "back wall", "/#/testimonials", walk, steps)
    if p["touch"]:
        await touch(cdp, "touchEnd")
    await asyncio.sleep(1.0)

    if p["touch"]:
        async def along():
            await swipe(cdp, W * 0.83, H * 0.32, W * 0.2, H * 0.32)
            await asyncio.sleep(1.5)
    else:
        async def along():
            await wheel(cdp, -100, n=2)
    await until(cdp, "testimonial", cards_in_front, along, steps)

    t0 = time.monotonic()
    if p["touch"]:
        # On a phone the row is compact (TitleChrome): 48 px targets, 16 px in from the
        # corner, the menu rightmost. Flutter's mobile semantics would not switch on from a
        # script, so the drawer is confirmed by its panel: on a phone it covers the screen.
        await tap(cdp, p, W - 40, 40)
        while not drawer_open(await shot(cdp)):
            if time.monotonic() - t0 > LIMITS["drawer"]:
                raise Hang("drawer: the menu did not open the drawer")
            await asyncio.sleep(0.25)
    else:
        if not await semantics_click(cdp, p, "Open menu"):
            r = await cdp("Runtime.evaluate", returnByValue=True, expression=
                          "[...document.querySelectorAll('flt-semantics[role=button]')].map(n => n.textContent).slice(0, 30)")
            raise Hang(f"drawer: no 'Open menu' button in the semantics tree; labels: {r['result'].get('value')}")
        while not await has_label(cdp, "next station"):
            if time.monotonic() - t0 > LIMITS["drawer"]:
                raise Hang("drawer: did not open with the gallery's radio in it")
            await asyncio.sleep(0.25)
    steps["drawer"] = round(time.monotonic() - t0, 1)
    return steps


async def run_profile(p, url, remote=None):
    import websockets
    proc = None
    if remote:
        tabs = json.load(urllib.request.urlopen(f"http://127.0.0.1:{remote}/json"))
        page = next(t for t in tabs if t.get("type") == "page" and "pc-profile=1" in t.get("url", ""))
    else:
        prof = tempfile.mkdtemp(prefix="journey-")
        proc = subprocess.Popen([wp.CHROME, "--start-minimized", "--disable-features=CalculateNativeWinOcclusion",
                                 "--no-first-run", "--no-default-browser-check",
                                 f"--remote-debugging-port={PORT}", f"--user-data-dir={prof}",
                                 "--window-size=1280,860", "about:blank"])
        page = None
        for _ in range(150):
            try:
                tabs = json.load(urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json"))
                page = next(t for t in tabs if t["type"] == "page")
                break
            except Exception:
                time.sleep(0.2)
    result = {"profile": p["name"], "url": url}
    try:
        async with websockets.connect(page["webSocketDebuggerUrl"], max_size=None, ping_interval=None) as ws:
            cdp = wp.Cdp(ws)
            for d in ("Page", "Runtime"):
                await cdp(f"{d}.enable")
            if remote:
                r = await cdp("Runtime.evaluate", expression="[innerWidth, innerHeight]", returnByValue=True)
                p = dict(p, w=r["result"]["value"][0], h=r["result"]["value"][1])
            else:
                await cdp("Emulation.setDeviceMetricsOverride", width=p["w"], height=p["h"],
                          deviceScaleFactor=p["dpr"], mobile=p["mobile"])
                if p["touch"]:
                    await cdp("Emulation.setUserAgentOverride", userAgent=wp.UA, platform="Android")
                    await cdp("Emulation.setTouchEmulationEnabled", enabled=True, maxTouchPoints=5)
            try:
                result["steps"] = await journey(cdp, p, url)
                result["ok"] = True
            except Hang as e:
                result["ok"], result["hang"] = False, str(e)
                path = os.path.join(tempfile.gettempdir(), f"journey-hang-{p['name']}.png")
                (await shot(cdp)).save(path)
                result["hang_screen"] = path
            errors = console_errors(cdp)
            if errors:
                result["ok"], result["console_errors"] = False, errors[:10]
    finally:
        if proc:
            proc.terminate()
    return result


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--url", required=True)
    ap.add_argument("--profile", choices=["desktop", "phone", "both"], default="both")
    ap.add_argument("--remote", type=int, default=None, help="a real phone's CDP port (adb forward)")
    a = ap.parse_args()
    url = a.url + ("&" if "?" in a.url else "?") + "pc-profile=1"
    profiles = {"desktop": [DESKTOP], "phone": [PHONE], "both": [DESKTOP, PHONE]}[a.profile]
    ok = True
    for p in profiles:
        r = asyncio.run(run_profile(p, url, a.remote if p["touch"] else None))
        print(json.dumps(r), flush=True)
        ok &= r["ok"]
    print("JOURNEY " + ("PASS" if ok else "FAIL"), flush=True)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
