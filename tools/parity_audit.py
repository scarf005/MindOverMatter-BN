#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESIDUAL = re.compile(
    r'effect_on_condition|effect_on_conditions|jmath_function|run_eoc|run_eocs|completion_eoc|'
    r'do_turn_eoc|activated_eocs|deactivated_eocs|test_eoc|queue_eocs|ondamage_eocs|"eoc"\s*:|"math"\s*:|'
    r'result_eoc|result_eocs'
)
PLAYER_POWER_DIRS = { 'powers' }
EXEMPT_ZERO_LEVEL_PREFIXES = ( 'nether_attunement_', )
REQUIRED_LUA_SNIPPETS = [
    'teleport_potion_comedown',
    'practice_focus_cost',
    'matrix_spell_adjustment',
    'awakening_reducer',
    'telepathic_stole_recently',
]
REQUIRED_IDS = {
    'GENERIC': { 'telekin_ritual_summon_strength_item' },
    'SPELL': {
        'pyrokin_call_flame_short_term',
        'pyrokin_call_flame_long_term',
        *{ f'telekin_ritual_summon_lifting_jack_{i}' for i in range( 1, 21 ) },
    },
}


def load_json(path: Path):
    with path.open(encoding='utf-8') as f:
        return json.load(f)


def objects(path: Path):
    data = load_json(path)
    return data if isinstance(data, list) else [data]


def main() -> int:
    errors: list[str] = []
    for path in ROOT.rglob('*'):
        if '.git' in path.parts or not path.is_file():
            continue
        text = path.read_text(encoding='utf-8', errors='ignore')
        if path.name not in {'TODO.md', 'parity_audit.py'} and RESIDUAL.search(text):
            errors.append(f'residual forbidden EoC/jmath/math token in {path.relative_to(ROOT)}')

    by_type: dict[str, set[str]] = {}
    for path in ROOT.rglob('*.json'):
        if '.git' in path.parts:
            continue
        for obj in objects(path):
            if not isinstance(obj, dict):
                continue
            typ = obj.get('type')
            oid = obj.get('id') or obj.get('abstract')
            if isinstance(oid, str) and isinstance(typ, str):
                by_type.setdefault(typ, set()).add(oid)
            if typ == 'SPELL' and path.relative_to(ROOT).parts[:1] == ('powers',):
                spell_id = str(oid)
                if obj.get('max_level') == 0 and not spell_id.startswith(EXEMPT_ZERO_LEVEL_PREFIXES):
                    errors.append(f'player power has max_level 0: {spell_id} in {path.relative_to(ROOT)}')

    for typ, ids in REQUIRED_IDS.items():
        present = by_type.get(typ, set())
        for oid in sorted(ids - present):
            errors.append(f'missing required {typ} id: {oid}')

    main_lua = (ROOT / 'main.lua').read_text(encoding='utf-8')
    for snippet in REQUIRED_LUA_SNIPPETS:
        if snippet not in main_lua:
            errors.append(f'missing Lua parity marker: {snippet}')

    if errors:
        print('\n'.join(errors))
        return 1
    print('parity audit passed')
    return 0


if __name__ == '__main__':
    sys.exit(main())
