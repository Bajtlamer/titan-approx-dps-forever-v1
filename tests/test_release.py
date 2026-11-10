import importlib.util, pathlib, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class Release(unittest.TestCase):
 def test_version_and_publish_order(self):
  spec=importlib.util.spec_from_file_location('release',ROOT/'tools/release.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
  commands=m.commands('0.1.0-alpha',pathlib.Path('/tmp/game'),pathlib.Path('release-notes/ref-v0.1.0-alpha.md'))
  apply=next(i for i,c in enumerate(commands) if '--apply' in c)
  push=next(i for i,c in enumerate(commands) if c[:2]==['git','push'])
  publish=next(i for i,c in enumerate(commands) if c[:3]==['gh','release','create'])
  self.assertLess(apply,push);self.assertLess(push,publish)
  self.assertIn('--prerelease',commands[publish]);self.assertIn('--verify-tag',commands[publish]);self.assertNotIn('--force',sum(commands,[]))
 def test_manifest_drives_package_version(self):
  spec=importlib.util.spec_from_file_location('package',ROOT/'tools/package.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
  self.assertEqual(m.version(),'0.1.0-alpha')
if __name__=='__main__':unittest.main()
