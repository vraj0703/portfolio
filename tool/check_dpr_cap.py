"""End-to-end check of the phone DPR cap in web/index.html, in real Chrome over CDP.

Serves nothing itself: point it at a running build (python -m http.server PORT --directory
build/web). Loads the page twice, once as a phone (touch, 412x915 at 2.625) and once as a
desktop (no touch, 1440x900 at 2.0), and reads window.devicePixelRatio as Flutter will.

    python tool/check_dpr_cap.py http://127.0.0.1:PORT/

Exit 0 when the phone reads 2 and the desktop keeps its 2.0; 1 otherwise.
"""
import asyncio, json, os, subprocess, sys, tempfile, time, urllib.request

sys.path.insert(0, os.path.dirname(__file__))
import web_profile as wp  # noqa: E402

PROFILES = {
    # name: (touch, width, height, ratio, expected)
    "phone": (True, 412, 915, 2.625, 2.0),
    "desktop": (False, 1440, 900, 2.0, 2.0),
    "desktop-hidpi": (False, 1440, 900, 3.0, 3.0),
}


async def read_ratio(port, url, touch, width, height, ratio):
    import websockets
    tabs = json.load(urllib.request.urlopen(f"http://127.0.0.1:{port}/json"))
    page = next(t for t in tabs if t["type"] == "page")
    async with websockets.connect(page["webSocketDebuggerUrl"], max_size=None) as ws:
        cdp = wp.Cdp(ws)
        await cdp("Page.enable")
        await cdp("Emulation.setDeviceMetricsOverride", width=width, height=height,
                  deviceScaleFactor=ratio, mobile=touch, screenWidth=width, screenHeight=height)
        await cdp("Emulation.setTouchEmulationEnabled", enabled=touch, maxTouchPoints=5 if touch else 1)
        await cdp("Emulation.setEmulatedMedia", features=[
            {"name": "pointer", "value": "coarse" if touch else "fine"},
            {"name": "any-pointer", "value": "coarse" if touch else "fine"}])
        await cdp("Page.navigate", url=url)
        await asyncio.sleep(3)
        r = await cdp("Runtime.evaluate", expression="window.devicePixelRatio", returnByValue=True)
        return r["result"]["value"]


def main():
    url = sys.argv[1]
    port = 9333
    prof = tempfile.mkdtemp(prefix="cdp-dpr-")
    proc = subprocess.Popen([wp.CHROME, "--headless=new", f"--remote-debugging-port={port}",
                             f"--user-data-dir={prof}", "--no-first-run", "about:blank"])
    try:
        for _ in range(100):
            try:
                urllib.request.urlopen(f"http://127.0.0.1:{port}/json")
                break
            except Exception:
                time.sleep(0.2)
        ok = True
        for name, (touch, w, h, ratio, expected) in PROFILES.items():
            got = asyncio.run(read_ratio(port, url, touch, w, h, ratio))
            good = abs(got - expected) < 1e-6
            ok &= good
            print(f"{name:14} touch={touch!s:5} screen {w}x{h} at {ratio}: devicePixelRatio {got} "
                  f"(expected {expected}) {'ok' if good else 'FAIL'}")
        sys.exit(0 if ok else 1)
    finally:
        proc.terminate()


if __name__ == "__main__":
    main()
