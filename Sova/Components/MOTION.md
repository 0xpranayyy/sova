# MOTION.md: living illustrations in this project

> Copy this file next to the project's art (for example `src/art/MOTION.md`) and fill in **Part 2** as you learn the project. Part 1 is the method and stays as it is. The `rossark-motion-skill` reads this file first, and Part 2 overrides the skill's defaults.

---

## Part 1. The method

**The goal:** anything drawn (a character, a plant, a flame, a street, a logo, a chart) feels alive and calm. Nothing teleports, nothing bounces, nothing shouts.

### Principles
1. **Never teleport:** interpolate everything; never swap drawings.
2. **Calm by default:** strong curves, no bouncy overshoot.
3. **Small amplitudes:** when unsure, halve it.
4. **Arcs and pivots:** each moving part is a layer rotating around its joint (stem base, hinge, neck, hook).
5. **Overlap and follow-through:** tips and trailing parts move later and further; give each part the same wave with a growing phase delay.
6. **Variety without chaos:**
   - repeated items get a seeded phase, speed and size;
   - nothing moves in sync, and there's no random value per frame.
7. **One main action per scene, plus two or three idle loops.** Side things stay quiet.
8. **Opacity only to appear or disappear.**
9. **The layout never moves:** motion lives inside the drawing.
10. **Reduced motion:** loops freeze on a good frame 0, and one-shots show their final frame.
11. **Nothing runs unseen:** pause off screen, when hidden and in the background.
12. **Enough frames:** anything under ~100 ms flickers at 30 fps; render and export at 60 when you can. Blinks close in ~110 ms and reopen in ~190 ms.
13. **Interface rules:**
    - frequency decides how much (often seen = barely moves; rare moments get the delight);
    - every motion has a purpose;
    - shared elements travel, never teleport;
    - interface moves stay under 300 ms;
    - exits are faster than entrances;
    - nothing appears from scale 0;
    - interruptions continue from the current value.

### The engine
- **Clocks:** a loop clock for idle life, a one-shot clock for a scene that tells an action. One per character, group or scene.
- **Tracks:** keyframes `[ms, value, 'out'?]` read with `track(t, keys)`. The last key equals the first. `track` stops at every key, so use it for one move (a blink, a lid). For acting (a chain of poses), use `flow(t, keys)`, which passes through the keys without stopping and never overshoots.
- **Helpers:**
  - `wave` (−1 to 1), for sway and breathing;
  - `loop` (0 to 1), for drift and falling;
  - `bell`, to fade in and out;
  - `seg`, for one beat of a one-shot;
  - `seeded(i)`, for per-item variety.
- **Curves:**
  - travel uses ease-in-out `(0.77, 0, 0.175, 1)`;
  - open and arrive use ease-out `(0.23, 1, 0.32, 1)`;
  - leaving uses ease-in;
  - endless loops are linear.

### Quick recipes
| Subject | Recipe |
|---|---|
| Character | breathing 1–2 units over 3–5 s; a blink every 3–4 s; pupils glide; head tilt 3–6° |
| Waiting to be tapped | a jiggle every ~270 ms: squash 2%, widen 2%, the bulge trading sides |
| Floating figure | rises in from 30% of its height below, drifts 5% down and up, leaves rising |
| Tail, hair, ears | rotation around the root, phase delayed along the chain, 4–10° |
| Plant | sway 1.5–4° around the base over 3–6 s; leaves on seeded phases |
| Cloth, flag | a wave that travels along the length, growing away from the fixed edge |
| Fire | a lean of 2–4° and a 3–6% stretch on two waves of different periods |
| Smoke, steam | rises 8–14 units and fades in and out with `bell` |
| Water | ripples grow and fade; floating things bob 1–2 units and rock 2° |
| Rain, snow | seeded `loop`s; snow sways sideways |
| Sky | clouds drift over 20–60 s with parallax; sun rays take 30–60 s per turn |
| Lights | a glow of 2–5% over 2–4 s; stars twinkle at seeded times |
| Machines | gears turn linearly by ratio; a clock hand steps with ease-out |
| Phone | ±3° bursts, then a pause |
| Icon, logo | plays once on appear, then rests |
| Chart | a one-shot draw-on, with bars staggered 40–80 ms |

### Acting (a whole character)
- **Every channel:** key pose (`flow`) + idle (`wave`s, never off while on stage) + follow-through (the parent read 90–140 ms earlier) + accents (a `wave` inside a `seg` window).
- **Arms:** an upper arm and a forearm share a round elbow; the forearm points at shoulder angle + elbow bend.
- **Head turns:** slide the face toward the turn (eyes 10, nose 13 in a 100-wide head) and the ears the other way. Blink on the turn.
- **Weight:** the hips shift and carry the upper body, and the legs angle to keep the feet under it.
- **Landing:** hover, then fall with gravity and stretch; squash hard (0.8) on contact and keep the volume (`width = 1 / height^0.6`).
- **In the air:** limp feet (toes down, one knee folded, trading slowly). The shadow stays on the floor and scales with the height.
- **Props:** enter from off screen already moving and roll by distance / radius. The eyes follow them. A kick hits at the middle of the swing; the prop leaves as a throw, spinning, with a short squash.
- **Asymmetry:** the arms never mirror each other.
- **Camera:** a view from a little above is a whole build, not a tweak: the head is 40–50% of the height, the torso is short and narrower than the head, the legs are short, the feet are round from above, and the shadow is a wide oval with the feet in its lower half. Keep it in one `build` object. A flat view keeps a thin pill shadow.
- **Framing:** on a phone, as big as the screen allows, with the feet low.

### From a reference video
- Contact sheets at the full frame rate (`tools/sheet.sh`).
- Measure motion with numbers (`tools/track_edges.py`): a 2% jiggle or a 5% float doesn't show to the eye.
- Sample colors from pixels (`tools/sample_colors.py`).
- Go part by part: feet, shadow, hands, head.
- Compare proportions as ratios of one unit (head widths). "Stretched" means a ratio is far off.
- Compare your render with the reference at the same moments.
- Don't publish a copy of someone else's art.

### Performance
- Everything is a function of one clock's time.
- Draw many items in one SVG or `Canvas`.
- Reset repeating animations to 0 before starting, and cancel them on cleanup.
- Declare curves at the top of the module.

### Workflow
1. Read Part 2 and the art file's header comments.
2. List what could live in the drawing.
3. Pick one main action and two or three idle loops.
4. Split the art into layers at their pivots.
5. Put the numbers in tokens.
6. Check frame 0, the final frames and the loop seams. For a character, look at a contact sheet of every 4th frame of your own render.
7. Run the checks.
8. Hand off: what moves, and what hasn't been seen on a real device.

---

## Part 2. This project (Sova)

### Where the code is
- **Platforms:** SwiftUI on iOS 26 (iPhone and iPad), SwiftUI on watchOS 26, and an HTML/JS film renderer for marketing videos (not in the app).
- **Engine:** `Sova/Support/Motion.swift` (and the same file in `WatchShared/`), from rossark-motion-skill (MIT): `track`, `flow`, `seg`, `wave`, `seeded`, the two curves, and `LoopClock` / `OneShotClock`.
- **The owl, iOS:** `Sova/Components/OwlMark.swift`. One `TimelineView` clock per owl drives one `Canvas`, drawn in owl units (x −14…114, y −4…128; the feet pivot is (50, 119), the shoulders are (6, 66) and (94, 66)). It's paused off screen, outside the active scene, with Reduce Motion, and always for owls under 30 pt.
  - **Idle loop, 9 s** (each owl phase-shifted by `seeded(size)`): two glances (500 ms glide, a 1.3 s hold), five blinks (on each glance, once between, and a double at the end of the loop), breathing 1.8% over 3.6 s, a tilt of ±1.5° over 4.7 s, and the wings swaying 2° / 1.6° on 3.1 s / 3.7 s.
  - **Eyes:** the pupil and shine slide inside the disc. The lids are feathers clipped 2 units wider than the eye; the upper lid comes down while the lower one rises, and they meet at y 52, where a closed eye shows a curved line.
  - **Happy** is a morph (260 ms ease-out): the pupils shrink away while the smile arc draws on from the middle, and the cheeks warm and grow 12%. It never swaps drawings.
  - **The hop** (a tap or `celebrate`) is a 900 ms `flow`: crouch 0.90, launch 1.08, apex, fall stretching 1.05, contact 0.83, rebound 1.04, settle. The width is `1 / sy^0.6`. Wing beats open in 100 ms and fold in 150 ms; the right wing is 40 ms behind; there's 1 beat for a tap and 3 for a celebration.
- **The owl, watchOS:** `WatchShared/WatchOwl.swift`. `WatchOwl` is a static `Canvas` drawing with `lid`, `wingLeft`, `wingRight` and `breath` inputs. `LiveWatchOwl` drives them from one `TimelineView` clock (30 fps), using `OwlMotion`: breath 1.2% over 3.6 s, wings 1.8° / 1.5° on 3.1 s / 3.7 s, and a 7.2 s blink loop (one blink, then a double). Complications use the static `WatchOwl`.
- **The film owl:** `owl()` and `hopState()` in the film renderer (scratchpad, not committed). It uses the same tokens as the apps.

### The owner's rules
- 2026-11-21: "stick to the original branding, use original logo". Flat sticker colors only, no gradients, glows or glass in brand motion.
- Celebrations (Day done, poke) may be playful; everything seen often stays calm.

### Rig limits
- The eyes are one group: a blink scales the group (iOS) or covers it with skin-colored lids clipped 2 units wider than the eye (watch, film). A closed eye shows a curved lash line where the lids meet, never blank skin.
- The happy eyes are a different drawing (a smile arc). The switch is a scale and opacity transition, never a hard swap.
- The owl has no separate head layer: tilt rotates the whole figure from the feet.

### How changes are checked
- There's no Swift toolchain in the cloud sessions. Build in Xcode (⌘B) or with Xcode Cloud, then check on device through TestFlight.
- Reduce Motion: the owl breathes no more, blinks stop, and the hop is skipped. The watch clock pauses when the screen dims (`isLuminanceReduced`).
