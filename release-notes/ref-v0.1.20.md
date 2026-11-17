# Titan Approx DPS 0.1.20

Item tooltips now compare any equippable item with what you wear, not only weapons. Boots, gloves, rings, trinkets and other gear show the derived effect of the stat change for your class: melee and ranged attack power, spell power, base health, base mana, and physical and spell crit in points. Examples: Agility becomes attack power and crit for Hunter and Rogue, Strength for Warrior, Intellect gives mana and spell crit but never spell damage, and a Stamina-only item shows health with "no change from these stats" for damage.

When you have 20 fights with a build snapshot, the attack power change is turned into a calibrated damage estimate with the same method as the weapon estimate, and spell power uses the existing spell fit. Crit is shown but not included in the percentage. Rings and trinkets are compared with both worn pieces. Weapon tooltips gain the same derived rows. Stats without a confirmed conversion (Spirit, Hit, Haste and others) are listed as not modelled. Crit conversion is known for level 60 only. Druid Agility counts as attack power in Cat Form only.

Includes the 0.1.19 source change that was never published: random-bonus variants of the same base weapon can be compared, and identical variants stay excluded.

Conversions are documented in ref-item-stat-effects.md and need live client confirmation. Existing statistics and SavedVariables are preserved.

Validation: full tools/check.py suite, including class rules, health and mana thresholds, gear slots, rings, calibration and combat guards.
