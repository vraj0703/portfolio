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
