# Pulsefall

Pulsefall is a compact Godot 4 survival-action prototype. Move through the neon arena, collect XP, choose five upgrades, and defeat the spiked Overseer boss.

## Run

Open `project.godot` in Godot 4.7.1 or run from PowerShell:

```powershell
& 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64.exe' --path .
```

Controls:

- Move with `WASD` or the arrow keys.
- Select upgrades and restart with the mouse.
- The weapon fires automatically at the nearest enemy.

## Verify

Run the full headless regression suite from the repository root:

```powershell
$godot = 'C:\MyFiles\Godot\Godot_v4.7.1-stable_win64_console.exe'
& $godot --headless --editor --path . --quit
foreach ($id in '00','01','02','03','04','05','06','07','08','09') {
    & $godot --headless --path . --script "res://tests/verify_f$id.gd"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
& $godot --headless --path . --fixed-fps 60 --quit-after 3600
git diff --check
```
