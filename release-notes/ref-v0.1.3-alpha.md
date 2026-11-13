# Titan Approx DPS 0.1.3-alpha

Fresh weapon reports, duplicate-label fixes and clearer local-player evidence.

- Merge incidental item-link variants that made the same bow/staff appear twice. Keep actual enchant, gem, suffix and bonus variations separate.
- Read both native named-color and conventional item links; resolve missing names from client item data and refresh after data-load events.
- Remove redundant equal lifetime/current summaries and replace vague unknown/unclassified labels with explanations of missing weapon, hand or source evidence.
- Verify native source GUID against the local player; ignore group totals and zero/overall session IDs. Repeated session updates replace earlier contributions.
- Add a separate weapon-report period. First load starts a fresh period once; configuration provides a confirmed reset for later tests. All character and weapon lifetime history is retained. Old session revisions do not refill a reset period.
- Reject restores that would reduce existing weapon lifetime history. Sanitize and normalize report archives alongside lifetime archives when restoring.
- Add Recent test fights: native session ID, target observed at combat start, target changes, grouped status and spell/source breakdown. This is diagnostic context, not invented per-mob attribution.
- Reduce and mask the minimap icon, move it outside the map edge, and add a position reset control.

Fourteen Lua suites and three Python tests pass, including group-source exclusion, normalized identities, report-only reset, reload/compaction retention, transfer archives and minimap geometry. Two independent-review transfer findings were reproduced and fixed. Live appearance and capture ordering still require user testing. Existing lifetime amounts are preserved, not retrospectively rewritten based on screenshots.

Install the runtime ZIP and /reload. Fight one mob at a time and wait for combat to end before inspecting Recent test fights.
