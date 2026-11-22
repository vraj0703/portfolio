# What the site measures, and why

Vishal's order (2026-11-15): track the visitor's journey, the loading time, frame drops and hangs, the
interactions, and who a visitor probably is (a recruiter opens the CV, an investor studies a project, an
advocate leaves a testimonial), with PostHog, "genuine and effective data pointers rather than slabs of data
without meaning". Feature flags for the Connect and Menu buttons come from the same place (TANTR-8).

The rule this plan is written to: **an event exists only if it answers one of the six questions below.**
Fifteen events, no more. Anything else is a property on one of them, or is not collected.

## The six questions

| # | Question | Answered by |
|---|---|---|
| 1 | How many visitors never get in, and where in the loading do they give up? | `site_loaded`, `load_abandoned` |
| 2 | Is the site smooth on the machines people actually use? | `scene_health`, `hang`, `$exception` |
| 3 | Where do visitors go, in what order, and where do they leave? | `$pageview` per scene |
| 4 | Who is this visitor likely to be? | `cv_opened`, `contact_link_clicked`, `project_case_opened`, `project_link_opened`, `publication_opened` |
| 5 | Does a visitor who could recommend Vishal get to the end of doing it? | the four `testimonial_*` events |
| 6 | Where did they come from? | referrer and campaign tags, collected by PostHog itself |

## The events

Names are `object_verb`, lower snake case. Every event carries, without being asked: scene, viewport size,
device class (`phone` / `tablet` / `desktop`), and `visit_number`: how many times this browser has opened the
site (1 on a first visit).

### Loading (question 1)

| Event | When | Properties |
|---|---|---|
| `site_loaded` | once, when loading ends and the logo screen first accepts the tap (the loading gate lifting) | `ms_first_paint`, `ms_engine_ready`, `ms_gallery_built`, `ms_ready` (all from navigation start); `build_phases` (the BUILD_TIMING phases, ms each); `renderer`; `cores`, `memory_gb`, `connection` (when the browser tells); `intro_skipped`; `pointer_source`, `tilt_permission` (see below) |
| `load_abandoned` | the page is hidden or closed before `site_loaded`, which is to say during loading | `phase_reached` (LoadingPhase), `ms_waited`, same device properties |

Not "when the title takes input": the logo screen waits for the visitor's tap, so a time taken there
measures their patience, not the site (53 s in the first walk). The time a visitor spends on the logo before
tapping is already the gap between the `/#/logo` and `/#/title` page views; nothing is added for it.

`load_abandoned` is the number that says what the loading work is worth: of ten people who arrive, how many
see the title. It must be sent on `pagehide` with a beacon, or it never arrives.

### Smoothness (question 2)

| Event | When | Properties |
|---|---|---|
| `scene_health` | on leaving a scene, or when the page is hidden; at most one per scene visit, and only if the visit lasted 3 s | `scene`, `seconds`, `frames`, `frame_ms_p50`, `frame_ms_p95`, `slow_frames` (over 50 ms), `stalls` (over 500 ms), `worst_frame_ms`; `pointer_source`, `tilt_permission` (see below) |
| `hang` | a single frame or main-thread stall longer than 2 s (the web's nearest thing to an ANR); at most five a visit | `scene`, `ms`, `during` (what was happening: `gallery_build`, `focus`, `walk`, …) |
| `$exception` | any uncaught Flutter or platform error | PostHog's own error format, with the stack |

A summary per scene, not a stream of frames: `FrameWatch` already measures this for the console; the same
numbers are folded and sent once. Frame-by-frame data would be the slab this plan is written against.

### The journey (question 3)

One `$pageview` per scene, with the scene in the URL's fragment so PostHog's own tools (paths, web analytics,
heatmaps) work without anything bespoke:

`/#/logo` · `/#/title` · `/#/gallery` · `/#/gallery/<project-id>` (a focused piece) · `/#/testimonials` ·
`/#/skills` · `/#/contact` · `/static` (the plain page)

The fragment is for analytics only at first; whether it also becomes a real deep link is a separate decision.

### Who they probably are (question 4)

| Event | When | Properties | Reads as |
|---|---|---|---|
| `cv_opened` | the CV link is opened | `from` (scene) | recruiter |
| `contact_link_clicked` | a contact link is opened | `channel` (`email`, `linkedin`, `github`), `from` | recruiter or collaborator |
| `project_case_opened` | the sheet of a piece is opened | `project` | someone studying the work |
| `project_link_opened` | the link out of a piece is followed | `project`, `host` | strong interest in that product |
| `publication_opened` | a package or the Play listing is opened | `registry` (`npm`, `pypi`, `play`), `name` | developer |

These are signals, not labels: nothing is written onto the visitor. The groups are built in PostHog as saved
views, so their definitions can change without a release:

- **Recruiter-like:** `cv_opened`, or `contact_link_clicked`, or arrived by a CV link (`utm_source=cv`).
- **Investor- or partner-like:** `project_case_opened` for `shunya-systems` or `tantr`, and either
  `project_link_opened` or more than a minute in the gallery.
- **Developer-like:** `publication_opened`, or time in the skills hall.
- **Advocate:** `testimonial_form_opened`.

Honest limit: a visitor is a guess from two or three clicks. The surest signal of who someone is is the link
they arrived by, which is why question 6 matters more than it looks.

`cv_opened` cannot fire today: `ContactProfile.cv` is unset. It starts working the day the CV has a URL.

### Testimonials (question 5)

| Event | When | Properties |
|---|---|---|
| `testimonial_form_opened` | "add yours" is pressed | |
| `testimonial_text_copied` | the text is copied | `length` (bucketed: `short`, `medium`, `long`), never the text |
| `testimonial_linkedin_opened` | the LinkedIn step is opened | |
| `testimonial_submitted` | reserved for the day submitting happens on the site | |

Funnel: `/#/testimonials` → `testimonial_form_opened` → `testimonial_text_copied` → `testimonial_linkedin_opened`.

### Where they came from (question 6)

PostHog records referrer and campaign tags by itself. What makes it useful is tagging the links Vishal
controls, once: the CV (`?utm_source=cv`), the LinkedIn profile (`?utm_source=linkedin`), the GitHub profile
(`?utm_source=github`), an email signature (`?utm_source=email`), and one per application or pitch when it
matters (`&utm_campaign=<company>`). This is the cheapest and most reliable "who is this" there is.

### Two controls

`sound_toggled` (`muted`) and `intro_skipped`: two decisions are waiting on what visitors actually do.

### The menu and the radio (PORTFOLIO-23)

The radio moved into the drawer, on every screen; whether visitors find it there, and use it, decides
whether the wall radio and the drawer both earn their place.

- `menu_opened` (`scene`): the drawer opened, and on which screen.
- `radio_toggled` (`on`, `surface`: `drawer` | `wall`): the radio put on or off, and from where.
- `radio_station_changed` (`station`, `surface`: `drawer` | `wall`): the next station, and from where.

The title's heart (the way to the contact page) left the top row for the drawer's bar
(PORTFOLIO-24); it had no event of its own, so none is removed.

### The drawer's bar (PORTFOLIO-24)

- `nav_selected` (`destination`: `home` | `gallery` | `contact`, `from_scene`, `already_current`): a tap on the
  drawer's bottom bar. `already_current` is a tap that only closes the drawer: a visitor looking for somewhere
  they already are.

There is no separate "contact opened" event: arriving on the contact page is its own `$pageview`
(`/#/contact`), and a `nav_selected` with `destination: contact` just before it says it came from the bar.

### The pointer on phones (PORTFOLIO-27)

The logo's light, its rays and spring lines, and the title's sheen and parallax all follow one pointer. On a
phone it comes from a finger, the phone's tilt or a slow idle drift; on desktop from the mouse, or the drift once
the mouse has rested 8 s. Two properties say which, so "is the effect alive on phones?" has an answer. They are
properties on events already sent, not new events:

- `pointer_source` (`mouse` | `touch` | `tilt` | `drift` | `still`):
  - On `site_loaded`, the source at that moment: before the logo's tap, so on a phone `tilt` (Android) or
    `drift`, and on desktop `still`.
  - On `scene_health`, the source that drove the pointer longest during that scene visit. It is counted on the
    logo, title and contact screen, where the pointer lights anything; the gallery carries the last one.
  - `still` means the light is at the centre: reduced motion is on, or a desktop mouse has not moved yet.
- `tilt_permission` (`granted` | `denied` | `not_asked` | `not_needed`): what became of the motion permission.
  - Only iOS Safari asks, once, on the logo's tap.
  - `not_needed` covers browsers that give tilt without asking (Android Chrome) and those with no sensor.
  - `site_loaded` is sent before the tap, so on an iPhone it always says `not_asked`; the answer shows on the
    `scene_health` events after it.

## What is deliberately not collected

- No names, emails or text typed by visitors. The testimonial text never leaves the page through analytics.
- No autocapture of every click: inside a canvas it records coordinates without meaning.
- No frame-by-frame or per-second samples.
- No session recordings to begin with (see below).

## PostHog features, and whether they earn their place here

| Feature | Use it? | Why |
|---|---|---|
| Events, funnels, paths | yes | the six questions |
| Web analytics (visitors, sources, devices, countries) | yes | free with `$pageview` |
| Error tracking | yes | `$exception` with stacks; today errors on a visitor's machine are invisible |
| Feature flags | yes | the Connect and Menu buttons (TANTR-8); later, the intro skip |
| Web vitals | yes, but read with care | the page is one canvas, so "largest paint" means the loading screen; `site_loaded` is the real number |
| Heatmaps | only on still screens | useful on the logo, title, contact, a focused piece and the plain page; in the corridor the camera moves, so a click map there means nothing |
| Session replay | not yet | recording a canvas costs frames on a site that is already short of them; switch on for a small sample behind a flag once loading is fixed |
| Surveys | later | a one-question survey could ask recruiters what they were looking for |
| Self-driving | later | priced per use; worth it once there is traffic to read |

## Identity and privacy (Vishal's decision, 2026-11-16: return visits)

- **A stored anonymous id, no cookie.** PostHog keeps its anonymous id in the browser's localStorage
  (`persistence: 'localStorage'`), so a visitor who returns is the same visitor and "came back three times" can
  be seen; recruiters who come back are the case that matters. Nothing else identifies them: no names, no
  emails, no person profiles (`person_profiles: 'never'`).
- **`visit_number` on every event:** a counter kept beside the id in localStorage (`portfolio_visit_number`),
  raised once per page load and registered with PostHog as a super property. A first visit is 1; storage the
  browser refuses (a private window) counts as 1 and breaks nothing.
- **Do Not Track and Global Privacy Control are honoured:** when the browser sends either, the SDK is not
  started at all, so nothing is loaded, stored or sent, and every flag keeps its compiled default.
  (`respect_dnt: true` is set as well; PostHog's own check covers Do Not Track only.)
- **The honest paragraph** is on the plain page, `web/static/index.html` ("What this site measures"): what is
  collected, that an anonymous id and a visit count are stored, and that the signals above switch it off.
  `web/privacy-policy.html` is Jotter's policy, not the site's, and is not edited.
- Cookieless mode, the earlier default, is no longer used: it could not see a return visit.
- The project token is public by nature but is not committed: it reaches the build as
  `--dart-define=POSTHOG_TOKEN=…` from a repository secret. With no token every call is a no-op and the
  site behaves exactly as today.

## How it is built (for the seat)

- `domain/analytics/analytics.dart`: one interface (`capture(event, props)`, `screen(path)`, `flag(key, orElse)`),
  and a typed wrapper so event names and properties are written once, not as strings at call sites.
- `data/analytics/`: a PostHog implementation over the browser SDK through `dart:js_interop`, and a no-op.
  Prefer no new Dart dependency; say so if `posthog_flutter` turns out to be the better road.
- The SDK script is added to `web/index.html` so that it loads after the first paint and never blocks it;
  events raised before it is ready are queued and sent when it is.
- Sources that already exist: `LoadingProgress` / `LoadingPhase` and `BUILD_TIMING` for loading; `FrameWatch`
  for frames; `SceneBloc` state changes for scenes (one listener, not a call per widget).
- Feature flags `title_menu_button` and `gallery_walk_stick`: the compiled default is the present behaviour
  (shown). `title_connect_button` is dropped with the button it gated (PORTFOLIO-23); archive it in PostHog. A flag that is absent, or PostHog being unreachable, means the default. The first paint never waits.
- Tests: every event in this file exists in the typed wrapper and nowhere else as a string; a no-token build
  sends nothing; `load_abandoned` is sent on hide before load and not after; `scene_health` is capped; the
  flag default holds when the SDK is missing.

## The five saved views to make in PostHog

1. **Getting in:** arrivals → `site_loaded`, with `load_abandoned` by `phase_reached` and by device class.
2. **Smoothness:** `scene_health` p95 by scene and device class; `hang` count.
3. **The journey:** paths from `/#/title`.
4. **Who came:** the four groups, by week, by source.
5. **Testimonials:** the funnel above.
