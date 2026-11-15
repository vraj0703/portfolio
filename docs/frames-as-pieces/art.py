"""The seven drawings of the gallery pieces, as SVG markup on a 400 x 500 field, and each piece's label and case.
This is the reference the Dart painters are ported from: same coordinates, same counts. Run it to print the SVGs.
Classes: a-line (ink stroke, 2; w2 = 3; w3 = 4), a-faint (ink stroke 1 at 28%), a-fill (ink fill), a-hollow (ground fill, ink stroke 2),
a-accent (accent fill), a-accent-line (accent stroke 5)."""
import html as H, json, math, pathlib
f = lambda v: f"{v:.1f}"

def mesh():
    pts = [(200, 96), (330, 205), (282, 380), (118, 380), (70, 205)]
    s = '<circle cx="200" cy="250" r="176" class="a-faint"/>'
    for i in range(5):
        for j in range(i + 1, 5):
            s += f'<line x1="{pts[i][0]}" y1="{pts[i][1]}" x2="{pts[j][0]}" y2="{pts[j][1]}" class="a-line"/>'
    for i, (x, y) in enumerate(pts):
        s += f'<circle cx="{x}" cy="{y}" r="{15 if i == 0 else 9}" class="{"a-accent" if i == 0 else "a-fill"}"/>'
    return s

def five():
    s = ""
    for i in range(5):
        side = 300 - i * 52
        s += f'<rect x="{200 - side / 2}" y="{250 - side / 2}" width="{side}" height="{side}" rx="{18 - i * 2}" transform="rotate({i * 11} 200 250)" class="a-line w2"/>'
    return s + '<circle cx="200" cy="250" r="20" class="a-accent"/>'

def constellation():
    pts = []
    for i in range(12):
        a = i * 2.39996 + 0.6; r = 34 + 13.5 * i
        pts.append((200 + r * math.cos(a) * 0.86, 250 + r * math.sin(a) * 1.05))
    s = '<polyline points="' + " ".join(f"{f(x)},{f(y)}" for x, y in pts) + '" class="a-line"/>'
    for i, (x, y) in enumerate(pts):
        if i == 11: s += f'<circle cx="{f(x)}" cy="{f(y)}" r="15" class="a-accent"/>'
        elif i % 2 == 0: s += f'<circle cx="{f(x)}" cy="{f(y)}" r="8" class="a-fill"/>'
        else: s += f'<rect x="{f(x - 7)}" y="{f(y - 7)}" width="14" height="14" transform="rotate(45 {f(x)} {f(y)})" class="a-hollow"/>'
    return s

def marks():
    s = ""
    for i in range(67):
        row, col = divmod(i, 10)
        x, y = 74 + col * 28, 76 + row * 54
        s += f'<line x1="{x}" y1="{y}" x2="{x}" y2="{y + 36}" class="{"a-accent-line" if i == 66 else "a-line w3"}"/>'
    for row in range(7):
        n = 10 if row < 6 else 7
        s += f'<line x1="62" y1="{76 + row * 54 + 44}" x2="{74 + (n - 1) * 28 + 12}" y2="{76 + row * 54 + 44}" class="a-faint"/>'
    return s

def grid():
    s = ""
    for r in range(20):
        for c in range(16):
            x, y = 50 + c * 20, 60 + r * 20
            if (x - 200) ** 2 / 100 ** 2 + (y - 250) ** 2 / 124 ** 2 < 1: continue
            s += f'<circle cx="{x}" cy="{y}" r="2.4" class="a-fill"/>'
    for i, k in enumerate((1, 0.68, 0.36)):
        s += f'<rect x="{f(200 - 86 * k)}" y="{f(250 - 108 * k)}" width="{f(172 * k)}" height="{f(216 * k)}" rx="{f(26 * k)}" class="{"a-accent-line" if i == 2 else "a-line w2"}"/>'
    return s

def rings():
    s = ""
    for i in range(7):
        r = 34 + i * 26; a0, a1 = math.radians(200 - i * 9), math.radians(-20 + i * 9)
        x0, y0, x1, y1 = 200 + r * math.cos(a0), 330 + r * math.sin(a0), 200 + r * math.cos(a1), 330 + r * math.sin(a1)
        s += f'<path d="M{f(x0)} {f(y0)} A{r} {r} 0 0 1 {f(x1)} {f(y1)}" class="a-line w2"/>'
    return s + '<circle cx="200" cy="330" r="9" class="a-accent"/>'

def strokes():
    s = ""
    for i in range(5):
        y = 130 + i * 62; amp = 46 - i * 5
        s += f'<path d="M48 {y} C130 {y - amp} 150 {y + amp} 200 {y} S300 {y - amp} 352 {y}" class="{"a-accent-line" if i == 2 else "a-line"}" style="stroke-width:{3 + (i * 7) % 9}"/>'
    return s

P = [
 dict(t="Shunya Systems", line="A two-person company run with AI agents", num="22 written rules", tags=["Claude Code", "Python", "Salt"], years="2026", art=mesh(), acc="#c1900a", ground="#8a6a14", motif="Five machines, every one connected to every other. The filled one is where the plans are made.",
      summary="A company of two, Vishal and an AI chief of staff. The agent plans and reviews on one machine and hands the work to agents on the others, under 22 written rules that say what it may do alone, what it must ask about, and what it must never touch.", stats=["5 nodes", "22 written rules", "15 instruments"], stack=["Claude Code", "Python", "Salt", "Tailscale"], url=""),
 dict(t="tantr app", line="One runtime for what every app rebuilds", num="31 packages", tags=["Flutter", "Dart", "JSON Schema"], years="2026", art=five(), acc="#0f9f73", ground="#1d6b4f", motif="Five frames, one inside the next, around one centre: the five things, written once.",
      summary="Most product apps rebuild the same five things: forms, insight cards, notifications, asking the user to act, and chat. tantr writes them once behind one wire contract, and a new product is carved from a reference app in one command.", stats=["31 packages", "5 profiles", "7 apps"], stack=["Flutter", "Dart", "shelf", "JSON Schema"], url="https://tantr.app"),
 dict(t="Publications", line="Open-source packages and one Play Store app", num="12 published", tags=["Node", "Python", "Flutter"], years="", art=constellation(), acc="#4a40c8", ground="#37318a", motif="Twelve points on one thread: six packages, five projects, and the one app.",
      summary="The parts of the agent systems, published for anyone to install: six npm packages under @raj-sadan (mind, memory, knowledge, senses, a dashboard and a utility library) and five Python projects on PyPI, among them ai-constitution. Jotter, a notes app, is on Google Play.", stats=["6 npm packages", "5 PyPI projects", "1 Play Store app"], stack=["Node", "Python", "Flutter"], url="https://www.npmjs.com/~vraj0703"),
 dict(t="Twin Health", line="Digital health platform", num="67 releases, 0 hotfixes", tags=[], years="2022 –", art=marks(), acc="#5b5fe0", ground="#3f3d8f", motif="Sixty-seven strokes, one per release, none crossed out.",
      summary="A digital health platform, from 2022: 67 releases shipped without a single hotfix.", stats=["67 releases", "0 hotfixes", "$87K saved"], stack=[], url=""),
 dict(t="FieldAssist / PayU", line="Field force at scale, payment encryption", num="1,600+ files", tags=[], years="2016 –", art=grid(), acc="#b07d28", ground="#8a6b3a", motif="A field of many small parts, and at its centre three locks, one inside the next.",
      summary="At PayU, in fintech from 2016: client-side encryption of card PIN and PAN with Triple DES. At FieldAssist, in FMCG from 2018: an enterprise field-force app of more than 1,600 files, shipped in several flavors.", stats=["1,600+ files", "Multi-flavor", "Triple DES"], stack=[], url=""),
 dict(t="School and College", line="In preparation", num="", tags=[], years="", art=rings(), acc="#d98a0a", ground="#96600f", motif="Growth rings.", summary="", stats=[], stack=[], url="", soon=True),
 dict(t="Creative Works", line="In preparation", num="", tags=[], years="", art=strokes(), acc="#d94a3a", ground="#8f3027", motif="Brush lines.", summary="", stats=[], stack=[], url="", soon=True),
]

if __name__ == "__main__":
    for p in P:
        print(f"<!-- {p['t']} -->\n<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 400 500\">{p['art']}</svg>\n")
