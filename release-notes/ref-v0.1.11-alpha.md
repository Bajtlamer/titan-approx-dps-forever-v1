# Titan Approx DPS 0.1.11-alpha

Rough weapon comparison in item tooltips.

## Added

- Hovering a weapon (item tooltip, also linked items) shows a comparison with the weapon equipped in the same slot: weapon DPS of both, percentage change, and stat differences (green for gain, red for loss).
- When you have recorded fights with the equipped weapon, the tooltip also shows a rough effect on your auto-attack damage and your typical DPS before and after. It applies the weapon DPS change only to the share of your recorded damage that came from auto-attacks, and states that share.
- Shown outside combat only. Items in slots 16 (main hand, one-hand and two-hand), 17 (off hand) and 18 (ranged, thrown) are compared. Armor and the equipped item itself are skipped.

## Limits

- This is a rough comparison, not a measured result. Abilities, stat scaling, procs and enchants are not included. A fuller estimate calibrated on your own data is planned.
- Item stat and tooltip APIs are used behind guards; if the client does not provide them the tooltip is simply unchanged. Real-client behavior requires in-game verification.
