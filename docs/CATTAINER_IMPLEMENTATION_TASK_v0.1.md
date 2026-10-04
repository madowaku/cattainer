# CATTAINER Implementation Task v0.1

## 0. Goal

Build a **playable Godot 4.7 prototype** of CATTAINER for Windows 11, using the repository:

`https://github.com/madowaku/cattainer.git`

The prototype must prove the core game loop:

> **Cut away cardboard cells to design the smallest connected box that can fit every required cat pose, one cat at a time.**

This is **not** a simultaneous packing puzzle.  
Each cat is tested independently against the same final container shape.

The first milestone is **Stage 001–010**, fully playable, with deterministic fit checks, clear rank feedback, and a lightweight “cat enters the box” presentation.

Do not overbuild. The priority is:

1. rule clarity
2. satisfying cell removal
3. readable fit-test animation
4. reliable solver logic
5. clean foundation for future 5×5 / generated stages

---

# 1. Product Identity

## Working title

**CATTAINER**

Subtitle is optional and not required for v0.1.

## Core fantasy

“You are designing the smallest possible box that any of these cats can fit into.”

The humor comes from the fact that the cats are different shapes, but only one enters the box at a time.

## Core mechanic

- Board: 4×4
- Every board cell begins as cardboard unless the stage defines otherwise.
- Player removes/restores cardboard cells.
- Remaining active cells must stay 4-connected.
- Pressing `TEST` checks each required cat independently.
- Cats may:
  - translate
  - rotate by 90°
- Cats may **not** reflect.
- If all required cats can fit, the stage clears.
- Fewer remaining cells produce a better rank.

---

# 2. Tech

- Engine: **Godot 4.7**
- Language: **GDScript**
- Target:
  - Windows desktop first
  - layout should also be mobile-friendly for future Android
- Internal reference resolution:
  - primary design target: **360×800**
  - secondary target: **720×1280**
- No external plugins required for v0.1.
- No network dependency.
- No Python dependency at runtime.

Python may exist only under `/tools/` for offline stage verification.

---

# 3. Repository Structure

Create this structure:

```text
cattainer/
├─ project.godot
├─ README.md
├─ assets/
│  ├─ ui/
│  ├─ cats/
│  └─ audio/
├─ data/
│  ├─ cats.json
│  └─ stages.json
├─ scenes/
│  ├─ main.tscn
│  ├─ game.tscn
│  ├─ board_cell.tscn
│  ├─ cat_card.tscn
│  └─ result_overlay.tscn
├─ scripts/
│  ├─ main.gd
│  ├─ game.gd
│  ├─ board.gd
│  ├─ board_cell.gd
│  ├─ fit_solver.gd
│  ├─ stage_loader.gd
│  ├─ cat_view.gd
│  └─ ui_feedback.gd
├─ tools/
│  └─ verify_stages.py
├─ tests/
│  ├─ test_fit_solver.gd
│  ├─ test_stage_data.gd
│  └─ test_board_rules.gd
└─ docs/
   ├─ CATTAINER_IMPLEMENTATION_TASK_v0.1.md
   └─ VALIDATION_v0.1.md
```

Keep gameplay logic independent from visual presentation.

---

# 4. Cat Definitions

All v0.1 cats use 5 cells.

Use these exact logical shapes.

Coordinates are local integer grid coordinates.

## LOAF

```text
■■
■■
■
```

```json
[[0,0],[1,0],[0,1],[1,1],[0,2]]
```

## LONG

```text
■
■
■
■■
```

```json
[[0,0],[0,1],[0,2],[0,3],[1,3]]
```

## SPLOOT

```text
■■■
 ■
 ■
```

```json
[[0,0],[1,0],[2,0],[1,1],[1,2]]
```

## CURL

```text
■ ■
■■■
```

```json
[[0,0],[2,0],[0,1],[1,1],[2,1]]
```

Store these in `data/cats.json`.

Example:

```json
{
  "LOAF": {
    "cells": [[0,0],[1,0],[0,1],[1,1],[0,2]],
    "allow_rotation": true,
    "allow_reflection": false
  }
}
```

---

# 5. Fit Solver

Implement `FitSolver`.

## Required behavior

Input:

- active box cells
- one cat shape
- board width / height

Output:

```gdscript
{
    "fits": true,
    "rotation": 90,
    "offset": Vector2i(1, 0),
    "placed_cells": [...]
}
```

If no fit exists:

```gdscript
{
    "fits": false
}
```

## Algorithm

For each unique rotation:

1. normalize cat coordinates to top-left origin
2. compute rotated bounding box
3. iterate every legal board offset
4. place rotated cat at offset
5. if every cat cell exists in active box cells:
   - return success immediately

No reflection in v0.1.

Because the board is only 4×4, brute force is preferred.

The runtime solver must be deterministic.

When multiple placements exist, choose the first result using deterministic ordering:

1. rotation: 0, 90, 180, 270
2. y ascending
3. x ascending

---

# 6. Board Rules

## Default state

Stage begins with all 16 cells active.

## Cell interaction

Primary interaction:

- click / tap active cell → remove cell
- click / tap removed cell → restore cell

Use a short 100–160 ms animation.

Suggested feel:

- active → removed:
  - slight scale-down
  - cardboard scrap flick / dust
- removed → active:
  - soft pop-in

Do not use physically simulated cardboard pieces in v0.1.

## Connectivity

The remaining active box must be **4-connected**.

If removing a cell would split the container:

- reject the removal
- briefly shake the cell
- show a tiny hint:
  - `Keep the box connected.`

Restoring a cell is always allowed.

## Empty board

Never allow zero active cells.

---

# 7. Stage Data

Create `data/stages.json`.

Each stage must contain:

```json
{
  "id": "001",
  "cats": ["LOAF"],
  "clear_cells": 8,
  "great_cells": 6,
  "perfect_cells": 5
}
```

Rank logic:

- `PERFECT`: remaining cells <= perfect_cells
- `GREAT`: remaining cells <= great_cells
- `CLEAR`: remaining cells <= clear_cells
- If all cats fit but above clear_cells:
  - still show `FIT!`
  - do not complete stage
  - message: `All cats fit. Make the box smaller.`

This avoids accidental clear on an almost untouched 16-cell board.

---

# 8. Stage 001–010

Use this first-pass stage pack.

The exact thresholds may be adjusted after human playtest, but `perfect_cells` should match verified minima.

| Stage | Cats | Perfect |
|---|---|---:|
| 001 | LOAF | 5 |
| 002 | LOAF + SPLOOT | 6 |
| 003 | LOAF + CURL | 6 |
| 004 | LONG + SPLOOT | 6 |
| 005 | LONG + CURL | 6 |
| 006 | SPLOOT + CURL | 6 |
| 007 | LOAF + LONG | 7 |
| 008 | LOAF + LONG + SPLOOT | 7 |
| 009 | LONG + SPLOOT + CURL | 7 |
| 010 | LOAF + LONG + SPLOOT + CURL | 8 |

Suggested rank thresholds:

```text
Stage 001: CLEAR 8 / GREAT 6 / PERFECT 5
Stage 002: CLEAR 9 / GREAT 7 / PERFECT 6
Stage 003: CLEAR 9 / GREAT 7 / PERFECT 6
Stage 004: CLEAR 9 / GREAT 7 / PERFECT 6
Stage 005: CLEAR 9 / GREAT 7 / PERFECT 6
Stage 006: CLEAR 9 / GREAT 7 / PERFECT 6
Stage 007: CLEAR 10 / GREAT 8 / PERFECT 7
Stage 008: CLEAR 10 / GREAT 8 / PERFECT 7
Stage 009: CLEAR 10 / GREAT 8 / PERFECT 7
Stage 010: CLEAR 12 / GREAT 10 / PERFECT 8
```

---

# 9. Main Gameplay Screen

Aim for the spirit of the final visual concept:

- warm cardboard / paper visual identity
- cozy cat illustrations
- readable premium puzzle-game UI
- not childish
- tactile but clean

## Layout

Portrait-first.

### Header

- `CATTAINER`
- Stage label
- optional previous / next stage arrows
- settings button
- rules/help button

### Objective

Display:

`Make the smallest box for every cat.`

Below:

`Perfect: 8 cells`

### Main board

- centered 4×4 grid
- largest visual element
- warm cardboard active cells
- darker recessed empty cells
- obvious cell boundaries
- current cell count visible near board

### Cat row

Show required cats only.

Each card includes:

- tiny cat art / silhouette
- name
- test state:
  - waiting
  - checking
  - fit
  - fail

Example:

```text
LOAF   ✓
LONG   ✓
SPLOOT …
CURL   ×
```

### Controls

Primary:

`TEST`

Secondary:

- `UNDO`
- `RESET`

### Rank strip

Always show:

- CLEAR
- GREAT
- PERFECT

Highlight the current achievable rank based on current cell count.

Do not mark final success until TEST passes.

---

# 10. Test Sequence

Pressing TEST should be a small event.

Do not instantly output four checkmarks.

Sequence:

1. disable board input
2. dim nonessential UI slightly
3. for each required cat:
   - highlight cat card
   - find fit
   - if fit:
     - animate simplified cat block silhouette onto board
     - hold 300–450 ms
     - mark card ✓
     - fade cat silhouette out
   - if fail:
     - attempt animation ends with gentle bump / squash
     - mark card ×
     - stop sequence
4. restore board input

Total test duration should remain short.

Target:

- 1 cat: ~0.7–1.0 sec
- 4 cats: ~2.0–3.0 sec

Allow tapping TEST again after sequence completes.

Optional later:
- hold TEST to skip animation

Not required in v0.1.

---

# 11. Cat Presentation

Important:

Logical cats are polyominoes.

Visual cats should eventually be cute illustrated poses.

For v0.1:

- use clean placeholder cat art if needed
- but ensure each cat pose visually resembles its logical shape

Suggested silhouettes:

- LOAF → compact sitting / loaf
- LONG → stretched body
- SPLOOT → flat spread pose
- CURL → curled pose

During board-fit animation, it is acceptable to display:

- translucent colored cat silhouette
- block silhouette
- simple squishy cat outline

Do not spend excessive time on final art before gameplay is verified.

---

# 12. Undo / Reset

## Undo

Maintain a stack of board states.

Each accepted cell toggle pushes one state.

Undo restores previous board shape.

TEST must not add undo states.

## Reset

Returns the stage to its initial board.

Confirm dialog is not needed in v0.1.

---

# 13. Completion

When all cats fit:

Determine rank.

## Below CLEAR threshold

Show:

`ALL CATS FIT`

and:

`Make the box smaller.`

Do not complete stage.

## CLEAR / GREAT / PERFECT

Show a compact result overlay.

Examples:

```text
ALL CATS FIT!
GREAT
8 cells
```

or:

```text
PERFECT!
7 cells
```

Include:

- NEXT
- RETRY
- optional `Try another perfect shape`

For stages with multiple perfect solutions, do not imply one canonical shape is required.

---

# 14. Progression

Local-only save.

Persist:

- highest unlocked stage
- best cell count per stage
- best rank per stage

Suggested ConfigFile:

`user://save.cfg`

Stage unlock:

- clearing Stage N unlocks Stage N+1
- Stage 001 unlocked by default

For developer/debug mode, allow all stages unlocked with a constant.

---

# 15. Visual Direction

Do not aim for photorealism.

Use:

- warm cardboard
- cream UI panels
- dark brown typography
- one green primary action color
- subtle gold for PERFECT
- soft paper / corrugated texture
- very restrained shadows

The board must remain more readable than decorative.

Priority order:

1. board
2. cat requirements
3. TEST
4. rank goal
5. decorative cats

Avoid visual clutter.

---

# 16. Motion

Keep motion short and tactile.

Recommended timings:

- cell remove: 120–160 ms
- cell restore: 100–140 ms
- invalid remove shake: 180–240 ms
- cat card focus: 120 ms
- cat fit move: 250–400 ms
- fit confirmation pulse: 160–220 ms
- PERFECT celebration: < 1.5 sec

No long transitions.

---

# 17. Audio

Optional but desirable if implementation remains small.

Use simple temporary SFX:

- cardboard pop
- soft tap
- cat fit “plop”
- fail bump
- perfect sparkle

Do not block v0.1 on audio asset sourcing.

---

# 18. Offline Verification Tool

Create `tools/verify_stages.py`.

Responsibilities:

- parse `cats.json`
- parse `stages.json`
- enumerate connected 4×4 box states
- compute minimum possible cell count for each stage
- confirm `perfect_cells`
- report number of optimal shapes
- exit nonzero on invalid stage data

Example output:

```text
CATTAINER Stage Verification v0.1

001  LOAF                         min=5  PASS
002  LOAF,SPLOOT                  min=6  PASS
...
010  LOAF,LONG,SPLOOT,CURL        min=8  PASS

10/10 PASS
```

Python is development-only.

---

# 19. Automated Tests

At minimum:

## Fit solver

Test:

- exact match
- rotated match
- no fit
- reflection is rejected
- deterministic first solution

## Board connectivity

Test:

- removing edge cell allowed
- removing articulation cell rejected
- restoring cell allowed

## Stage data

Test:

- stage IDs unique
- cats exist
- thresholds satisfy:
  - perfect <= great <= clear
- perfect matches verifier output

## Rank

Test threshold boundaries exactly.

---

# 20. Human Playtest Checklist

Add to `docs/VALIDATION_v0.1.md`.

Observe:

### Rule clarity

- Does player understand that cats enter one at a time?
- Does player incorrectly try to reserve different spaces for different cats?
- Is `TEST` understood without explanation?

### Feel

- Is removing cells satisfying?
- Does reconnect rejection feel fair?
- Is TEST too slow?

### Puzzle quality

- Does Stage 002 produce the first “one box, separate cats” realization?
- Does Stage 004 make rotations noticeable?
- Does Stage 007 introduce “multiple valid shapes” naturally?
- Does Stage 010 feel like a small final exam?

### UI

Check:

- 360×800
- 720×1280
- mouse
- touch emulation

No overlap, clipping, or unreadable text.

---

# 21. Acceptance Criteria

v0.1 is complete when all conditions pass:

- [ ] Godot 4.7 project opens without errors.
- [ ] Stage 001–010 playable.
- [ ] Board cell remove/restore works.
- [ ] Invalid disconnected shapes are prevented.
- [ ] Undo works.
- [ ] Reset works.
- [ ] TEST checks every cat independently.
- [ ] Cat rotation works.
- [ ] Reflection is not used.
- [ ] CLEAR / GREAT / PERFECT rank works.
- [ ] Stage progression saves locally.
- [ ] Runtime contains no Python dependency.
- [ ] Offline verifier confirms all 10 perfect minima.
- [ ] Automated gameplay-logic tests pass.
- [ ] 360×800 layout has no clipping.
- [ ] 720×1280 layout has no clipping.
- [ ] README explains how to run.
- [ ] `docs/VALIDATION_v0.1.md` records test results and any known issues.

---

# 22. Non-goals for v0.1

Do **not** implement yet:

- 5×5
- procedural stage generation in Godot
- 100-stage campaign
- skins
- monetization
- online leaderboard
- Steam integration
- Android export
- localization beyond simple string-ready architecture
- reflections
- immovable cells
- obstacles
- holes with special behavior
- multiple simultaneous cats
- elaborate narrative

First prove the original mechanic.

---

# 23. Preferred Implementation Order

1. Godot project skeleton
2. cat/stage data
3. pure fit solver
4. automated solver tests
5. 4×4 board
6. connectivity checks
7. cell editing
8. TEST sequence
9. rank logic
10. Undo / Reset
11. Stage progression
12. visual polish
13. offline Python verifier
14. 360×800 / 720×1280 QA
15. final validation report

---

# 24. Deliverables

Return:

1. playable Godot 4.7 project
2. Stage 001–010
3. `tools/verify_stages.py`
4. automated test results
5. `docs/VALIDATION_v0.1.md`
6. screenshots:
   - 360×800 normal play
   - 360×800 TEST sequence
   - 360×800 PERFECT
   - 720×1280 normal play
7. concise implementation summary
8. known issues / human playtest items
9. commit hash

Do not claim real-device testing unless actually performed.

---

# 25. Final Design Principle

The prototype succeeds if the player quickly understands:

> “I’m not packing all the cats together.  
> I’m designing one tiny box that works for every cat.”

The best moment is:

> “Wait. If I rotate that cat, I can remove one more cell.”

Everything in v0.1 should support that realization.
