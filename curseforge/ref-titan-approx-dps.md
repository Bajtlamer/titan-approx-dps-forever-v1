# Titan Approx DPS

## Summary

Post-fight damage analysis, weapon records and estimated weapon comparisons for WoW Forever, with optional Titan Panel integration.

## Description

Review completed fights and build a personal record of weapon performance in WoW Forever. Titan Approx DPS uses readable native damage-meter sessions to provide post-fight summaries, weapon records, historical statistics and estimated comparisons.

### Features

- Post-fight session capture from supported native damage-meter data.
- Weapon-loadout context and protected best-fight records.
- Recent, report-period and lifetime statistics.
- Overview, Weapons, Spells, Compare, History and Data views.
- Rough and calibrated weapon comparison estimates where sufficient evidence is available.
- Recording controls, JSON transfer tools, a minimap launcher and optional Titan Panel integration.

### Requirements and installation

Requires WoW Forever 1.60.1 and readable native damage-meter APIs. Install `TitanApproxDPS` in `Interface/AddOns/` and restart the client. Titan Panel is optional.

### Getting started

Complete a supported fight, leave combat, then open the results with the minimap launcher or `/tadps window`. Hover the launcher or Titan entry for a compact summary.

- `/tadps status`: open capability and data information.
- `/tadps compare`: open weapon comparisons.
- `/tadps pause` and `/tadps resume`: control recording.
- `/tadps method NAME`: label the method for subsequent observations, outside combat.
- `/tadps export` and `/tadps import`: open the transfer tools.

### Notes and limitations

This is post-fight analysis. Session capture depends on the native data and event sequence the client exposes. Uncertain session starts, protected fields and missing evidence limit what can be recorded. Pending capture does not resume across reloads, while completed saved statistics remain available.

Weapon comparisons are estimates. An ability associated with a weapon does not prove how much of its damage was caused by that item. Missing durations, ambiguous weapon attribution, unavailable crit/miss details and unproven PvE/PvP classification remain explicitly unresolved rather than being guessed.

### Reporting issues

Include the addon version, client build, character class, relevant weapon setup, steps to reproduce and any capability messages. State whether the issue occurred during capture, after combat or while comparing weapons. Review exported data for character identity before sharing it.

## Upload reference (local notes)

Use **Summary** for the short project summary and **Description**, including its subsections, for the main project description. The notes below are preparation references and do not need to be pasted into the public description.

- Current local version: `0.1.18`.
- Intended client: WoW Forever 1.60.1, interface `16001`.
- Runtime folder: `TitanApproxDPS`.
- Dependencies and integrations: No required companion addon. Titan Panel is optional. Recording depends on readable native damage-meter data.
- [400px PNG avatar](../artwork/v1/TitanApproxDPS/avatar-400.png)
- [1024px PNG logo](../artwork/v1/TitanApproxDPS/logo-1024.png)
- [64px PNG icon preview](../artwork/v1/TitanApproxDPS/icon-64.png)
- [Original generated PNG](../artwork/v1/TitanApproxDPS/master.png)
- [All artwork versions](../artwork/)

Suggested screenshots to capture in game: Overview after a completed fight; weapon records; Compare tab with estimates; optional Titan Panel summary.
