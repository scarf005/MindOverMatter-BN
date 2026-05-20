# Mind Over Matter BN parity TODO

Goal: reach DDA Mind Over Matter feature parity in the XDG fork at `~/.local/share/cataclysm-bn/mods/MindOverMatter` without porting DDA EoC/jmath/math interpreters or loader support.

## Hard migration rule

- MUST NOT port DDA EoC, jmath, queued EoC runners, result EoCs, generic math interpreters, or compatibility loaders for those systems.
- MUST implement every EoC-backed user-visible behavior semantically with BN-compatible JSON and Lua.
- Lua bindings may be added when Lua lacks the narrow capability needed to express a specific feature.
- Avoid C++ changes unless a narrow Lua binding or hook is absolutely necessary; prefer pure Lua/JSON first.
- Missing DDA EoC/jmath source files are not themselves blockers if their gameplay behavior is fully represented by Lua/JSON replacements.

## Validation loop

1. Add or update a focused regression test/audit for one parity gap.
2. Implement the smallest Lua/JSON change that makes it pass; add a narrow Lua binding only when pure Lua/JSON cannot express the behavior.
3. Run `./out/build/linux-full/src/cataclysm-bn-tiles --check-mods mindovermatter` from the BN worktree against this XDG mod.
4. Run the no-EoC residual scan against this XDG mod.
5. Commit the tested parity slice.

## Completed parity gaps

- [x] Matrix crystal awakening: success/failure messages, per-path boosts, crystal draining, already-known overload, coruscating random path, awakening count/reducer state.
- [x] Portal storm awakening: distant/medium/close recurrence, `ps_str` strength, awakening count/reducer state, path-specific success/failure effects.
- [x] Matrix crystal wield modifiers: +4 effective psionic school level while wielding matching crystal.
- [x] Noetic resilience comedown: -3 effective psionic school level while comedown is active.
- [x] Potion comedown timing: delayed 12-30 h or 18-30 h transition.
- [x] Teleport potion comedown: recurring 30-90 min random blink while active.
- [x] Practice focus costs: DDA tiered focus loss of 50/25/10/5 based on current focus.
- [x] Psionic proficiency replacements: preserved gameplay impact for basic channeling, containment, ritual, warping, and morphic work in BN terms.
- [x] Clairsentience speed reading: reading-speed and reading-XP behavior equivalent to DDA `CLAIR_SPEED_READ`/enchantment behavior.
- [x] Pyrokinesis banked flame: short/long selection, drain cost, duration, cleanup, and spawned flame tool parity.
- [x] Telekinesis lifting jack: 1-20 level-scaled summons, duration, cleanup, and item parity.
- [x] Telekinetic enhance strength cleanup item/effect parity.
- [x] Telepathic stealing timer reset and dialogue-side cooldown semantics.
- [x] Restore or semantically replace reduced `mutations/psi_passives.json` content.
- [x] Restore or semantically replace reduced `powers/vitakinesis_eoc.json` content.
- [x] Restore or semantically replace reduced `itemgroups/itemgroups.json` content.
- [x] Restore or semantically replace reduced `obsolete/contemplation_notes.json` content.
- [x] Restore or semantically replace reduced `damage_types.json` content.
- [x] Restore or semantically replace reduced `powers/drain_spells.json` content.
- [x] Audit missing source IDs reported by parity script and either restore compatible JSON data or document exact Lua/JSON replacement.
- [x] Restore non-gameplay docs/test data where safe: `NewPowerGuide.md`, `test_data.json` equivalents.

## Final parity audit status

- `tools/parity_audit.py` now compares DDA source IDs against the BN fork and fails on any unverified missing non-EoC/non-jmath ID.
- Current unverified missing DDA IDs: 0.
- Current DDA monster override IDs skipped as non-applicable: 28, all because the corresponding base monsters do not exist in BN base data.

## Required residual scan

```sh
rg -n 'effect_on_condition|effect_on_conditions|jmath_function|run_eoc|run_eocs|completion_eoc|do_turn_eoc|activated_eocs|deactivated_eocs|test_eoc|queue_eocs|ondamage_eocs|"eoc"\s*:|"math"\s*:|result_eoc|result_eocs' ~/.local/share/cataclysm-bn/mods/MindOverMatter
```
