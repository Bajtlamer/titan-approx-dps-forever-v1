# Titan Approx DPS 0.1.10-alpha

Converging statistics and separate damage categories.

## Added

- Typical DPS per weapon group: a duration-weighted average of one DPS value per fight, with fight count, a spread estimate and a confidence label (low under 10 fights, medium, high at 30 or more fights with a tight spread). It becomes more accurate as the weapon is used.
- Recent DPS: the median of the last 20 fights, so a change of weapon or build shows up quickly.
- Statistics are kept per weapon group and per combat mode. The Titan tooltip shows the current report period and, when different, the all-periods value.
- Damage categories: melee, ranged, spells, pet and other, available on every report group. Melee, ranged and spell damage never share a group. This applies to all nine classes.
- Native session revisions replace their fight sample instead of adding another one. Fights older than the retained history are folded into a permanent weighted summary.

## Unchanged

- Cumulative lifetime damage and the protected best-fight records.
- Fresh weapon reports reset only the report-period statistics; lifetime statistics and records stay.

## Limits

- Samples need fights of at least 10 seconds with a known duration.
- Statistics describe observed damage with a weapon, not its isolated causal contribution.
- Real-client behavior requires in-game verification.
