# Reference: records, statistics, categories, build snapshot and estimates

Status: current as of 0.1.17-alpha. All values come from completed native damage-meter sessions of the local player. Nothing here reads the combat log or invents crit, miss or weapon attribution.

## 1. What a "maximum" is

The native damage meter returns per-fight summaries, not single hits. All "best" values are therefore:

- Best fight: the largest total damage credited to a weapon group (or to the character) in one fight.
- Best DPS: the largest damage divided by fight seconds in one fight. Only fights of at least 10 seconds with a known duration qualify.
- Best spell: the largest damage of one spell or ability in one fight, per weapon group.

A single-hit maximum is not available and is never shown.

## 2. Protected values

Two kinds of values cannot be reset, deleted, hidden away or lowered by the player:

- Character and weapon lifetime damage (cumulative).
- The records above (`character.records`).

Rules for records (`Records.lua`): a value is replaced only when strictly larger; fresh weapon reports, hiding a weapon, a damage-meter reset and an import never lower it; import merges by keeping the larger value; a later native revision that corrects a fight downward leaves the record as it was; malformed record data is rejected on load and on import. The module has no function that clears, lowers or deletes records. Records are keyed by the weapon group at the time a fight is stored, and a one-time backfill (`recordsBackfilled`) fills them from retained fight history on first load. Fights already folded into historical totals cannot be backfilled.

Everything else (typical DPS, recent DPS, spreads, estimates) improves with use and follows the report period or all periods.

## 3. Statistics (`Stats.lua`)

- Sample: one DPS value per fight and weapon group, damage assigned to the group divided by fight seconds, fights of at least 10 seconds. Samples are derived from stored fights, so a native session revision replaces its sample.
- Typical DPS: duration-weighted mean of the samples (weighted Welford update, weight is fight seconds). Statistics are kept per weapon group and per combat mode; "all fights" merges the modes with the parallel-merge formula.
- Spread: relative standard error, `sqrt((S / W) / n) / mean`, where `S` and `W` are the weighted sum of squares and total weight.
- Confidence: none (no fights), low (under 10), medium (10 to 29, or 30 or more with spread of 10 percent or more), high (30 or more fights with spread under 10 percent).
- Recent DPS: median of the last 20 samples in capture order.
- Report period statistics reset with "Start fresh weapon reports". Lifetime (all periods) statistics never reset. Fights retired from the retained window (over 2048) are folded into a permanent weighted summary (`baseStats`).

## 4. Categories (`Categories.lua`)

| Category | Contains |
|----------|----------|
| Melee | main hand and off hand weapon groups, druid form attacks, shield abilities, melee swings with unknown hand |
| Ranged | the ranged slot group (Auto Shot and ranged abilities) |
| Spells | known abilities that use no specific weapon (caster spells, finishers) |
| Pet | damage the native source marks as pet or summon |
| Other | unidentified spells and weapon-less abilities that need a missing weapon |

Melee, ranged and spell damage never share a group. Caster spells are never credited to an equipped staff.

## 5. Build snapshot (`BuildSnapshot.lua`)

Read once when combat starts and stored on every fight of that combat. If nothing is readable at combat start the latest out-of-combat reading is used and labelled `out of combat`.

Fields (a field is stored only when readable; unreadable values are absent, never zero): level, strength, agility, stamina, intellect, spirit (effective values), attackPower and rangedAttackPower (base plus buffs), spellPower (highest school), meleeCrit, rangedCrit, spellCrit (one decimal), mainHandSpeed, offHandSpeed, rangedSpeed (two decimals), source, and `bucket` = `ap<band of 100>-sp<band of 50>` using the larger of melee and ranged attack power.

## 6. Item tooltip comparison

Shown outside combat when hovering a weapon with a slot 16 (main hand, one hand, two hand), 17 (off hand) or 18 (ranged, thrown) equip location, compared with the item equipped in the same slot. Never shown for the equipped item itself or for non-weapons.

Always: weapon DPS of both, percentage change, stat differences.

Rough effect (fewer than 20 usable fights): `autoShare * weaponDpsChange`, where autoShare is the observed auto-attack share of the equipped weapon's damage.

Calibrated estimate (`Estimator.lua`, at least 20 fights with a build snapshot):

- Auto-attacks (melee, ranged). Per fight `k = autoDps / (weaponDps + AP / 14)`, using attack power for melee and ranged attack power for ranged. The typical `k` is the duration-weighted mean. Change in DPS `= k * ((newWeaponDps - oldWeaponDps) + deltaAP / 14)`, where `deltaAP` is the new item's attack power difference plus strength and agility converted at classic rates for warriors, paladins, shamans (strength 2), rogues and hunters (melee strength 1 and agility 1, ranged agility 2). Percentage = change in DPS divided by the typical group DPS of the usable fights. Confidence: low under 30 fights, high at 30 or more with spread under 10 percent, otherwise medium.
- Spells. Ordinary least squares of the spell group's DPS on spell power over the fights. Required: at least 20 fights, spell power range of at least 5 points and 3 percent of its mean, and a positive slope. Change in DPS `= slope * deltaSpellPower`. Confidence: high at 30 or more fights with r squared of at least 0.7, medium with r squared of at least 0.3, otherwise low. Shown only when the two weapons differ in spell power.

Missing weapon DPS, too few fights or degenerate data produce a reason line, never a number. These are estimates: abilities, procs, enchants, set bonuses and other stats are not modelled.

## 7. Window and tooltip

- Tooltip (hover): compact summary without paging, three text levels (large key values, normal rows, small light tips).
- Results window (left click on the minimap button or Titan panel, or `/tadps window`): native tabs (Overview, Weapons, Spells, Compare, History, Data), native drop-down boxes for scope, category and period, native search box, check box for hidden weapons, sortable scrollable lists with scroll bars. Fallback controls are used when a native template is missing.

### Colors by value type

| Value | Color |
|-------|-------|
| Titles and key metric labels | gold `FFD100` |
| Row labels | `E6E6E6` |
| Tips and explanations | `B8B8B8`, small font |
| Unavailable | grey `9D9D9D` |
| Damage | `74D5FF` |
| Ability damage | `F3A5CE` |
| DPS | `FFB84D` |
| Percentage shares | `7FD694` |
| Lifetime damage | `FFE680` |
| Protected records | legendary orange `FF8000` |
| Gains / losses | green `1EFF00` / red `FF4040` |
| Confidence | high green, medium gold, low grey |
| Categories | class colors: melee `C79C6E`, ranged `ABD473`, spells `9482C9`, pet `00FF96`, other grey |

Weapon names keep the item quality colors from item links.

## 8. Stored fields

- `character.records`: `{character={fightDamage,fightDPS}, weapons={[group]={name,fightDamage,fightDPS,spells={[id]={value,at}}}}}`, each entry `{value,seconds,at,receiptID}`.
- `character.baseStats[group][mode]`: `{n,mean,s,weight}`.
- `receipt.build`: the snapshot above.
All three are validated on load and on import.

## 9. Known limits

- Real-client behavior of the native APIs, templates and fonts needs in-game verification.
- Attribution of damage to a weapon is by supported attack and ability rules, not the weapon's isolated causal contribution.
- Estimates assume the variation in your own fights reflects the effect being measured; buffs and gear changes are that variation.
