# Titan Approx DPS 0.1.12-alpha

Titan tooltip redesign: no paging, three text levels, a color for every type of value.

## Changed

- The Titan tooltip no longer pages. It is a compact summary: character lifetime and best fight, then every visible weapon group with its typical DPS, recent DPS, protected best values, lifetime damage and its top three spells. All spells remain available in the right-click Weapon results menu, which is scrollable.
- Three text levels: key values (character lifetime, typical DPS, weapon DPS change) in a large font; ordinary rows in the normal tooltip font; tips, confidence notes and explanations in a small, light font.
- Colors by value type, following Blizzard conventions where one exists: gold for titles and key metric labels, white for labels, item quality colors from item links, green for gains and red for losses, grey for unavailable values and low confidence, legendary orange for protected records, and class colors for damage categories (melee, ranged, spells, pet). Damage, ability damage, DPS, percentage shares and lifetime each have their own color.
- Category label (Melee, Ranged, Spells, Pet, Other) shown at the right of each weapon heading.
- Cumulative report DPS is no longer shown in the tooltip; typical and recent DPS replace it. Report period damage is shown only when it differs from lifetime.
- The weapon comparison in item tooltips uses the same colors and text levels, and restores the Blizzard font for shared tooltip lines when the tooltip is cleared.

## Removed

- Tooltip paging, mouse wheel paging and the page counter.

## Limits

- Text sizes and tooltip widths depend on the client fonts and need in-game verification.
