import pathlib, subprocess, sys, tempfile, unittest, zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
class Packaging(unittest.TestCase):
 def test_runtime_and_safe_install(self):
  subprocess.run([sys.executable,'tools/package.py'],cwd=ROOT,check=True,capture_output=True)
  with zipfile.ZipFile(ROOT/'dist/TitanApproxDPS-0.1.0-alpha.zip') as z:
   self.assertIn('TitanApproxDPS/Core.lua',z.namelist())
   self.assertTrue(all(p.startswith('TitanApproxDPS/') and not p.endswith('.md') for p in z.namelist()))
  with tempfile.TemporaryDirectory() as t:
   base=pathlib.Path(t);other=base/'Other';other.mkdir();(other/'keep').write_text('safe')
   cmd=[sys.executable,'tools/install.py','--addons-dir',t]
   subprocess.run(cmd,cwd=ROOT,check=True,capture_output=True);self.assertFalse((base/'TitanApproxDPS').exists())
   subprocess.run(cmd+['--apply'],cwd=ROOT,check=True,capture_output=True)
   self.assertEqual((base/'TitanApproxDPS/Core.lua').read_bytes(),(ROOT/'TitanApproxDPS/Core.lua').read_bytes())
   self.assertEqual((other/'keep').read_text(),'safe')
if __name__=='__main__':unittest.main()
