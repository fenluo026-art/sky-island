from pathlib import Path
import sys

root = Path(__file__).resolve().parents[2]
required = [
    root/"project.godot",
    root/"export_presets.cfg",
    root/"scenes/main.tscn",
    root/"scripts/main.gd",
]
missing = [str(p) for p in required if not p.exists()]
if missing:
    print("Missing required files:", *missing, sep="\n")
    sys.exit(1)

project = (root/"project.godot").read_text()
preset = (root/"export_presets.cfg").read_text()
if 'package/unique_name="com.fenluo.skyisland"' not in preset:
    print("ERROR: Android package id missing from export preset")
    sys.exit(1)
if 'version/name="1.1.0"' not in project:
    print("ERROR: project version is not 1.1.0")
    sys.exit(1)
if 'path: build/SkyIsland-1.1.0.apk' not in (root/".github/workflows/build.yml").read_text():
    print("ERROR: workflow artifact path mismatch")
    sys.exit(1)

print("Static project checks: PASS")
