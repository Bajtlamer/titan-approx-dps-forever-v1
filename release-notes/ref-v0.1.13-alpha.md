# Titan Approx DPS 0.1.13-alpha

New results window.

## Changed

- A left click on the minimap button or on the Titan panel opens (and closes) the results window. Hovering still shows the compact tooltip, right click still opens the menu.
- Header: character lifetime damage, best fight and best DPS in one fight in a large font, marked as protected.
- Tabs: Overview, Weapons, Spells, Compare, History, Data.
- Filters: scope, category (melee, ranged, spells, pet, other) and period (report period or all periods) as drop-down menus, a search box that matches weapons, categories, spells and targets, and a toggle for hidden weapons. The scope is shared with the Titan tooltip.
- Sortable columns: click a heading, click again to reverse. The active column is shown.
- Every list scrolls with a scroll bar and the mouse wheel. There is no Previous/Next paging.
- Overview and Weapons list weapon groups with a detail list below showing every spell of the selected group (damage, share, best in one fight).
- Spells tab combines spells across weapons. History lists completed fights newest first. Data explains the capture state and what cannot be known.
- Compare: choose any two weapons or groups with two drop-downs and see typical DPS, recent DPS, best DPS, best fight, lifetime and fights counted with a signed, colored difference.
- Same colors and three text levels as the Titan tooltip: large key values, normal rows, small light tips.
- Unknown tab names fall back to Overview.

## Limits

- Drop-downs are buttons that open the native context menu (they cycle through options if that menu is unavailable). Look, sizes and scrolling need in-game verification.
- Compare reports observed differences. They are not caused by the weapon alone.
