from pathlib import Path
import sys

# .github/validate_project.py -> repository root is one parent above .github.
root = Path(__file__).resolve().parents[1]

required = [
    "project.godot",
    "export_presets.cfg",
    "scenes/main.tscn",
    "scripts/main.gd",
    "scripts/core/world_definition.gd",
    "scripts/core/world_coordinates.gd",
    "scripts/core/chunk_key.gd",
    "scripts/core/lod_profile.gd",
    "scripts/core/performance_budget.gd",
    "scripts/world/world_layer.gd",
    "scripts/world/world_region.gd",
    "scripts/world/chunk_manager.gd",
    "scripts/camera/sandbox_camera.gd",
    "scripts/ui/layer_debug_panel.gd",
    ".github/workflows/build.yml",
]

missing = [path for path in required if not (root / path).is_file()]
if missing:
    print("Missing required files:", *missing, sep="\n")
    sys.exit(1)

project = (root / "project.godot").read_text()
preset = (root / "export_presets.cfg").read_text()
main_script = (root / "scripts/main.gd").read_text()
chunk_manager = (root / "scripts/world/chunk_manager.gd").read_text()
world_definition = (root / "scripts/core/world_definition.gd").read_text()
workflow = (root / ".github/workflows/build.yml").read_text()

checks = [
    ('version/name="1.2.0"' in project, "project version is not 1.2.0"),
    ('version/name="1.2.0"' in preset, "export preset version is not 1.2.0"),
    ("80000.0" in world_definition or "80_000.0" in world_definition,
     "80,000 km² world definition missing"),
    ("layer_id" in chunk_manager and "coordinate" in chunk_manager,
     "layer-aware ChunkKey system missing"),
    ("--export-debug" in workflow, "Android workflow must use debug export"),
    ("build/SkyIsland-1.2.0.apk" in workflow, "workflow APK path mismatch"),
    ("WorldCoordinates" in main_script, "main scene is not wired to world coordinates"),
]

for ok, message in checks:
    if not ok:
        print("ERROR:", message)
        sys.exit(1)

print("Static project checks: PASS")
