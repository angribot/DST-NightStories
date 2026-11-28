## Related repositories

Find local checkouts in the `workspace.library` entries of `.luarc.json` (machine-local, gitignored; `jq '."workspace.library"' .luarc.json`); ask if one is missing.

- DST-scripts: the game's scripts ("游戏源码", "原版", "上游"), with the contents of `scripts/` at its root. Each commit is one game build, so its history shows upstream updates.
- GlassicAPI: the API mod this mod builds on.
- DST-Fixed: Too Strong Fixed (纯净辅助), a companion mod. Cross-check it whenever a change touches a mechanic it also modifies.

Target the latest game build. Add compatibility code for older builds or third-party mods only when asked.

## Terminology

Name game and mod content by its in-game string in the language you are writing, in replies as well as files: English from `STRINGS` (the game's `strings.lua`, this mod's `main/strings.lua`), other languages from the matching `.po` (the game's `languages/`, this mod's `languages/`). An empty `msgstr` means the game shows the English name (e.g. Civi).

## Code layout

Mirror the vanilla `scripts/` layout.

- `main/`: load-time registration of this mod's content and data (assets, tuning, strings, actions, recipes). Tunable numbers go in `main/tuning.lua` as `TUNING.*`.
- `scripts/`: this mod's prefabs, components, and widgets at their vanilla paths; modules they share go in `scripts/nightstories/`.
- `postinit/`: hooks on vanilla targets only, at the path of the vanilla file that defines the target (a hook on a function from vanilla `prefabs/staff_common.lua` goes in `postinit/prefabs/staff_common.lua`). Hooks may check this mod's prefabs or tags; this mod's own modules and data live in `main/` or `scripts/`.
- Name new components, tags, fields, and anim files like vanilla ones, without an `ns_` prefix.

## Implementation

- Reach for vanilla and GlassicAPI interfaces and existing files first; add a helper, wrapper, component, or file only when none of them can hold the code.
- Guard only against states you can point to in the game source.

## Comments

- Write comments in the format `.lint/check-comments --help` describes. Head a copied upstream function with one that cites it and names the change that made the copy necessary.
- After DST-scripts, GlassicAPI, or DST-Fixed updates, run `.lint/check-upstream`, recheck each reported fact against the new code, and update the version in its comment.

## Lua compatibility

Target DST's Lua 5.1 runtime plus `bit`, not LuaJIT extensions.

- Use Lua 5.1 syntax: no `goto`/labels, `\x`/`\z` escapes, floor division, or native bitwise operators. Use `bit` for bitwise operations.
- Use `unpack` and `loadstring` instead of `table.unpack` and string-based `load`. Pass arguments to `xpcall` through a closure.
- Use `table.concat` for repeated strings with separators and `math.log(x) / math.log(base)` for other logarithm bases. Lua 5.1 silently ignores the extra arguments to `string.rep` and `math.log`.
- Access standard globals missing from the mod environment through `GLOBAL`, including `unpack`, `coroutine`, and `loadstring`.
- Keep coroutine yields outside C-call boundaries, including `pcall`/`xpcall`, metamethods, `table.sort` comparators, and `gsub` callbacks.
- Avoid relying on cross-runtime `math.random` sequences or out-of-range `%d` formatting.

`.lint/check-lua` checks the first rule, `table.unpack`, and stylua formatting (fix with `stylua <file>`). The pre-commit hook runs it, `.lint/check-changelog`, and `.lint/check-comments`; enable the hook once per clone with `git config core.hooksPath .githooks`.

## Testing

Verify changed behavior with a simulation in a temporary directory outside the repository (e.g. `mktemp -d`); the repository keeps no test cases. Simulate on the game's Lua 5.1 runtime (`uv run --with lupa`, `lupa.lua51`) and load mod files the way `mods.lua` does. Simulations still only approximate DST, so list the engine-dependent behavior left to check in-game.

## Release notes

Release notes live in the `changelog` variable of `modinfo.lua`; there is no CHANGELOG file.

- Each language block opens with the current release's entries and no heading, since `description` already prepends "本次更新:" / "Changes:".
- After a blank line, `最近更新：` / `Recent Changes:` lists earlier entries of the current minor series, newest first.
- Publish with `.workshop/publish.sh`, after a `--dry-run`.
- Bump the version when `.workshop/publish.sh --published-version` prints the `version` in `modinfo.lua`. The user picks Y (minor) or Z (patch); propose one if they did not.
- No bump, while the published version is below `version`: add the entries to the current release in a commit of their own, leaving Recent Changes as is.
- Z bump (e.g. `1.60.3` → `1.60.4`): write the new entries at the top and move the previous release's entries to the top of Recent Changes. The first patch of a series creates that section. Recent Changes accumulates every entry since the minor release.
- Y bump (e.g. `1.59.3` → `1.60.0`): replace the whole changelog with this release's entries and drop Recent Changes.
- Commit a bump as `chore: bump version to X.Y.Z`, title only, carrying the release's changelog: its entries and the move into Recent Changes. The commits it releases leave the changelog alone.
- Keep Chinese and English in lockstep: same entries, same order, moved and dropped together.
- Write each entry as a player-facing headline: one clause naming what changed, leaving out conditions, mechanics, and causes.
- Write both languages in the simple present, describing the game after the update: `橙影背包拾取更快` / `The Orange Night Pack picks up items faster`. Chinese entries drop 了 (`修复…的问题`); English entries without a subject start with the base verb (`Fix the Queen's Torch AOE hit range`).
