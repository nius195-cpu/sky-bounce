#!/usr/bin/env python3
"""Validate actual AAB contents, manifest, billing metadata and release flags."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

bundle = Path(sys.argv[1])
mode = sys.argv[2]
root = Path(__file__).resolve().parents[1]
tool = root / '.godot/bundletool-all-1.18.3.jar'
expected = 'a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29'
if not tool.is_file() or hashlib.sha256(tool.read_bytes()).hexdigest() != expected:
    tool.parent.mkdir(exist_ok=True)
    with urllib.request.urlopen('https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar', timeout=120) as response, tool.open('wb') as output:
        import shutil
        shutil.copyfileobj(response, output)
    assert hashlib.sha256(tool.read_bytes()).hexdigest() == expected, 'bundletool checksum mismatch'
java = str(Path(os.environ['JAVA_HOME']) / 'bin/java')
subprocess.run([java, '-jar', str(tool), 'validate', '--bundle=' + str(bundle)], check=True)
manifest = subprocess.check_output([java, '-jar', str(tool), 'dump', 'manifest', '--bundle=' + str(bundle), '--module=base'])
xml = ET.fromstring(manifest)
a = '{http://schemas.android.com/apk/res/android}'
application = xml.find('application')
assert xml.attrib['package'] == 'org.skybounce.keepitup'
assert application is not None
assert application.get(a + 'debuggable', 'false') == 'false', 'Release is debuggable'
assert application.get(a + 'testOnly', 'false') == 'false', 'Release is test-only'
profileable = application.find('profileable')
assert profileable is None or profileable.get(a + 'enabled', 'false') == 'false', 'Production profiling is enabled'
sdk = xml.find('uses-sdk')
assert sdk is not None and int(sdk.get(a + 'targetSdkVersion')) >= 36
permissions = sorted(p.get(a + 'name') for p in xml.findall('uses-permission'))
allowed = {'com.android.vending.BILLING', 'android.permission.INTERNET', 'android.permission.ACCESS_NETWORK_STATE'}
assert 'com.android.vending.BILLING' in permissions, 'Billing permission missing'
assert not (set(permissions) - allowed), 'Unexpected permissions: ' + str(set(permissions) - allowed)
metadata = {p.get(a + 'name'): p.get(a + 'value') for p in application.findall('meta-data')}
assert metadata.get('com.google.android.play.billingclient.version') == '9.1.0', 'Wrong billing library'
with zipfile.ZipFile(bundle) as archive:
    names = archive.namelist()
    for required in ['BundleConfig.pb', 'base/assets/project.binary', 'base/assets/_cl_', 'base/dex/classes.dex', 'base/lib/arm64-v8a/libgodot_android.so']:
        assert required in names, 'Missing release game content: ' + required
    assert not any(n.startswith('base/assets/tests/') or n.startswith('base/assets/tools/') for n in names), 'Development tools included'
    assert archive.testzip() is None
    signed = any(n.upper().startswith('META-INF/') and n.upper().endswith(('.RSA', '.DSA', '.EC')) for n in names)
    assert signed == (mode == 'signed'), 'Unexpected AAB signing state'
report = {'application_id': xml.attrib['package'], 'version_name': xml.get(a+'versionName'), 'version_code': xml.get(a+'versionCode'), 'target_sdk': sdk.get(a+'targetSdkVersion'), 'debuggable': False, 'test_only': False, 'profileable': False, 'billing_library': metadata.get('com.google.android.play.billingclient.version'), 'permissions': permissions, 'mode': mode, 'aab_signed': signed, 'requires_play_console_review_and_tests': True, 'note': 'Build validation is not Google Play approval or a real billing transaction test.'}
bundle.with_suffix('.verification.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
