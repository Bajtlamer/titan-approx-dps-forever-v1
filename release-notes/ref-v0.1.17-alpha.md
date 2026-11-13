# Titan Approx DPS 0.1.17-alpha

Cleanup and documentation. No behavior change.

## Changed

- Removed two unused runtime files left from the old window (`Comparisons.lua`, `Metrics.lua`). Nothing shown to the player depended on them.
- Their regression checks (untimed damage stays out of the timed DPS pool, per-mode row pooling) were ported to storage-level assertions, so the protection is kept.

## Documentation

- New reference `ref-weapon-records-and-estimates.md`: exact definitions of records, statistics, categories, the build snapshot, both item tooltip comparisons and the estimator formulas, the color table, stored fields and known limits.
- README, the development ledger and the staged plan describe the final state of all stages.

## Unchanged

- Records, lifetime damage, statistics, window, tooltips and estimates behave exactly as in 0.1.16-alpha.
