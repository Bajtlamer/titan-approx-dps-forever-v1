# Release procedure

The user authorizes publishing source and releases to Bajtlamer/titan-approx-dps-forever-v1 and installing every release into the local Forever AddOns directory. See AGENTS.md.

1. Complete the runtime change and increase the patch version in the manifest and Namespace.lua. Retain alpha while the runtime remains a development candidate. Packaging-only edits do not require a runtime bump.
2. Write release-notes/ref-vVERSION.md describing actual behavior, tests and remaining live limitations.
3. Run python3 tools/check.py. Inspect git diff and git status for private captures, SavedVariables, temporary files or unrelated changes. Commit reviewed source.
4. Run python3 tools/release.py to inspect the release sequence, then the same command with --publish. It checks the remote and clean tree, reruns verification, packages, previews/applies backed-up local installation, verifies bytes, tags the commit, pushes source/tag and creates the GitHub release with ZIP/checksums. Alpha versions use prerelease status.
5. Confirm the remote commit and tag and inspect release assets with gh release view vVERSION --repo Bajtlamer/titan-approx-dps-forever-v1. Download the ZIP/checksums to a temporary directory and compare hashes. Source push alone is not a published runtime package.
6. Tell the player to restart WoW for initial installation/new manifest assets, or use /reload for Lua-only updates. Never close the game automatically.

The sequence stops on errors. An existing local tag is not overwritten. For a retry after partial publication, inspect local and remote tags/releases first and complete only the missing steps, preserving original runtime bytes. Never force-push or delete releases automatically.

If installation permissions or GitHub access are unavailable, retain the verified local package and source commit, record the exact failure, and report which requested actions remain undone. The standing user authorization persists; missing environment access is not a reason to ask for task permission again.
