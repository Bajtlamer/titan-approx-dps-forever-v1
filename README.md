# Titan Approx DPS

Development candidate `0.1.0-alpha` for World of Warcraft Forever, interface `16001`.

Analyzes completed native damage-meter sessions. No live DPS display or combat-log event registration. Optional Titan integration; the minimap launcher and results window work independently.

## Candidate behavior

- Stores observed damage, spell summaries and weapon-loadout context after combat, with duplicate-safe replacement of retained session contributions.
- Preserves 200 recent sessions and folds older retained receipts into historical aggregates.
- Displays Overview, Weapons, Spells, Pets, Compare, History and Data views. Current comparison uses the first two loadout rows; arbitrary profile selection remains planned.
- Keeps PvE, PvP, mixed and unknown data separate. This initial adapter cannot prove complete recipient classification, so captured sessions are deliberately unknown. Pure-mode rankings are unavailable until a validated classifier exists.
- Records a selected method label for the next observed fight. Method dictionaries use immutable versions. Editing/version selection controls remain planned.
- Crits, hit maxima, misses and pet splits are unavailable from this adapter, with explanations. No unavailable count is represented as zero.
- Provides JSON export and validated, confirmed replacement of the current character, retaining a pre-import backup. This initial UI handles up to 15,000 JSON bytes. Multipart collections, comparison archives, multi-character transfer and rollback controls remain planned. Large records remain in SavedVariables and are never truncated into an export.

Only native session IDs first observed during an observed combat interval are admitted. Uncertain session starts are excluded with a coverage note. Native IDs already present on login are baselined. Pending capture does not currently resume across reloads; completed statistics survive. Real-client event order and availability require validation before reliable capture can be claimed.

Weapon results mean damage while a loadout was equipped, not proven damage caused by each item. Mixed or incomplete equipment is kept separate. Unknown-duration damage stays outside pooled damage-per-second calculations.

## Use

Install `TitanApproxDPS/` in your Forever `Interface/AddOns/` directory and restart the client after initial installation.

- `/tadps`: results.
- `/tadps status`: capability and capture notes.
- `/tadps pause` and `/tadps resume`: recording control.
- `/tadps method NAME`: select a newly named method for future fights, outside combat.
- `/tadps compare`: initial comparison view.
- `/tadps export` and `/tadps import`: small-snapshot transfer. Exports include character identity.
- `/tadps minimap`: show/hide launcher.

Back up game-managed SavedVariables while WoW is closed before testing a development build. No changes are made to other AddOns or their databases.

## Development

Run `python3 tools/check.py` with LuaJIT installed. This runs domain, regression, review, simulated-client and package/installer checks, and compiles every manifest-loaded Lua file with Lua 5.1 semantics.

Run `python3 tools/package.py` for a runtime-only ZIP and checksums. `python3 tools/install.py --addons-dir PATH` previews installation; `--apply` installs a staged candidate, backs up an existing folder and verifies installed bytes.

Automated tests are not proof of live Forever API support. See [the development ledger](Codex-development-progress.md) for evidence and outstanding work and the two `plan-*` documents for the full intended scope.
