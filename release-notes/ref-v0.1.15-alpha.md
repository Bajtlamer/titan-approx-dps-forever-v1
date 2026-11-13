# Titan Approx DPS 0.1.15-alpha

Character build snapshot, collected at the start of every fight.

## Added

- When combat starts the addon reads the character's offensive stats once and stores them on every fight of that combat: level, strength, agility, stamina, intellect, spirit, attack power, ranged attack power, spell power (highest school), melee, ranged and spell crit chance, and main hand, off hand and ranged speed.
- A build bucket (attack power band of 100, spell power band of 50) is stored with each snapshot. It is the key later used to group caster spell statistics by build instead of by weapon.
- Only readable values are stored. A value that cannot be read (restricted, invalid) is left out, never stored as zero. A genuinely readable zero is kept.
- If nothing is readable at combat start, the most recent out-of-combat reading is used and labelled "out of combat".
- Window, Data tab: number of fights that carry a snapshot and a readable line describing the latest one. Window, History tab: a Build bucket column.
- Snapshots are validated on load and on import, and they are exported and imported with the fights.

## Unchanged

- No combat log events are registered. No statistic, record or lifetime value changes: this version only collects data.

## Limits

- Stat functions may be restricted in combat in some clients; the out-of-combat fallback covers that. Real-client behavior requires in-game verification.
- Snapshots are kept with retained fights; fights folded into historical totals no longer carry theirs.
