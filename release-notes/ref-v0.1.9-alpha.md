# Titan Approx DPS 0.1.9-alpha

Protected best-fight records.

## Added

- Per weapon group and for the character: best total damage in one fight, best DPS in one fight (fights of at least 10 seconds), and best damage of each spell or ability in one fight.
- The Titan tooltip shows "Best fight / Best DPS (protected)" under each weapon group, in a dedicated record color.
- Records are taken from every stored fight and backfilled once from retained fight history on first load.

## Protection

- Records only ever increase. There is no reset, delete or lowering action.
- Starting fresh weapon reports, hiding a weapon, meter reset and import do not lower them. Import merges by keeping the larger value.
- Later native corrections that lower a fight do not lower an existing record.
- Malformed record data in SavedVariables or an import is rejected, never silently accepted.

## Limits

- The damage meter provides per-fight summaries, not single hits. These records are best fight values, not a maximum single hit.
- Fights older than the retained history that were already folded into historical totals cannot be backfilled; records start from retained history.
- Real-client behavior requires in-game verification.

Lifetime damage behavior is unchanged.
