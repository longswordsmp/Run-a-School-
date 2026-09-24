# Prints a checksum per source file, matching tools/checksum.lua run in Studio.
# checksum = (len, sum over bytes of b * (i % 251 + 1)) mod 2^31, CRLF normalised to LF,
# trailing newline stripped (Studio drops it).
import sys, pathlib

MAP = {
    "Shared/Config.lua": "ReplicatedStorage.Shared.Config",
    "Shared/UI.lua": "ReplicatedStorage.Shared.UI",
    "Server/Walkers.lua": "ServerScriptService.Server.Walkers",
    "Server/Remotes.lua": "ServerScriptService.Server.Remotes",
    "Server/DataService.lua": "ServerScriptService.Server.DataService",
    "Server/StudentProps.lua": "ServerScriptService.Server.StudentProps",
    "Server/StudentFactory.lua": "ServerScriptService.Server.StudentFactory",
    "Server/PlotService.lua": "ServerScriptService.Server.PlotService",
    "Server/HallService.lua": "ServerScriptService.Server.HallService",
    "Server/DebugBridge.lua": "ServerScriptService.Server.DebugBridge",
    "Server/StealService.lua": "ServerScriptService.Server.StealService",
    "Server/SchoolService.lua": "ServerScriptService.Server.SchoolService",
    "Server/Main.server.lua": "ServerScriptService.Server.Main",
    "Client/HUD.client.lua": "StarterPlayer.StarterPlayerScripts.HUD",
    "Client/Menus.client.lua": "StarterPlayer.StarterPlayerScripts.Menus",
    "Client/Prompts.client.lua": "StarterPlayer.StarterPlayerScripts.Prompts",
    "Client/Effects.client.lua": "StarterPlayer.StarterPlayerScripts.Effects",
}

root = pathlib.Path(__file__).resolve().parent.parent / "src"
for rel, path in MAP.items():
    f = root / rel
    if not f.exists():
        continue
    data = f.read_bytes().replace(b"\r\n", b"\n").rstrip(b"\n")
    s = 0
    for i, b in enumerate(data):
        s = (s + b * (i % 251 + 1)) % 2147483648
    print(f"{path} {len(data)} {s}")
