# Class weapon rules implementation plan

Goal: expand the approved weapon/spell classification design to all nine Forever classes without guessing hand or actor identity.

Architecture: a data registry contains exact class/spell-ID families, classification targets and primary implementation references. WeaponAttribution resolves these rules only for explicit player-origin records and recorded eligible slots. Known spells without a weapon attack, form abilities and shield abilities get separate named groups. Native collection and lifetime records remain unchanged. Unlisted ranks and unknown sources remain unresolved.

Constraints: Forever interface 16001, Lua 5.1, post-fight only. Preserve raw damage, character lifetime, report reset semantics and conservative dual-wield behavior. No combat-log events, English-name matching or private SavedVariables in source. No blanket attribution of spells to whatever item is equipped.

- [x] Inspect Forever simulator implementations for all nine classes; record exact supported IDs and their source paths.
- [x] Add failing tests for each class, cross-class/actor/missing-item guards, dual-wield main-hand abilities, positive unresolved damage, categories, conservation and lifetime reset/import behavior.
- [x] Add SpellRules.lua before WeaponAttribution.lua in the manifest. Replace the Hunter-only conditional with the shared lookup. Keep auto-attack handling and unresolved dual-wield swings conservative.
- [x] Expose current-class rule coverage through the native menu. Add a prefixed reference inventory generated from the registry so partial rank coverage is explicit.
- [x] Bump the candidate version, update release notes, run all suites, inspect source changes and build/verify the runtime package.
- [x] Preview/apply the authorized game installation and attempt Git publication; report environmental blocks without bypassing them. Both mutations are blocked by filesystem permissions; deployment/publication remain unfinished.

Review focus: same spell ID in a different class, unknown actor origin, shield/relic in a requested weapon slot, Druid form attacks mistaken for held-weapon attacks, repeated native snapshots, and old backups with less classified lifetime. Test each applicable boundary rather than assuming class support means complete spell coverage.
