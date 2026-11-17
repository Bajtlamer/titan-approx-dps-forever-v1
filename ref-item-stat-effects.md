# Item stat effects by class

Used by `TitanApproxDPS/ItemEffects.lua` to turn the stat difference between a hovered item and the equipped one into derived values. The conversions come from the Forever data overview supplied by the project owner on 2026-11-17 and still need live client confirmation. Crit conversion is level 60 only, without talents or buffs.

## Common rules

- Stamina: first 20 points give 1 health each, further points 10 each, before other modifiers. Applied at the current total Stamina.
- Intellect: for mana classes first 20 points give 1 mana each, further points 15 each. It also gives spell crit. It never gives spell power.
- Agility: gives physical crit by the class values below. Armor and dodge are not modelled.
- Spirit, Hit, Haste, Armor, Defense, Block, resistances, MP5/HP5, ratings, procs and set bonuses are listed as "not modelled", never converted.

## Per class

| Class | Strength | Agility | Agility per +1 crit point | Intellect per +1 spell crit point |
|-------|----------|---------|---------------------------|-----------------------------------|
| Warrior | 2 melee AP | 2 ranged AP | 20 | none |
| Paladin | 2 melee AP | none | 19.8 | 59.9 |
| Hunter | 1 melee AP | 1 melee AP, 2 ranged AP | 52.9 | 60.6 |
| Rogue | 1 melee AP | 1 melee AP, 2 ranged AP | 29 | none |
| Shaman | 2 melee AP | none | 19.7 | 59.2 |
| Druid | 2 melee AP | 1 melee AP in Cat Form only | 20 | 59.9 |
| Mage | 1 melee AP | none | 19.5 | 59.5 |
| Priest | 1 melee AP | none | 20 | 59.5 |
| Warlock | 1 melee AP | none | 20 | 60.6 |

Mana classes: all except Warrior and Rogue. Spell crit from Intellect is not added to ranged crit. Druid form is read when the tooltip is shown (Cat Form is form ID 1); an unknown form keeps a note and omits Agility attack power.

## Damage estimate

- Melee and ranged attack power change goes through the calibrated factor k of the equipped weapon group, the same method as the weapon estimate (`Estimator.AutoPower`): extra DPS is k times attack power / 14. It needs 20 fights with a build snapshot.
- Spell power goes through the existing straight-line fit of spell damage on spell power (`Estimator.Spell`).
- Crit points are shown but not included in the percentage, because Forever does not confirm the crit damage multiplier.
- A direct "Attack Power" bonus counts as melee attack power, "Ranged Attack Power" as ranged, matching the weapon estimate.
- Items with no damage-relevant stat show "no change from these stats" and, where applicable, the health or mana change.

## Slots

Head, neck, shoulders, chest, waist, legs, feet, wrists, hands, back, off-hand items and shields, relics, and rings and trinkets (compared with both worn pieces, each labelled). An empty slot is compared with nothing. Shirt and tabard are not compared. The comparison is skipped for a slot where the same variant is already worn, outside combat only, and uses no combat events.
