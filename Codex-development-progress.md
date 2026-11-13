# Development ledger: Titan Approx DPS

Plan: plan-titan-approx-dps-implementation.md
Design approved for automatic development by user on 2026-11-10.

## Candidate 0.1.0-alpha

Started native API adapter, pure data storage, post-fight recorder, equipment tuple capture, named methods, aggregate queries, native result windows, Titan integration, minimap launcher, bounded JSON transfer, package and installer.

No full implementation-plan task is marked complete: their real-client gates and several specified behaviors remain outstanding. This is a diagnostic/development candidate, not a completed release.

Verification: four Lua suites (domain assertions, migration/JSON regressions, independent-review regressions, simulated runtime integration), a Python package/installer scenario, and compilation of all manifest-loaded Lua files. Tests were initially run against missing modules, then against implementation. Additional failing regression checks drove parser grammar and optional spell-read fixes.

Independent review found five defects: malformed saved data initialization, invalid imported method references, stale session-context admission, ignored late revisions and unknown-duration damage inflating DPS. Reproductions are retained in tests/review.lua; the suite passes after fixes. No second review was requested.

Ruling: this directory is not a Git repository; use the existing authorized workspace, without Git initialization or skill wrapper scripts requiring Git. No commit, remote, push or worktree was created.

Ruling: first candidate uses conservative unknown recipient classification. Player-selected methods never certify PvE/PvP. Pure-mode rankings remain gated by actual source evidence.

Ruling: only session IDs first observed during combat can acquire that interval's equipment/method context. Unknown post-combat first sightings are excluded instead of guessing their interval. Live event order must be tested.

Ruling: complete migration collections, arbitrary comparison selection, persistent pending-session reconciliation, full settings/geometry controls and archive imports remain unimplemented. Initial bounded JSON restore handles current-character small snapshots only. README describes these limits. No cumulative snapshot merging.

## Live gate

Not tested in the running WoW client. Native payloads, session creation order, out-of-combat readability, source identity, equipment API behavior, UI layout, minimap dragging and actual clipboard copying remain unverified. A loadable package is prepared for this gate.

Next: validate candidate in Forever, correct adapter/session identity against captured public metadata, implement missing lifecycle/coverage and transfer collection requirements, complete UI comparisons/method controls and remaining acceptance cases. Do not promote conditional hit, crit, miss, pet or mode fields without adequate public evidence.

Installation attempt: installer preview succeeded. Applying to /Applications/World of Warcraft/_forever_/Interface/AddOns failed when creating the staging directory with Operation not permitted. No destination runtime files were installed or changed. Sandbox permission escalation is unavailable. Package remains in dist/ for manual installation and live validation.

## Candidate 0.1.1-alpha: Titan-first reporting

Reviewed all five user screenshots from Desktop/ApproxDPS: old UI displays 11,645 damage across 46 sessions under an equipped staff/bow set, with six spell contributions. This establishes observed previous-candidate capture, not complete client validation.

Implemented compact weapon/loadout groups, merged method summaries, damage shares, separately labeled group/character lifetime, bounded tooltip pages and native result/configuration menus. Hide/show affects reports only. Importing an older snapshot retains the missing character lifetime amount as a separately labeled protected offset; new fights continue adding to it. Existing combined weapon sets remain one group.

Tests: reports.lua covers aggregation, percentages, visibility and import lifetime protection. titan_menu.lua covers native rendering labels, menu callbacks, rarity text, complete spell pagination and actual owner-frame wheel dispatch. Existing runtime and review suites pass; packaging/release tests use the new version.

Independent review found that installed Titan does not forward the broker OnMouseWheel field. Added a failing native owner-dispatch test, then bound EnableMouseWheel/HookScript once per owner; full suite passes. No further concrete blockers were reported. This new layout still needs live inspection.

Ruling: weapon removal is reversible hiding, preserving weapon data and character lifetime. No delete/reset control is added. Historical mixed equipment is not split into individual weapon damage without source evidence.

0.1.1 delivery evidence: all seven Lua suites, three Python tests and manifest compilation passed; git diff --check passed. Runtime ZIP built with checksums. Installer preview succeeded, but apply failed creating its staging directory with Operation not permitted; installed 0.1.0 files were not modified. Git branch creation failed locking .git refs. gh repo view failed connecting to api.github.com. No new commit, tag, push or GitHub release was produced for 0.1.1 in this environment.

## Candidate 0.1.2-alpha: supported slot attribution

User clarified the requirement as damage from each actual main-hand/off-hand/ranged item, not equipped-set damage, and accepted a partial supported implementation.

Implemented WeaponAttribution.lua and rewrote primary report aggregation to classify auto-attacks to saved item/slot keys. Ranged Auto Shot has an explicit ID rule and other ranged auto-attacks can use the guarded client predicate. Player-origin 6603 can reach main hand only with unambiguous off-hand state and known non-Druid class; dual wield and unknown historical actor identity remain unresolved. No weapon ability rules are enabled yet. Pet/summon markers and unclassified damage are kept outside weapon subtotals. Raw data and character lifetime are preserved.

Public primary references inspected: Forever DamageMeterDocumentation.lua, SpellDocumentation.lua (IsRangedAutoAttackSpell), ItemDocumentation.lua (GetItemInfoInstant), and Blizzard DamageMeterEntry.lua (creatureName special pet formatting), all under Gethe/wow-ui-source/forever. This supports guarded candidate APIs, not live validation. Historical names use captured item links, never substring inference about attack types.

Storage now retains conserved player/summon/unknown origin aggregates alongside existing spell totals. Restore validates those sums; derived caches are rebuilt. Independent review found cross-class import could corrupt class evidence. Reproduced the defect, rejected mismatched known classes, preserved destination runtime identity and stripped player certainty when source/destination class evidence is unavailable. Full suite passes.

Ruling: scope is initially classified auto-attacks. Unsupported abilities remain visible as unclassified and do not inflate any weapon. No guessed off-hand split, no assignment of old pet-ambiguous melee records, and no restoration of class certainty from unknown imported metadata.

0.1.2 delivery: eight Lua suites, three Python tests and all manifest compilation pass. Installer preview succeeded; applying failed at staging-directory creation with Operation not permitted, before destination changes. GitHub API access remains unavailable. Current source changes are not committed/published; existing Git metadata write restrictions remain in effect. The ZIP is ready for manual installation and full client restart.

## Candidate 0.1.3-alpha: fresh reports and screenshot issues

Inspected both new Desktop/ApproxDPS screenshots (21:23:50 and 21:24:27). They show duplicate Item 3036/4566 headings, identical lifetime/selected totals, unclear category labels and overlapping minimap artwork. Duplicate headings are reproduced from incidental item-link fields; screenshots alone do not establish that all underlying historical damage was doubled. Lifetime history is retained as requested.

Normalized item identities across unique/link-level/spec fields while retaining enchant/gem/suffix/bonus identity; support named rarity-color links and client item-name loading. Added reportGeneration and separately retained reportBaseRows, so current reports can reset without deleting character or weapon lifetime history. First candidate load starts the requested fresh report period once. Further reset uses a confirmed menu action outside combat. Native source GUID must match the local player; group sources/totals and zero/overall session IDs do not contribute.

Renamed unexplained damage groups and suppress redundant equal summaries. Added native-session/target-start/spell/source diagnostics in Recent test fights, retaining only NPC target names (player targets get a generic label). No arbitrary damage-to-mob split is inferred. Smaller masked minimap icon, separated radius and a position reset control require live visual acceptance.

Independent review found reportBaseRows were omitted from class-origin sanitization and JSON spell-key normalization. Reproduced both in report_transfer.lua, fixed both shared paths, and reran the full suite. Fourteen Lua suites, three Python tests and shipped Lua compilation pass. Additional retention coverage crosses the 2048-receipt threshold without losing either lifetime or current report totals.

Ruling: reset affects the current reporting period only, retaining raw lifetime records. Older restores that reduce known weapon lifetime are rejected. Initial target metadata is observational context; controlled mob-by-mob tests must wait for combat to end. No party-member totals or target-health inference is used.

0.1.3 delivery: verification and diff whitespace checks pass; ZIP/checksums built. Installation failed creating the staging directory with Operation not permitted before changing installed files. GitHub repository access now succeeds, but git add fails creating .git/index.lock with Operation not permitted. No commit, tag, push or GitHub release was created. The verified ZIP remains available for manual installation and /reload.

## Candidate 0.1.4-alpha: Arcane Shot and empty origin groups

User approved associating Arcane Shot with the saved ranged weapon. Added an explicit eight-rank ID rule guarded by Hunter class, player origin and a recorded item that is not known to be nonweapon. Forever simulator sim/hunter/arcane_shot.go corroborates IDs and ranged-special classification; local MaxDps Hunter Forever uses 3044. No guessed mapping for other abilities or unknown actors is introduced.

Reproduced the missing 53-damage association with a failing regression, then implemented the rule. Also skip zero-damage origin buckets at the classifier boundary. The screenshot's 111 damage now yields ranged 92 (39 auto, 53 ability) and summon 19, with no empty melee category. Positive unresolved melee remains visible. Rules are derived reporting changes; raw receipts and character lifetime remain intact, with no new automatic reset. Tests cover ranks, shares, conservation, guards and lifetime preservation.

0.1.4 delivery: all 15 Lua suites, 3 Python tests and shipped Lua compilation passed; git diff --check passed; ZIP and SHA256SUMS built. Installation preview succeeded, but apply failed at staging-directory creation with Operation not permitted, before changing installed files. git add failed creating .git/index.lock with Operation not permitted. No commit, tag, push or GitHub release was produced. Manual installation of the verified ZIP and /reload are required in this environment.

## Candidate 0.1.5-alpha: all-class rule registry

Implemented plan-class-weapon-rules.md using the approved class-independent collector and class-specific exact-ID attribution approach. SpellRules.lua covers all nine classes with 33 families/187 IDs, each linked to its inspected Forever simulator implementation. Inventory is ref-class-weapon-rules.md. Added separate no-specific-weapon, form, shield and required-weapon-not-recorded categories. Ability rules menu exposes current-class targets and supported IDs.

Ruling: source-backed exact IDs only, including partial Warrior/Rogue rank coverage, because the inspected implementations do not list every low-level rank. Do not infer rules from localized names or old expansion mechanics. Unlisted IDs remain unresolved and the inventory says so explicitly. No off-hand split is invented for ordinary dual-wield swings. Form attacks are not held-weapon attacks even where the simulator uses a generic main-hand proc mask.

Added failing per-class and menu regressions, implemented the registry/resolver, and reran the suite. All registry IDs are exercised with damage conservation. Raw receipts/lifetime reset behavior remain unchanged. Independent fresh-context review found a shared ranged-auto actor/nonweapon guard gap. Reproduced and fixed predicate-only actor handling and known nonweapon rejection, retaining the deliberate fixed-ID75 legacy attribution. Added class-rule import downgrade rejection and same-class round-trip coverage recommended by review. No additional new-class/import blockers were found.

Ruling: retain the fixed Auto Shot75 legacy rule with absent actor metadata when a ranged item is recorded, except a positively known nonweapon. Other predicate-derived auto IDs require explicit player origin. Missing item metadata is not proof of a nonweapon. This preserves valid historical weapon totals while preventing newly expanded caster-auto coverage from assigning uncertain actors or relics.

0.1.5 delivery: all 16 Lua suites, 3 Python tests and shipped Lua compilation passed. ZIP includes all 21 runtime files, including the newly manifest-loaded SpellRules.lua; every packaged byte and SHA256SUMS matched. git diff --check passed. Installation preview succeeded; apply failed creating the staging directory with Operation not permitted before modifying installed files. git add failed creating .git/index.lock with Operation not permitted. Release sequence preview is correct, but no source commit, tag, push or GitHub release was produced. The verified ZIP is ready for manual installation followed by a full client restart. Existing work stayed in the supplied workspace because prior candidate source was already uncommitted and Git metadata is not writable; no unrelated edits were reverted.

## Candidate 0.1.7-alpha: tooltip colors and website illustration

User requested colored tooltip values, violet slashes, and an illustrated website guide from the annotated screenshot. Added local presentation helpers for sky-blue damage, pink ability totals, amber DPS, green spell shares, gold lifetime and violet slash separators. Unavailable values remain gray. Shortened the report damage/DPS heading and clarified the percentage footer. Existing menu rendering tests strip WoW color markup before checking displayed text and verify spaced slash pairs.

Created website-assets/titan-approx-dps-tooltip-guide.png with the built-in image generation tool from the supplied screenshot. Inspected generated numbers and explanations against the screenshot, including bow1242,712/530,spell shares and pet475. Retained its prompt as website-assets/Codex-tooltip-illustration-prompt.txt. The illustration is a website asset and is not shipped in the addon runtime ZIP.

0.1.7 delivery: all 16 Lua suites, 3 Python tests and shipped compilation passed. Additional direct rendering checks verified lifetime, damage, ability, DPS, percentage and violet slash color markup, including gray unavailable values. Package bytes/checksum verified. Installation preview succeeded but apply failed at staging-directory creation with Operation not permitted. git add failed creating .git/index.lock with Operation not permitted. No installation, source commit, tag, push or GitHub release was completed. Website PNG and retained generation prompt are saved in website-assets/. In-game appearance awaits user verification.

## Candidates 0.1.9-alpha to 0.1.17-alpha: records, statistics, window and estimates

Plan: plan-weapon-records-stats-estimates.md (user-approved, executed inline, one releasable version per stage, in-game verification by the user after each). Reference: ref-weapon-records-and-estimates.md.

- 0.1.9: protected best-fight records (Records.lua). Max-only, import merges by maximum, malformed data rejected, backfill from retained history. Test tests/records.lua.
- 0.1.10: running statistics (Stats.lua) and categories (Categories.lua). Samples derived from receipts, so native revisions replace their sample; permanent weighted summary for retired receipts. Tests stats.lua and categories.lua.
- 0.1.11: rough comparison in item tooltips (Compare.lua, TooltipHook.lua). Added during execution at the user's request, before the tooltip and window stages.
- 0.1.12: Titan tooltip without paging, three text levels, a color per value type (Style.lua). Reports.Pages and wheel paging removed.
- 0.1.13: new results window (UI/ViewModel.lua, UI/Widgets.lua, UI/Window.lua). 0.1.14 replaced button imitations with native tabs, drop-down boxes, search box and check box after user feedback; templates confirmed from another addon running in the same client (TitanGatheredForeverV3).
- 0.1.15: build snapshot at combat start (BuildSnapshot.lua), visible in the Data and History tabs.
- 0.1.16: calibrated estimate (Estimator.lua) with a 20 fight minimum.
- 0.1.17: documentation and cleanup. Comparisons.lua and Metrics.lua removed (unused since the old window was replaced); their regression checks were ported to storage-level assertions.

Deviations from the plan: the rough comparison was added as its own version; the Compare tab compares observed results of two recorded weapons rather than estimating an arbitrary item (the estimate lives in the item tooltip); version numbers shifted by the extra releases.

Findings fixed along the way: two Python tests hard-coded a version and failed on every release (now read the manifest); check.py hung when it inherited an open stdin (run with stdin closed); a window test exposed a fragile search-box capability check (hardened); an estimator test depended on floating-point summation order (now integer damage like the real meter). The illustrated tooltip guide in website-assets predates the 0.1.12 colors and layout and is outdated; the folder is excluded locally from git.

Open: in-game verification of the 0.1.15 and 0.1.16 behavior needs at least 20 fights with a build snapshot per weapon; whether website-assets belongs in the repository is undecided.
