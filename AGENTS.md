## Testing

This repository accepts no test files. Run any test as a simulation in a temporary directory outside the repository (e.g. `mktemp -d`).

## Release notes

Release notes live in the `changelog` variable of `modinfo.lua`; there is no CHANGELOG file. Update them in the same change that bumps `version`.

- Each language block opens with the current release's entries and no heading, since `description` already prepends "本次更新:" / "Changes:".
- After a blank line, `最近更新：` / `Recent Changes:` lists earlier entries of the current minor series, newest first.
- Patch bump (e.g. `1.60.3` → `1.60.4`): write the new entries at the top and move the previous release's entries to the top of Recent Changes. The first patch of a series creates that section. Recent Changes accumulates every entry since the minor release.
- Minor bump (e.g. `1.59.3` → `1.60.0`): replace the whole changelog with this release's entries and drop Recent Changes.
- Keep Chinese and English in lockstep: same entries, same order, moved and dropped together.
- Write each entry as a player-facing `- ` line describing the in-game effect.
