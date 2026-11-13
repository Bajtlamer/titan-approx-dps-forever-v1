# Titan Approx DPS 0.1.4-alpha

Hunter Arcane Shot now appears under the ranged weapon recorded for the fight. The rule covers ranks 1 through 8 and requires Hunter class, explicit player origin and a recorded ranged item that is not known to be a nonweapon. Other abilities and uncertain sources remain separate. Pet damage stays separate.

A 111-damage regression fight now yields Heavy Shortbow 92 (Auto Shot 39, Arcane Shot 53) plus pet Attack 19. Percentages within the bow group are 42.4% and 57.6%. These totals associate supported abilities with their weapon; they do not measure how much of a spell's damage was caused by the item alone.

Empty origin buckets no longer produce misleading zero-damage melee categories. Real unresolved damage remains visible. Reports are rebuilt from existing records, with no new reset, no raw record deletion and no reduction of character lifetime. Existing player-origin Arcane Shot records can now increase the classified ranged lifetime subtotal; records without source evidence stay unresolved.

Validation: 15 Lua suites, 3 Python tests and compilation of shipped Lua. The regression covers all eight ranks, actor/class/item guards, conservation, shares and report resets preserving lifetime. Live client verification remains required.

Rank IDs and ranged-special classification reference: https://github.com/gunba/wow-forever-sim/blob/forever/sim/hunter/arcane_shot.go. Local MaxDps Hunter Forever also identifies Arcane Shot as 3044. No third-party implementation code is copied.

Install the packaged TitanApproxDPS folder and run /reload. No new runtime files or automatic report reset are introduced by this update.
