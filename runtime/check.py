#!/usr/bin/env python3
"""Regression and emulator checks, invoked by runtime/build.py check.

The emulator checks compare original placement, independently relocated module
layouts, public-entry provenance, constants, output, and source-disk hashes.
"""

from datetime import datetime, timezone
import json
from pathlib import Path
import sys
import tempfile
import unittest

from paths import ROOT, TOOLS, RUNTIME, BUILD
from corpus import BASE, catalog, find_volume, pack, sha, volume_words
sys.path.insert(0,str(TOOLS))
import libmatch


class Regressions(unittest.TestCase):
    def test_catalog_gap(self):
        _,words=volume_words(find_volume())
        entries=catalog(words)
        entry=next(e for e in entries if e['start']=='0101')
        self.assertEqual(entry['zones'],'0003')
        self.assertFalse(any(int(e['start'],8)<=0o104<int(e['start'],8)+int(e['zones'],8)
                             for e in entries))

    def test_extract_provenance(self):
        directory=RUNTIME
        corpus=json.loads((directory/'corpus.json').read_text())
        _,words=volume_words(find_volume())
        self.assertEqual(len(corpus['images']),26)
        for record in corpus['images']:
            start=int(record['zone'],8)*1024+int(record['zone_word'],8)
            expected=pack(words[start:start+record['words']])
            self.assertEqual((directory/record['path']).read_bytes(),expected)
            self.assertEqual(sha(expected),record['sha256'])

    def test_map_ignored_listing_noise_and_kept_high_addresses(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'map.lst'
            path.write_text(' FROM 02000\n PASCODER 01000 P/2 10752\n'
                            ' P/E E 10761 P/1D C 10136 CBOБOД 11563\n\n')
            symbols=libmatch.load_symbols(path)
        self.assertNotIn('FROM',{s.name for s in symbols})
        self.assertEqual(next(s.address for s in symbols if s.name=='P/2'),0o10752)
        self.assertEqual(next(s.kind for s in symbols if s.name=='P/1D'),'C')

    def test_entry_alias_did_not_cut_module(self):
        symbols=[libmatch.Symbol('P/X',BASE,'M'),libmatch.Symbol('P/Y',BASE+1,'E'),
                 libmatch.Symbol('FREE',BASE+3,'Z')]
        section=libmatch.sections(symbols,BASE,8)[0]
        self.assertEqual(section[1],BASE+3)
        self.assertEqual(section[2][0].name,'P/Y')

    def test_numeric_immediate_changed(self):
        ref=[(0o42400003<<24)|0o2200000]
        target=[(0o42400004<<24)|0o2200000]
        self.assertIsNone(libmatch.match_at(ref,target,BASE,BASE+1,0,BASE))

    def test_indexed_offset_changed(self):
        ref=[(0o10100003<<24)|0o2200000]
        target=[(0o10100004<<24)|0o2200000]
        self.assertIsNone(libmatch.match_at(ref,target,BASE,BASE+1,0,BASE))

    def test_internal_branch_was_not_relocated(self):
        ref=[((0o03000000|BASE+1)<<24)|0o2200000,0o6700000002200000]
        target=[1,1]+ref
        self.assertIsNone(libmatch.match_at(ref,target,BASE,BASE+2,2,BASE))

    def test_ambiguity_was_retained(self):
        ref=[0o6700000002200000]
        symbols=[libmatch.Symbol('P/X',BASE,'M'),libmatch.Symbol('FREE',BASE+1,'Z')]
        result=libmatch.find_candidates(ref,symbols,ref+ref)
        self.assertEqual(len(result[0]['matches']),2)

    def test_zero_block_was_not_a_match(self):
        symbols=[libmatch.Symbol('P/X',BASE,'M'),libmatch.Symbol('FREE',BASE+2,'Z')]
        self.assertEqual(libmatch.find_candidates([0,0],symbols,[0]*8),[])


def disk_paths():
    from build import environment
    paths=[find_volume()]+list(ROOT.glob('*.bin'))
    for volume in ('77','2113','2148','2048'):
        for directory in environment(BUILD)['BESM6_PATH'].split(':'):
            path=Path(directory)/volume
            if path.is_file():
                paths.append(path)
                break
    return paths


def check():
    import build
    directory=RUNTIME
    unit=unittest.TextTestRunner(verbosity=2).run(
        unittest.defaultTestLoader.loadTestsFromTestCase(Regressions))
    if not unit.wasSuccessful():
        raise RuntimeError('regression checks failed')
    snapshots={str(p):sha(p.read_bytes()) for p in disk_paths()}
    results=[]
    for profile in ('monitor','svs','mark3','pak'):
        build.golden(profile)
        for name,expected in [('smoke','RUNTIME 41\nABC'),('nested','NESTED 43')]:
            result=build.run(profile,directory/'examples'/(name+'.pas'))
            if expected not in result['output']:
                raise AssertionError(f'{profile}/{name}: wrong output: {result["output"]!r}')
            results.append(dict(profile=profile,scenario=name,**result))
    result=build.run('pak',directory/'examples'/'packed.pas')
    if 'PACKED 66' not in result['output']:
        raise AssertionError('packed-array/set result differs')
    results.append(dict(profile='pak',scenario='packed',**result))
    result=build.run('monitor',directory/'examples'/'bounds.pas')
    if 'OVERANGE IN' not in result['output']:
        raise AssertionError('bounds error was not reported')
    results.append(dict(profile='monitor',scenario='bounds-error',**result))
    try:
        build.run('monitor',directory/'examples'/'unsupported.pas')
    except ValueError as exc:
        if 'unsupported helpers' not in str(exc) or 'P/4' not in str(exc):
            raise
        results.append(dict(profile='monitor',scenario='unsupported-helper',error=str(exc)))
    else:
        raise AssertionError('unsupported P/4 was silently accepted')
    for path,digest in snapshots.items():
        if sha(Path(path).read_bytes())!=digest:
            raise AssertionError(f'source changed during checks: {path}')
    record=dict(checked_at=datetime.now(timezone.utc).isoformat(),
                regression_checks=unit.testsRun,original_placement_profiles=4,
                source_hashes=snapshots,scenarios=results)
    (directory/'validation.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n')
    print(f'Passed {unit.testsRun} regression checks, 4 original-placement comparisons, '
          f'and {len(results)} emulator scenarios; source hashes unchanged.')


if __name__=='__main__':
    check()
