# Titan Approx DPS 0.1.0-alpha

First diagnostic alpha for World of Warcraft Forever, interface 16001.

- Post-fight native meter collection with retained session replacement and lifetime damage.
- Weapon-loadout and spell summaries, named combat methods and separate combat-mode storage.
- Initial results window, optional Titan integration and minimap launcher.
- Small-snapshot JSON export and confirmed replacement import with backup.

This is a development prerelease. Real-client API behavior, event order and layout are unverified. Captured combat mode currently remains unknown. Crits, miss counts, individual hit maxima and separate pet totals are unavailable from this adapter. Full comparison selection, multipart/multi-character migration, archives and pending-session recovery remain planned. See README.md for exact limits.

Validation includes four Lua suites, manifest Lua 5.1 compilation and Python packaging/release-tool tests. This does not establish live-client support.

Install the TitanApproxDPS folder from the attached runtime ZIP into Interface/AddOns and restart the client. Open results with /tadps.
