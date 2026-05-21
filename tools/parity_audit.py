#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DDA_ROOT = Path('/home/scarf/repo/Cataclysm-DDA/data/mods/MindOverMatter')
BN_ROOT = Path('/home/scarf/repo/cata/Cataclysm-BN-worktrees/feat-mind-over-matter-port')
RESIDUAL = re.compile(
    r'effect_on_condition|effect_on_conditions|jmath_function|run_eoc|run_eocs|completion_eoc|'
    r'do_turn_eoc|activated_eocs|deactivated_eocs|test_eoc|queue_eocs|ondamage_eocs|"eoc"\s*:|"math"\s*:|'
    r'result_eoc|result_eocs'
)
PLAYER_POWER_DIRS = { 'powers' }
EXEMPT_ZERO_LEVEL_PREFIXES = ( 'nether_attunement_', )
SKIPPED_DDA_TYPES = { 'effect_on_condition', 'jmath_function', 'proficiency', 'proficiency_category', 'practice', 'damage_info_order', 'monster_flag' }
NON_APPLICABLE_BASE_MONSTERS = {
    'mon_archunk_weak', 'mon_brute_pupa', 'mon_brute_pupa_decoy', 'mon_carrion_grub',
    'mon_feral_cop_fungal_infected', 'mon_feral_human_axe_fungal_corpse', 'mon_feral_human_axe_fungal_infected',
    'mon_feral_human_crowbar_fungal_corpse', 'mon_feral_human_crowbar_fungal_infected',
    'mon_feral_human_pipe_fungal_corpse', 'mon_feral_human_pipe_fungal_infected', 'mon_frog_mega',
    'mon_frog_mother', 'mon_fungal_raptor', 'mon_fungal_wretch', 'mon_fungaloid_shambler',
    'mon_hulk_pupa', 'mon_hulk_pupa_decoy', 'mon_nether_fish', 'mon_nether_spearfisher',
    'mon_shrapnel_swarm', 'mon_skeleton_brute_fungus', 'mon_skeleton_fungus', 'mon_structural_spur',
    'mon_zombie_medical_pupa', 'mon_zombie_medical_regenerating', 'mon_zombie_pupa_medical_decoy',
    'mon_zombie_regenerating',
}
REQUIRED_LUA_SNIPPETS = [
    'teleport_potion_comedown',
    'practice_focus_cost',
    'matrix_spell_adjustment',
    'awakening_reducer',
    'telepathic_stole_recently',
    'apply_clair_night_eyes',
    'on_book_skill_read',
]
HANDLED_LUA_SPELL_PATTERNS = [
    re.compile(r'.*_knack$'),
    re.compile(r'^effect_biokin_pkill_[1-6]$'),
    re.compile(r'^effect_clair_night_eyes_[1-8]$'),
    re.compile(r'^fd_hot_air[2-4]$'),
    re.compile(r'^EOC_.*_MATRIX_AWAKENING$'),
]

REQUIRED_IDS = {
    'GENERIC': { 'telekin_ritual_summon_strength_item' },
    'SPELL': {
        'pyrokin_call_flame_short_term',
        'pyrokin_call_flame_long_term',
        *{ f'telekin_ritual_summon_lifting_jack_{i}' for i in range( 1, 21 ) },
    },
    'effect_type': {
        'effect_biokin_concentration',
        'effect_clair_concentration',
        'effect_electrokin_concentration',
        'effect_photokin_concentration',
        'effect_pyrokin_concentration',
        'effect_telekin_concentration',
        'effect_telepath_concentration',
        'effect_teleport_concentration',
        'effect_vitakin_concentration',
        'effect_psi_lost_concentration',
        'effect_vita_return_from_death_damage_tracker',
        'eff_mind_seeing_bonus_20',
        'eff_mind_seeing_bonus_30',
    },
    'enchantment': { 'enchant_clair_speed_read' },
    'monster_attack': { 'tk_smash' },
    'construction': { 'ap_standing_pyrokinetic_lamp' },
    'construction_group': { 'place_standing_pyrokinetic_lamp' },
}


def load_json(path: Path):
    with path.open(encoding='utf-8') as f:
        return json.load(f)


def objects(path: Path):
    data = load_json(path)
    return data if isinstance(data, list) else [data]


def collect_ids(root: Path):
    by_type: dict[str, set[str]] = {}
    for path in root.rglob('*.json'):
        if '.git' in path.parts:
            continue
        try:
            objs = objects(path)
        except Exception:
            continue
        for obj in objs:
            if not isinstance(obj, dict):
                continue
            typ = obj.get('type')
            oid = obj.get('id') or obj.get('abstract')
            if isinstance(oid, str) and isinstance(typ, str):
                by_type.setdefault(typ, set()).add(oid)
    return by_type


def main() -> int:
    errors: list[str] = []
    for path in ROOT.rglob('*'):
        if '.git' in path.parts or not path.is_file():
            continue
        text = path.read_text(encoding='utf-8', errors='ignore')
        if path.name not in {'TODO.md', 'parity_audit.py'} and RESIDUAL.search(text):
            errors.append(f'residual forbidden EoC/jmath/math token in {path.relative_to(ROOT)}')

    by_type = collect_ids(ROOT)
    dda_by_type = collect_ids(DDA_ROOT)
    bn_base_monsters = collect_ids(BN_ROOT / 'data/json').get('MONSTER', set())

    for path in ROOT.rglob('*.json'):
        if '.git' in path.parts:
            continue
        for obj in objects(path):
            if not isinstance(obj, dict):
                continue
            typ = obj.get('type')
            oid = obj.get('id') or obj.get('abstract')
            if typ == 'SPELL' and path.relative_to(ROOT).parts[:1] == ('powers',):
                spell_id = str(oid)
                if obj.get('max_level') == 0 and not spell_id.startswith(EXEMPT_ZERO_LEVEL_PREFIXES):
                    errors.append(f'player power has max_level 0: {spell_id} in {path.relative_to(ROOT)}')

    for typ, ids in REQUIRED_IDS.items():
        present = by_type.get(typ, set())
        for oid in sorted(ids - present):
            errors.append(f'missing required {typ} id: {oid}')

    for typ, dda_ids in sorted(dda_by_type.items()):
        if typ in SKIPPED_DDA_TYPES:
            continue
        present = by_type.get(typ, set())
        for oid in sorted(dda_ids - present):
            if typ == 'MONSTER' and oid in NON_APPLICABLE_BASE_MONSTERS and oid not in bn_base_monsters:
                continue
            errors.append(f'missing DDA {typ} id without verified replacement: {oid}')

    unexpected = sorted(oid for oid in NON_APPLICABLE_BASE_MONSTERS if oid in bn_base_monsters)
    for oid in unexpected:
        errors.append(f'non-applicable monster now exists in BN base and needs MoM override: {oid}')

    main_lua = (ROOT / 'main.lua').read_text(encoding='utf-8')
    for snippet in REQUIRED_LUA_SNIPPETS:
        if snippet not in main_lua:
            errors.append(f'missing Lua parity marker: {snippet}')

    for path in ROOT.rglob('*.json'):
        if '.git' in path.parts:
            continue
        for obj in objects(path):
            if not isinstance(obj, dict) or obj.get('type') != 'SPELL' or obj.get('effect') != 'lua':
                continue
            spell_id = obj.get('id')
            effect_id = obj.get('effect_str')
            keys = [key for key in (effect_id, spell_id) if isinstance(key, str)]
            if any(key in main_lua for key in keys):
                continue
            if any(pattern.match(key) for key in keys for pattern in HANDLED_LUA_SPELL_PATTERNS):
                continue
            errors.append(f'lua spell lacks explicit semantic coverage: {path.relative_to(ROOT)}:{spell_id}:{effect_id}')

    if errors:
        print('\n'.join(errors))
        return 1
    print('parity audit passed')
    return 0


if __name__ == '__main__':
    sys.exit(main())
