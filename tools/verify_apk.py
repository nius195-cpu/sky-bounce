#!/usr/bin/env python3
"""Reject an Android shell accidentally built without Godot game content."""
import sys
import re
from pathlib import Path
import zipfile

apk = Path(sys.argv[1])
with zipfile.ZipFile(apk) as archive:
    names = set(archive.namelist())
    for required in ("AndroidManifest.xml", "classes.dex", "assets/project.binary",
                     "assets/_cl_", "lib/arm64-v8a/libgodot_android.so"):
        if required not in names:
            sys.exit("APK validation failed, missing: " + required)
    if "assets/main.tscn.remap" in names:
        remap = archive.read("assets/main.tscn.remap").decode("utf-8")
        match = re.search(r'path="res://([^"]+)"', remap)
        if not match or "assets/" + match[1] not in names:
            sys.exit("APK validation failed: exported main scene missing")
    elif "assets/main.tscn" not in names:
        sys.exit("APK validation failed: main scene missing")
    bad_file = archive.testzip()
    if bad_file:
        sys.exit("APK validation failed, corrupt entry: " + bad_file)
print(f"Validated playable Godot APK: {apk} ({apk.stat().st_size:,} bytes)")
