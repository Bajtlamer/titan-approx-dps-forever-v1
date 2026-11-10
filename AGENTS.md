# Titan Approx DPS Forever

Target Forever 1.60.1, interface 16001. Runtime uses Lua 5.1 semantics. Preserve post-fight-only analysis, separate combat modes, unknown evidence and existing statistics. Do not register combat-log events or invent crit/miss/weapon attribution.

## Validation and releases

- Run `python3 tools/check.py` before completing runtime updates, installation, or release publication.
- User explicitly authorizes using git and gh to version and publish this project's source and release packages to `https://github.com/Bajtlamer/titan-approx-dps-forever-v1.git`.
- User explicitly authorizes automatic local installation of every release into `/Applications/World of Warcraft/_forever_/Interface/AddOns` using `tools/install.py`. Do not ask again for that task authorization.
- Preview installation, then apply with the backed-up installer; verify installed bytes. Preserve other AddOns, enablement and SavedVariables. Never restart the game automatically.
- Publish the runtime ZIP and SHA256SUMS as GitHub release assets, with the matching version tag and accurate release notes. Alpha versions are prereleases. The GitHub automatic source ZIP is not the installable package.
- Increment the patch version for each completed new runtime release; synchronize manifest and Namespace.lua. Never replace an existing release version with different bytes. Packaging/tooling-only changes do not alter the runtime version.
- Use `python3 tools/release.py` for a preview of the tested-install-and-publication sequence; `--publish` executes it. Source commits may be pushed separately when release installation is blocked.
- Respect sandbox/network permissions. Report blocked installation or publication honestly; do not bypass restrictions or claim local commits are published.

## Repository hygiene

Runtime files live only in TitanApproxDPS/. Tools, tests and prefixed documents stay at root. Exclude dist/, private captures, SavedVariables and temporary data from Git. Do not copy third-party AddOn code without applicable rights.

Documentation uses plan-, ref-, book-, Codex- and tmp- prefixes. Temporary tmp-* files are ignored and removed after use. No emoji, decorative glyphs or em dashes in text.
