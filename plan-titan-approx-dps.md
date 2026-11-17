# Titan Approx DPS: design and development plan

Status: approved for automatic development on 2026-11-10; first diagnostic alpha implemented, live acceptance pending.
Date: 2026-11-10.
Execution preference: automatic development after plan review.

## 1. Objective

Build a World of Warcraft Forever AddOn that evaluates completed fights, keeps a durable record of the player's observed damage and helps compare weapons, spells, weapon-and-spell combinations, combat methods and pets. Keep PvE and PvP statistics separate. Provide a Titan Panel summary, a circular minimap launcher, a tabbed comparison window, and export/import for migration between computers.

The user's confirmed scope is an entirely in-game AddOn using supported metrics. An external combat-log analyzer is excluded. Unavailable data must be explained rather than estimated from unrelated signals.

The user explicitly requires post-fight analysis rather than an in-combat damage display. During combat, record only the context needed for later attribution, such as equipment changes, session boundaries and any readable target classification evidence. Read and accumulate completed damage results after the fight when their fields are public. No live DPS display, floating combat text, crit alerts or rotation suggestions are required. Historical results may remain accessible during combat, but the ongoing fight does not change their numbers.

Success means answering, within recorded conditions:

- Which spells contribute the most damage and damage per combat second?
- Which equipped weapon profiles have the strongest observed results?
- How does the same spell perform under different weapon loadouts?
- Which named combat methods perform best within PvE or PvP under comparable conditions?
- What damage and crit records are actually available for the player and their pets?
- How often do weapon attacks or damaging spells fail to land, and which failure reasons are actually observed?
- Can the player move all retained statistics to another computer without losing or doubling them?

## 2. Findings and feasibility

At planning time the project directory was empty and was not a Git repository. Titan Gathered Forever v3 is available at `../titan-gathered-forever-v3/`. Its runtime supplies useful examples for LibDataBroker/Titan integration, native report frames, guarded API reads, SavedVariables, JSON export and LuaJIT tests. Reuse patterns where appropriate; this AddOn must not depend on Titan Gathered or write to its database.

Read-only inspection of `/Applications/World of Warcraft/.build.info` on 2026-11-10 reports active product `wowf`, version `1.60.1.70862`. The proposed manifest interface is `16001`, matching the installed reference AddOn. Installation metadata does not establish live API behavior.

The [Forever damage-meter API declarations](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/DamageMeterDocumentation.lua) describe session totals and spell summaries, with combat-sensitive returns. They do not establish individual hit counts, crit counts, hit maxima, weapon identity, or pet ownership. The similarly named `maxAmount` must not be interpreted as a maximum individual hit. These are candidate APIs to validate on the installed build, not proof of live availability.

The [Forever combat-log declarations](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/CombatLogDocumentation.lua) mark combat-log events as restricted. This design therefore does not register traditional combat-log events or parse protected combat-log text. The moving source branch is reference evidence; milestone 1 must record a pinned source revision and the live client build separately.

### Feature availability policy

- Session damage, native DPS and per-spell totals: expected candidates, requiring live validation.
- Weapon profiles and equipment history: collect independently of damage API support.
- Spell plus weapon-loadout comparisons: supported only when equipment coverage for the native session is complete and unchanged.
- Exact damage from a particular weapon or hand: unavailable unless a public source explicitly identifies it. Equipping a staff does not prove that the staff caused a spell's damage.
- Observed crit percentage, average crit damage, maximum crit and maximum normal hit: conditional on readable, complete hit evidence. Currently unproven and expected unavailable through the documented session summaries.
- Misses and other unsuccessful attack outcomes: a required statistics category, conditional on attributable public outcome counts and sufficient denominators. Native damage totals alone do not establish these counts. Unknown miss coverage must never display as zero misses.
- Pet totals and pet hit records: conditional on explicit ownership and readable separate data. Never infer ownership from a creature name alone.
- Target classification, damage school, direct versus periodic damage, cast efficiency and buff context: optional columns only where the validated source supplies them reliably.

Every result carries a data state: `available`, `pending`, `partial`, `unavailable`, or `ambiguous`, plus a plain-language reason. Zero is a measured zero; missing evidence is not zero.

### Review of user-provided AddOns, 2026-11-10

Reviewed the local Zadrot meter in full, and the MaxDps_Hunter manifest, shared entry/configuration, license, all three Forever specialization files, plus selected other-client examples. This was a source review with a small isolated Lua control-flow check, not an in-game validation. The source packages were left unchanged.

**Zadrot_DamageMeter: useful collection and UI reference.** Its [manifest](<home-dir>/Downloads/Zadrot_DamageMeter/Zadrot_DamageMeter.toc:1) targets interface `16001`. In [RefreshSessions](<home-dir>/Downloads/Zadrot_DamageMeter/Zadrot_DamageMeter.lua:98), it calls `C_DamageMeter.GetCombatSessionFromType` for the current damage and healing sessions. [GetPositionFromSession](<home-dir>/Downloads/Zadrot_DamageMeter/Zadrot_DamageMeter.lua:108) identifies the player with `isLocalPlayer`; the compact display shows rank, not the player's numeric DPS. The tooltip uses `totalAmount` for bars and `amountPerSecond` for DPS/HPS at [DrawSection](<home-dir>/Downloads/Zadrot_DamageMeter/Zadrot_DamageMeter.lua:243).

Its [event handlers](<home-dir>/Downloads/Zadrot_DamageMeter/Zadrot_DamageMeter.lua:405) set a dirty flag; an [on-demand ticker](<home-dir>/Downloads/Zadrot_DamageMeter/Zadrot_DamageMeter.lua:322) coalesces refreshes at one-second intervals and detaches when idle. Twenty preallocated tooltip rows avoid rebuilding frames. The [tooltip anchor](<home-dir>/Downloads/Zadrot_DamageMeter/Zadrot_DamageMeter.lua:145) moves above or below the meter according to screen position. Adopt these architectural ideas with our own implementation: cache invalidation from events, bounded row pools, idle shutdown and screen-aware tooltip placement.

Limitations relevant to this project:

- API methods are called without individual capability/error guards. `tostring(src.name)` and numeric `string.format` in `DrawSection` have no secret-value guards. Only some entry paths wrap `FillTip` in `pcall`; periodic rendering and `RefreshSessions` are not covered. This is a conditional runtime hazard when fields are restricted, not evidence that the AddOn fails on every client.
- It reads only the current session; it has no historical-session reconciliation, lifetime SavedVariables, hit/crit collection, weapon attribution, pet ownership model, or statistics import/export.
- It assumes the first source supplies a suitable bar maximum and uses literal enum numbers. Our adapter must validate source order or use a proven public maximum, and resolve named enums from the client.
- Its default-position detector checks Y `-150`, while the declared default is `-70`. Do not copy this mismatch into position reset/feedback behavior.

**MaxDps_Hunter: recommendation reference.** The [manifest](<home-dir>/Downloads/MaxDps_Hunter/MaxDps_Hunter.toc:1) declares version `v11.2.23`, interface `120105`, dependency `MaxDps` and load-on-demand. It routes different specialization files by game type, including dedicated Forever files. The separate MaxDps core was not present at the reviewed Downloads path, so its helper semantics, restriction handling and live loading cannot be verified from this package alone.

[Main.lua](<home-dir>/Downloads/MaxDps_Hunter/Main.lua:32) assigns a specialization function to `MaxDps.NextSpell`. The Forever [Beast Mastery](<home-dir>/Downloads/MaxDps_Hunter/Specialization/Forever/Beastmastery.lua:8), [Marksmanship](<home-dir>/Downloads/MaxDps_Hunter/Specialization/Forever/Marksmanship.lua:8) and [Survival](<home-dir>/Downloads/MaxDps_Hunter/Specialization/Forever/Survival.lua:8) functions return a recommended spell ID based on core-provided cooldown, range, mana and aura helpers. They do not calculate measured DPS, collect damage events, or maintain crit/history records. Shared pet action-slot/range helpers do not establish damage ownership.

The useful ideas are modular adapters, stable spell IDs and separation between shared infrastructure and optional class rules. Our initial data collector remains class-independent; hard-coded Hunter spell lists are not a coverage requirement. If recommendations are added later, they must be a separate feature with independently validated inputs, not the source of measured effectiveness.

Reasons not to transplant the recommendation rules:

- Each Forever function contains consecutive returns behind the same global-cooldown predicate. Under a consistent helper result in one invocation, the first Aimed Shot return prevents the following Multi-Shot branch from being reached. An isolated Lua fixture reproduced this for all three files. This does not establish the real core's cooldown semantics or a complete rotation fix, but it rules out treating the list as a validated optimum.
- `Near(8)` is applied inconsistently to melee/ranged sections across specializations. Its intended semantics require the missing core before judging live range correctness.
- Calls such as `GetCritChance()` and combat-log references found in other-client files are not a new Forever hit-data source. A character-sheet crit value, if public, describes reported character stats rather than the observed crit rate across fights.

The [Forever enum declarations](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/DamageMeterConstantsDocumentation.lua) distinguish `DamageDone`, `Dps`, `HealingDone`, `Hps` and `Current`. Resolve and validate the appropriate enum rather than inferring it from display labels or copying literal numbers. The [API declarations](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/DamageMeterDocumentation.lua) still mark session reads as combat-sensitive; these packages do not remove the post-fight capture gate.

Use original code for the adopted patterns. MaxDps_Hunter's supplied license says `All Rights Reserved`; no license was included in the two-file Zadrot package. Neither review changes our dependency list or authorizes bundling third-party source.

**Plan impact:** strengthen task 1 with named-enum resolution and guarded periodic paths; task 4 with dirty-cache rendering and reusable rows; task 5 with viewport-aware tooltip placement. Keep the supported-metrics scope, post-fight persistence and conditional crit/pet/weapon attribution rules unchanged.

## 3. Approaches considered

1. **Native meter with equipment profiles, recommended and selected for this draft.** Record readable native session summaries after combat and associate them with observed equipment. It fits the confirmed in-game scope and leaves unsupported fields visible with explanations.
2. **Traditional combat-log meter.** Best suited to detailed hit statistics on clients that expose them, but restricted combat-log access makes it unsuitable as the Forever foundation.
3. **AddOn plus external log analyzer.** Could provide additional analysis if disk logs contain the necessary evidence, but requires separate tooling and unverified data availability. Excluded by the user's scope choice.

## 4. Runtime and boundaries

- Runtime folder and manifest: `TitanApproxDPS/TitanApproxDPS.toc`.
- AddOn name: `Titan Approx DPS`; initial development version: `0.1.0-alpha`.
- Account SavedVariables: `TitanApproxDPSDB`, partitioned by stable character identity, client flavor and schema version.
- Lua with Lua 5.1 semantics; no runtime compilation or network service.
- Native WoW frames and built-in artwork; minimal dependencies.
- Titan is an optional integration using its available LibDataBroker library. Recording, minimap access and the main window must work without Titan installed.
- No hard dependency on another damage meter, Titan Gathered, or an external application.
- English UI and documentation initially; names obtained from the client retain their localization.
- No automation of player actions, combat-log restriction workarounds, group-message reporting, release publication, or game restart.

Use the reference AddOn's guarded-read approach, but validate every new API against Forever. Do not assume Classic APIs merely because the version begins with `1`.

## 5. What gets recorded

### Sessions and capture lifecycle

Use the native meter's session boundaries as the primary damage interval. Local combat and equipment events provide context, not a substitute timing definition for native totals.

1. On login, detect capabilities, recording policy and character identity. Observe existing native sessions as a baseline; do not silently count pre-installation history.
2. Observe session creation and equipment context, including the interval between the earliest possible session start and the local combat event. Missing pre-pull equipment coverage makes attribution partial.
3. During combat, observe lightweight context and mark native session updates for later processing; do not query damage summaries for live display or accumulate ongoing totals. Keep previously finalized results unchanged. Never perform arithmetic, string formatting, serialization or table-key operations on secret values.
4. When a session ends, request a readable snapshot. Inspect containers and fields before iterating or using them. Restricted data remains pending even after the player's combat flag clears.
5. Retry at 0.5, 1, 2, 5 and 10 seconds, then on relevant native meter/restriction updates. Maintain at most 32 pending sessions, expose overflow as a coverage gap, and never fabricate missing damage.
6. Persist a readable session contribution atomically. Repeated update events must not add that contribution again. A later changed snapshot replaces its retained contribution, rather than adding another fight.
7. Reload, logout, death, native meter reset, zoning, recording pauses and session eviction have explicit states. Preserve pending identifiers and known context, but never claim uninterrupted observation across an unknown interval.

Native session IDs are not assumed globally unique or stable across reloads. Persist a meter epoch, public session metadata and a local receipt ID. Reconcile known pending/committed receipts after reload only when their identity is unambiguous. On an ambiguous collision or reset, retain history, mark a gap and baseline unknown old sessions rather than risking duplicate totals. Never call the native reset API as part of an AddOn reset.

Recording eligibility applies to the entire native session. A session spanning a pause, resume, import cutover or unknown login interval is excluded from lifetime and comparison aggregates, with a visible coverage gap; no partial damage split is invented. Completed sessions whose whole interval preceded a pause may still resolve from pending state. Resume baselines native history and admits only wholly observed new sessions. Export tells the user if pausing would exclude an open fight and allows waiting for it to finish. On the destination, imported pending records remain historical unresolved observations; their source-client native identifiers are never queried or committed as destination sessions.

### Weapons and loadouts

Record main hand, off hand, ranged slot where supported, and an explicit unarmed profile. Keep caster weapons, shields and held off-hand items in the equipment context. Missing item metadata is retried and never collapsed into unarmed.

A weapon profile uses item ID, relevant item-link variant fields and equipment role. Display names are labels, not keys. Keep enchant and variant information when available, with a separate base-item rollup for comparing the same item across variants. Record the full weapon tuple as a loadout ID.

Store full equipment and readable character context as a separate fingerprint so a weapon change can be distinguished from simultaneous armor, level or talent changes. Unsupported context is explicitly unknown. Do not duplicate full equipment data into every spell record.

For a session with one fully observed loadout, associate its spell totals with that loadout as **damage while equipped**. A dual-wield session belongs to the pair; do not credit the full damage independently to both hands. A ranged weapon in the tuple does not prove every spell used it.

If equipment changes mid-session, retain overall and spell totals under `Mixed equipment`. The timeline identifies weapons observed, but no proportional split is invented. Direct weapon records require explicit source evidence. Delayed projectiles, damage-over-time effects, procs and summons are not reassigned to a new weapon based on their arrival time.

Each weapon remains discoverable in the UI, including historical and unequipped weapons. Its page shows associated loadouts and spells. Where direct weapon damage is unavailable, show that limitation alongside equipped-loadout results.

### Spells

Key spells by numeric spell ID. Preserve distinct IDs/ranks and use a fallback label when names are not cached. Keep spell-only aggregates and a separate `(spellID, loadoutID)` view for eligible sessions. Track direct and periodic components separately only with explicit source evidence; otherwise show the native combined total.

A successful cast does not establish a hit, a damage amount, a crit, or a cast-to-damage match. Cast counts may be shown separately if validated, but damage per cast requires complete matching coverage.

### Pets

Keep owner-only, pet-only and owner-plus-pet totals distinct when the source permits. First establish whether native owner totals already include pets. Never add a pet subtotal to an owner total that already includes it.

Pets, guardians and temporary summons require an explicit owner association. If the native source folds them into player totals without a reliable split, label player totals `Includes pets; split unavailable` and leave the pet panel unavailable. Owner equipment is context, not a pet weapon identity. Pet changes and dismissal do not erase historical records.

### Target and environment context

Partition lifetime counters, spell/loadout/method aggregates, comparison queries and exported records by `pve`, `pvp`, `mixed` or `unknown`. PvE and PvP have independent rankings. Mixed and unknown fights retain their damage in separately visible history/totals, but never enter either pure ranking. An optional all-context total is explicitly labeled and never decides the best weapon or method.

Classify the player's outgoing damage recipients using complete readable evidence for the native session. Non-player-controlled hostile NPCs support PvE; hostile players and explicitly player-controlled pets/guardians support PvP. Verified recipients of both kinds mean mixed. Missing coverage or unresolved ownership means unknown, or mixed if both recipient kinds are already proven. A selected target, PvP flag or zone alone does not establish the classification of every recipient. Record environment separately as outdoor, dungeon, raid, battleground, arena or unknown; location never substitutes for recipient evidence. Do not split an indivisible mixed session's damage or duration between pure modes.

Use public native target summaries where sufficient and preserve reasons where not. The diagnostic gate must establish whether Forever exposes enough evidence for automatic pure-mode classification; if not, keep the affected data in unknown instead of guessing. User-selected test labels describe intent and must never silently turn unknown observations into verified PvE or PvP.

### Combat methods

Proposed v1 representation: a named, user-selected test profile, chosen outside combat, with an immutable method ID and version (`methodRef = {methodID, version}`). Examples include ranged with pet, ranged without pet, melee, or a player-defined spell strategy. These labels express the intended method; measured spell contributions and supported pet data show the observed results. They do not certify that a rotation was followed.

Snapshot the selected method when session observation begins. A label selected after a fight starts applies only to the next fight; editing a method creates a new version and does not reclassify previous results. Unlabeled fights remain `Unassigned`, keeping all other valid statistics. Incomplete session-start coverage cannot produce a verified method association. Compare method versions within the same proven combat mode, with equipment, character context, pet semantics and sample sizes visible.

The proposed method profiles add no recommendation engine, cast-order reconstruction or timing heuristic. Keep their dictionary, per-session association, aggregate keys and versions in export/import.

## 6. Metric definitions

### Damage and DPS

- Lifetime damage is damage observed while recording was enabled, starting at the recorded coverage date. It is not the character's pre-installation lifetime damage.
- Store native damage totals as reported and label their semantics. Do not silently subtract overkill. Offer effective damage only if overkill meaning and coverage are validated.
- Session DPS uses the native source's documented amount-per-second value where readable. Store its denominator/basis separately.
- For comparisons across sessions, use `sum(eligible damage) / sum(eligible native session duration)`, labeled **damage per combat second**. This is not an average of session DPS values or damage divided by wall-clock lifetime.
- Spell contribution uses the same eligible session-duration pool as its parent loadout comparison, including sessions where that spell did no damage. A separate `DPS in sessions using this spell` view may use a narrower pool, but must state that denominator.
- Unknown or zero duration produces no derived DPS. Damage remains eligible for lifetime totals, with timed-damage coverage shown separately.
- Best session DPS is distinct from maximum individual hit. Label spell contribution and pet-inclusive totals explicitly.

### Crit and hit metrics, conditional feature

Only calculate these when complete public hit evidence exists for the selected bucket:

- Observed crit rate: `100 * critCount / critEligibleLandedCount`. Show the numerator and denominator. Unknown crit flags and components that cannot crit do not enter this rate.
- Observed normal average: `normalDamage / normalCount`; observed crit average: `critDamage / critCount`.
- Crit damage percentage: `100 * observedCritAverage / observedNormalAverage` within the same spell, component, hand and compatible context. A value of `200%` means twice the observed normal average; optional bonus display is `100%`.
- Crit share of damage: `100 * critDamage / classifiedDamage`. This answers a different question and has a separate label.
- Maximum crit and normal hit: maxima of explicitly classified individual hits. Do not use a spell total or the meter's bar maximum.
- No eligible hits, absent normal baseline, or incomplete classification produces an explained unavailable result. Miss/dodge/parry rates require separate complete attempt evidence.

Example acceptance fixture: normal hits `100, 120, 80`, crits `200, 240` yield total `740`, crit rate `40% (2/5)`, normal mean `100`, crit mean `220`, crit damage `220%`, max normal `120`, max crit `240`, and crit damage share approximately `59.459%`. At 10 eligible combat seconds, damage per combat second is `74`.

Do not pool incompatible spell/hand ratios into a single implied universal crit multiplier. Aggregate counts and sums before calculating compatible rates; never average displayed percentages.

### Misses, avoidance and prevented damage

The user requires failed attacks to be recorded, including failures for reasons other than a literal `MISS`. Keep an overall **Unsuccessful attacks** category and separate reason counters where the source explicitly supplies them: miss, dodge, parry, immune, evade, full resist, full block, full absorb, deflect, reflect and unknown failure. A reflect is a redirected outcome and must be labeled as such; do not silently classify it as a literal miss.

Partial blocks, partial resists and partial absorbs are mitigation on a landed attack, not an unsuccessful attack. A normal or critical hit can carry a mitigation annotation. Glancing/crushing hits, where explicitly reported, are also landed outcomes. Do not infer a full failure from a zero damage total or an unavailable amount. Full prevention requires explicit evidence; multiple flags on the same resolution must not create multiple failed attacks. If no single primary reason can be established, count one unknown failure and retain any readable annotations separately.

Persist primitive `resolvedAttackCount`, `landedAttackCount`, `failedAttackCount` and `failedByReason` per compatible weapon/hand, spell/component, loadout, combat mode and method bucket. Include pets only with proven ownership. Attempts refer to resolved strikes against individual recipients, not button presses or casts: an AoE cast can resolve against several targets, and periodic components must not share an unrelated direct-strike denominator. Unresolved or unobserved outcomes are coverage gaps, not failed attacks.

Show observed unsuccessful rate as `100 * failedAttackCount / resolvedAttackCount`, and literal miss rate as `100 * failedByReason.miss / resolvedAttackCount`, only for a completely observed, compatible set of resolutions. Individual reason rates use the same denominator. Show counts, denominator and coverage. Exact counts with incomplete denominator may be displayed as partial observations, but not as a complete failure rate. Require `resolvedAttackCount = landedAttackCount + failedAttackCount`, and require mutually exclusive primary failure-reason counts to sum to `failedAttackCount`.

Acceptance example: 80 landed strikes plus 10 misses, 5 dodges, 3 parries and 2 immunes yield 100 resolved strikes, 20 unsuccessful attacks, a `20%` unsuccessful rate and `10%` literal miss rate. A partially blocked landed strike remains one of the 80 landed strikes and does not increment failures. Observed crit rate still uses its eligible landed-hit denominator, rather than treating misses as non-crits.

These statistics follow the post-fight workflow. Complete public post-fight counts are sufficient if a source provides them; individual events are not required solely to reconstruct those counts. However, waiting until after combat cannot recover miss fields absent from the source. Unattributed `UNIT_COMBAT` notifications, timing matches to recent casts, character-sheet hit chance and successful casts do not establish the player's weapon/spell failure counts. Expose unsupported outcome fields with a reason, while retaining supported damage comparisons.

## 7. Comparisons and useful additions

Default rankings answer **observed performance under the selected conditions**, not guaranteed weapon superiority or an optimal rotation.

- Compare two loadouts or a spell across two loadouts using the same character, context filters, damage semantics, duration basis and pet policy.
- Compare named method versions in the same combat mode; show weapon differences and observed spell contributions rather than treating the method label as proof of an executed rotation.
- Show damage, damage per combat second, eligible duration, session count, sample coverage, spell share, best session DPS and conditional hit/crit fields.
- Show conditional unsuccessful-attack counts, literal misses, per-reason breakdowns and observed rates alongside damage, preserving separate PvE/PvP and method scopes. Never rank missing failure data as perfect accuracy.
- Default ranking eligibility: at least 10 complete timed sessions and 120 combat seconds per side. Make these thresholds configurable. Below-threshold rows stay visible as `Insufficient sample`.
- Show absolute and percentage differences. A zero or missing baseline has no percentage difference.
- Distinguish a supported numeric result from a fair comparison: mark differences in level, other equipment, known target context and readable build/talent fingerprints. Unknown context stays visible.
- Offer session, current-login, character lifetime and imported archive scopes. Combined-character lifetime damage is optional and never used as the default weapon ranking.
- Keep partial, mixed-equipment and unavailable samples visible, while excluding them from rankings that require complete attribution.
- Provide recording pause/resume, clear coverage dates, pinned comparison profiles and a recent-fight view.

Resource efficiency, buff uptime, simulation-based recommendations and statistical significance claims are deferred until their inputs and methodology are validated.

## 8. User interface

Use one movable, resizable tabbed window as the initial interface. Retain position, size, selected character, filters and last tab. Support Escape to close, readable column headings, scrolling/pagination and empty-state explanations.

Tabs:

1. **Overview:** latest finalized fight, owner/pet policy, lifetime damage, top spells, methods and coverage. Show PvE and PvP separately, with explicit access to mixed/unknown history.
2. **Weapons:** historical weapon list, linked loadouts, spell breakdown and conditional damage records.
3. **Spells:** per-spell results, contribution and loadout comparisons.
4. **Pets:** supported pet breakdowns or the reason a split is unavailable.
5. **Compare:** two selectable weapon, spell or method profiles, shared combat-mode filters, samples and differences. Select/create/version the next-fight method outside combat here.
6. **History:** latest 200 detailed sessions, capture state, timestamps and mixed-equipment warnings.
7. **Data and settings:** recording, capability report, retention, export/import, minimap visibility and scoped reset.

The Titan Panel entry shows the last finalized fight's DPS or a selected cumulative metric, labeled with its combat mode, and opens the main window on left click. Values stay unchanged during a new fight. Its paged tooltip lists every recorded weapon through accessible pages, with a real horizontal separator between weapon result groups. Each group shows supported values and attribution labels under the selected PvE/PvP scope. Mouse wheel changes pages. Right click opens settings and recording controls. Missing Titan must not prevent startup.

Coalesce native meter events into a queue of session references needing post-fight processing and reuse a bounded row pool for finalized results. Refresh open reports after a readable completed contribution is committed, after a query/filter change or after an import; do not run a live DPS repaint loop. Pending capture retries remain independent of tooltip visibility and must defer restricted reads while combat resumes. Detach update callbacks when no scheduled capture work remains. Anchor tooltips to available screen space.

The minimap launcher uses a circular button with a thin standard border, draggable around the minimap circumference. Save its angle, support minimap scale changes, and provide hide/show and position reset controls. Left click opens results; right click opens settings. Use built-in artwork and native button feedback.

Commands: `/tadps`, `/tadps compare`, `/tadps export`, `/tadps import`, `/tadps status`, `/tadps pause`, `/tadps resume`, and `/tadps minimap`. `/tadps status` reports capabilities and coverage without dumping private combat records.

The design deliberately leaves exact pixel dimensions, column widths and sorting controls to implementation, subject to live layout checks. No special glyphs or decorative emoji in UI text or documentation.

## 9. Persistence, export and import

### SavedVariables and retention

Use schema-versioned character records, equipment/profile/method dictionaries, metric sums/counts/maxima partitioned by combat mode and method version, capability/coverage records, deduplication receipts and settings. Persist sufficient primitive statistics to recompute every displayed supported metric.

Keep the latest 200 detailed sessions by default, at most 32 pending sessions, and 2,048 recent deduplication receipts with their replaceable contributions. Before retiring receipts, fold their contributions into a stable historical aggregate; never subtract or revise that retired aggregate based on an unrecognized old native session. Unknown old sessions remain outside capture after a new baseline.

Trimming recent detail never reduces lifetime totals or removes weapon/spell profiles. Do not persist an unbounded raw event log. At a configurable default 8 MiB estimated serialized data size, warn and offer an archive/export; do not silently delete lifetime data. Exact memory and byte cost must be measured during implementation.

Unknown future schemas open in a preservation mode with recording/import mutation disabled. Migrations are transactional with a retained pre-migration copy. Resetting sessions, statistics or settings uses explicit scopes and confirmation; it never clears other AddOns or the native meter.

### Migration format and behavior

Use a versioned JSON format named `TitanApproxDPS-statistics`, schema `1`, containing all retained characters, profiles, primitive statistics, history, coverage, semantics and capture receipts. Version the JSON interchange format separately from the internal SavedVariables schema. UI preferences are optional in the export. A human-readable CSV summary may be added later; it is not the migration format.

Default transfer flow:

1. Pause recording and resolve readable pending sessions, or explicitly export them as pending. Freeze the snapshot.
2. Generate a JSON document or, for large histories, a collection manifest plus bounded JSON documents. Use numbered clipboard parts, starting live EditBox tests at 16 KiB per part. Identify collection, document and part separately, with declared lengths and integrity checksums.
3. On the destination, paste all parts into an import staging view. Reject missing, duplicate, mixed or damaged parts before accepting a document. A collection must contain every manifest-declared document before restoration is possible.
4. Validate schema, types, finite nonnegative values, references, counts, lengths and metric invariants. Parse JSON as data, never with `loadstring` or execution of pasted text.
5. Preview characters, replacement scope, retained sessions, unavailable metrics and identity mapping.
6. Confirm **Restore selected character statistics**. Keep a pre-import backup; replace that character's statistics atomically. Preserve destination settings unless explicitly included and selected. Destination recording resumes with a fresh capture baseline.

Import does not add cumulative snapshots together. Restoring the same export twice must leave the same totals. A separate **Open as comparison archive** action preserves local live statistics and excludes archive totals from local lifetime totals. Reopening the same snapshot updates/selects the existing archive instead of duplicating it. Divergent histories from two simultaneously used computers are not merged in v1.

Migration snapshots need stable identity mapping. Include the minimum character identity needed for a reliable restore, state it in the export UI, and allow explicit mapping when a stable public GUID is unavailable. Exclude opponent names and transient target GUIDs by default. A redacted share export, if added, is marked comparison-only and cannot silently replace a character's live data. The AddOn sends nothing over the network and cannot write arbitrary external files; copy/paste and game-managed SavedVariables are the supported paths.

Safety limits per JSON document: 16 MiB reconstructed bytes, nesting depth 32, maximum 100,000 container entries, and bounded strings. Larger datasets, including one large character, are partitioned at record boundaries into multiple documents under a shared collection manifest. Cross-document references, unique record ownership and collection completeness are validated before one atomic restore. No snapshot is truncated, and no data is applied document by document to the live store. Staging may be cancelled without mutation; insufficient client memory must leave local data intact and allow a later retry. Checksums detect accidental corruption and are not authentication.

## 10. Delivery sequence and acceptance gates

The detailed task checklist is [plan-titan-approx-dps-implementation.md](plan-titan-approx-dps-implementation.md).

1. **Compatibility and diagnostics:** establish which data exists on Forever. Produce a loadable diagnostic alpha and an evidence report. This is the first live gate; unsupported fields remain unavailable.
2. **Durable damage capture:** implement post-fight summaries, coverage, session reconciliation and lifetime totals. Prove repeated events/reloads do not duplicate damage.
3. **Weapon and spell analysis:** implement equipment profiles, conservative attribution, spells, conditional pets and metric calculations.
4. **Results and comparisons:** build all tabs, fair-comparison filters and accessible history.
5. **Titan and minimap:** integrate the paged weapon results and circular launcher, including operation without Titan.
6. **Migration:** deliver full round-trip export/import, previews, backups and comparison archives.
7. **Release candidate validation:** package runtime-only files and execute automated plus live acceptance checks.

These are dependency-ordered milestones, not calendar promises. Live validation is required at compatibility discovery and final acceptance. In automatic mode, complete independent tasks while awaiting live evidence, but do not label mocked API behavior as verified client support.

### Definition of done

- Native readable damage and spell totals match a recorded client reference for the same session, semantics and source scope.
- Ongoing combat changes no displayed or cumulative damage numbers; finalized public results update aggregates once, with revisions replacing the earlier contribution.
- PvE/PvP aggregates remain disjoint; mixed and unknown fights are retained outside both rankings. Method versions survive collection, comparison and transfer.
- Unsupported crit, hand and pet fields display reasons, and no spell total becomes a hit record.
- Every historical weapon is accessible; mixed-equipment sessions cannot produce invented splits.
- Pet inclusion never doubles owner totals.
- DPS weighting, zero-duration cases, retries, native resets and reload reconciliation have meaningful tests.
- Titan tooltip pagination and separators, all tabs and minimap dragging pass live checks.
- Export/import restores every retained supported statistic and coverage label, including attack-resolution counts and failure reasons; repeat restore is idempotent; malformed imports mutate nothing.
- Runtime files compile with Lua 5.1 semantics; deterministic tests and packaging checks pass.
- Documentation distinguishes automated verification from live acceptance and records remaining limitations.

## 11. Risks and decisions reserved for review

The principal risk is that several requested statistics cannot be observed through Forever's public APIs. The accepted fallback is a useful supported-metrics AddOn, with conditional fields preserved for future public API support. More UI cannot recover missing hit evidence.

Weapon comparisons remain observational. Buffs, target armor, encounter length and player behavior can change damage independently of the equipped weapon. Expose coverage and context rather than claiming a causal upgrade recommendation.

Long restrictions or native history eviction may leave gaps. Capture coverage must stay visible and historical data must survive those gaps.

The builder review identified recording-boundary eligibility and oversized single-character migration as consequential gaps. The explicit exclusion policy and transactional collection format above resolve them as proposed design decisions.

The user approved automatic development. Runtime candidate 0.1.0-alpha now exists; see Codex-development-progress.md for actual progress and limitations. Local installation was attempted but blocked by filesystem permissions before destination changes. No Git initialization, commit, push or publication has occurred. Automatic local installation rules in the sibling Titan Gathered repository apply to that repository; they are not silently copied as authorization for this new project. Packaging and a previewable installer are planned here; deployment must follow this project's actual permissions and the user's subsequent development instructions.
