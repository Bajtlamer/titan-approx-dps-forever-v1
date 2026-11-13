# Forever class weapon rules

Candidate 0.1.5-alpha covers all nine Forever classes through 33 exact-ID ability families (187 spell IDs). This is an explicit supported inventory, not a promise that every spell or rank is classified. The IDs and mechanics below are corroborated by the linked Forever simulator implementation, read on 2026-11-10. No third-party implementation code is copied. Simulator corroboration still requires live client confirmation.

## Classification contract

- Weapon rules require the recorded class, explicit player origin, and a saved item in the requested slot that is not known to be a nonweapon.
- Main-hand abilities can be assigned during dual wield if the ability itself proves the hand. Ordinary melee auto swings still cannot be divided between hands from native spell totals. No off-hand damage is invented.
- A missing requested item produces the required-weapon-not-recorded group. A staff or shield being equipped never redirects an unsupported spell to it.
- No-specific-weapon abilities have no weapon-hit damage component in the referenced implementation. Their output can still depend on equipment stats and buffs; these totals do not isolate a weapon's causal effect.
- Druid form attacks remain separate from held weapon attacks. Shield attacks remain separate from weapon reports. Pet/summon markers override every class rule. Unknown actor origins do not gain class-rule certainty.
- Auto Shot and the guarded native ranged-auto predicate remain shared auto-attack rules. Predicate-only ranged auto IDs require explicit player origin and reject known nonweapon items. The fixed Auto Shot ID 75 retains its historical attribution when a ranged item is recorded, unless that item is known nonweapon. Caster wand attacks can use the predicate when the client exposes it; no unsupported fixed wand rule is assumed.
- Unlisted IDs, unverified classes and inconsistent native breakdowns stay unresolved. Exact IDs avoid English-name matching, cast-timing guesses and confusion with group members' casts.
- The classifier reads retained aggregates. It does not mutate raw receipts, reset reports or delete lifetime history. Newly supported historical player-origin abilities may increase a classified weapon subtotal while character lifetime remains unchanged.

## Coverage limitations

Warrior and Rogue families list only the rank IDs exposed by the inspected implementations; lower ranks and new overrides not listed remain unresolved. In particular, this is not complete low-level Warrior/Rogue spell coverage. Druid Claw currently lists only 9850. Hunter Multi-Shot uses the single Forever rank 2643, not an old expansion rank list. Improved Slam overrides, seals/poisons/imbues with uncertain hand attribution, and additional unlisted abilities are not guessed. A per-class live test should check each newly observed ID before extending this inventory.

Inspect the native Ability rules submenu for the current character's supported families and IDs. Recent test fights shows observed IDs and actor origins for finding gaps.

## DRUID

- **Wrath**: No specific weapon. IDs: 5176, 5177, 5178, 5179, 5180, 6780, 8905, 9912. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/druid/wrath.go).
- **Claw**: Form ability. IDs: 9850. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/druid/claw.go).
- **Shred**: Form ability. IDs: 5221, 8992, 9829, 9830. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/druid/shred.go).
## HUNTER

- **Arcane Shot**: Ranged. IDs: 3044, 14281, 14282, 14283, 14284, 14285, 14286, 14287. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/hunter/arcane_shot.go).
- **Aimed Shot**: Ranged. IDs: 19434, 20900, 20901, 20902, 20903, 20904. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/hunter/aimed_shot.go).
- **Multi-Shot**: Ranged. IDs: 2643. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/hunter/multi_shot.go).
- **Serpent Sting**: Ranged. IDs: 1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/hunter/serpent_sting.go).
- **Raptor Strike**: Main hand. IDs: 2973, 14260, 14261, 14262, 14263, 14264, 14265, 14266. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/hunter/raptor_strike.go).
## MAGE

- **Fireball**: No specific weapon. IDs: 133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151, 25306. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/mage/fireball.go).
- **Frostbolt**: No specific weapon. IDs: 116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/mage/frostbolt.go).
## PALADIN

- **Holy Strike**: Main hand. IDs: 679, 678, 1866, 680, 2495, 5569, 10332, 10333. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/paladin/holy_strike.go).
- **Exorcism**: No specific weapon. IDs: 879, 5614, 5615, 10312, 10313, 10314. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/paladin/exorcism.go).
- **Consecration**: No specific weapon. IDs: 26573, 20116, 20922, 20923, 20924, 1280345, 1280346, 1280347, 1280348, 1280349. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/paladin/consecration.go).
## PRIEST

- **Smite**: No specific weapon. IDs: 585, 591, 598, 984, 1004, 6060, 10933, 10934. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/priest/smite.go).
- **Shadow Word: Pain**: No specific weapon. IDs: 589, 594, 970, 992, 2767, 10892, 10893, 10894. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/priest/shadow_word_pain.go).
## ROGUE

- **Sinister Strike**: Main hand. IDs: 1759, 8621, 11293, 11294. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/rogue/sinister_strike.go).
- **Backstab**: Main hand. IDs: 2590, 8721, 11279, 11281, 25300. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/rogue/backstab.go).
- **Ambush**: Main hand. IDs: 8676, 8725, 11268, 11269. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/rogue/ambush.go).
- **Hemorrhage**: Main hand. IDs: 16511. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/rogue/hemorrhage.go).
- **Eviscerate**: No specific weapon. IDs: 6762, 8624, 11299, 11300, 31016. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/rogue/eviscerate.go).
## SHAMAN

- **Stormstrike**: Main hand. IDs: 17364. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/shaman/stormstrike.go).
- **Lightning Bolt**: No specific weapon. IDs: 403, 529, 548, 915, 943, 6041, 10391, 10392, 15207, 15208. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/shaman/lightning_bolt.go).
- **Lightning Bolt Overload**: No specific weapon. IDs: 408439, 408440, 408441, 408442, 408443, 408472, 408473, 408474, 408475, 408477. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/shaman/lightning_bolt.go).
- **Earth Shock**: No specific weapon. IDs: 8042, 8044, 8045, 8046, 10412, 10413, 10414. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/shaman/earth_shock.go).
## WARLOCK

- **Shadow Bolt**: No specific weapon. IDs: 686, 695, 705, 1088, 1106, 7641, 11659, 11660, 11661, 25307. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/warlock/shadowbolt.go).
- **Corruption**: No specific weapon. IDs: 172, 6222, 6223, 7648, 11671, 11672, 25311. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/warlock/corruption.go).
- **Immolate**: No specific weapon. IDs: 348, 707, 1094, 2941, 11665, 11667, 11668, 25309. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/warlock/immolate.go).
## WARRIOR

- **Heroic Strike**: Main hand. IDs: 11567, 25286. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/warrior/heroic_strike_cleave.go).
- **Cleave**: Main hand. IDs: 20569. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/warrior/heroic_strike_cleave.go).
- **Mortal Strike**: Main hand. IDs: 21553. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/warrior/mortal_strike.go).
- **Overpower**: Main hand. IDs: 11585. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/warrior/overpower.go).
- **Slam**: Main hand. IDs: 11605. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/warrior/slam.go).
- **Shield Slam**: Shield ability. IDs: 23925. [Implementation reference](https://github.com/gunba/wow-forever-sim/blob/forever/sim/warrior/shield_slam.go).
