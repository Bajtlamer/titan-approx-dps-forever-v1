# Plan: item effect comparison for non-weapon gear

Goal: hovering any equippable item shows what swapping it in would change: attack power, spell power, health, mana, crit points and, with enough fight data, a calibrated damage estimate. Weapons keep their comparison and gain the same derived rows.

## Decisions (approved 2026-11-17)

- Formula plus calibration: derived values work immediately; the percentage uses the existing calibrated estimators after 20 fights with a build snapshot.
- Intellect shows mana and spell crit, never spell damage. Conversions are in ref-item-stat-effects.md.
- Crit is shown in points and is not part of the percentage.
- Rings and trinkets are compared with both worn pieces. Druid uses the current form read at hover time.

## Units

- `ItemEffects.lua`: per-class rules, `Derive` (pure) and `Context` (guarded reads of level, Stamina, Intellect, form).
- `Estimator.lua`: shared `calibrate`, new `AutoPower` and `ForGear`; weapon behavior unchanged.
- `Compare.lua`: gear slot table and slot names.
- `TooltipHook.lua`: `EvaluateGear`/`RenderGear`, shared row helpers, derived rows on weapon tooltips.

## Tests

`tests/item_effects.lua` (class rules, thresholds, level, form), `tests/gear_tooltip.lua` (tooltip output, rings, calibration, guards), plus additions to `tests/estimator.lua` and `tests/tooltip_hook.lua`. Run `python3 tools/check.py`.

## Release

Runtime change: patch version increment and stable numeric version through `tools/release.py` after the check passes.
