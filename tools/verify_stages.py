"""Exhaustive independent verifier. Python is never used by the game."""
import argparse
import itertools
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def orientations(shape):
    seen = set()
    for _ in range(4):
        min_x = min(x for x, y in shape)
        min_y = min(y for x, y in shape)
        normalized = tuple(sorted((x - min_x, y - min_y) for x, y in shape))
        if normalized not in seen:
            seen.add(normalized)
            yield normalized
        shape = [(-y, x) for x, y in shape]

def placements(shape):
    result = []
    for rotated in orientations(shape):
        width = max(x for x, y in rotated) + 1
        height = max(y for x, y in rotated) + 1
        for y in range(5 - height):
            for x in range(5 - width):
                result.append(sum(1 << ((cy + y) * 4 + cx + x) for cx, cy in rotated))
    return result

NEIGHBORS = []
for i in range(16):
    x, y = i % 4, i // 4
    NEIGHBORS.append(sum(1 << (ny * 4 + nx) for nx, ny in
                         [(x-1, y), (x+1, y), (x, y-1), (x, y+1)]
                         if 0 <= nx < 4 and 0 <= ny < 4))

def connected(mask):
    if not mask:
        return False
    reached = mask & -mask
    frontier = reached
    while frontier:
        cell = frontier & -frontier
        frontier ^= cell
        new = NEIGHBORS[cell.bit_length() - 1] & mask & ~reached
        reached |= new
        frontier |= new
    return reached == mask

def verify():
    cats = json.loads((ROOT / 'data/cats.json').read_text())
    stages = json.loads((ROOT / 'data/stages.json').read_text())
    assert len(stages) == 10 and len({s['id'] for s in stages}) == 10
    for cat in cats.values():
        assert len(cat['cells']) == 5 and len(set(map(tuple, cat['cells']))) == 5
        assert cat['allow_rotation'] and not cat['allow_reflection']
    candidates = {key: placements(cat['cells']) for key, cat in cats.items()}
    masks_by_count = {n: [sum(1 << i for i in indices) for indices in itertools.combinations(range(16), n)]
                      for n in range(5, 17)}
    report = []
    for stage in stages:
        assert stage['perfect_cells'] <= stage['great_cells'] <= stage['clear_cells'] <= 16
        assert stage['cats'] and all(key in cats for key in stage['cats'])
        for count, masks in masks_by_count.items():
            optimal = [mask for mask in masks if connected(mask) and
                       all(any(mask & cat_mask == cat_mask for cat_mask in candidates[key])
                           for key in stage['cats'])]
            if optimal:
                report.append({'id': stage['id'], 'minimum': count, 'optimal_shapes': len(optimal),
                               'example_mask': optimal[0], 'matches': count == stage['perfect_cells']})
                break
    return report

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--write', action='store_true', help='Write verification evidence for runtime tests.')
    args = parser.parse_args()
    try:
        report = verify()
    except (AssertionError, KeyError, ValueError) as exc:
        print(f'INVALID DATA: {exc}', file=sys.stderr)
        sys.exit(1)
    print('CATTAINER exhaustive 4x4 verification (rotations only)')
    for row in report:
        print(f"{row['id']} min={row['minimum']} optimal_shapes={row['optimal_shapes']} "
              f"{'PASS' if row['matches'] else 'FAIL'} mask={row['example_mask']}")
    if args.write:
        (ROOT / 'data/verification.json').write_text(json.dumps(report, indent=2) + '\n')
    sys.exit(0 if all(row['matches'] for row in report) else 1)
