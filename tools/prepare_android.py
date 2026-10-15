#!/usr/bin/env python3
"""Install pinned Godot Android binaries and configure local SDK/debug signing.

The Gradle project is committed under android/build. Large engine AARs are
restored from the matching official export templates rather than stored in Git.
Only the Android entries at the start of the official TPZ are downloaded.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import urllib.request
import zipfile
import zlib

ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.6.3.stable"
URL = ("https://github.com/godotengine/godot/releases/download/4.6.3-stable/"
       "Godot_v4.6.3-stable_export_templates.tpz")
HASHES = {
    "android_debug.apk": "5cd4cfc1a8fc23ed45be5f0a36a6cc279d15b50a40c6ef69c89276895441cd1d",
    "android_release.apk": "e91ef7e517e73aec1ddcc4c455c5fd53de1837c240a7c520ac438b73874b54c1",
    "android_source.zip": "c260fe8ab52ee0627d4d27a07117f7a7f04ce2a73cef7356a032fac0e1998009",
}
LIBRARIES = {
    "libs/debug/godot-lib.template_debug.aar": "a0d9c91163a2749531009099279525abc26f988d2f6b66f2840c60fa4f41e9c1",
    "libs/release/godot-lib.template_release.aar": "9589a935fa0d21b829adc9fd946b22af4d42577676410e4c2faa9a89d1914ef6",
}


def digest(path: Path) -> str:
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def read_exact(stream, size: int) -> bytes:
    chunks = []
    while size:
        data = stream.read(min(size, 1024 * 1024))
        if not data:
            raise RuntimeError("Official template download ended early; retry preparation.")
        chunks.append(data)
        size -= len(data)
    return b"".join(chunks)


def download_android_entries(destination: Path) -> None:
    """Stream ZIP local entries, validating each output against a pinned SHA256.

    This avoids downloading unrelated desktop/iOS templates in the 1.2GB TPZ.
    No untrusted archive paths are used: only the three names above are written.
    """
    print("Downloading Godot 4.6.3 Android templates (~435 MB)...", flush=True)
    request = urllib.request.Request(URL, headers={"User-Agent": "SkyBounce-Android-Build"})
    found = set()
    with urllib.request.urlopen(request, timeout=180) as stream:
        while len(found) != len(HASHES):
            header = struct.unpack("<IHHHHHIIIHH", read_exact(stream, 30))
            signature, _, flags, method, _, _, _, compressed, _, name_len, extra_len = header
            if signature != 0x04034B50 or flags & 8 or compressed == 0xFFFFFFFF:
                raise RuntimeError("Unexpected Godot archive structure; update the pinned installer.")
            name = read_exact(stream, name_len).decode("utf-8")
            read_exact(stream, extra_len)
            basename = Path(name).name
            wanted = name == "templates/" + basename and basename in HASHES
            if wanted:
                if method != 8:
                    raise RuntimeError("Unexpected Godot compression method.")
                output = destination / basename
                partial = output.with_suffix(output.suffix + ".partial")
                inflater = zlib.decompressobj(-15)
                with partial.open("wb") as handle:
                    while compressed:
                        data = read_exact(stream, min(compressed, 1024 * 1024))
                        compressed -= len(data)
                        handle.write(inflater.decompress(data))
                    handle.write(inflater.flush())
                if not inflater.eof or digest(partial) != HASHES[basename]:
                    partial.unlink(missing_ok=True)
                    raise RuntimeError("Checksum mismatch for " + basename)
                partial.replace(output)
                found.add(basename)
                print("Verified " + basename, flush=True)
            else:
                while compressed:
                    chunk = min(compressed, 1024 * 1024)
                    read_exact(stream, chunk)
                    compressed -= chunk


def main() -> None:
    sdk_value = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    java_value = os.environ.get("JAVA_HOME")
    if not sdk_value or not java_value:
        raise RuntimeError("Set ANDROID_HOME (Android SDK) and JAVA_HOME (JDK 17+) first.")
    sdk, java = Path(sdk_value).resolve(), Path(java_value).resolve()
    if not all((java / "bin" / tool).is_file() for tool in ("java", "javac", "keytool")):
        raise RuntimeError("JAVA_HOME must point to a full JDK with java, javac, and keytool (not a JRE).")
    for required in ("platform-tools/adb", "platforms/android-36/android.jar", "build-tools/36.1.0/apksigner"):
        if not (sdk / required).is_file():
            raise RuntimeError("Missing SDK component: " + required + ". See docs/ANDROID.md.")
    data_root = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
    config_root = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    templates = data_root / "godot/export_templates" / VERSION
    templates.mkdir(parents=True, exist_ok=True)
    if any(not (templates / name).is_file() or digest(templates / name) != sha
           for name, sha in HASHES.items()):
        download_android_entries(templates)
    project = ROOT / "android/build"
    for required in ("build.gradle", "settings.gradle", "config.gradle", "gradle.properties",
                     "gradlew", "gradle/wrapper/gradle-wrapper.jar",
                     "gradle/wrapper/gradle-wrapper.properties", "src/main/AndroidManifest.xml"):
        if not (project / required).is_file():
            raise RuntimeError("Incomplete checkout: missing android/build/" + required)
    if (ROOT / "android/.build_version").read_text().strip() != VERSION:
        raise RuntimeError("Android Gradle template version does not match Godot " + VERSION)
    with zipfile.ZipFile(templates / "android_source.zip") as source:
        for name, sha in LIBRARIES.items():
            destination = project / name
            if not destination.is_file() or digest(destination) != sha:
                destination.parent.mkdir(parents=True, exist_ok=True)
                with source.open(name) as reader, destination.open("wb") as writer:
                    shutil.copyfileobj(reader, writer)
                if digest(destination) != sha:
                    raise RuntimeError("Engine AAR checksum mismatch: " + name)
        for entry in source.infolist():
            if entry.filename.startswith("res/") and not entry.is_dir():
                target = project / entry.filename
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(source.read(entry))
    (project / "gradlew").chmod(0o755)
    key = config_root / "godot/sky-bounce-debug.keystore"
    key.parent.mkdir(parents=True, exist_ok=True)
    if not key.is_file():
        subprocess.run([str(java / "bin/keytool"), "-genkeypair", "-noprompt",
                        "-keystore", str(key), "-storepass", "android", "-alias", "androiddebugkey",
                        "-keypass", "android", "-dname", "CN=Android Debug,O=Android,C=US",
                        "-keyalg", "RSA", "-keysize", "2048", "-validity", "10000"], check=True)
    # A separate settings file avoids overwriting a developer's editor settings.
    settings = ROOT / ".godot/android-config/godot/editor_settings-4.6.tres"
    settings.parent.mkdir(parents=True, exist_ok=True)
    values = {
        "export/android/android_sdk_path": str(sdk),
        "export/android/java_sdk_path": str(java),
        "export/android/debug_keystore": str(key),
        "export/android/debug_keystore_user": "androiddebugkey",
        "export/android/debug_keystore_pass": "android",
    }
    text = '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    text += "".join(f"{name} = {json.dumps(value)}\n" for name, value in values.items())
    settings.write_text(text)
    print("Android Gradle project ready. Debug signing configured (not for store releases).")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError) as exc:
        sys.exit("Android preparation failed: " + str(exc))
