# Titan-first report update

User authorized replacing the large default results window with compact Titan reports, using Titan Gathered 3 as a local interaction reference.

The native tooltip groups equipped weapon profiles across methods, retains item-link rarity colors, lists spell damage and shares of selected group damage, and separates weapon groups with horizontal rules. Character lifetime is always visible; weapon/loadout lifetime is independent of the current combat-mode filter. Superseded by 0.1.2: raw tuples remain intact, but supported auto-attacks are classified to individual items/slots; uncertain damage remains in explicit unassigned groups. No dual-wield split is invented.

Right-click menus control report mode, reversible per-character weapon visibility, recording, minimap, transfer and secondary windows. Weapon hiding keeps collecting and never changes lifetime data. The current character and other saved characters' lifetime totals have no delete/reset action. Older imports preserve the local lifetime amount not represented in restored detail, without assigning it to arbitrary weapons.

Report construction and imported data remain based on supported completed-fight observations. Pure PvE/PvP, crit/miss and pet limitations are unchanged. This update does not invent missing identity or outcome fields.

Implementation: Reports.lua plus Titan/Core/Minimap routing, protected-lifetime import changes, version 0.1.1-alpha, seven Lua suites and three Python tests. New UI live acceptance, installation and publication must be reported separately from automated checks. See README and release notes for behavior.
