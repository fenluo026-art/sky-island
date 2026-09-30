from pathlib import Path
import sys

root = Path(__file__).resolve().parents[2]
required = [
    root / "project.godot",
    root / "export_presets.cfg",
    root / "scenes/main.tscn",
    root / "scripts/main.gd",
]
missing = [str(p) for p in required if not p.exists()]
if missing:
    print("Missing required files:", *missing, sep="\n")
    sys.exit(1)

project = (root / "project.godot").read_text()
preset = (root / "export_presets.cfg").read_text()
workflow = (root / ".github/workflows/build.yml").read_text()

checks = [
    ('package/unique_name="com.fenluo.skyisland"' in preset,
     "Android package id missing from export preset"),
    ('version/name="1.1.2"' in project,
     "project version is not 1.1.2"),
    ('build/SkyIsland-1.1.2.apk' in workflow,
     "workflow APK path mismatch"),
]
for ok, message in checks:
    if not ok:
        print("ERROR:", message)
        sys.exit(1)

print("Static project checks: PASS")
