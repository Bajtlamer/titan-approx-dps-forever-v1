# Titan Approx DPS 0.1.1-alpha

Compact Titan-first weapon and spell reporting for Forever.

- Hover Titan/minimap for grouped item-colored weapon/loadout headings, lifetime totals, selected-scope damage and damage per combat second.
- Spell rows show damage and percentage of the group's damage, sorted by damage. Aggregate methods once; preserve mode filters and report missing spell attribution.
- Separators and bounded pages keep the report compact. Wheel handling binds to actual launcher frames because the installed Titan bridge does not forward the broker callback.
- Right-click menus provide weapon results, character lifetime totals, scope, recording, minimap visibility, transfer and reversible report hiding. Hiding never deletes statistics; Show all weapons restores visibility.
- Restoring older data preserves character lifetime through an explicit carried-forward amount. New fights add to it; no invented weapon attribution is created.
- /tadps opens the compact summary. /tadps window retains the optional large view.

Existing staff/bow sets remain a single equipped-set group. The collector cannot prove item-specific damage. Crits, misses, pet splits and automatic pure PvE/PvP classification retain their existing limitations.

Validation: seven Lua suites, three Python tests and compilation of all shipped Lua files with Lua 5.1 semantics. Independent review found and drove a frame-dispatch pagination fix. Screenshots confirm the previous candidate collected data, but this new native layout still needs live validation.
