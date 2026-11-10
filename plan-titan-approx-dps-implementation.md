# Titan Approx DPS Implementation Plan

> **For agentic workers:** Use `superpowers:executing-plans` to implement this plan task by task in automatic mode after the user reviews it. Track progress with the checkboxes. Use subagents only when explicitly requested by the user or an applicable skill.

**Goal:** Deliver a post-fight analysis AddOn with cumulative weapon, spell and combat-method comparisons, separate PvE/PvP statistics, conservative attribution and complete statistics migration.

**Architecture:** A guarded native-meter adapter produces public session snapshots. Pure Lua modules manage capture receipts, profiles, aggregates and comparisons; native frames present the results. A separate validated JSON transfer path restores saved statistics without summing overlapping snapshots.

**Tech stack:** Lua 5.1 semantics, LuaJIT tests, Python 3.10+ tooling, native WoW frames, optional Titan LibDataBroker integration, JSON interchange.

**Spec:** [plan-titan-approx-dps.md](plan-titan-approx-dps.md). Status: automatic development authorized by the user; diagnostic alpha implemented. Full task acceptance remains pending; see Codex-development-progress.md.

## Global constraints

- Target Forever `1.60.1`, expected interface `16001`; record the actual live build separately.
- Entirely in-game operation; no external combat-log analyzer.
- Analyze and accumulate damage only from readable completed fights. No live DPS display, combat text, crit alerts or rotation suggestions. Previously finalized results stay unchanged during combat.
- Aggregate and query by `pve`, `pvp`, `mixed` or `unknown`; never put mixed/unknown damage into pure-mode rankings. Track environment separately from verified recipient classification.
- Named combat methods are versioned user-selected test profiles captured at session start, not reconstructed rotations. Changing the selected method during combat takes effect for the next fight.
- Never register traditional combat-log events, parse protected combat text, or derive numbers from secret values.
- Unknown evidence is not zero. Preserve metric state and reason through storage, UI and exports.
- Distinguish native totals, damage while equipped, exact weapon evidence and individual hit maxima.
- Record misses and unsuccessful attacks by explicit reason where supported. Partial mitigation stays a landed outcome; unknown counts are not zero. Calculate outcome rates only with complete compatible resolution denominators.
- Keep owner and pet inclusion semantics explicit and prevent double counting.
- Runtime and SavedVariables names are `TitanApproxDPS` and `TitanApproxDPSDB`.
- Initial version `0.1.0-alpha`; increment patch for each subsequently completed runtime candidate, not intermediate edits.
- No dependency on Titan Gathered; recording and the main UI work without Titan.
- Use the user-provided Zadrot and MaxDps_Hunter packages as inspected design references only. Implement adopted patterns independently; do not add them as dependencies or bundle their source.
- Default caps: 200 detailed sessions, 32 pending sessions, 2,048 receipts, 8 MiB soft storage warning.
- Import limits per JSON document: 16 MiB, depth 32, 100,000 container entries; larger histories use a transactional multi-document collection. Start clipboard-part tests at 16 KiB.
- Do not add em dashes, emoji or decorative glyphs. Documentation uses the user's filename prefixes.
- Never modify unrelated AddOns, SavedVariables, enablement or the running game automatically.

## Review focus

1. Secret values or containers remain restricted after combat: defer capture without leaking values into arithmetic, sorting, iteration or serialization. Owned by tasks 1 and 2.
2. Repeated native events, session-ID reuse, reloads and resets: one contribution per provable session; ambiguity creates a gap. Owned by task 2.
3. Weapon swaps, uncached items, DoTs and dual wield: retain totals without inventing hand or weapon attribution. Owned by task 3.
4. Native owner totals already contain pet damage: combined views never add it twice. Owned by task 3.
5. Repeated, malformed or interrupted imports: complete validation and staging before atomic replacement; preserve the old data on failure. Owned by task 6.

## Planned files and interfaces

Runtime files, loaded in this order by the manifest:

1. `Localization/enUS.lua`: UI copy and unavailable reasons.
2. `Namespace.lua`: namespace, version and shared validation helpers.
3. `Settings.lua`: defaults and validated settings.
4. `Storage.lua`: internal schema, character records, migration and backup.
5. `Capabilities.lua`: guarded feature detection and public-value checks.
6. `Meter.lua`: native API adapter and semantic mapping.
7. `Equipment.lua`: item/loadout fingerprints and timelines.
8. `Metrics.lua`: pure primitive aggregation and derived metrics.
9. `Sessions.lua`: capture lifecycle, retries and receipt reconciliation.
10. `Profiles.lua`: weapon/spell indexes and eligible associations.
11. `Comparisons.lua`: filters, denominators, rankings and differences; `Methods.lua`: method definitions, immutable versions and next-fight selection.
12. `Json.lua`: bounded deterministic JSON encoding/decoding.
13. `Transfer.lua`: snapshot schema, parts, validation, restore and archives.
14. `UI/Style.lua`, `UI/Window.lua`, `UI/Results.lua`, `UI/Transfer.lua`: shared styling, tabs, results and migration.
15. `Titan.lua`, `Minimap.lua`: optional panel integration and circular launcher.
16. `Core.lua`: initialization, events, throttling and slash commands.

All these paths are under `TitanApproxDPS/`. Use `ns` from the AddOn namespace; avoid global state except the declared SavedVariables and slash command handlers. All domain modules receive an injectable API/clock for deterministic tests. Create modules when their task needs them, rather than generating empty placeholders.

Tooling lives under `tools/`, tests and fixtures under `tests/`, and runtime packages under ignored `dist/`. `README.md` is the conventional entry point. Other durable Markdown files use `plan-`, `ref-` or `book-` as appropriate.

### Shared contracts

Use these field names consistently. A field can be absent only where its state/reason explains why.

- `Metric = {state, value?, reason?, numerator?, denominator?}`. `state` is one of the five design states. Only available values enter eligible arithmetic.
- `Coverage = {beganAt, endedAt?, complete, reasons, clientBuild, capturePolicyVersion}`.
- `EquipmentSnapshot = {at, loadoutID?, contextID?, slots, complete, reason?}`. Each readable slot has an item ID, role and variant key; explicit empty slots differ from unreadable slots.
- `SessionSnapshot = {nativeRef, completed, duration: Metric, totalDamage: Metric, nativeDPS: Metric, ownerPetMode, spells, pets, coverage, combatMode, combatModeReason, environment, methodRef?}`. `nativeRef` contains public adapter metadata only; receipt identity is assigned by `Sessions`. `combatMode` is one of `pve`, `pvp`, `mixed`, `unknown`. A `methodRef` contains immutable `methodID` and `version`, assigned by the session recorder from a proven session-start snapshot.
- `SpellSummary = {spellID, damage: Metric, nativeDPS: Metric, hits?, component?, targetContext?}`. Optional `hits` is available only for a separately validated public source with complete evidence.
- `AttackOutcomes = {state, resolvedAttackCount?, landedAttackCount?, failedAttackCount?, failedByReason?, complete, reason?}`. Attach only to compatible attributed buckets. Primary reason keys are `miss`, `dodge`, `parry`, `immune`, `evade`, `fullResist`, `fullBlock`, `fullAbsorb`, `deflect`, `reflect`, `unknown`; keep partial mitigation annotations separate. Partial observed counts cannot produce a complete rate.
- `Contribution = {receiptID, revision, characterID, snapshot, equipmentContext, attribution, primitives}`. `attribution` is `loadout`, `direct`, `mixed`, or `unknown`; exact weapon IDs require `direct` evidence.
- `Query = {scope, characterID, archiveID?, combatMode, environment?, loadoutID?, spellID?, methodRef?, petPolicy, metricBasis, minSessions, minSeconds}`. Queries carry the same semantic filters on both sides of a comparison. Mixed/unknown scopes support inspection, never pure-mode recommendations.
- `ImportPreview = {snapshotID, characters, replacements, warnings, digest, canApply}`. A preview is bound to the validated payload and destination revision; destination changes invalidate it.

Concrete internal table layouts and algorithms may be settled by the implementer while preserving these contracts and the design's invariants. Record changes to a contract in both documents before dependent implementation proceeds.

## Task 1: Forever compatibility and diagnostic alpha

**Create:** `TitanApproxDPS/TitanApproxDPS.toc`, `Localization/enUS.lua`, `Namespace.lua`, `Settings.lua`, `Storage.lua`, `Capabilities.lua`, `Meter.lua`, `Core.lua`, `tests/harness.lua`, `tests/capabilities.lua`, `tests/meter.lua`, `tools/check.py`, `.gitignore`, `ref-forever-capabilities.md`.

**Interfaces:** `Capabilities.Probe(api) -> report`; `Capabilities.IsPublic(value) -> boolean`; `Meter.New(api, capabilities) -> adapter`; `adapter:ReadSession(nativeRef) -> SessionSnapshot|nil, reason`; `Storage.Open(saved, identity) -> store`; `Settings.Normalize(saved) -> settings`.

- [ ] Write failing adapter tests using synthetic absent APIs, throwing calls, forbidden-value sentinels and readable session/spell fixtures. Assert no secret value reaches iteration, comparison, formatting or saved output. Assert `maxAmount=5000` never becomes a max-hit result.
- [ ] Add fixtures based on the Zadrot review: missing individual API methods despite a present namespace, restricted names and amounts during post-fight retries, empty/reordered source arrays, local-player lookup independent of rank, and absent/changed named enum members. Resolve `Enum.DamageMeterType.DamageDone` and `Enum.DamageMeterSessionType.Current` from verified client evidence; use no unverified literal fallback. Missing enum support disables the affected read safely.
- [ ] Run `luajit tests/capabilities.lua` and `luajit tests/meter.lua`; confirm failures exercise missing implementation rather than a broken harness.
- [ ] Implement the minimal loadable alpha, safe capability checks, injectable adapter and `/tadps status`. The manifest declares `OptionalDeps: Titan`, schema storage and interface `16001`. Missing APIs produce unavailable results without aborting load. Never call `ResetAllCombatSessions`.
- [ ] Implement `python3 tools/check.py` to run all current suites and compile every manifest-loaded Lua file using LuaJIT, without downloading dependencies or substituting Lua 5.5. Ignore `dist/`, `.work/`, `tmp-*`, SavedVariables and private captures.
- [ ] Verify `python3 tools/check.py` passes. Inspect the candidate manifest load order and missing-Titan startup fixture.
- [ ] Perform a live diagnostic pass when the candidate can be installed: solo mob, hostile player/duel if available, melee, ranged/caster and pet case. Record build, supported methods/events, post-combat restriction behavior, duration meaning, owner/pet inclusion, spell shape and the completeness of readable recipient classification. Determine whether player-controlled pets and mixed PvE/PvP fights are distinguishable; unsupported classification remains unknown. Pin the inspected UI source revision and distinguish it from the installed build.
- [ ] Update `ref-forever-capabilities.md` with available, unavailable and unverified capabilities. If the core native totals are unavailable, retain diagnostics and report the blocking live fact; do not implement a fabricated damage collector. Unsupported optional fields do not block supported work.
- [ ] Probe whether any supported public post-fight source supplies attributed attack-resolution counts, failure reasons and complete denominators. Record unsupported miss/outcome capabilities explicitly; do not use missing damage, unattributed unit events or cast timing as a fallback. This capability gate does not block supported damage capture.

**Acceptance:** Loadable diagnostics; honest capability states; no forbidden event registration or combat-blocked popup; live evidence gate recorded separately from mock checks.

## Task 2: Durable session capture and lifetime totals

**Create:** `Sessions.lua`, `Metrics.lua`, `tests/sessions.lua`, `tests/storage.lua`, `tests/metrics.lua`, `tests/fixtures/session_updates.lua`. **Modify:** manifest, `Storage.lua`, `Core.lua`, `Meter.lua`.

**Interfaces:** `Sessions.New(store, meter, equipment, clock) -> recorder`; `recorder:Handle(event, ...)`; `recorder:Tick(now)`; `recorder:Baseline(nativeSessions)`; `Storage:UpsertContribution(contribution) -> changed`; `Metrics.Aggregate(contributions, historicalBase) -> primitives`; `Metrics.Derive(primitives, basis) -> metrics`.

- [ ] Write failing lifecycle tests: snapshots `damage=100` repeated twice contribute `100`, a replacement `150` contributes `150`, and a separate completed session `50` raises lifetime to `200`. Native Overall and individual sessions must never both contribute.
- [ ] Assert that repeated in-combat meter events only queue references/context: no damage-summary query, accumulation or result-number change occurs until the fight is complete and readable. A post-fight retry deferred by a new fight must resume later without losing or doubling a contribution.
- [ ] Add tests for restrictions lasting beyond combat, incomplete spell data, retries at the design's exact delays, 32-pending overflow, logout/reload, session-ID reuse, native reset, eviction, late revision, unknown/zero duration and future schema preservation. Unknown identity must not replay a session.
- [ ] Add boundary fixtures: a fight spanning pause/resume contributes no damage and records a gap; an entirely completed pre-pause pending fight may settle once; import cutovers never resume a source native session. Export warns before pausing an open fight and can wait for completion.
- [ ] Add retention tests proving 201 detailed sessions retain 200 without reducing lifetime damage, and receipt retirement preserves maxima/counts while refusing unrecognized old revisions.
- [ ] Run `luajit tests/sessions.lua`, `luajit tests/storage.lua` and `luajit tests/metrics.lua`; confirm expected failures.
- [ ] Implement public snapshot extraction, coverage records, persisted reconciliation and atomic upsert. Compute replacement aggregates from retained contributions plus the stable historical base, so revised maxima cannot leave stale records. Keep known partial spell totals distinct from complete parent totals.
- [ ] Implement recording controls and native-reset baselines. Fresh login/import may baseline unknown historical native sessions; only provably observed or reconciled sessions contribute.
- [ ] Run the full check command; verify deterministic replay fixtures preserve the lifetime invariant across reloads and revisions.

**Acceptance:** Correct observed lifetime damage, explicit gaps, repeat-event safety and bounded recent detail. No claim that baseline native history is newly observed damage.

## Task 3: Weapon profiles, spells, conditional pets and metrics

**Create:** `Equipment.lua`, `Profiles.lua`, `Methods.lua`, `Comparisons.lua`, `tests/equipment.lua`, `tests/profiles.lua`, `tests/methods.lua`, `tests/comparisons.lua`. **Modify:** `Metrics.lua`, `Sessions.lua`, manifest, `Core.lua`.

**Interfaces:** `Equipment.New(api, clock) -> tracker`; `tracker:Observe(at) -> EquipmentSnapshot`; `tracker:ContextFor(nativeRef) -> equipmentContext`; `Methods.New(store) -> methods`; `methods:Define(name, description, existingMethodID?) -> methodRef`; `methods:Select(methodRef|nil)`; `methods:Snapshot() -> methodRef|nil`; `Profiles.Build(store, query) -> rows`; `Comparisons.Compare(store, leftQuery, rightQuery) -> result`; `Comparisons.Rank(store, query) -> rows`. `Define` creates an immutable version; selections never mutate an active session's method association.

- [ ] Write failing equipment tests for main/off hand, ranged, caster weapon, shield, explicit unarmed, unreadable slot, uncached name, item variants, swaps between sessions and swaps inside a session. Assert identical names with different IDs never collide; an uncached item is not unarmed.
- [ ] Add attribution fixtures for dual wield, pre-pull cast, delayed projectile, DoT, pet swap and mixed equipment. Full session damage belongs to a proven stable tuple; a mixed session yields no invented per-hand or per-weapon split.
- [ ] Add conditional metric tests using the design's `740` damage fixture and unavailable-hit fixtures. Assert `40%`, `220%`, `120`, `240`, and `74` where supported. Assert summaries alone produce unavailable crit and hit-max fields.
- [ ] Add failure-outcome fixtures: 80 landed, 10 miss, 5 dodge, 3 parry and 2 immune resolutions produce total 100, failed 20, unsuccessful rate 20% and miss rate 10%. Assert a partially blocked/absorbed landed strike is not a failure, multi-flag failures count once, full prevention requires explicit evidence, and redirected reflect outcomes remain labeled. Unknown/zero denominators and incomplete coverage suppress rates; a damage-only summary yields unavailable outcome counts, never zero misses.
- [ ] Verify outcome aggregation preserves disjoint primary reasons, resolution-count invariants, per-recipient AoE resolution semantics, separate direct/periodic components and crit-eligible landed denominators. Same-snapshot revisions replace previous counts rather than double them.
- [ ] Add weighting test: `100/10s` plus `900/30s` yields `25` damage per combat second, rather than arithmetic mean `20`. For a spell absent from one eligible session, retain the full comparison duration denominator. Reject percent differences from a zero baseline.
- [ ] Add pet tests: native owner total `1000` including pet `300` remains combined `1000`; only a proven split yields owner-only `700`. Ambiguous pet ownership yields no separate pet claim. Missing split metadata does not erase parent damage.
- [ ] Add comparison tests for default 10-session/120-second thresholds, different character/semantic scopes, PvE versus PvP, unknown targets, mixed equipment and incomplete duration. Keep insufficient samples visible without ranking them as winners.
- [ ] Add recipient-classification tests: proven hostile NPCs are PvE, hostile players and proven player-owned hostile pets are PvP, both kinds are mixed, and incomplete/unowned recipient evidence is unknown. PvP flags, selected targets, method labels and battleground location cannot alone promote a session to verified PvP. For contributions of PvE `100`, PvP `200`, mixed `50` and unknown `25`, assert four separate totals and optional labeled overall `375`; neither pure-mode ranking may include the last two.
- [ ] Add method tests: selection before a fight snapshots its immutable version, a mid-fight selection applies next time, editing creates a new version, missing start coverage gives no verified method association, and unassigned fights retain their valid weapon/spell/mode statistics. Compare method versions using the same combat mode and display differences in equipment context.
- [ ] Run the new suites and confirm their failures. Implement profiles, primitive metric derivation, independent spell views and comparison eligibility. Contextual differences produce readable caveats, not automatic causal recommendations.
- [ ] Run `python3 tools/check.py`. Update the capability reference when a conditional data source is actually established; do not add speculative API calls for hit evidence.

**Acceptance:** Every requested metric has either a tested calculation from adequate evidence or an explicit reason it is unavailable. Every weapon remains discoverable without double attribution.

## Task 4: Tabbed results and comparison UI

**Create:** `UI/Style.lua`, `UI/Window.lua`, `UI/Results.lua`, `tests/ui_results.lua`. **Modify:** manifest, localization and `Core.lua`.

**Interfaces:** `Window.Show(tab?, selection?)`; `Window.Refresh()`; `Results.BuildView(store, query, tab) -> viewModel`; `Results.Render(frame, viewModel)`. Keep domain calculation out of frame callbacks.

- [ ] Write view-model tests for all seven tabs, empty state, unavailable values, long names, hundreds of profiles, sort stability, archive scope, mixed-equipment explanations, PvE/PvP scope selection and method comparison/selection controls. Include unsuccessful counts, literal misses, reason breakdowns and denominator/coverage labels. Assert sorting never converts unavailable values into zero or ranks unknown misses as perfect accuracy.
- [ ] Add event-coalescing and row-pool tests: a burst of native updates queues session references without live rendering, and one finalized contribution causes one visible report refresh. Hidden views do not allocate/repaint rows. Pending capture retries continue independently of visible windows, deferring reads while restricted or in combat. Reopening history during combat shows only finalized results.
- [ ] Run `luajit tests/ui_results.lua` to confirm failures; implement reusable paged/scrolling rows, shared filters and two-profile comparison controls. Save frame geometry and per-view selection without sharing accidental filter state between unrelated views.
- [ ] Implement `/tadps`, `/tadps compare`, recording controls and status access. Refresh visible results on finalized commits and user filter changes, coalesce repeated invalidations and reuse bounded row frames. Do not create a live DPS timer. Closed views do no rendering work; detach update callbacks when no scheduled capture work remains.
- [ ] Run the full check command and mock event/UI integration checks.
- [ ] Check the real client at small and large UI scales: dragging, resizing, Escape, tab switching, long localized names, empty profiles, scrolling and readable state reasons. Record live results in `book-live-validation.md` when created in task 7.

**Acceptance:** The user can find every historical weapon and spell, compare two eligible profiles, and understand unavailable/partial results without reading technical diagnostics.

## Task 5: Titan Panel and circular minimap launcher

**Create:** `Titan.lua`, `Minimap.lua`, `tests/titan.lua`, `tests/minimap.lua`. **Modify:** manifest, settings, localization, `Core.lua`.

**Interfaces:** `Titan.Initialize(api) -> boolean`; `Titan.Refresh(viewModel)`; `Minimap.Initialize(settings, api)`; `Minimap.SetVisible(visible)`.

- [ ] Write failing tests for LibDataBroker present/absent, delayed integration availability, tooltip paging, every weapon accessible across pages, one horizontal separator between groups, click routing and wheel bounds.
- [ ] Assert the Titan entry shows the latest finalized DPS or selected cumulative metric with its mode; ongoing combat cannot change the number. Tooltip results obey the selected PvE/PvP scope and expose mixed/unknown data separately.
- [ ] Add tooltip-placement cases near top/bottom screen edges and a position-reset fixture whose saved default and default-position detector agree. Repeated show/hide cycles must leave no idle refresh callback running.
- [ ] Add minimap tests for saved angle, hide/show, position reset, left/right click and changes in minimap size/scale. Button placement stays on the visible circumference.
- [ ] Run both suites and confirm failures. Implement the optional Titan integration and native circular button. Avoid loading another AddOn solely to create a launcher.
- [ ] Run the full check command. Validate Titan hover/click behavior, tooltip length, circular border and minimap dragging live, including startup with Titan disabled.

**Acceptance:** Both launchers reach the same results UI, every weapon group is accessible, and missing Titan does not affect recording or the minimap.

## Task 6: Complete migration and comparison archives

**Create:** `Json.lua`, `Transfer.lua`, `UI/Transfer.lua`, `tests/json.lua`, `tests/transfer.lua`, `tests/transfer_ui.lua`, `ref-statistics-format.md`. **Modify:** manifest, window tabs, storage, localization and commands.

**Interfaces:** `Json.Encode(value) -> string`; `Json.Decode(text, limits) -> value|nil, reason`; `Transfer.Export(store, options) -> snapshot`; `Transfer.Parts(snapshot, maxBytes) -> parts`; `Transfer.Stage(parts, store) -> ImportPreview|nil, reason`; `Transfer.Apply(preview, store, mode, mapping) -> result`. Modes are `restore` and `archive`. A snapshot may contain one document or a manifest-declared collection. Parts carry snapshot, document and part identifiers; staging must validate every collection document before returning an applicable preview.

- [ ] Write round-trip fixtures including all supported primitives, weapon variants, spell IDs, conditional pet records, unavailable states, pending capture, coverage, retained history, combat-mode partitions/reasons, environments, method dictionaries/immutable versions/session associations and identity mapping. Recomputed metrics and mode/method comparison eligibility after restore must equal the source. Invalid method references or combat-mode values reject the snapshot before mutation.
- [ ] Include attack-outcome states, primitive counts, failure reasons and denominator coverage in round-trip fixtures. Reject negative counts, inconsistent `resolved = landed + failed` or failure-reason sums, and any imported claimed complete rate with missing denominator evidence before mutation.
- [ ] Add tests for repeated restore and repeated archive imports, changed destination revision, mismatched part IDs/checksums, duplicate/missing parts, Unicode strings, duplicate JSON keys, excessive nesting/entries/bytes, invalid references, negative/nonfinite counters, inconsistent counts and future schemas. All rejection paths must preserve the destination byte-for-byte.
- [ ] Add a single-character fixture exceeding one document's byte or entry limit. Export must partition records into bounded documents, and full collection restore must reproduce the original statistics. Missing documents, duplicate record ownership, broken cross-document references, cancellation and simulated staging-memory failure must never partially replace live data.
- [ ] Run the suites to confirm failures. Implement bounded JSON data parsing, deterministic encoding, part checksums and fully staged validation. Reuse or vendor a compatible parser only after reviewing license, limits and Lua 5.1 behavior; no runtime network dependency.
- [ ] Implement frozen export snapshots, part navigation, paste staging, readable preview and explicit restore confirmation. Apply against the preview's bound destination revision, retain a pre-import backup and reset the destination capture baseline. Never sum cumulative imports.
- [ ] Implement comparison archives excluded from local totals. Exclude opponent identity by default and make migration identity requirements visible before copying. Preserve imported pending records as unresolved historical data and create a fresh destination recording baseline.
- [ ] Verify `python3 tools/check.py`; round-trip the largest supported payload through the actual client EditBox. Detect truncation, choose a verified part size, and test interrupted paste/retry and restore rollback.
- [ ] Document format, limits, restore/archive behavior and a step-by-step transfer to a second device in `ref-statistics-format.md` and the README.

**Acceptance:** Complete retained-statistics migration, idempotent restoration, archive isolation, no execution of imported data and no mutation before validated confirmation.

## Task 7: Packaging and release candidate acceptance

**Create:** `tools/package.py`, `tools/install.py`, `tests/test_package.py`, `tests/test_install.py`, `README.md`, `book-live-validation.md`, `book-releases.md`, `release-notes/ref-unreleased.md`. **Modify:** `tools/check.py`, capability reference and version metadata.

**Interfaces:** `python3 tools/check.py`; `python3 tools/package.py`; `python3 tools/install.py --addons-dir PATH` for preview, with `--apply` only for an authorized installation.

- [ ] Write package/installer tests proving runtime allowlisting, correct manifest paths, checksums, no private data, no SavedVariables writes, backup before replacement, verification of installed bytes and rollback on copy failure. Run `python3 -m unittest discover -s tests -p 'test_*.py'` and confirm failures before implementation.
- [ ] Implement a runtime-only ZIP rooted at `TitanApproxDPS/`, SHA-256 checksums and a previewable backed-up installer. Do not copy development files into the AddOn directory.
- [ ] Run `python3 tools/check.py` and `python3 tools/package.py`; inspect the ZIP contents. Run an installer preview against a temporary test destination.
- [ ] Complete live scenarios: solo melee, caster, ranged, pet where available, PvP where available, dual wield where available, mid-fight swap, DoT after swap, multiple targets, death, zoning, reload, native meter reset, recording pause, unavailable APIs and restricted post-combat snapshots. Mark unavailable test conditions as untested, not passed.
- [ ] Compare readable native session and spell totals under identical source/pet semantics. Show exact matching totals or document unresolved deltas; do not accept arbitrary tolerance to hide attribution errors.
- [ ] Stress replay at least 1,000 synthetic sessions and 500 profiles across modes/method versions. Verify retention invariants and record CPU/storage behavior; tune only where measured costs warrant it. Verify no damage rendering or accumulation occurs during combat and that post-fight invalidations are coalesced.
- [ ] Verify migration between independent test stores and a live copy/paste round trip. Confirm every requested feature is either supported and tested or visibly unavailable with its reason.
- [ ] Update current behavior, installation instructions, formulas, limitations and verification evidence. Report automated and live checks separately. Install only within granted task authorization and actual filesystem permissions; report a blocked install plainly.

**Acceptance:** A reviewable runtime package, tested installer, recorded live limitations, and reproducible verification. A plan, mock test pass or source ZIP alone is not a fully validated in-game release.

## Automatic-mode execution notes

Read both plan documents at the start. Establish repository/worktree context before any Git operation; this planning directory was not a repository. Do not initialize Git, create a remote or publish solely because those actions appear in a generic skill.

Execute tasks in order, checking off evidence-backed steps. Where a live gate is waiting, continue independent pure-logic and UI work using clearly labeled fixtures. Keep unsupported runtime capabilities disabled until verified. Stop only dependent work if readable damage itself is unavailable.

Use failing-then-passing tests for substantive state, metric and import behavior. Do not add tests that merely repeat static copy or every reversible styling choice. Run focused suites during work and the full check command at integration boundaries. Commit coherent verified milestones only when a Git repository and the task's authorization exist; no pushes or release publication are implicit.

Before implementation, the user should review the design's principal calls: supported metrics only, damage-while-equipped attribution, one tabbed window, optional Titan, post-fight persistence, and replace-based migration with separate comparison archives. The already supplied automatic execution preference remains the intended development method.
