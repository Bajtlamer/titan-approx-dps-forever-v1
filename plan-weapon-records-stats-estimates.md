# Weapon records, converging statistics, new window and upgrade estimates

> For the executor: work inline in one session, stage by stage, using superpowers:executing-plans. Steps use checkbox syntax. Each stage ends in a releasable runtime version that the user tests in the game before the next stage begins. Multi-agent mode is not used.

**Goal:** show the best results and a steadily more accurate typical result for every weapon, separately for melee, ranged and spell damage in every class, compare a dropped weapon with the equipped one in the item tooltip, and present everything in a scrollable, searchable, typographically ordered window and Titan panel.

**Architecture:** new pure-Lua modules (`Records.lua`, `Stats.lua`, `BuildSnapshot.lua`, `Estimator.lua`, `UI/ViewModel.lua`) hold all logic and are fully testable with LuaJIT stubs. WoW-facing frames (`UI/Window.lua`, `UI/Widgets.lua`, `TooltipHook.lua`) stay thin and only render view-model output. Data is additive inside schema 1, so existing SavedVariables keep working.

**Tech stack:** Lua 5.1 semantics (Forever 1.60.1, interface 16001), existing `tests/*.lua` suites run by `tools/check.py` through LuaJIT, Python tests for packaging.

## Fixed constraints (from AGENTS.md and the user)

- Post-fight analysis only. No combat-log events. No invented crit, miss or weapon attribution.
- The damage meter returns per-fight summaries, not single hits. The "maximum" values are therefore defined as:
  - best total damage in one fight with a weapon,
  - best DPS in one fight (fights of at least 10 seconds),
  - best damage of one spell or ability in one fight with a weapon.
  A true single-hit maximum is not available and the UI says so in a hint line.
- Two values are protected and can never be reset, deleted, hidden away or lowered by import: cumulative lifetime damage (already exists) and the new records (Stage 1).
- Everything else (report period statistics, running averages) improves with use and may be reset through the existing fresh-report action.
- No emoji, decorative glyphs or em dashes in any text, code strings or documents.
- Runtime version is increased by one patch per completed stage. Manifest and `Namespace.lua` stay synchronized. Release only through `tools/release.py`. The game is never restarted automatically. In-game verification is done by the user.

## UI and typography rules (apply to Stage 3, 4 and 6)

- Three text levels, defined once in `UI/Widgets.lua` as named fonts and color tokens:
  - Primary: large font (about 18 to 20 px), saturated color from the existing palette. Used only for the key values: lifetime damage, best fight, typical DPS, upgrade percentage.
  - Body: normal font (12 px), white or the palette color of the metric. Used for rows and labels.
  - Hint: small font (10 px), light grey (`B8B8B8` to `D0D0D0`). Used for tips, definitions, confidence notes and explanations.
- Existing palette is kept: damage `74D5FF`, ability `F3A5CE`, dps `FFBF4D`, percent `7FD694`, lifetime `FFD76A`, slash `C878FF`, unavailable `A0A0A0`. New tokens: record `FF9F43` (best values), good `7FD694`, bad `FF6B6B`.
- Lists are always scrollable with a scrollbar, filterable and searchable. There is no Previous/Next pagination anywhere. The existing Titan tooltip paging is replaced by a short summary plus "open window for the full list".
- Native controls are used where available: tabs, dropdown (combo box), search box, scroll list, column headers with sort. A capability probe in `Capabilities.lua` selects modern controls (`ScrollUtil`, dropdown templates) or the older fallbacks (`FauxScrollFrameTemplate`, `UIDropDownMenuTemplate`). Which path the client takes is reported in `/tadps status` so the user can tell during in-game testing.

## File structure

| File | Action | Responsibility |
|------|--------|----------------|
| `TitanApproxDPS/Records.lua` | create | protected maxima: observe, merge, validate, backfill |
| `TitanApproxDPS/Stats.lua` | create | running statistics (count, mean, variance, recent window), confidence label |
| `TitanApproxDPS/Categories.lua` | create | melee, ranged, spell, pet classification axis on top of existing groups |
| `TitanApproxDPS/BuildSnapshot.lua` | create | stat snapshot of the character taken at combat start |
| `TitanApproxDPS/Estimator.lua` | create | new-versus-equipped weapon estimate with confidence |
| `TitanApproxDPS/TooltipHook.lua` | create | item tooltip lines using the estimator |
| `TitanApproxDPS/UI/Widgets.lua` | create | fonts, color tokens, tab bar, dropdown, search box, scroll list |
| `TitanApproxDPS/UI/ViewModel.lua` | create | pure filtering, sorting, searching, row building for the window |
| `TitanApproxDPS/UI/Window.lua` | rewrite | tabs, filters and lists built from the view model |
| `TitanApproxDPS/Titan.lua` | modify | new compact tooltip with font hierarchy |
| `TitanApproxDPS/Storage.lua` | modify | records and stats fields, validation, rebuild hooks |
| `TitanApproxDPS/Sessions.lua` | modify | pass snapshot, call Records and Stats observers |
| `TitanApproxDPS/Transfer.lua` | modify | records max-merge on import, export of new fields |
| `TitanApproxDPS/TitanApproxDPS.toc` | modify | load order for new files |
| `tests/records.lua`, `stats.lua`, `categories.lua`, `viewmodel.lua`, `estimator.lua`, `window_stub.lua` | create | one suite per module |
| `tools/check.py` | modify | register new suites |
| `ref-weapon-records-and-estimates.md` | create (last stage) | final reference of definitions and formulas |

## Stage 0: Baseline

- [ ] Run `python3 tools/check.py`. Expected: all suites and manifest compilation pass.
- [ ] Review the 49 uncommitted paths against AGENTS.md (no `tmp-*`, no SavedVariables, no `dist/`). Check `website-assets/` is intended for the repository.
- [ ] Commit the current 0.1.8-alpha source as one baseline commit. Release 0.1.8 through `tools/release.py` only if the user wants it before new work.
- [ ] Decide with the user whether the 0.1.8 candidate was already tested in game; if not, that test result may change Stage 1 assumptions.

## Stage 1: Protected records (version 0.1.9-alpha)

Definition of the data, stored per character in `c.records`, additive and nil-safe:

```lua
c.records = {
  character = { fightDamage = {value=0}, fightDPS = {value=0} },
  weapons = {
    -- key is the weapon group id produced by WeaponAttribution (item/slot key)
    [groupId] = {
      name = 'item link or name at capture',
      fightDamage = { value=N, seconds=S, at=T, receiptID=R },
      fightDPS    = { value=N, seconds=S, at=T, receiptID=R },
      spells = { [spellID] = { value=N, at=T } },
    },
  },
}
```

Rules:
- `Records.Observe(character, contribution, groups)` raises a record only when the new value is strictly greater (`max` semantics). It never lowers one.
- DPS records require `seconds >= 10`. Unknown-duration fights never produce a DPS record.
- Records are not cleared by fresh-report, hide, `DAMAGE_METER_RESET`, import or epoch change.
- `Records.Merge(a, b)` is a field-wise `max` and is used by import and by schema checks.
- `Records.Backfill(character, api)` walks retained receipts once (flag `c.recordsBackfilled`) so history already in the database yields records. Folded older aggregates cannot be backfilled and the hint line says "records start from retained history".

Tasks:
- [ ] Write `tests/records.lua` first with these cases, then run it and confirm it fails because the module is missing:
  - new weapon, first fight sets all records;
  - smaller later fight does not change them;
  - larger later fight replaces them and updates `at` and `receiptID`;
  - a 5 second fight updates `fightDamage` but not `fightDPS`;
  - fresh report start (`c.reportGeneration` change) leaves records unchanged;
  - import of a snapshot with lower records leaves current records unchanged, with higher records raises them;
  - malformed records (negative, NaN, non-table) are rejected by validation and do not corrupt `Storage.Open`;
  - backfill from receipts is idempotent;
  - no public function exists that clears or lowers records (assert on the module table keys).
- [ ] Create `Records.lua` with `Observe`, `Merge`, `Validate`, `Backfill`. Add it to the `.toc` after `WeaponAttribution.lua`.
- [ ] `Storage.lua`: validate `c.records` in `Open`, initialize in `Character()`, call `Records.Observe` from `UpsertContribution` using `WeaponAttribution.Split` on that single contribution.
- [ ] `Transfer.lua`: export `records`, merge with `Records.Merge` on apply, never replace.
- [ ] `Titan.lua`: show `Best fight` and `Best DPS` lines per weapon in the existing compact tooltip, record color, primary size is deferred to Stage 3.
- [ ] Register `tests/records.lua` in `tools/check.py`, bump version to 0.1.9-alpha in the `.toc` and `Namespace.lua`, write `release-notes/ref-v0.1.9-alpha.md`.
- [ ] Run `python3 tools/check.py`, commit, run `python3 tools/release.py` preview, then publish with `--publish` as authorized.
- [ ] User checks in game: fight, confirm records appear, run fresh reports, confirm records stay.

## Stage 2: Converging statistics and categories (version 0.1.10-alpha)

Data per weapon group, category (melee, ranged, spell, pet) and mode, stored in `c.stats` and rebuilt-safe:

```lua
stat = { n=0, mean=0, m2=0, weightSeconds=0, recent={} } -- recent: ring of last 20 fight DPS values
-- Welford update, weighted by fight seconds
function Stats.Add(s, dps, seconds)
  s.n = s.n + 1
  s.weightSeconds = s.weightSeconds + seconds
  local delta = dps - s.mean
  s.mean = s.mean + delta * (seconds / s.weightSeconds)
  s.m2 = s.m2 + delta * (dps - s.mean) * seconds
  -- push to recent ring, drop oldest beyond 20
end
```

- `Stats.Summary(s)` returns `typical` (duration-weighted mean), `recentMedian`, `spread` (relative standard error) and `confidence` (`low` below 10 fights, `medium` 10 to 29, `high` 30 and above with spread below 10 percent). With too few fights it returns `nil` values, shown as Unavailable, never zero.
- Categories: `Categories.Of(group)` maps groups to `melee`, `ranged`, `spell`, `pet` using existing slot and rule data. Caster spells are not attributed to the staff. They are grouped by category `spell` under a build key (Stage 5) instead of by weapon. Wand shooting stays ranged.
- Report period stats reset with fresh reports. Lifetime stats are a second, never reset copy. Records and lifetime damage stay the only protected values.

Tasks:
- [ ] `tests/stats.lua`: mean of known samples equals expected, weighting by seconds, short fights (under 10 s) excluded, ring keeps 20, confidence thresholds, median, empty returns nil values, fresh report resets period stats only.
- [ ] `tests/categories.lua`: one case per class (warrior, rogue dual wield, hunter ranged, mage spell, priest wand, druid form, shaman, paladin, warlock) using `SpellRules` ids, asserting the category and that melee, ranged and spell stats never mix.
- [ ] Implement `Stats.lua` and `Categories.lua`, hook into `Storage.UpsertContribution`, extend `Reports.Build` groups with `category`, `typical`, `recentMedian`, `confidence`.
- [ ] Update `Titan.lua` tooltip lines: category heading, `Typical DPS (n fights, confidence)`, `Recent DPS`, `Best fight`, lifetime.
- [ ] Version 0.1.10-alpha, check, commit, release preview and publish.
- [ ] User checks in game: typical value moves smoothly over several fights; melee and ranged for a hunter are separate.

## Stage 3: Titan panel with font hierarchy (version 0.1.11-alpha)

- [ ] Create `UI/Widgets.lua` fonts (`TADPS_Primary`, `TADPS_Body`, `TADPS_Hint`) and color tokens. Share them with the tooltip.
- [ ] Rewrite `Titan.Render` so the tooltip is a short summary: lifetime and best fight in primary font, up to three most recent weapon groups, each with typical DPS, record and category in body font, definitions and tips in hint font through `SetFontObject` on the tooltip line fontstrings (`_G[name..'TextLeft'..i]`). Remove tooltip paging, add the hint "Click the minimap button or /tadps window for the full list".
- [ ] Titan bar text stays short: `typical DPS | lifetime`.
- [ ] `tests/titan_menu.lua` update: assert font objects are applied to the right lines, no paging text remains, record and typical lines present.
- [ ] Version, check, commit, release.

## Stage 4: New window (version 0.1.12-alpha)

Layout (opened from the minimap button, `/tadps window`):
- Header bar: character, class, lifetime damage and best fight in primary font, protected badge text "Lifetime and records cannot be reset" in hint font.
- Tab bar: Overview, Weapons, Spells, Compare, History, Data.
- Filter row: scope dropdown (all, pve, pvp, mixed, unknown), category dropdown (all, melee, ranged, spell, pet), period dropdown (report period, lifetime), search box.
- Body: scroll list with column headers. Clicking a header sorts. Row = weapon or spell with value columns (damage, DPS, typical, best, share). Selecting a weapon row fills a detail pane with its spells, again in a scroll list.
- Footer hint line in small light text explaining the current tab.

`UI/ViewModel.lua` is pure: `Build(store, query)` where `query = {tab, scope, category, period, search, sortKey, sortDesc}` returns `{header, columns, rows, detail, hints}`. Search is case-insensitive over weapon name and spell name. All sorting and filtering happens here so the UI frames contain no logic.

Tasks:
- [ ] `tests/viewmodel.lua`: filter by scope and category, search match and no match, sort by each column both ways, stable order on ties, empty states return a hint and zero rows, hidden weapons excluded unless requested, selected weapon detail lists all spells (no truncation).
- [ ] Implement `UI/ViewModel.lua`, then `UI/Widgets.lua` list, tabs, dropdown and search constructors with the capability fallback.
- [ ] Rewrite `UI/Window.lua` as a thin renderer. Remove `W.page`, Previous and Next buttons, and the single long `FontString` text dump.
- [ ] `tests/window_stub.lua`: with stubbed `CreateFrame` verify the window builds under both modern and fallback control paths, that every list has a scrollbar object and that no paging control exists.
- [ ] Compare tab: pick two weapons with two dropdowns (not just the first two rows), show typical DPS difference with confidence.
- [ ] Version, check, commit, release. User verifies layout, scrolling, search and filters in game and reports which control path `/tadps status` shows.

## Stage 5: Character build snapshot (version 0.1.13-alpha)

- [ ] `BuildSnapshot.lua`: at `PLAYER_REGEN_DISABLED` (outside restricted calls) read public values with the existing `IsPublic` guard: `UnitLevel`, `UnitStat` for the five stats, `UnitAttackPower`, `UnitRangedAttackPower`, `GetSpellBonusDamage`, `GetCritChance`, `GetSpellCritChance`, weapon speeds from `UnitAttackSpeed`. Anything unreadable is stored as missing, never zero.
- [ ] Attach the snapshot to the pending session and to the stored contribution as `build`. Add `buildBucket` (rounded attack power and spell power bands) used as the key for caster spell stats.
- [ ] `tests/runtime.lua` extension: snapshot stored with the contribution, missing values stay missing, restricted values are skipped, snapshot never triggers any combat-log registration (assert absence of `RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')`).
- [ ] Version, check, commit, release. This stage only collects data, user plays normally to build samples.

## Stage 6: Upgrade estimate in the item tooltip (version 0.1.14-alpha)

Estimator logic, documented as an estimate and never as a measurement:
1. Read new item stats and weapon DPS and speed through public item APIs, same slot as the equipped item.
2. Per category: melee auto damage scales with weapon DPS plus attack power per speed; special abilities scale with normalized speed and attack power; ranged likewise; spell damage scales with spell power and intellect, not with the weapon.
3. Calibrate with the user's own data: from stored `build` and DPS samples compute damage per unit of attack power or spell power once at least 20 fights exist (simple least squares inside `Estimator.lua`, no external library).
4. Output `deltaPercent` versus the equipped item's typical DPS and a confidence label from sample count and fit quality. Below the minimum sample count output nothing numeric.

Tooltip lines (via `TooltipDataProcessor.AddTooltipPostCall` for Item, only outside combat):
- primary size: `Approx vs equipped: +7.4%` in good or bad color;
- hint size: `Estimate from N fights, confidence medium. Not a measured result.`

Tasks:
- [ ] `tests/estimator.lua`: synthetic data with a known linear relation recovers the coefficient, equal items give 0 percent, upgrade gives positive, downgrade negative, fewer than 20 fights gives `nil`, spell category ignores weapon DPS, missing item stats give Unavailable, no division by zero.
- [ ] Implement `Estimator.lua` and `TooltipHook.lua`, register in the `.toc`, guard with capability probe so absence of `TooltipDataProcessor` disables the hook without errors.
- [ ] Compare tab in the window reuses the estimator for a chosen item link.
- [ ] Version, check, commit, release. User verifies tooltip values against his own judgment in game.

## Stage 7: Documentation and cleanup

- [ ] Write `ref-weapon-records-and-estimates.md` with the exact definitions of records, statistics, categories and estimator formulas, plus known limits (no single hit maximum, estimate not causal).
- [ ] Update `README.md` and `Codex-development-progress.md`.
- [ ] Remove dead code left from the old window (`W.page`, text dump). Run `python3 tools/check.py` and the release preview.

## Risks and how they are handled

- Native API shape in Forever is unverified in game. Every stage ships behind capability probes and reports the active path in `/tadps status`, so in-game testing gives clear signals.
- Reattribution can change group keys over time. Records are keyed at observation time and only ever grow, so a reclassification cannot lower them.
- Native session revisions can correct a fight downward. Records keep the higher value by design and the hint line states this.
- Saved data growth: stats use fixed-size ring buffers and counters, so size stays bounded. Export size limits are revisited in Stage 4 together with the Data tab.
- Estimates may mislead on small samples. They are suppressed below 20 fights and always carry a confidence label.
