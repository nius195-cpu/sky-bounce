#!/usr/bin/env python3
"""Build a release AAB; signing uses ephemeral files and masked output only.

RELEASE_MODE=unsigned produces a validation artifact, NOT a Play-uploadable file.
RELEASE_MODE=signed requires private GitHub secrets. This script never publishes.
"""
from __future__ import annotations
import base64
import hashlib
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
mode = os.environ.get('RELEASE_MODE', 'unsigned')
if mode not in ('unsigned', 'signed'):
    raise SystemExit('RELEASE_MODE must be unsigned or signed')
secrets = []

def run(command, env=None):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
    for line in process.stdout:
        for value in secrets:
            line = line.replace(value, '***')
        line = re.sub(r'(release_keystore_password\s*[=:]\s*)\S+', r'\1***', line, flags=re.I)
        print(line, end='', flush=True)
    if process.wait() != 0:
        raise SystemExit('Release build command failed; inspect the sanitized output above.')

required = ['ANDROID_UPLOAD_KEYSTORE_BASE64', 'ANDROID_UPLOAD_KEY_ALIAS', 'ANDROID_UPLOAD_KEYSTORE_PASSWORD']
if mode == 'signed':
    if any(not os.environ.get(key) for key in required):
        raise SystemExit('Signed AAB requires all three ANDROID_UPLOAD_* GitHub secrets. No debug key will be substituted.')
    secrets = [os.environ[key] for key in required]
    if any('\n' in os.environ[key] or '\r' in os.environ[key] for key in required[1:]):
        raise SystemExit('Signing alias and password must each be a single line.')
run(['python3', 'tools/check_billing_plugin.py'])
run(['python3', 'tools/prepare_android.py'])
engine = os.environ.get('GODOT_BIN', 'godot')
environment = os.environ.copy()
environment['XDG_CONFIG_HOME'] = str(ROOT / '.godot/android-config')
run([engine, '--headless', '--editor', '--import', '--quit'], environment)
run([engine, '--headless', '--script', 'res://tests/run.gd'], environment)
original = (ROOT / 'export_presets.cfg').read_text()
output = ROOT / 'builds/release'
output.mkdir(parents=True, exist_ok=True)
bundle = output / f'sky-bounce-{mode}.aab'
try:
    with tempfile.TemporaryDirectory(prefix='sky-bounce-signing-', dir=os.environ.get('RUNNER_TEMP', '/tmp')) as temporary:
        if mode == 'unsigned':
            section, marker, rest = original.partition('[preset.1.options]')
            options, following, tail = rest.partition('[preset.2]')
            assert marker and following and 'package/signed=true' in options
            options = options.replace('package/signed=true', 'package/signed=false')
            (ROOT / 'export_presets.cfg').write_text(section + marker + options + following + tail)
        else:
            key = Path(temporary) / 'upload.jks'
            try:
                key.write_bytes(base64.b64decode(os.environ[required[0]], validate=True))
            except Exception:
                raise SystemExit('Invalid signing-keystore encoding; no key contents were logged.')
            key.chmod(0o600)
            environment.update({
                'GODOT_ANDROID_KEYSTORE_RELEASE_PATH': str(key),
                'GODOT_ANDROID_KEYSTORE_RELEASE_USER': os.environ[required[1]],
                'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD': os.environ[required[2]],
            })
        run([engine, '--headless', '--export-release', 'Google Play', str(bundle)], environment)
        if mode == 'signed':
            run([str(Path(os.environ['JAVA_HOME']) / 'bin/jarsigner'), '-verify', str(bundle)])
finally:
    (ROOT / 'export_presets.cfg').write_text(original)
# Validate the actual release artifact with official bundletool, not just a ZIP file.
run(['python3', 'tools/verify_release.py', str(bundle), mode])
checksum = hashlib.sha256(bundle.read_bytes()).hexdigest()
bundle.with_suffix('.aab.sha256').write_text(checksum + '  ' + bundle.name + '\n')
print(f'Release {mode} bundle created. No Play upload or purchase was performed.')
