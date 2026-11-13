# Titan Approx DPS 0.1.16-alpha

Calibrated upgrade estimate in item tooltips.

## Added

- Hovering a weapon now shows an estimated change calibrated on your own fights when at least 20 fights of the equipped weapon carry a build snapshot:
  - Auto-attacks (melee and ranged): damage per second is modelled as an efficiency factor times (weapon DPS + attack power / 14). The factor absorbs hits, misses, crits and uptime and is fitted from your fights. The estimate is the change in weapon DPS (plus attack power the new item gives, including strength or agility converted at classic rates) as a percentage of your typical DPS with the equipped weapon, with the DPS difference.
  - Spells: a straight-line fit of your spell group DPS on spell power over your fights. The estimate is the slope times the spell power the new item adds or removes.
- Each estimate states the number of fights and a confidence level (low, medium, high), and the line under it says what is and is not included.
- Spell estimates are shown only when the two weapons differ in spell power, and only when the data supports them: spell power must have varied across your fights and the fitted relation must be positive. Otherwise the tooltip gives the reason in small text.
- Below 20 fights the tooltip keeps the rough comparison and tells you how many of your fights have a build snapshot.
- Data tab: a row explaining what calibrated estimates need.

## Limits

- It is an estimate, not a measurement. Abilities, procs, enchants, set bonuses and other stats (such as intellect for crit) are not modelled.
- Strength and agility to attack power use classic rates for warriors, paladins, shamans, rogues and hunters only.
- Buffs and gear changes between fights are the variation the fit uses; a build that never changed gives a weaker spell fit.
- Real-client behavior requires in-game verification.
