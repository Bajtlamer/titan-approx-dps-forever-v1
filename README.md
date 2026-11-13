# Titan Approx DPS

Development candidate `0.1.8-alpha` for World of Warcraft Forever, interface `16001`.

Analyzes completed native damage-meter sessions. No live DPS display or combat-log event registration. Optional Titan integration; the minimap launcher and results window work independently.

## Candidate behavior

- Stores observed damage, spell summaries and weapon-loadout context after combat, with duplicate-safe replacement of retained session contributions.
- Preserves 200 recent sessions and folds older retained receipts into historical aggregates. Current weapon reports use a separately resettable report period; character and weapon lifetime histories remain intact.
- Titan-first reports: hover the panel or minimap launcher for individual weapon-slot headings in saved item rarity colors, per-spell damage and percentage of the selected group's damage, group lifetime and character lifetime. The tooltip is a compact summary without paging: each weapon shows its top three spells, and right click > Weapon results lists every spell in a scrollable menu.
- Right click opens native menus for weapon results, character lifetime totals, combat-mode filters, recording, minimap visibility, export/import and reversible weapon visibility. Hidden groups keep collecting data; Show all weapons restores them without loss.
- The results window opens with a left click on the minimap button or the Titan panel (also /tadps window). It has Overview, Weapons, Spells, Compare, History and Data tabs, scope, category and period drop-downs, a search box, sortable columns and scrollable lists with scroll bars. There is no Previous/Next paging. Compare lets you choose any two weapons.
- Keeps PvE, PvP, mixed and unknown data separate. This initial adapter cannot prove complete recipient classification, so captured sessions are deliberately unknown. Pure-mode rankings are unavailable until a validated classifier exists.
- Records a selected method label for the next observed fight. Method dictionaries use immutable versions. Editing/version selection controls remain planned.
- Crits, hit maxima, misses and pet splits are unavailable from this adapter, with explanations. No unavailable count is represented as zero.
- Provides JSON export and validated, confirmed replacement of the current character, retaining a pre-import backup. Restoring an older snapshot cannot lower character lifetime damage; restoring data that would reduce an existing weapon lifetime is rejected. This initial UI handles up to 15,000 JSON bytes. Multipart collections, comparison archives, multi-character transfer and rollback controls remain planned. Large records remain in SavedVariables and are never truncated into an export.

Only native session IDs first observed during an observed combat interval are admitted. Uncertain session starts are excluded with a coverage note. Native IDs already present on login are baselined. Pending capture does not currently resume across reloads; completed statistics survive. Real-client event order and availability require validation before reliable capture can be claimed.

Weapon results associate supported attacks and abilities with their recorded slot/item; they do not isolate the item's causal contribution to damage. Mixed or incomplete equipment is kept separate. Unknown-duration damage stays outside pooled damage-per-second calculations.

## Use

Install `TitanApproxDPS/` in your Forever `Interface/AddOns/` directory and restart the client after initial installation.

- `/tadps`: compact Titan summary, without opening the large window.
- `/tadps window`: optional detailed window.
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

Automated tests are not proof of live Forever API support. See [the development ledger](Codex-development-progress.md) for evidence and outstanding work and the `plan-*` documents for the full intended scope.

## Reading the compact report

Spell percentages use the selected classified group's damage, not character lifetime damage and not an average of session percentages. Weapon lifetime always includes all recorded modes; the selected damage/spell rows use the current report scope. Methods are combined for this summary. Missing spell damage is shown as unattributed. Native spell overlaps are flagged rather than normalized away.

The primary report classifies supported attacks to individual slots/items rather than crediting the equipped set. Auto Shot (75), or a public C_Spell.IsRangedAutoAttackSpell result, goes to the saved ranged item. Player-origin melee Auto Attack (6603) goes to main hand only with known non-Druid character context and an explicitly empty/nonweapon off hand. Dual wield, unknown source, shapeshift ambiguity, mixed equipment, unsupported abilities and pet/summon markers remain separate. Shields never receive a weapon damage group.

The class registry supports all nine Forever classes using exact spell IDs and explicit player-origin evidence. Supported main-hand or ranged abilities join that saved item; known abilities without a weapon attack, form attacks and shield attacks get separate named groups. Unlisted abilities stay unresolved. See [the current inventory](ref-class-weapon-rules.md) for rank coverage, references and limitations. Weapon lifetime is the supported classified subtotal, not a claim to complete item-attributed damage. Each weapon's timed denominator includes eligible intervals with that same slot/variant equipped, including intervals with zero assigned attacks. Hidden profiles do not alter character lifetime.

Historical slot tuples can be reinterpreted without modifying raw receipts. Older melee records lack actor-source evidence and remain unresolved; no historical pet swings are guessed as player weapon damage. New reads preserve the native creature-name marker as player/summon/unknown evidence. Native marker meaning and ranged-auto predicate behavior remain live-validation gates. Item names keep their captured rarity colors.

There is no lifetime reset or weapon-delete action. Visible weapons controls only hide reports and do not delete damage records. Character totals may legitimately change when a native session revision corrects earlier data; user maintenance and imports cannot erase the lifetime counter. Protected lifetime carried forward from an older restore has no invented weapon attribution.

## Fresh tests and reading uncertain damage

On first load of 0.1.3-alpha, a fresh weapon-report period starts once. Historical character and weapon lifetime data is preserved. Later use right click > Start fresh weapon reports > Confirm fresh reports to start another period outside combat. Hiding and report resets never delete lifetime history; old native revisions do not repopulate a reset report period.

The collector reads the native local-player source, verifies its public GUID against the player, and requests only that source's spell breakdown. It does not use the party total, other party sources, target health differences or unattributed UNIT_COMBAT events. Own pet/summon contributions may be present in the native owner's breakdown and remain separate from weapon damage. Zero/overall session IDs are excluded, and repeated updates replace a session contribution.

- Your spells: weapon not identified: recorded local-player source damage whose spell currently has no supported weapon rule.
- Your melee: hand or source not recorded: a swing summary that cannot be assigned to one hand, or old data without player-versus-pet evidence.
- Your pet / summon: separate damage: a nonempty native creature marker in the local player's spell breakdown.
- Damage without spell details: a readable local total whose per-spell attribution is missing or inconsistent.
- Combat type not verified: incomplete evidence for PvE versus PvP. This is not a label for group-member damage.

For a controlled test, fight one mob, wait for combat to end, then inspect Recent test fights. It shows native session ID, your damage, spell IDs and source markers, initial NPC target, observed target changes and whether you were grouped. The initial target is context, not proof that every hit landed on that mob. Multi-target/chain pulls may share a native session. The addon does not invent per-mob allocations from an aggregate.

The primary report merges incidental item-link differences such as unique/link-level fields, retains actual enchant/gem/suffix/bonus variants, resolves missing item names through the client, and refreshes after item-data events. The compact minimap texture is masked and moved outward; Reset minimap position restores its new default. In-game visual acceptance remains necessary.

Starting with 0.1.4-alpha, empty origin buckets no longer create zero-damage melee or spell categories. Positive unresolved damage remains visible. Existing reports are reclassified from retained records without another automatic reset; character lifetime totals and raw records are unchanged. Historical Arcane Shot records without explicit player-origin evidence remain unresolved.

## Class rules in 0.1.5-alpha

The shared registry now covers all nine Forever classes with 33 ability families and 187 explicit spell IDs. Supported main-hand and ranged abilities join their recorded weapon. Known abilities without a specific weapon attack, Druid form attacks and shield abilities have named separate groups. Pet damage and uncertain actor/hand evidence stay separate. Current-class coverage is visible in right click > Ability rules.

See [the exact inventory and evidence](ref-class-weapon-rules.md) for supported ranks and limitations. This is not exhaustive ability coverage: unlisted IDs, particularly lower Warrior/Rogue ranks, remain unresolved. Rules never use an equipped staff as proof that a caster spell came from that weapon. Existing records are reinterpreted without an automatic reset or lifetime deletion.

This release adds SpellRules.lua to the manifest. Fully restart the WoW client after installation so the new file list is loaded. No new data collection during combat is introduced.
