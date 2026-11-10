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
