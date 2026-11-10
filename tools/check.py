#!/usr/bin/env python3
import pathlib, shutil, subprocess
root=pathlib.Path(__file__).resolve().parents[1]
lua=shutil.which('luajit')
if not lua: raise SystemExit('LuaJIT required (Lua 5.1 semantics)')
for suite in sorted((root/'tests').glob('*.lua')):
    subprocess.run([lua,str(suite)],cwd=root,check=True)
for line in (root/'TitanApproxDPS/TitanApproxDPS.toc').read_text().splitlines():
    if line.endswith('.lua'):
        subprocess.run([lua,'-e','assert(loadfile(arg[1])); os.exit(0)',str(root/'TitanApproxDPS'/line)],check=True)
print('PASS all suites and manifest-loaded Lua files compile')
import sys
subprocess.run([sys.executable,'-m','unittest','discover','-s','tests','-p','test_*.py'],cwd=root,check=True)
