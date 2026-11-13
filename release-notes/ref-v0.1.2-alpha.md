# Titan Approx DPS 0.1.2-alpha

Partial individual weapon attribution replaces equipped-set grouping in the main report.

- Auto Shot and readable client-identified ranged auto-attacks are assigned to the recorded ranged item.
- Player-origin melee auto-attacks can be assigned to main hand when the saved context has an empty or proven nonweapon off hand and known non-Druid character class.
- Shields are excluded. Ambiguous dual-wield swings, source/form uncertainty, pet/summon markers, unsupported abilities and missing equipment stay in separate unassigned groups.
- Auto-attack and ability subtotals are distinct. This candidate has no validated weapon-ability rules, so ability damage is kept unclassified.
- Preserve raw receipts, spell/mode/method aggregates and character lifetime. Historical ranged results can be reinterpreted from slot tuples; old melee data without source evidence stays unresolved.
- DPS pools include eligible intervals with the same item in the same slot even when it produced no assigned damage in that interval. Unknown-duration damage never enters the timed numerator.
- Imported actor-origin primitives are validated for conservation. Live destination identity is retained, different-class restores are rejected, and missing class evidence cannot create player-melee certainty.

All eight Lua suites, three Python tests and Lua 5.1 compilation pass. Independent review identified the cross-class import issue, reproduced in tests and fixed. Native creature-name semantics, ranged-auto classification and the updated report still require live validation.

Install the attached runtime ZIP and fully restart WoW because the manifest adds WeaponAttribution.lua. Open /tadps, hover the Titan entry or minimap launcher, and right click for scope and visibility controls.
