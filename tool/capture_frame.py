"""Capture a project's live site as its corridor frame's picture (PORTFOLIO-6).

    python tool/capture_frame.py shunya-systems

The single way a frame's picture is made, so refreshing it is this one command:
headless Chrome opens the project's URL at a desktop width whose shape is the frame card's
exactly (3.56 x 2.56, the card inside the moulding: GalleryLayout), waits for the page to
settle, and writes

    assets/frames/<id>.webp        the picture, lossy WebP like the gallery's other textures
    assets/frames/<id>.json        what was captured, from where, and when

Headless is fine here: this is a picture of a page, not a measurement (the web-profile skill's
rule against headless is about timing). Needs the Chrome the other tools use (CHROME env var)
and Pillow with WebP.

Could CI refresh it on a schedule later? Yes in principle: a scheduled workflow could run this
on ubuntu-latest (it has Chrome), commit the two files and open a PR, so a person sees the new
picture before it ships. Not added (PORTFOLIO-6: say, do not add).
"""
import argparse, asyncio, base64, datetime, io, json, os, re, subprocess, sys, tempfile, time, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHROME = os.environ.get("CHROME", r"C:\Program Files\Google\Chrome\Application\chrome.exe")
PORT = 9343

# The live site each project's frame shows. One line per project that has one.
SITES = {
    "shunya-systems": "https://shunya.systems",
    "tantr": "https://shunya.systems/tantr/",
}

# The card's shape (GalleryLayout: 4 x 3 frame less a 0.22 border each side).
CARD_W, CARD_H = 3.56, 2.56


def _virtual_size():
    """The page size the site is laid out at: ONE constant, LiveFrames.virtualWidth/Height in
    lib/domain/gallery/live_frames.dart, read here so the capture and the live iframe (which is
    that size scaled down to the card) show the same layout."""
    src = open(os.path.join(ROOT, "lib", "domain", "gallery", "live_frames.dart"), encoding="utf-8").read()
    w = int(re.search(r"static const int virtualWidth = (\d+);", src).group(1))
    h = int(re.search(r"static const int virtualHeight = (\d+);", src).group(1))
    return w, h


VIEW_W, VIEW_H = _virtual_size()

# The texture's size: the gallery decodes surfaces at 1024 on the long side.
OUT_W = 1024
QUALITY = 86


async def capture(url, settle_s):
    import websockets
    prof = tempfile.mkdtemp(prefix="capture-frame-")
    proc = subprocess.Popen([CHROME, "--headless=new", "--hide-scrollbars", "--no-first-run",
                             "--no-default-browser-check", f"--remote-debugging-port={PORT}",
                             f"--user-data-dir={prof}", f"--window-size={VIEW_W},{VIEW_H}", "about:blank"])
    try:
        page = None
        for _ in range(150):
            try:
                tabs = json.load(urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json"))
                page = next(t for t in tabs if t["type"] == "page")
                break
            except Exception:
                time.sleep(0.2)
        if page is None:
            raise RuntimeError("Chrome did not start")
        async with websockets.connect(page["webSocketDebuggerUrl"], max_size=None) as ws:
            n = 0

            async def cdp(method, **params):
                nonlocal n
                n += 1
                my = n
                await ws.send(json.dumps({"id": my, "method": method, "params": params}))
                while True:
                    msg = json.loads(await ws.recv())
                    if msg.get("id") == my:
                        if "error" in msg:
                            raise RuntimeError(f"{method}: {msg['error']}")
                        return msg.get("result", {})

            await cdp("Page.enable")
            await cdp("Emulation.setDeviceMetricsOverride", width=VIEW_W, height=VIEW_H,
                      deviceScaleFactor=1, mobile=False)
            await cdp("Page.navigate", url=url)
            # Loaded, then a settle for fonts, the panel's canvas and any entrance.
            for _ in range(60):
                r = await cdp("Runtime.evaluate", expression="document.readyState", returnByValue=True)
                if r["result"].get("value") == "complete":
                    break
                await asyncio.sleep(0.5)
            await asyncio.sleep(settle_s)
            shot = await cdp("Page.captureScreenshot", format="png",
                             clip={"x": 0, "y": 0, "width": VIEW_W, "height": VIEW_H, "scale": 1})
            return base64.b64decode(shot["data"])
    finally:
        proc.terminate()


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("project", help="the project's id, e.g. shunya-systems")
    ap.add_argument("--settle", type=float, default=4.0, help="seconds to wait after load")
    ap.add_argument("--from", dest="source", metavar="URL",
                    help="take the picture from this URL instead (a preview of a page not live yet); "
                         "the record keeps the declared URL and says where it came from")
    a = ap.parse_args()
    url = SITES.get(a.project)
    if not url:
        sys.exit(f"capture_frame: no site for '{a.project}'; known: {', '.join(SITES)}")
    from PIL import Image
    png = asyncio.run(capture(a.source or url, a.settle))
    im = Image.open(io.BytesIO(png)).convert("RGB")
    out_h = round(OUT_W * CARD_H / CARD_W)
    im = im.resize((OUT_W, out_h), Image.LANCZOS)
    out_dir = os.path.join(ROOT, "assets", "frames")
    os.makedirs(out_dir, exist_ok=True)
    pic = os.path.join(out_dir, f"{a.project}.webp")
    im.save(pic, "WEBP", quality=QUALITY, method=6)
    meta = {
        "project": a.project,
        "url": url,
        "captured_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        "viewport": f"{VIEW_W}x{VIEW_H}",
        "picture": f"{OUT_W}x{out_h}",
        "tool": "tool/capture_frame.py",
    }
    if a.source:
        meta["captured_from"] = a.source
    with open(os.path.join(out_dir, f"{a.project}.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
        f.write("\n")
    print(json.dumps({**meta, "bytes": os.path.getsize(pic)}))


if __name__ == "__main__":
    main()
