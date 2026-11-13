# Titan Approx DPS 0.1.5-alpha

The Hunter-only ability branch is replaced by a shared registry for all nine Forever classes. It contains 33 families and 187 exact spell IDs, corroborated against the linked Forever simulator implementations. See ref-class-weapon-rules.md for the full inventory and explicit rank limitations. This is class-wide support, not exhaustive spell or rank coverage.

Supported main-hand strikes (including Rogue abilities during dual wield), Hunter ranged abilities and Forever Paladin Holy Strike join the saved weapon. Known spells/finishers without a weapon-damage component, Druid form attacks and shield abilities get named separate groups. Pets/summons and unknown actors remain separate. Required but unrecorded weapons get an explicit category. Ordinary dual-wield swings are not divided between hands.

The native Ability rules submenu lists the current class's families, target and exact IDs. Existing reports are reinterpreted without another reset or deletion of lifetime records. Classified weapon totals can grow as retained player-origin abilities gain a rule; character lifetime remains unchanged.

Predicate-only ranged auto IDs now require player origin and reject positively identified nonweapon items. The fixed Auto Shot75 rule retains historical attribution unless the ranged item is known nonweapon. Missing item metadata does not erase otherwise valid historical attribution.

Validation: 16 Lua suites and 3 Python tests, shipped Lua compilation, package/installer tests, and an independent code review. The class regression iterates every rule ID and covers class/actor/item guards, source uncertainty, caster ranged-auto handling, reset conservation and backups that would reduce classified weapon lifetime. Simulator evidence requires additional live-client testing; unlisted low-level Warrior/Rogue ranks remain unresolved.

This release adds SpellRules.lua to the manifest. Fully restart WoW after installation so the new file is loaded. No game restart is performed automatically.
