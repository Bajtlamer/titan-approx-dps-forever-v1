#!/usr/bin/env python3
"""Preview or execute verified local installation followed by a GitHub prerelease."""
import argparse
import pathlib
import re
import shlex
import subprocess
import sys
ROOT = pathlib.Path(__file__).resolve().parents[1]
REPO = 'Bajtlamer/titan-approx-dps-forever-v1'
DEFAULT_ADDONS = pathlib.Path('/Applications/World of Warcraft/_forever_/Interface/AddOns')
def commands(version, addons_dir, notes):
    tag = 'v' + version
    result = [
        [sys.executable, 'tools/check.py'],
        [sys.executable, 'tools/package.py'],
        [sys.executable, 'tools/install.py', '--addons-dir', str(addons_dir)],
        [sys.executable, 'tools/install.py', '--addons-dir', str(addons_dir), '--apply'],
        ['git', 'tag', tag],
        ['git', 'push', 'origin', 'HEAD', 'refs/tags/' + tag],
        ['gh', 'release', 'create', tag,
         'dist/TitanApproxDPS-' + version + '.zip', 'dist/SHA256SUMS',
         '--repo', REPO, '--verify-tag', '--title', 'Titan Approx DPS ' + version,
         '--notes-file', str(notes)],
    ]
    if '-' in version:
        result[-1].append('--prerelease')
    return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--publish', action='store_true')
    parser.add_argument('--addons-dir', type=pathlib.Path, default=DEFAULT_ADDONS)
    args = parser.parse_args()
    toc = (ROOT/'TitanApproxDPS/TitanApproxDPS.toc').read_text()
    version = re.search(r'^## Version: (\S+)$', toc, re.M).group(1)
    notes = pathlib.Path('release-notes/ref-v' + version + '.md')
    if not (ROOT/notes).is_file():
        raise SystemExit('Create reviewed release notes first: ' + str(notes))
    planned = commands(version, args.addons_dir, notes)
    if not args.publish:
        for command in planned:
            print(shlex.join(command))
        print('Preview only. --publish executes all steps and stops on the first failure.')
        return
    def output(command):
        return subprocess.check_output(command, cwd=ROOT, text=True).strip()
    if output(['git','status','--porcelain']):
        raise SystemExit('Commit all source changes before release publication.')
    remote = output(['git','remote','get-url','origin'])
    if remote not in ('https://github.com/'+REPO+'.git', 'git@github.com:'+REPO+'.git'):
        raise SystemExit('Origin does not match the authorized repository.')
    subprocess.run(['gh','repo','view',REPO,'--json','nameWithOwner'],cwd=ROOT,check=True)
    for command in planned:
        subprocess.run(command, cwd=ROOT, check=True)
if __name__ == '__main__':
    main()
