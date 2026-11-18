"""Tests for tool/web_profile.py's input routing. Run: python -m unittest tool/test_web_profile.py"""
import asyncio, os, sys, unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(__file__))
import web_profile as wp  # noqa: E402


class FakeCdp:
    """Records what the scenario sends; answers every call at once."""

    def __init__(self):
        self.calls = []

    async def __call__(self, method, **params):
        self.calls.append((method, params))
        return {}

    async def send(self, method, **params):
        self.calls.append((method, params))


def run_journey(adb):
    cdp, swipes = FakeCdp(), []
    with mock.patch.object(wp, "ADB", adb), \
            mock.patch.object(wp, "adb_input", lambda *a: swipes.append(a)), \
            mock.patch.object(asyncio, "sleep", mock.AsyncMock()):
        asyncio.run(wp.scenario_journey(cdp))
    return cdp, swipes


def part(cdp, name):
    """The calls between the `journey:name` mark and the next mark."""
    out, inside = [], False
    for method, params in cdp.calls:
        if method == "Runtime.evaluate" and "journey:" in params.get("expression", ""):
            inside = f"journey:{name}'" in params["expression"]
            continue
        if inside:
            out.append(method)
    return out


class RemoteInput(unittest.TestCase):
    def test_corridor_drags_are_cdp_touch_on_a_phone(self):
        # adb's swipes arrive with an empty pointerType, which the corridor ignores.
        cdp, swipes = run_journey(adb="adb")
        corridor = part(cdp, "corridor")
        self.assertEqual(corridor.count("Input.dispatchTouchEvent"), 2 * 8)  # 2 drags: start, 6 moves, end
        self.assertEqual([s[0] for s in swipes].count("swipe"), 8)  # the title scroll only

    def test_title_scroll_stays_on_adb_on_a_phone(self):
        cdp, _ = run_journey(adb="adb")
        self.assertNotIn("Input.dispatchTouchEvent", part(cdp, "scroll"))

    def test_emulated_profile_uses_cdp_touch_throughout(self):
        cdp, swipes = run_journey(adb=None)
        self.assertEqual([s for s in swipes if s[0] == "swipe"], [])
        self.assertIn("Input.dispatchTouchEvent", part(cdp, "scroll"))
        self.assertIn("Input.dispatchTouchEvent", part(cdp, "corridor"))


if __name__ == "__main__":
    unittest.main()


def _trace(tasks, marks, nav=0):
    """A minimal trace: the renderer main thread, its tasks (start ms, length ms), user marks."""
    ev = [{"ph": "M", "name": "thread_name", "pid": 1, "tid": 1, "args": {"name": "CrRendererMain"}},
          {"ph": "R", "name": "navigationStart", "pid": 1, "tid": 1, "ts": nav * 1000}]
    ev += [{"ph": "X", "name": "RunTask", "pid": 1, "tid": 1, "ts": a * 1000, "dur": d * 1000}
           for a, d in tasks]
    ev += [{"ph": "R", "name": f"journey:{n}", "pid": 1, "tid": 1, "ts": t * 1000} for n, t in marks]
    return ev


class AfterLoaded(unittest.TestCase):
    def test_counts_only_what_follows_the_accepted_tap(self):
        # Two taps; the logo accepted the second (site_loaded). The 300 ms task before it is
        # loading, which is allowed to be heavy; the 250 ms one after it is a stall.
        ev = _trace(tasks=[(1000, 300), (5000, 40), (6000, 250), (7000, 120), (8000, 90)],
                    marks=[("tap", 4000), ("tap", 5500), ("title", 5600)])
        r = wp.after_loaded(ev, 100)
        self.assertEqual(r["ms_ready"], 5500)
        self.assertEqual([s["ms"] for s in r["stalls"]], [250, 120])
        self.assertEqual(r["longest"]["ms"], 250)

    def test_none_without_a_tap_mark(self):
        self.assertIsNone(wp.after_loaded(_trace([(0, 200)], []), 100))


class ScreenSampling(unittest.TestCase):
    def test_mean_colour_samples_a_screencast_frame_not_a_screenshot(self):
        # A clipped capture resizes the phone's viewport for the shot, and the app under test
        # pays for each flip (resizeCanvas, render targets reallocated): the tool made stalls.
        # A whole-screen capture is heavier. One tiny screencast frame is neither.
        import base64, io
        from PIL import Image
        buf = io.BytesIO()
        Image.new("RGB", (4, 8), (200, 160, 112)).save(buf, "JPEG")
        frame = {"method": "Page.screencastFrame",
                 "params": {"sessionId": 7, "data": base64.b64encode(buf.getvalue()).decode()}}
        cdp = FakeCdp()
        cdp.events = [frame, dict(frame)]

        async def wait_event(name, timeout=120):
            return cdp.events.pop(0)
        cdp.wait_event = wait_event

        r, g, b = asyncio.run(wp.mean_colour(cdp))
        methods = [m for m, _ in cdp.calls]
        self.assertNotIn("Page.captureScreenshot", methods)
        self.assertEqual(methods, ["Page.startScreencast", "Page.screencastFrameAck", "Page.stopScreencast"])
        self.assertGreater(r, 150)
        self.assertEqual(cdp.events, [], "a stale frame was left to be read next time")


class EnterFromLogo(unittest.TestCase):
    def test_one_tap_when_the_fade_is_slow(self):
        # The fade reads ~143 red 1.5 s after the accepted tap and ~121 later. A second tap in
        # that window opens the contact menu on the title and the screen never goes dark.
        reads = iter([(217, 172, 112), (143, 105, 66), (143, 105, 66), (121, 83, 53)])
        taps = []

        async def colour(cdp):
            return next(reads)

        async def tap(cdp, x, y):
            taps.append((x, y))

        with mock.patch.object(wp, "mean_colour", colour), \
                mock.patch.object(wp, "touch_tap", tap), \
                mock.patch.object(asyncio, "sleep", mock.AsyncMock()):
            entered = asyncio.run(wp.enter_from_logo(FakeCdp()))
        self.assertTrue(entered)
        self.assertEqual(len(taps), 1)


class JourneyScreens(unittest.TestCase):
    """tool/check_journey.py's readings of the screen, on made-up screens."""

    def setUp(self):
        global cj, Image
        import check_journey as cj  # noqa: E402
        from PIL import Image

    def test_logo_tan_and_dark_title(self):
        self.assertTrue(cj.logo_like(Image.new("RGB", (64, 40), (200, 150, 110))))
        self.assertFalse(cj.logo_like(Image.new("RGB", (64, 40), (60, 30, 20))))

    def test_gallery_is_grey_and_bold_is_bright(self):
        self.assertEqual(cj.scene(Image.new("RGB", (64, 40), (180, 175, 165))), "gallery")
        self.assertEqual(cj.scene(Image.new("RGB", (64, 40), (230, 190, 90))), "bold")

    def test_a_brown_card_in_front(self):
        im = Image.new("RGB", (400, 800), (180, 175, 165))
        im.paste((110, 60, 25), (80, 260, 320, 460))
        self.assertTrue(cj.cards_in_front(im))
        self.assertFalse(cj.cards_in_front(Image.new("RGB", (400, 800), (180, 175, 165))))

    def test_the_phone_drawer_is_one_warm_panel(self):
        self.assertTrue(cj.drawer_open(Image.new("RGB", (400, 800), (180, 130, 80))))
        im = Image.new("RGB", (400, 800), (180, 175, 165))
        im.paste((20, 20, 20), (0, 400, 400, 600))
        self.assertFalse(cj.drawer_open(im))

    def test_a_frozen_screen_has_not_moved(self):
        a = Image.new("RGB", (64, 40), (100, 100, 100))
        self.assertFalse(cj.moved(a, a.copy()))
        self.assertTrue(cj.moved(a, Image.new("RGB", (64, 40), (140, 100, 100))))
