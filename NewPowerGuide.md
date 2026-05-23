# Adding New Powers

When adding powers to the BN port, implement gameplay with BN JSON and Lua. Do not add DDA condition-runner or formula-function data. If a power needs behavior that JSON cannot express, add a narrow Lua helper or binding for that behavior.

Guidelines:

1. Choose a difficulty because it controls psionic drain.
2. Add drain through the Lua/JSON drain helpers used by the existing powers.
3. Keep psionic powers somewhat unpredictable with BN-supported random damage, duration, or Lua randomness.
4. Connect new powers to their path through learning, practice recipes, matrix awakening, portal awakening, and professions when appropriate.
5. Practice recipes live under `recipes/practice` and should grant progress through `main.lua` craft-completion handlers.
6. Preserve the theme: powers are mental disciplines, not spellbook magic.

Path themes:

- Biokinesis improves base human capabilities and body control, but does not heal or shapeshift.
- Clairsentience enhances senses and short-term foresight, but does not create long-term prophecy.
- Pyrokinesis creates and manipulates heat, flame, and light, but does not create cold or living flame bodies.
- Telekinesis moves, lifts, slows, and redirects matter, but does not perform complex manipulation.
- Telepathy reads and disrupts minds, but does not permanently rewrite personalities or affect mindless targets.
- Teleportation moves through space and the Nether, but does not teleport partial bodies or travel through time.
- Vitakinesis affects healing, disease, poison, sleep, and living processes, but does not instantly close every wound.

Matrix technology may bend a few of these limits.
