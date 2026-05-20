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

## Open parity gaps

- [ ] Matrix crystal awakening: exact success/failure messages, per-path boosts, crystal draining, already-known overload, coruscating random path, awakening count/reducer state.
- [ ] Portal storm awakening: distant/medium/close recurrence, `ps_str` strength, awakening count/reducer state, path-specific success/failure effects.
- [ ] Matrix crystal wield modifiers: +4 effective psionic school level while wielding matching crystal.
- [ ] Noetic resilience comedown: -3 effective psionic school level while comedown is active.
- [ ] Potion comedown timing: delayed 12-30 h or 18-30 h transition instead of only effect-removal handling.
- [ ] Teleport potion comedown: recurring 30-90 min random blink while active.
- [ ] Practice focus costs: DDA tiered focus loss of 50/25/10/5 based on current focus.
- [ ] Psionic proficiency replacements: preserve gameplay impact for basic channeling, containment, ritual, warping, and morphic work in BN terms.
- [ ] Clairsentience speed reading: reading-speed and reading-XP behavior equivalent to DDA `CLAIR_SPEED_READ`/enchantment behavior.
- [ ] Pyrokinesis banked flame: short/long selection, drain cost, duration, cleanup, and spawned flame tool parity.
- [ ] Telekinesis lifting jack: 1-20 level-scaled summons, duration, cleanup, and item parity.
- [ ] Telekinetic enhance strength cleanup item/effect parity.
- [ ] Telepathic stealing timer reset and dialogue-side cooldown semantics.
- [ ] Restore or semantically replace reduced `mutations/psi_passives.json` content.
- [ ] Restore or semantically replace reduced `powers/vitakinesis_eoc.json` content.
- [ ] Restore or semantically replace reduced `itemgroups/itemgroups.json` content.
- [ ] Restore or semantically replace reduced `obsolete/contemplation_notes.json` content.
- [ ] Restore or semantically replace reduced `damage_types.json` content.
- [ ] Restore or semantically replace reduced `powers/drain_spells.json` content.
- [ ] Audit missing source IDs reported by parity script and either restore compatible JSON data or document exact Lua/JSON replacement.
- [ ] Restore non-gameplay docs/test data where safe: `NewPowerGuide.md`, `test_data.json` equivalents.

## Required residual scan

```sh
rg -n 'effect_on_condition|effect_on_conditions|jmath_function|run_eoc|run_eocs|completion_eoc|do_turn_eoc|activated_eocs|deactivated_eocs|test_eoc|queue_eocs|"eoc"\s*:|"math"\s*:|result_eoc|result_eocs' ~/.local/share/cataclysm-bn/mods/MindOverMatter
```
