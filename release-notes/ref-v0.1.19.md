# Titan Approx DPS 0.1.19

Weapon tooltip comparisons now distinguish random-bonus variants of the same base item. A bagged Grunt Axe of the Gorilla can be compared with an equipped Grunt Axe of Holy Wrath. Identical variants remain excluded even when their unique ID or link level differs.

Comparisons select fight history for the equipped weapon's exact variant, including suffixes, enchants and bonus IDs. Existing fight statistics and SavedVariables are preserved.

Validation: full tools/check.py suite, including same-base bonus and suffix comparisons, identical-variant suppression and equipped-variant history selection. Live tooltip confirmation remains necessary.
