# CATTAINER v0.1 validation

Date: **2026-10-04, Asia/Tokyo**. Engine: **4.7.stable.official.5b4e0cb0f**. Host: Windows; rendered QA used the installed AMD Radeon OpenGL compatibility driver.

## Automated results

**342 checks passed; 0 failed.** Full evidence: `qa/test_results.json`.

- Exact / rotated / impossible / mirrored shapes and deterministic first placement.
- All four rotations of every cat, with no reflections.
- Edge removal, articulation rejection, nonempty board, unconditional restoration, diagonal disconnection, Undo and Reset.
- Unique ordered stage IDs, valid cats, all 160 rank-count cases and verifier witness fits.
- Full 16-cell box reports FIT without completion; failed cat stops the sequence; disconnected restored board cannot pass TEST.
- UI cell / Undo / Reset signals exercised in a running scene.
- SPACE starts TEST even when a board cell has keyboard focus; it does not toggle that cell.
- Runtime CLEAR, GREAT and PERFECT results.
- Stage 001–010 driven through accepted cuts and animated TEST; every required cat passed independently.
- Busy input cannot mutate the box; TEST does not add history.
- Progression unlock, all ten best scores, reload, preservation of better scores and persisted reduced-motion settings.
- Screen-touch events passed through Godot's input system and toggled a cell with mouse-from-touch emulation.
- Converted loop music loads and has the expected >200-second duration.

## Exhaustive independent verification

All 4×4 masks with at least five cells are enumerated. Masks with fewer cells cannot contain any five-cell cat and are excluded by that lower bound. Minima search examines increasing sizes, filters to connected masks and tests each cat separately. Rotations and translated board masks count as distinct optimal states; symmetry equivalents are not deduplicated.

| Stage | Cats | Minimum | Optimal masks |
|---|---|---:|---:|
|001|LOAF|5|24|
|002|LOAF, SPLOOT|6|16|
|003|LOAF, CURL|6|12|
|004|LONG, SPLOOT|6|8|
|005|LONG, CURL|6|12|
|006|SPLOOT, CURL|6|32|
|007|LOAF, LONG|7|56|
|008|LOAF, LONG, SPLOOT|7|16|
|009|LONG, SPLOOT, CURL|7|32|
|010|LOAF, LONG, SPLOOT, CURL|8|136|

The supplied thresholds were retained: **10/10 verified**. `data/verification.json` is reproducible with `python tools/verify_stages.py --write`.

## UI and rendered interaction

The Godot skill's native `scenario_runner.gd` was executed directly from PowerShell, with the scene viewport explicitly set before startup.

| State | Size | Layout findings |
|---|---|---:|
| Normal Stage 010 | 360×800 |0|
| PERFECT result |360×800|0|
| Normal Stage 010 |720×1280|0|
| Help, settings, stage picker |360×800|0 each|

Every layout report passed `fail_on: ["any"]`: no zero-size, entirely offscreen or unexpected overlapping controls. Rendered screenshots were also visually inspected for partial clipping, text readability and sprite contamination; the cat atlas uses tight source regions to exclude neighboring whiskers.

The 360×800 scenario sends actual mouse input to cut, Undo, Reset and TEST, asserts each resulting board mask and checks the asynchronous PERFECT outcome. TEST and PERFECT screenshots came from the live sequence.

- [360×800 normal play](qa/normal_360.png)
- [360×800 TEST](qa/test_360.png)
- [360×800 PERFECT](qa/perfect_360.png)
- [720×1280 normal play](qa/normal_720.png)
- [Help](qa/help_360.png), [settings](qa/settings_360.png), [stage picker](qa/stages_360.png)

## Project and build checks

- Whole-project resource loading and all scene instantiation passed. Native debug diagnostics: **0 errors, 0 parse errors, 0 project warnings**.
- Normal source boot is clean. Headless runs deliberately do not start background playback; rendered builds play music normally.
- Matching Windows x86_64 debug and release templates were present, and exports completed.
- Debug and release exported executables ran their internal QA entry (`-- --qa --stage=10 --mask=383 --smoke`), dispatched the real TEST button, checked music playback, Stage 010 PERFECT and saved unlock, and captured a rendered screenshot. Evidence: `qa/export_smoke.json`, `qa/release_smoke.json` and `qa/export_smoke.png`.
- Runtime needs no Python, network connection or external plugin.
- Production progression starts at Stage 001; `DEBUG_UNLOCK_ALL` remains false.

Harness note: bundled Python launcher wrappers did not work reliably on this Windows/Python 3.14 host (timeouts and an unavailable POSIX `killpg` call). Direct native Godot calls succeeded. The external scenario harness emits enum-cast warnings in its own scripts; those are separate from the project, whose strict static and runtime logs are clean.

## Human playtest items / limits

These are intentionally not claimed as completed human or hardware tests:

- [ ] A new player understands that cats enter separately, without reserving disjoint spaces.
- [ ] Stage 002 teaches reuse of one box; Stage 004 makes rotation noticeable.
- [ ] Stage 007's multiple valid solutions feel natural; Stage 010 feels like a small final exam.
- [ ] Cuts, connectivity rejection, the 0.7–2.6-second TEST sequence and sound levels feel good during a longer session.
- [ ] Android / physical touchscreen device testing (not part of this Windows prototype).

The illustrated cat over a placement is decorative. Colored occupied cells and the tiny logical diagrams are the exact fit geometry. Restoration can temporarily create an island; it must be connected before TEST. Windows binaries are unsigned local prototypes.
