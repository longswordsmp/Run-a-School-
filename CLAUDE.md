# Run a School — working notes

Steal-a-Brainrot style school tycoon for Roblox. The plan and build order are in GAME-PLAN.md;
its Status section says what is done and verified.

## Layout (disk -> Studio)
| Disk | Studio |
|---|---|
| src/Shared/Config.lua | ReplicatedStorage.Shared.Config (ModuleScript) |
| src/Server/*.lua | ServerScriptService.Server.<Name> (ModuleScripts) |
| src/Server/Main.server.lua | ServerScriptService.Server.Main (Script) |
| src/Client/HUD.client.lua | StarterPlayer.StarterPlayerScripts.HUD (LocalScript) |
| tools/build_map.lua | run once in Edit mode via execute_luau; rebuilds Workspace.Map + Workspace.Plots |

Disk is the source of truth. Studio's place is unsaved ("Place1") until tomas does File > Save.

## Getting code into Studio
- Roblox Studio MCP runs on tomas's PC only; a cloud session cannot reach it.
- Whole files: `execute_luau` (Edit) that sets `ModuleScript.Source = [==[ ... ]==]`. Fewer escaping
  mistakes than multi_edit JSON. Small changes: multi_edit with exact strings.
- After pushing, run tools/checksum.lua in Studio and `python tools/checksum.py` locally; every
  line must match.

## Next steps
1. Push PlotService, HallService, Main (Script), HUD (LocalScript). Checksum everything.
2. Play test: students walk off the bus, Enroll one, it walks to your school and sits, cash piles
   on the desk pad, stepping on it pays out. Screenshot + console output as evidence.
3. Tune the sit height in PlotService.sitCFrame from a screenshot.
4. Lineup screenshot of all 20 students to check the props.
5. Then step 3 of the build order (steal, carry, Ruler, lock, sell).

## Rules
- Never claim something works without a screenshot, console output or measurement.
- Bright and saturated look; yellow is fine in this project.
