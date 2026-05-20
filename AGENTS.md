# Mind Over Matter Fork Agent Rules

- This XDG user mod repository is the authoritative Mind Over Matter fork target.
- Do not add or retain DDA condition-runner, formula-function, queued-runner, result-runner, or generic formula-interpreter gameplay data.
- Migrate DDA condition-runner-backed gameplay semantically with Lua, JSON, and narrow BN C++/Lua bindings.
- Validate from the BN engine worktree with `--check-mods mindovermatter` against this XDG path.
- Do not declare feature parity from loader success, marker checks, or TODO checkboxes alone; audit every DDA-vs-BN missing ID and either restore compatible data or record the exact semantic replacement with verified coverage.
