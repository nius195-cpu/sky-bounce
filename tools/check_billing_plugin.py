#!/usr/bin/env python3
"""Verify vendored official plugin files without downloading mutable dependencies."""
import hashlib
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1] / 'addons/GodotGooglePlayBilling'
lock = json.loads((root / 'UPSTREAM.json').read_text())
for name, expected in lock['files'].items():
    path = root / name
    assert path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == expected, f'Billing plugin mismatch: {name}'
assert lock['release'] == '3.3.0' and lock['billing_library'] == '9.1.0'
print('Official Godot billing plugin 3.3.0 / Billing Library 9.1.0 checksums verified')
